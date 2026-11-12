// swift-tools-version: 6.0
import Foundation
import PackageDescription

// Swift Testing ships as a framework in the Command Line Tools, but SwiftPM only
// adds its parent as an include path. When Xcode is not the active toolchain we add
// the framework search path explicitly. With full Xcode active, SwiftPM handles it.
func activeDeveloperDirectory() -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcode-select")
    process.arguments = ["-p"]
    let pipe = Pipe()
    process.standardOutput = pipe
    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        return ""
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

let developerDirectory = activeDeveloperDirectory()
let commandLineToolsFrameworks = "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
let commandLineToolsTestingLibs = "/Library/Developer/CommandLineTools/Library/Developer/usr/lib"
let needsCommandLineToolsTestingPath =
    developerDirectory.contains("CommandLineTools")
    && FileManager.default.fileExists(atPath: commandLineToolsFrameworks + "/Testing.framework")

let testSwiftSettings: [SwiftSetting] =
    needsCommandLineToolsTestingPath
    ? [.unsafeFlags(["-F", commandLineToolsFrameworks])]
    : []
let testLinkerSettings: [LinkerSetting] =
    needsCommandLineToolsTestingPath
    ? [
        .unsafeFlags([
            "-F", commandLineToolsFrameworks,
            "-Xlinker", "-rpath",
            "-Xlinker", commandLineToolsFrameworks,
            "-Xlinker", "-rpath",
            "-Xlinker", commandLineToolsTestingLibs,
        ])
    ]
    : []

let package = Package(
    name: "AudioBoost",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "AudioBoostDomain", targets: ["AudioBoostDomain"]),
        .library(name: "AudioBoostCore", targets: ["AudioBoostCore"]),
        .library(name: "AudioBoostCoreAudio", targets: ["AudioBoostCoreAudio"]),
        .library(name: "AudioBoostUI", targets: ["AudioBoostUI"]),
        .executable(name: "AudioBoost", targets: ["AudioBoost"]),
    ],
    targets: [
        .target(
            name: "AudioBoostDomain",
            path: "Sources/AudioBoostDomain"
        ),
        .target(
            name: "AudioBoostCore",
            dependencies: ["AudioBoostDomain"],
            path: "Sources/AudioBoostCore"
        ),
        .target(
            name: "AudioBoostCoreAudio",
            dependencies: ["AudioBoostDomain"],
            path: "Sources/AudioBoostCoreAudio",
            linkerSettings: [
                .linkedFramework("CoreAudio"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("AVFoundation"),
            ]
        ),
        .target(
            name: "AudioBoostUI",
            dependencies: ["AudioBoostDomain", "AudioBoostCore"],
            path: "Sources/AudioBoostUI"
        ),
        .executableTarget(
            name: "AudioBoost",
            dependencies: ["AudioBoostDomain", "AudioBoostCore", "AudioBoostCoreAudio", "AudioBoostUI"],
            path: "Sources/AudioBoost"
        ),
        .testTarget(
            name: "AudioBoostDomainTests",
            dependencies: ["AudioBoostDomain"],
            path: "Tests/AudioBoostDomainTests",
            swiftSettings: testSwiftSettings,
            linkerSettings: testLinkerSettings
        ),
        .testTarget(
            name: "AudioBoostCoreTests",
            dependencies: ["AudioBoostDomain", "AudioBoostCore"],
            path: "Tests/AudioBoostCoreTests",
            swiftSettings: testSwiftSettings,
            linkerSettings: testLinkerSettings
        ),
        .testTarget(
            name: "AudioBoostCoreAudioTests",
            dependencies: ["AudioBoostDomain", "AudioBoostCoreAudio"],
            path: "Tests/AudioBoostCoreAudioTests",
            swiftSettings: testSwiftSettings,
            linkerSettings: testLinkerSettings
        ),
        .testTarget(
            name: "AudioBoostUITests",
            dependencies: ["AudioBoostDomain", "AudioBoostCore", "AudioBoostUI"],
            path: "Tests/AudioBoostUITests",
            swiftSettings: testSwiftSettings,
            linkerSettings: testLinkerSettings
        ),
    ],
    swiftLanguageModes: [.v5]
)
