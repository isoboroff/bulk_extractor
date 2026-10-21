// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BulkExtractorApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "BulkExtractorApp", targets: ["BulkExtractorApp"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "BulkExtractorApp",
            dependencies: [],
            path: "Sources/BulkExtractorApp"
        )
    ]
)
