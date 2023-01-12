import AVKit
import Combine

enum RecordPermissionStatus {
    case notDetermined, granted, denied

    init() {
        self = .notDetermined
    }
}

protocol AudioRecordPermissionsProtocol {
    func checkStatus() -> AnyPublisher<RecordPermissionStatus, Never>
    func recordRequest() -> AnyPublisher<Bool, Never>
}

final class AudioRecordPermissions: AudioRecordPermissionsProtocol {
    private let session = AVAudioSession.sharedInstance()

    func checkStatus() -> AnyPublisher<RecordPermissionStatus, Never> {
        switch session.recordPermission {
        case .undetermined:
            return Just(.notDetermined).eraseToAnyPublisher()
        case .denied:
            return Just(.denied).eraseToAnyPublisher()
        case .granted:
            return Just(.granted).eraseToAnyPublisher()
        @unknown default:
            return Just(.notDetermined).eraseToAnyPublisher()
        }
    }

    func recordRequest() -> AnyPublisher<Bool, Never> {
        Future<Bool, Never> { [weak self] promise in
            self?.session.requestRecordPermission { granted in
                promise(.success(granted))
            }
        }
        .eraseToAnyPublisher()
    }
}
