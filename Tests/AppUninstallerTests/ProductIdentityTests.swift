import Testing
@testable import AppUninstaller

struct ProductIdentityTests {
    @Test
    func canonicalDisplayNameIsMacOptimizer() {
        #expect(ProductIdentity.displayName == "MacOptimizer")
    }
}
