// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "supabase-client-dependency",
  platforms: [
    .iOS(.v13),
    .macCatalyst(.v13),
    .macOS(.v10_15)
  ],
  products: [
    .library(name: "SupabaseClientDependency", targets: ["SupabaseClientDependency"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-dependencies.git",
      from: "0.4.2"
    ),
    .package(
      url: "https://github.com/supabase-community/supabase-swift.git",
      from: "0.2.1"
    ),
//    .package(
//      url: "https://github.com/pointfreeco/xctest-dynamic-overlay.git",
//      from: "1.0.2"
//    ),
  ],
  targets: [
    .target(
      name: "SupabaseClientDependency",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "Supabase", package: "supabase-swift"),
//        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay")
      ]
    ),
    .testTarget(
      name: "SupabaseClientTests",
      dependencies: ["SupabaseClientDependency"]
    ),
  ]
)
