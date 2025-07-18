// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let cxxLambdaSetting = CXXSetting.define("SPINE_USE_STD_FUNCTION", to: "1")

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
            name: "SpineC",
            targets: ["SpineC"]
        ),
        .library(
            name: "SpineSwift",
            targets: ["SpineSwift"]
        ),
        .library(
            name: "SpineiOS",
            targets: ["SpineiOSWrapper"]
        ),
        .library(
            name: "spine-c",
            targets: ["spine-c"]
        ),
        .library(
            name: "SpineRuntime",
            targets: ["SpineRuntime"]
        )
    ],
    targets: [
        .target(
            name: "SpineiOSWrapper",
            dependencies: [
                .target(name: "SpineiOS", condition: .when(platforms: [.iOS, .visionOS, .tvOS, .macCatalyst]))
            ],
            path: "spine-ios/Sources/SpineiOSWrapper"
        ),
        .target(
            name: "SpineiOS",
            dependencies: [
                "SpineSwift",
                "SpineShadersStructs",
            ],
            path: "spine-ios/Sources/SpineiOS"
        ),
        .target(
            name: "SpineC",
            path: "spine-ios/Sources/SpineC",
            sources: [
                "src",
                "spine",
            ],
            linkerSettings: [
                .linkedLibrary("c++")
            ]
        ),
        .target(
            name: "SpineSwift",
            dependencies: ["SpineC"],
            path: "spine-ios/Sources/SpineSwift",
            sources: [
                "Generated",
                "Extensions",
            ]
        ),
        .systemLibrary(
            name: "SpineShadersStructs",
            path: "spine-ios/Sources/SpineShadersStructs"
        ),
        .target(
            name: "spine-cpp",
            path: "spine-ios/Sources/spine-cpp",
            cxxSettings: [
                cxxLambdaSetting,
            ],
            linkerSettings: [
                
            ]
        ),
        .target(
            name: "spine-c",
            dependencies: [
                "spine-cpp",
            ],
            path: "spine-ios/Sources/spine-c",
            cxxSettings: [
                cxxLambdaSetting,
            ]
        ),
        .target(
            name: "spine_apple_extension",
            dependencies: [
                "spine-cpp",
            ],
            path: "spine-ios/Sources/spine_apple_extension"
            
        ),
        .target(
            name: "SpineRuntime",
            dependencies: [
                "spine-c", "SpineShadersStructs",
            ],
            path: "spine-ios/Sources/SpineRuntime",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "HeadlessTests",
            dependencies: [
                "spine-c",
                .target(
                    name: "spine_apple_extension",
                    condition: .when(platforms: [.iOS, .tvOS, .watchOS, .macCatalyst, .visionOS, .visionOS, .macOS])
                ),
                .target(
                    name: "SpineRuntime",
                    condition: .when(platforms: [.iOS, .tvOS, .watchOS, .macCatalyst, .visionOS, .visionOS, .macOS])
                ),
            ],
            path: "spine-ios/Tests/HeadlessTests",
            resources: [
                .process("Resources"),
            ]
        ),
    ],
    cxxLanguageStandard: .cxx11
)
