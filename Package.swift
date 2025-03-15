// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "spine-ios",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .macCatalyst(.v13),
        .visionOS(.v1),
        .macOS(.v10_15),
        .watchOS(.v6),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Spine",
            targets: ["SpineModule"]
        ),
        .library(name: "SpineSwift", targets: ["SpineSwift"])
    ],
    targets: [
        .target(
            name: "SpineModule",
            dependencies: [
                .byName(
                    name: "Spine",
                    condition: .when(platforms: [
                        .iOS,
                    ])
                ),
                "SpineCppLite",
                "SpineShadersStructs",
            ],
            path: "spine-ios/Sources/SpineModule"
        ),
        .target(
            name: "spine-c",
            
            path: "spine-ios/Sources/spine-c"
            
        ),
        .target(
            name: "SpineSwift",
            dependencies: [
                "spine-c"
            ],
            path: "spine-ios/Sources/SpineSwift"
            
        ),
        .target(
            name: "Spine",
            dependencies: [
                "SpineCppLite", "SpineShadersStructs"
            ],
            path: "spine-ios/Sources/Spine"
        ),
        .target(
            name: "SpineCppLite",
            path: "spine-ios/Sources/SpineCppLite",
            linkerSettings: [
                .linkedLibrary("c++"),
            ]
        ),
        .systemLibrary(
            name: "SpineShadersStructs",
            path: "spine-ios/Sources/SpineShadersStructs"
        )
    ],
    cxxLanguageStandard: .cxx11
)
