import Foundation
import XCTest
@testable import TokenBar

final class ModelsTests: XCTestCase {
    func testTokenCountsDecodesCodexPayload() throws {
        let data = Data(
            """
            {
              "input_tokens": 1200,
              "cached_input_tokens": 200,
              "output_tokens": 300,
              "reasoning_output_tokens": 50,
              "total_tokens": 1500
            }
            """.utf8)

        let counts = try JSONDecoder().decode(TokenCounts.self, from: data)

        XCTAssertEqual(counts.input, 1_200)
        XCTAssertEqual(counts.cachedInput, 200)
        XCTAssertEqual(counts.output, 300)
        XCTAssertEqual(counts.reasoningOutput, 50)
        XCTAssertEqual(counts.total, 1_500)
        XCTAssertEqual(counts.uncachedInput, 1_000)
    }

    func testTokenCountsDefaultsAndClampsNegativeValues() throws {
        let data = Data(#"{"input_tokens":-10,"total_tokens":-1}"#.utf8)

        let counts = try JSONDecoder().decode(TokenCounts.self, from: data)

        XCTAssertEqual(counts.input, 0)
        XCTAssertEqual(counts.cachedInput, 0)
        XCTAssertEqual(counts.output, 0)
        XCTAssertEqual(counts.total, 0)
    }

    func testCompactNumberFormatting() {
        XCTAssertEqual(CompactNumber.string(999), "999")
        XCTAssertEqual(CompactNumber.string(1_000), "1K")
        XCTAssertEqual(CompactNumber.string(1_000_000), "1M")
        XCTAssertEqual(CompactNumber.string(-10), "0")
    }

    func testTokenOnlyStateDoesNotExposeQuotaSnapshot() {
        let state = QuotaState.tokenOnly

        XCTAssertTrue(state.hidesQuota)
        XCTAssertNil(state.snapshot)
    }

    func testQuotaRemainingPercentIsClamped() {
        XCTAssertEqual(
            QuotaWindow(
                kind: .weekly,
                usedPercent: 25,
                windowMinutes: 10_080,
                resetsAt: nil)
                .remainingPercent,
            75)
        XCTAssertEqual(
            QuotaWindow(
                kind: .other,
                usedPercent: 120,
                windowMinutes: nil,
                resetsAt: nil)
                .remainingPercent,
            0)
    }
}
