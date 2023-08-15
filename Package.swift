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
    .library(name: "SupabaseClient", targets: ["SupabaseClient"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-dependencies.git",
      from: "1.0.0"
    ),
    .package(
      url: "https://github.com/supabase-community/supabase-swift.git",
      from: "0.3.0"
    ),
  ],
  targets: [
    .target(
      name: "SupabaseClient",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "Supabase", package: "supabase-swift"),
      ]
    ),
    .testTarget(
      name: "SupabaseClientTests",
      dependencies: ["SupabaseClient"]
    ),
  ]
)
