import AudioBoostDomain
import Foundation

public final class ConsoleBoostLogger: BoostLogging {
    public init() {}

    public func log(level: LogLevel, _ message: String) {
        #if DEBUG
            FileHandle.standardError.write(Data("[AudioBoost][\(level.rawValue)] \(message)\n".utf8))
        #endif
    }
}
