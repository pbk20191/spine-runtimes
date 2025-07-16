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
        .library(name: "SpineSwift", targets: ["SpineSwift"]),
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
        .target(
            name: "spine-cpp",
            path: "spine-ios/Sources/spine-cpp",
            cxxSettings: [
                .define("SPINE_USE_STD_FUNCTION", to: "1"),
            ],
            linkerSettings: [
                .linkedLibrary("c++"),
            ]
        ),
        .target(
            name: "spine-c",
            dependencies: [
                "spine-cpp"
            ],
            path: "spine-ios/Sources/spine-c",
            cxxSettings: [
                .define("SPINE_USE_STD_FUNCTION", to: "1"),
                .define("getDefaultExtension()", to: "____UNUSED_getDefaultExtension()"),
                .define("spine_report_leaks()", to: "__UNUSED_report_leaks()"),
                .define("spine_enable_debug_extension(x)", to: "__UNUSED_enable_debug_extension(x)"),
//                .define("initExtensions()", to: " "),
            ],
            linkerSettings: [
                .linkedLibrary("c++"),
                
            ]
        ),
        .target(
            name: "SpineSwift",
            dependencies: [
              "SpineShadersStructs", "spine-c"
            ],
            path: "spine-ios/Sources/SpineSwift",
            cSettings: [
                .define("SPINE_USE_STD_FUNCTION", to: "1"),
            ]
        ),
        .systemLibrary(
            name: "SpineShadersStructs",
            path: "spine-ios/Sources/SpineShadersStructs"
        )
    ],
    cxxLanguageStandard: .cxx11
)
