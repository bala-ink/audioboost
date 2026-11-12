import Foundation
import Testing

@main
struct AudioBoostTestLoader {
    static func main() async {
        guard let bundlePath = ProcessInfo.processInfo.environment["TEST_BUNDLE_PATH"],
            !bundlePath.isEmpty
        else {
            FileHandle.standardError.write(Data("TEST_BUNDLE_PATH is not set\n".utf8))
            exit(2)
        }

        guard dlopen(bundlePath, RTLD_LAZY | RTLD_LOCAL) != nil else {
            let reason = String(cString: dlerror())
            FileHandle.standardError.write(
                Data("failed to load test bundle at \(bundlePath): \(reason)\n".utf8)
            )
            exit(1)
        }

        let exitCode: CInt = await Testing.__swiftPMEntryPoint()
        exit(exitCode)
    }
}
