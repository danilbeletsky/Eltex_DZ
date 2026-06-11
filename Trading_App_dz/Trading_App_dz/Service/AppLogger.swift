import Foundation
import os.log

// MARK: - Log level & category

enum LogLevel: String, CaseIterable {
    case debug
    case info
    case warning
    case error

    var order: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        }
    }

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }

    var emoji: String {
        switch self {
        case .debug: return "debug"
        case .info: return "info"
        case .warning: return "warning"
        case .error: return "error"
        }
    }
}

enum LogCategory: String {
    case auth = "Auth"
    case p2p = "P2P"
    case network = "Network"

    var osLog: OSLog {
        switch self {
        case .auth:
            return OSLog(subsystem: AppLogger.subsystem, category: "Auth")
        case .p2p:
            return OSLog(subsystem: AppLogger.subsystem, category: "P2P")
        case .network:
            return OSLog(subsystem: AppLogger.subsystem, category: "Network")
        }
    }
}

// MARK: - AppLogger
nonisolated final class AppLogger {
    static let subsystem = Bundle.main.bundleIdentifier ?? "Trading_App_dz"

    static let shared = AppLogger()
    
    var minimumConsoleLevel: LogLevel = .debug

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private init() {}

    static func auth(
        _ message: String,
        level: LogLevel = .info,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        shared.log(message, category: .auth, level: level, metadata: metadata, file: file, function: function, line: line)
    }

    static func p2p(
        _ message: String,
        level: LogLevel = .info,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        shared.log(message, category: .p2p, level: level, metadata: metadata, file: file, function: function, line: line)
    }

    static func network(
        _ message: String,
        level: LogLevel = .info,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        shared.log(message, category: .network, level: level, metadata: metadata, file: file, function: function, line: line)
    }

    // MARK: - Core

    func log(
        _ message: String,
        category: LogCategory,
        level: LogLevel,
        metadata: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        let metaSuffix = metadata.isEmpty
            ? ""
            : " | " + metadata.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: ", ")

        let formatted = "[\(timestamp)] \(level.emoji) [\(category.rawValue)] \(message)\(metaSuffix) — \(fileName):\(line) \(function)"

        os_log("%{public}@", log: category.osLog, type: level.osLogType, formatted)

        #if DEBUG
        if level.rawValue >= minimumConsoleLevel.rawValue || shouldPrint(level: level) {
            print(formatted)
        }
        #endif
    }

    private func shouldPrint(level: LogLevel) -> Bool {
        level.order >= minimumConsoleLevel.order
    }
}

extension AppLogger {
    nonisolated static func networkRequest(
        method: String,
        url: String,
        bodySize: Int? = nil,
        metadata: [String: String] = [:]
    ) {
        var meta: [String: String] = ["method": method, "url": url]
        if let bodySize {
            meta["bodyBytes"] = "\(bodySize)"
        }
        meta.merge(metadata) { _, new in new }
        network("Запрос отправлен", level: .info, metadata: meta)
    }

    nonisolated static func networkResponse(
        url: String,
        statusCode: Int?,
        durationMs: Int?,
        dataSize: Int?
    ) {
        var meta: [String: String] = ["url": url]
        if let statusCode { meta["status"] = "\(statusCode)" }
        if let durationMs { meta["durationMs"] = "\(durationMs)" }
        if let dataSize { meta["dataBytes"] = "\(dataSize)" }
        network("Ответ получен", level: .info, metadata: meta)
    }

    nonisolated static func networkFailure(
        url: String,
        error: NetworkServiceError,
        underlying: Error? = nil
    ) {
        var meta: [String: String] = [
            "url": url,
            "mappedError": error.logDescription
        ]
        if let underlying {
            meta["underlying"] = String(describing: underlying)
        }
        network("Ошибка сетевого слоя", level: .error, metadata: meta)
    }
}

extension NetworkServiceError {
    var logDescription: String {
        switch self {
        case .noInternet: return "noInternet"
        case .timeout: return "timeout"
        case .parsing: return "parsing"
        case .forbiddenSection: return "forbiddenSection"
        case .server(let code): return "server(\(code))"
        case .unknown: return "unknown"
        }
    }
}
