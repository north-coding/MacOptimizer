import Foundation

enum ProductIdentity {
    static let displayName = "MacOptimizer"

    private static let legacyDisplayNames = [
        "Mac优化大师",
        "Mac最佳化大師",
        "Macオプティマイザー",
        "Mac 최적화 도구"
    ]

    static func normalizingLegacyProductName(in text: String) -> String {
        legacyDisplayNames.reduce(text) { result, legacyName in
            result.replacingOccurrences(of: legacyName, with: displayName)
        }
    }
}
