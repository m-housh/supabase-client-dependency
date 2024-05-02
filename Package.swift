// swift-tools-version: 5.8

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
    .library(name: "DatabaseExtensions", targets: ["DatabaseExtensions"]),
    .library(name: "DatabaseRouter", targets: ["DatabaseRouter"]),
    .library(name: "SupabaseClientDependencies", targets: ["SupabaseClientDependencies"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-case-paths.git",
      from: "1.0.0"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-dependencies.git",
      from: "1.0.0"
    ),
    .package(
      url: "https://github.com/supabase/supabase-swift.git",
      from: "2.0.0"
    ),
    .package(
      url: "https://github.com/m-housh/swift-identified-storage.git",
      from: "0.1.0"
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
      name: "DatabaseExtensions",
      dependencies: [
        .product(name: "PostgREST", package: "supabase-swift"),
      ]
    ),
    .target(
      name: "DatabaseRouter",
      dependencies: [
        "DatabaseExtensions",
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
        .product(name: "PostgREST", package: "supabase-swift"),
      ]
    ),
    .testTarget(
      name: "DatabaseRouterIntegrationTests",
      dependencies: [
        "DatabaseRouter",
        "SupabaseClientDependencies",
        .product(name: "CasePaths", package: "swift-case-paths")
      ]
    ),
    .target(
      name: "SupabaseClientDependencies",
      dependencies: [
        "AuthController",
        "DatabaseExtensions",
        "DatabaseRouter",
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "IdentifiedStorage", package: "swift-identified-storage"),
        .product(name: "Supabase", package: "supabase-swift"),
      ]
    ),
    .testTarget(
      name: "SupabaseClientTests",
      dependencies: ["SupabaseClientDependencies"]
    ),
  ]
)
