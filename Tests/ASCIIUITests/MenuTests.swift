import ASCIIUI
import Foundation
import XCTest

final class MenuTests: XCTestCase {
    func testNavigationSkipsUnavailableRowsAndWraps() {
        var menu = PopupMenuState(
            source: "test", label: "Options", anchor: .zero,
            items: [
                PopupItem(title: "Disabled", enabled: false) {}, nil,
                PopupItem(title: "Alpha") {}, PopupItem(title: "Beta", selected: true) {},
            ])
        XCTAssertEqual(menu.highlighted, 3)
        menu.move(1)
        XCTAssertEqual(menu.highlighted, 2)
        menu.move(-1)
        XCTAssertEqual(menu.highlighted, 3)
        menu.search("a", now: 1)
        XCTAssertEqual(menu.highlighted, 2)
        menu.search("b", now: 3)
        XCTAssertEqual(menu.highlighted, 3)
    }

    func testEmptyMenuAndSeparatorsHaveNoSelection() {
        var menu = PopupMenuState(
            source: "test", label: "Options", anchor: .zero,
            items: [nil, PopupItem(title: "Off", enabled: false) {}])
        menu.move(1)
        menu.search("off", now: 1)
        XCTAssertNil(menu.highlighted)
    }

    func testTypeaheadAccumulatesAndFallsBackAfterNoMatch() {
        var menu = PopupMenuState(
            source: "test", label: "Options", anchor: .zero,
            items: [
                PopupItem(title: "Alpha") {}, PopupItem(title: "Alpine") {}, PopupItem(title: "Beta") {},
            ])
        menu.search("al", now: 1)
        menu.search("p", now: 1.2)
        XCTAssertEqual(menu.highlighted, 0)
        menu.search("b", now: 1.3)
        XCTAssertEqual(menu.highlighted, 2)
        menu.search("alpi", now: 3)
        XCTAssertEqual(menu.highlighted, 1)
    }

    func testPlacementFlipsClampsAndPreservesAnchor() {
        let anchor = CGRect(x: 600, y: 400, width: 20, height: 28)
        let menu = PopupMenuState(source: "test", label: "Options", anchor: anchor, items: [])
        for bounds in [CGSize(width: 640, height: 460), CGSize(width: 10, height: 12)] {
            let frame = PopupPlacement.frame(
                anchor: menu.anchor, size: CGSize(width: 260, height: 200), bounds: bounds, below: true)
            XCTAssertTrue(CGRect(origin: .zero, size: bounds).contains(frame))
            XCTAssertEqual(menu.anchor, anchor)
        }
    }

    func testOptionalChoiceAndMissingSelectionRemainSelectable() {
        let options = [
            PopupChoice<Int?>(value: nil, title: "AUTO"),
            PopupChoice(value: 1, title: "One", enabled: false),
        ]
        XCTAssertFalse(PopupChoice.hasAlternative(to: nil, in: options))
        XCTAssertTrue(PopupChoice.hasAlternative(to: 2, in: options))
        XCTAssertTrue(
            PopupChoice.hasAlternative(to: "missing", in: [PopupChoice(value: "online", title: "Online")])
        )
    }

    func testLiteralCaptionsKeepTabsStableAndPlatformTargetsDistinct() {
        XCTAssertEqual(ASCIICaption.button("**Input**"), "[ **Input** ]")
        XCTAssertEqual(
            ASCIICaption.tab("Routes", selected: false).count,
            ASCIICaption.tab("Routes", selected: true).count)
        XCTAssertEqual(PopupMetrics.macOS.minimumTargetHeight, 28)
        XCTAssertEqual(PopupMetrics.iOS.minimumTargetHeight, 44)
        XCTAssertEqual(PopupMetrics.macOS.fontSize, 13)
        XCTAssertEqual(PopupMetrics.iOS.fontSize, 17)
        var metrics = PopupMetrics.iOS
        metrics.textScale = 2
        XCTAssertEqual(metrics.fontSize, 34)
    }
}
