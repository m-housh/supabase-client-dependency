// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "supabase-client-dependency",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "supabase-client-dependency",
            targets: ["supabase-client-dependency"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "supabase-client-dependency"),
        .testTarget(
            name: "supabase-client-dependencyTests",
            dependencies: ["supabase-client-dependency"]),
    ]
)
