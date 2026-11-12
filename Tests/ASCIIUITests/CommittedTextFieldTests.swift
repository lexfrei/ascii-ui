import XCTest

@testable import ASCIIUI

final class CommittedTextFieldTests: XCTestCase {
    func testInitialValueDoesNotRequireCommit() {
        var state = CommittedTextState(value: "Original")
        XCTAssertEqual(state.text, "Original")
        XCTAssertEqual(state.baseline, "Original")
        XCTAssertFalse(state.invalid)
        state.commit { _ in
            XCTFail("Unchanged value reached the callback")
            return true
        }
    }

    func testAcceptedDraftBecomesBaselineAndSkipsRepeatedTriggers() {
        var state = CommittedTextState(value: "Original")
        state.text = "Edited"
        var attempts: [String] = []
        for _ in 0..<3 {
            state.commit {
                attempts.append($0)
                return true
            }
        }
        XCTAssertEqual(attempts, ["Edited"])
        XCTAssertEqual(state.text, "Edited")
        XCTAssertEqual(state.baseline, "Edited")
        XCTAssertFalse(state.invalid)
    }

    func testRejectedDraftRemainsAvailableForRetry() {
        var state = CommittedTextState(value: "Original")
        state.text = "Rejected"
        var attempts: [String] = []
        for _ in 0..<2 {
            state.commit {
                attempts.append($0)
                return false
            }
        }
        XCTAssertEqual(attempts, ["Rejected", "Rejected"])
        XCTAssertEqual(state.text, "Rejected")
        XCTAssertEqual(state.baseline, "Original")
        XCTAssertTrue(state.invalid)
        state.commit { _ in true }
        XCTAssertEqual(state.baseline, "Rejected")
        XCTAssertFalse(state.invalid)
    }

    func testExternalValueReplacesUnfocusedDraftAndClearsError() {
        var state = CommittedTextState(value: "Original")
        state.text = "Rejected"
        state.commit { _ in false }
        state.receive("External", replacing: "Original", focused: false)
        XCTAssertEqual(state.text, "External")
        XCTAssertEqual(state.baseline, "External")
        XCTAssertFalse(state.invalid)
    }

    func testExternalValueReplacesFocusedUnchangedText() {
        var state = CommittedTextState(value: "Original")
        state.receive("External", replacing: "Original", focused: true)
        XCTAssertEqual(state.text, "External")
        XCTAssertEqual(state.baseline, "External")
    }

    func testExternalValuePreservesFocusedDirtyDraft() {
        var state = CommittedTextState(value: "Original")
        state.text = "Draft"
        state.receive("External", replacing: "Original", focused: true)
        XCTAssertEqual(state.text, "Draft")
        XCTAssertEqual(state.baseline, "External")
        var submitted: String?
        state.commit {
            submitted = $0
            return true
        }
        XCTAssertEqual(submitted, "Draft")
    }

    func testExternalComparisonUsesPreviousValueRatherThanAcceptedBaseline() {
        var state = CommittedTextState(value: "Original")
        state.text = "Accepted"
        state.commit { _ in true }
        state.receive("External", replacing: "Original", focused: true)
        XCTAssertEqual(state.text, "Accepted")
        XCTAssertEqual(state.baseline, "External")
    }

    func testAcceptedNormalizationToUnchangedValuePreservesRawDraft() {
        var state = CommittedTextState(value: "Original")
        state.text = " Original "
        var value = "Original"
        state.commit {
            value = $0.trimmingCharacters(in: .whitespaces)
            return true
        }
        XCTAssertEqual(value, "Original")
        XCTAssertEqual(state.text, " Original ")
        XCTAssertEqual(state.baseline, " Original ")
        state.commit { _ in
            XCTFail("Accepted unchanged-model draft was retried")
            return true
        }
    }

    func testAcceptedNormalizationWithExternalUpdateUsesFocusPolicy() {
        for focused in [false, true] {
            var state = CommittedTextState(value: "Original")
            state.text = " Edited "
            var value = "Original"
            state.commit {
                value = $0.trimmingCharacters(in: .whitespaces)
                return true
            }
            state.receive(value, replacing: "Original", focused: focused)
            XCTAssertEqual(state.text, focused ? " Edited " : "Edited")
            XCTAssertEqual(state.baseline, "Edited")
            XCTAssertFalse(state.invalid)
        }
    }
}
