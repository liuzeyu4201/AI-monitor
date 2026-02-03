import Foundation
import SwiftUI

enum ProviderID: String, Codable, CaseIterable, Identifiable {
    case openai
    case deepseek
    case qwen
    case zhipu

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .deepseek: return "DeepSeek"
        case .qwen: return "Qwen"
        case .zhipu: return "Zhipu"
        }
    }

    var accentColor: Color {
        switch self {
        case .openai: return Color(red: 0.05, green: 0.65, blue: 0.45)
        case .deepseek: return Color(red: 0.20, green: 0.40, blue: 0.95)
        case .qwen: return Color(red: 0.85, green: 0.50, blue: 0.10)
        case .zhipu: return Color(red: 0.60, green: 0.20, blue: 0.70)
        }
    }
}

struct Provider: Identifiable, Codable, Equatable {
    let id: ProviderID
    let displayName: String
    let apiBaseURL: String?

    init(id: ProviderID, apiBaseURL: String? = nil) {
        self.id = id
        self.displayName = id.displayName
        self.apiBaseURL = apiBaseURL
    }
}
