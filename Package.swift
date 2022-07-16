// swift-tools-version: 5.5

import PackageDescription

let package = Package(
	name: "brc-ios",
	platforms: [.iOS(.v15)],
	products: [
		.library(
			name: "BasicRemoteConfigs",
			targets: ["BasicRemoteConfigs"]),
	],
	targets: [
		.target(
			name: "BasicRemoteConfigs",
			dependencies: []
		),
		.testTarget(
			name: "BasicRemoteConfigsTests",
			dependencies: ["BasicRemoteConfigs"]
		),
	]
)
