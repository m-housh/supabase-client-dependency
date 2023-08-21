# supabase-client-dependency

A [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) client for supabase integrations.

This dependency wraps the [supabase-swift](https://github.com/supabase-community/supabase-swift) client,
database, and auth for convenience methods for use in `TCA` based apps.

This package adds some niceties around database queries as well as holds onto an `authentication` client.
In general you use this package / dependency to build your database clients for usage in a
[swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) based application.

## Installation

Install this as a swift package in your project.

```swift
import PackageDescription

let package = Package(
  ...
  dependencies: [
    .package(
      url: "https://github.com/m-housh/supabase-client-dependency.git",
      from: "0.1.0"
    )
  ],
  targets: [
    .target(
      name: "<My Target>",
      dependencies: [
        .product(name: "SupabaseClient", package: "supabase-client-dependency")
      ]
    )
  ]
)
```

## Usage

This package does not have an official `liveValue` declared on the dependency because it is intended that the live
value is setup in the project that depends on it. It does conform to the `TestDependencyKey` and has an `unimplemented`
version used in tests. It also has a `mock` factory method for the `auth` portion of the client dependency, which is
helpful for use in previews and test's.

Define the configuration for the supabase client.

```swift
import Dependencies
import SupabaseClient

extension SupabaseClientDependency.Configuration {
  public static let live = Self.init(url: supabaseURL, anonKey: localAnonKey)
}

// This url in general is used for local supabase installations and should be
// changed to your live url.
fileprivate let supabaseURL = URL(string: "http://localhost:54321")!

// Set this to anonymous key for your project, for local supabase installations this
// is printed to the screen when you call `supabase start` on your machine.
fileprivate let localAnonKey =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"

extension SupabaseClientDependency: DependencyKey {
  static var liveValue: Self {
    .live(configuration: .live)
  }
}
```

