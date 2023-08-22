import ComposableArchitecture
import SwiftUI

@main
struct ExamplesApp: App {
  var body: some Scene {
    WindowGroup {
      RootView(
        store: .init(initialState: .loggedOut(.init())) {
          RootFeature()
        }
      )
    }
  }
}
