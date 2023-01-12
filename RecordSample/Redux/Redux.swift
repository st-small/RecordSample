import Combine
import Foundation

// MARK: - Store
final class Store<State, Action>: ObservableObject {
    
    @Published private(set) var state: State
    
    private let middlewares: [(State, Action) -> AnyPublisher<Action, Never>?]
    private let reducer: (inout State, Action) -> Void
    
    private var middlewareCancellables: Set<AnyCancellable> = []
    
    init(
        state: State,
        reducer: @escaping (inout State, Action) -> Void,
        middlewares: [(State, Action) -> AnyPublisher<Action, Never>?]
    ) {
        self.state = state
        self.reducer = reducer
        self.middlewares = middlewares
    }
    
    func dispatch(_ action: Action) {
        reducer(&state, action)
        
        for middleware in middlewares {
            guard let middleware = middleware(state, action) else { break }
            middleware
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: dispatch)
                .store(in: &middlewareCancellables)
        }
    }
}

// MARK: - State
struct AppState: Equatable {
    var permissionsState: PermissionsState = .init()
    var recordAudioState: RecordAudioState = .init()
}

// MARK: - Actions
enum AppAction {
    case scenePhaseActive
    case setRecordAudio(status: RecordPermissionStatus)
    
    // MARK: - Record audio
    case startRecordSession
    case endRecordSession
    case cancelRecordSession
    
    case nop
}

// MARK: - Reducer
func appReducer(state: inout AppState, action: AppAction) -> Void {
    switch action {
    case .scenePhaseActive:
        break
    case let .setRecordAudio(status):
        state.permissionsState.recordAudio = status
    case .startRecordSession:
        print("Reducer: Record session started ... ")
        switch state.permissionsState.recordAudio {
        case .notDetermined:
            break
        case .granted:
            state.recordAudioState = .startRecord(UUID().uuidString)
            
        case .denied:
            state.recordAudioState = .error("Access denied!")
        }
    case .endRecordSession:
        print("Reducer: Record session complete ... ")
        if case let .startRecord(id) = state.recordAudioState {
            state.recordAudioState = .recordingCompete(id)
        }
    case .cancelRecordSession:
        print("Reducer: Record session cancelled ... ")
        if case let .startRecord(id) = state.recordAudioState {
            state.recordAudioState = .recordingCancel(id)
        }
    case .nop:
        break
    }
}

// MARK: - Middleware
func permissionsMiddleware(service: AudioRecordPermissionsProtocol) -> ((AppState, AppAction) -> AnyPublisher<AppAction, Never>?) {
    { state, action in
        switch action {
        case .scenePhaseActive:
            return service.checkStatus()
                .subscribe(on: DispatchQueue.main)
                .map { AppAction.setRecordAudio(status: $0) }
                .eraseToAnyPublisher()
        case .startRecordSession:
            guard state.permissionsState.recordAudio != .granted else {
                return Just(.nop).eraseToAnyPublisher()
            }
            return service.recordRequest()
                .subscribe(on: DispatchQueue.main)
                .map { AppAction.setRecordAudio(status: $0 == true ? .granted : .denied) }
                .eraseToAnyPublisher()
        default:
            break
        }
        
        return Empty().eraseToAnyPublisher()
    }
}

func audioRecorderMiddleware(service: AudioRecorderService) -> ((AppState, AppAction) -> AnyPublisher<AppAction, Never>?) {
    { state, action in
        switch action {
        case .startRecordSession:
            if case let .startRecord(recordId) = state.recordAudioState {
                print("AudioRecorder: Record session started ... ")
                service.startRecord(id: recordId)
            }
        case .endRecordSession:
            if case .recordingCompete = state.recordAudioState {
                service.stopRecord()
                print("AudioRecorder: Record session complete ... ")
            }
        case .cancelRecordSession:
            if case let .recordingCancel(recordId) = state.recordAudioState {
                print("AudioRecorder: Record session cancelled ... ")
                service.cancelRecord(id: recordId)
            }
        default:
            break
        }
        
        return Empty().eraseToAnyPublisher()
    }
}

func messagesMiddleware(service: MessagesService) -> ((AppState, AppAction) -> AnyPublisher<AppAction, Never>?) {
    return { state, action in
        switch action {
        case .endRecordSession:
            if case let .recordingCompete(recordId) = state.recordAudioState {
                service.prepareNewAudioMessage(id: recordId)
            }
        default:
            break
        }
        
        return Empty().eraseToAnyPublisher()
    }
}

// MARK: - Permissions
struct PermissionsState: Equatable {
    var recordAudio: RecordPermissionStatus = .init()
}

enum RecordAudioState: Equatable {
    case pending
    case startRecord(String)
    case recordingCompete(String)
    case recordingCancel(String)
    case error(String)
    
    init() {
        self = .pending
    }
}
