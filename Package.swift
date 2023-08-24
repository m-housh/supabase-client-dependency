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
    .library(name: "SupabaseClient", targets: ["SupabaseClient"]),
    .library(name: "SupabaseClientLive", targets: ["SupabaseClientLive"])
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
    .package(
      url: "https://github.com/supabase-community/gotrue-swift.git",
      from: "1.0.0"
    ),
    .package(
      url: "https://github.com/supabase-community/postgrest-swift.git",
      from: "1.0.0"
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
      name: "SupabaseClient",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "IdentifiedStorage", package: "swift-identified-storage"),
        .product(name: "GoTrue", package: "gotrue-swift"),
        .product(name: "PostgREST", package: "postgrest-swift"),
      ]
    ),
    .target(
      name: "SupabaseClientLive",
      dependencies: [
        "SupabaseClient",
        .product(name: "Supabase", package: "supabase-swift"),
      ]
    ),
    .testTarget(
      name: "SupabaseClientTests",
      dependencies: ["SupabaseClient", "SupabaseClientLive"]
    ),
  ]
)
