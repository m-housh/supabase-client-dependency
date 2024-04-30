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
    .library(name: "DatabaseRouter", targets: ["DatabaseRouter"]),
    .library(name: "SupabaseClientDependencies", targets: ["SupabaseClientDependencies"]),
    .library(name: "SupabaseExtensions", targets: ["SupabaseExtensions"])
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
      name: "DatabaseRouter",
      dependencies: [
        "SupabaseExtensions",
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
        .product(name: "Supabase", package: "supabase-swift"),
      ]
    ),
    .target(
      name: "SupabaseClientDependencies",
      dependencies: [
        "SupabaseExtensions",
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "IdentifiedStorage", package: "swift-identified-storage"),
        .product(name: "Supabase", package: "supabase-swift"),
      ]
    ),
    .target(
      name: "SupabaseExtensions",
      dependencies: [
        .product(name: "Supabase", package: "supabase-swift"),
      ]
    ),
    .testTarget(
      name: "SupabaseClientTests",
      dependencies: ["SupabaseClientDependencies"]
    ),
    .testTarget(
      name: "SupabaseClientIntegrationTests",
      dependencies: [
        "DatabaseRouter",
        "SupabaseClientDependencies",
        .product(name: "CasePaths", package: "swift-case-paths")
      ]
    ),
  ]
)
