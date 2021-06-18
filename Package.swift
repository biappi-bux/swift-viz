// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.4.0")),
]

#if swift(>=5.5)
    #if os(macOS)
    dependencies.append(
        .package(
            name: "SwiftSyntax",
            url: "https://github.com/apple/swift-syntax",
            .branch("release/5.5-05142021")
        )
    )
    #else
    dependencies.append(
        .package(
            name: "SwiftSyntax",
            url: "https://github.com/apple/swift-syntax",
            .branch("release/5.5")
        )
    )
    #endif
#elseif swift(>=5.4)
dependencies.append(
    .package(
        name: "SwiftSyntax",
        url: "https://github.com/apple/swift-syntax",
        .exact("0.50400.0")
    )
)
#elseif swift(>=5.3)
dependencies.append(
    .package(
        name: "SwiftSyntax",
        url: "https://github.com/apple/swift-syntax",
        .exact("0.50300.0")
    )
)
#else
fatalError("This does not support Swift <= 5.2.")
#endif

let package = Package(
    name: "swift-viz",
    dependencies: dependencies,
    targets: [
        .target(
            name: "swift-viz",
            dependencies: [
                "SwiftSyntax",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "swift-vizTests",
            dependencies: ["swift-viz"]),
    ]
)
