// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "supabase-client-dependency",
  platforms: [
    .iOS(.v16),
    .macCatalyst(.v16),
    .macOS(.v13),
    .tvOS(.v16),
    .watchOS(.v9),
  ],
  products: [
    .library(name: "AuthController", targets: ["AuthController"]),
    .library(name: "DatabaseRouter", targets: ["DatabaseRouter"]),
    .library(name: "SupabaseClientDependencies", targets: ["SupabaseClientDependencies"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-case-paths.git",
      from: "1.0.0"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-concurrency-extras",
      from: "1.0.0"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-dependencies.git",
      from: "1.0.0"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-identified-collections.git",
      from: "1.0.0"
    ),
    .package(
      url: "https://github.com/supabase/supabase-swift.git",
      from: "2.0.0"
    ),
    .package(
      url: "https://github.com/apple/swift-docc-plugin.git",
      from: "1.0.0"
    ),
  ],
  targets: [
    .target(
      name: "AuthController",
      dependencies: [
        .product(name: "Auth", package: "supabase-swift"),
        .product(name: "Dependencies", package: "swift-dependencies"),
      ]
    ),
    .testTarget(
      name: "AuthControllerTests",
      dependencies: [
        "AuthController",
        .product(name: "Dependencies", package: "swift-dependencies"),
      ]
    ),
    .target(
      name: "DatabaseRouter",
      dependencies: [
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "PostgREST", package: "supabase-swift"),
      ]
    ),
    .testTarget(
      name: "DatabaseRouterIntegrationTests",
      dependencies: [
        "DatabaseRouter",
        "SupabaseClientDependencies",
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
      ]
    ),
    .target(
      name: "SupabaseClientDependencies",
      dependencies: [
        "AuthController",
        "DatabaseRouter",
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "Supabase", package: "supabase-swift"),
      ]
    ),
    .testTarget(
      name: "SupabaseClientTests",
      dependencies: ["SupabaseClientDependencies"]
    ),
  ]
)
