import Foundation

protocol TokenUsageClient {
    func fetchUsage(for provider: Provider, cached: TokenUsage?, completion: @escaping (Result<TokenUsage, Error>) -> Void)
}
