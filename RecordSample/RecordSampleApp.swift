import SwiftUI

let store = Store<AppState, AppAction>(
    state: .init(),
    reducer: appReducer,
    middlewares: [
        permissionsMiddleware(service: AudioRecordPermissions()),
        audioRecorderMiddleware(service: AudioRecorderService.shared),
        messagesMiddleware(service: MessagesService())
    ]
)

@main
struct RecordSampleApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newValue in
            if newValue == .active {
                store.dispatch(.scenePhaseActive)
            }
        }
    }
}
