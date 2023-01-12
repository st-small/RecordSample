import SwiftUI

protocol Connector: View {
    associatedtype Content: View
    func map(store: Store<AppState, AppAction>) -> Content
}

extension Connector {
    var body: some View {
        Connected<Content>(map: map)
    }
}

private struct Connected<V: View>: View {
    @EnvironmentObject var store: Store<AppState, AppAction>

    let map: (Store<AppState, AppAction>) -> V

    var body: V {
        map(store)
    }
}
