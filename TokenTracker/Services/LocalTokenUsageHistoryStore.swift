import Foundation

final class LocalTokenUsageHistoryStore: TokenUsageHistoryStore {
    private let fileURL: URL

    init(filename: String = "token_usage_history.json") {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let directory = appSupport?.appendingPathComponent("TokenTracker", isDirectory: true)
        self.fileURL = directory?.appendingPathComponent(filename) ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
    }

    func load() -> [ProviderID: [TokenUsageSample]] {
        guard let data = try? Data(contentsOf: fileURL) else { return [:] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode([ProviderID: [TokenUsageSample]].self, from: data)
        } catch {
            return [:]
        }
    }

    func save(_ history: [ProviderID: [TokenUsageSample]]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(history)
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Intentionally ignore save failures for now; replace with proper logging if needed.
        }
    }
}
