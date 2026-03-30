// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MySTT",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "MySTT",
            dependencies: [
                "WhisperKit",
            ],
            path: "MySTT",
            exclude: ["Info.plist", "MySTT.entitlements"],
            resources: [
                .process("Resources"),
                .process("Assets.xcassets"),
            ]
        ),
        .testTarget(
            name: "MySTTTests",
            dependencies: [
                "MySTT",
            ],
            path: "Tests/MySTTTests"
        ),
    ]
)
