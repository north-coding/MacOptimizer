import Testing
@testable import AppUninstaller

struct ProductIdentityTests {
    @Test
    func canonicalDisplayNameIsMacOptimizer() {
        #expect(ProductIdentity.displayName == "MacOptimizer")
    }

    @Test
    func everyLanguageUsesCanonicalProductName() {
        for language in AppLanguage.allCases {
            #expect(language.productName == ProductIdentity.displayName)
        }
    }

    @Test
    func legacyTranslatedProductNamesAreNormalized() {
        let samples = [
            "欢迎使用Mac优化大师",
            "Mac最佳化大師 — 設定",
            "Macオプティマイザー",
            "Mac 최적화 도구"
        ]

        for sample in samples {
            let normalized = ProductIdentity.normalizingLegacyProductName(in: sample)
            #expect(normalized.contains(ProductIdentity.displayName))
            #expect(!normalized.contains("Mac优化大师"))
            #expect(!normalized.contains("Mac最佳化大師"))
            #expect(!normalized.contains("Macオプティマイザー"))
            #expect(!normalized.contains("Mac 최적화 도구"))
        }
    }
}
