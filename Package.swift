// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BLE_Sniffer",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "BLE_Sniffer",
            targets: ["BLE_Sniffer"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BLE_Sniffer",
            dependencies: [],
            path: "BLE_Sniffer",
            sources: [
                "BLE_SnifferApp.swift",
                "ContentView.swift", 
                "BLEManager.swift",
                "BLEDevice.swift",
                "SniffView.swift",
                "LibraryView.swift",
                "DeviceDetailView.swift"
            ],
            resources: [
                .process("Assets.xcassets")
            ]),
    ]
) 