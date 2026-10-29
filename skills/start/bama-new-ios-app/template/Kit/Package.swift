// swift-tools-version: 6.2
import PackageDescription

// Rules and data logic with no SwiftUI. The app links it, and
// `make test` runs its tests on the Mac, with no simulator.
let package = Package(
    name: "__APP_NAME__Kit",
    platforms: [.iOS("27.0"), .macOS(.v26)],
    products: [.library(name: "__APP_NAME__Kit", targets: ["__APP_NAME__Kit"])],
    targets: [
        .target(name: "__APP_NAME__Kit"),
        .testTarget(name: "__APP_NAME__KitTests", dependencies: ["__APP_NAME__Kit"]),
    ]
)
