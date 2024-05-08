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
    .library(name: "SupabaseDependencies", targets: ["SupabaseDependencies"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-case-paths.git",
      from: "1.0.0"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-concurrency-extras.git",
      from: "1.0.0"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-custom-dump.git",
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
      name: "SupabaseDependencies",
      dependencies: [
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "Supabase", package: "supabase-swift"),
      ]
    ),
    .testTarget(
      name: "SupabaseDependenciesTests",
      dependencies: [
        "SupabaseDependencies"
      ],
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency")
      ]
    ),
    .testTarget(
      name: "DatabaseRouterIntegrationTests",
      dependencies: [
        "SupabaseDependencies",
        .product(name: "CasePaths", package: "swift-case-paths"),
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
      ]
    ),
  ]
)
