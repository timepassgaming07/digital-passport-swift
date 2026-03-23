// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SovereignTrust",
    platforms: [.iOS(.v17)],
    products: [.library(name:"SovereignTrust", targets:["SovereignTrust"])],
    dependencies: [
        .package(url:"https://github.com/EFPrefix/EFQRCode.git", from:"6.2.1"),
    ],
    targets: [
        .target(
            name:"SovereignTrust",
            dependencies:[
                .product(name:"EFQRCode", package:"EFQRCode"),
            ],
            path:"Sources/SovereignTrust",
            exclude:["Resources/Info.plist"]
        ),
        .testTarget(name:"SovereignTrustTests",
            dependencies:["SovereignTrust"], path:"Tests"),
    ]
)
