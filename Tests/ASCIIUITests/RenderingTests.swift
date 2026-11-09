#if os(macOS)
    import AppKit
    import ASCIIUI
    import SwiftUI
    import XCTest

    @MainActor
    final class RenderingTests: XCTestCase {
        func testLiteralButtonAndTabRenderWithoutActivatingWindow() throws {
            _ = NSApplication.shared
            let keyWindow = NSApp.keyWindow
            var invoked = false
            let content = VStack {
                ASCIIButton("**Input**", accessibilityLabel: "Input") { invoked = true }
                ASCIITab("Routes", selected: false) {}
                ASCIITab("Routes", selected: true) {}
            }
            render(content) { host in
                let controls = buttons(in: host)
                XCTAssertEqual(controls.count, 3)
                guard controls.count == 3 else { return }
                XCTAssertEqual(controls[1].bounds.width, controls[2].bounds.width)
                XCTAssertTrue(controls.allSatisfy { $0.bounds.height >= 28 })
                controls[0].performClick(nil)
                XCTAssertTrue(invoked)
                XCTAssertTrue(NSApp.keyWindow === keyWindow)
            }
        }

        func testPanelRendersInsideFrozenBoundsWithoutShowingWindow() throws {
            var frames: [String: CGRect] = [:]
            let menu = PopupMenuState(
                source: "test", label: "Options", anchor: CGRect(x: 600, y: 400, width: 20, height: 28),
                items: [PopupItem(title: "Disabled", enabled: false) {}, nil, PopupItem(title: "Input [A]") {}])
            let content = PopupMenuPanel(
                menu: menu, bounds: CGSize(width: 640, height: 460),
                activate: { _ in }, highlight: { _ in }, move: { _ in }, search: { _ in }, dismiss: {}
            )
            .coordinateSpace(name: "workspace")
            .onPreferenceChange(PopupAnchors.self) { frames = $0 }
            try render(content) { host in
                let frame = try XCTUnwrap(frames["popup-panel"])
                XCTAssertTrue(host.bounds.contains(frame))
                XCTAssertGreaterThanOrEqual(frame.height, PopupMetrics.macOS.rowHeight * 2)
                let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                host.cacheDisplay(in: host.bounds, to: bitmap)
                XCTAssertGreaterThan(bitmap.pixelsWide, 0)
                XCTAssertEqual(menu.anchor, CGRect(x: 600, y: 400, width: 20, height: 28))
            }
        }

        func testPanelFontDoesNotInheritHostTypography() throws {
            let menu = PopupMenuState(
                source: "test", label: "Options", anchor: .zero,
                items: [PopupItem(title: "Wide input WWW [A]") {}, PopupItem(title: "Narrow iii") {}])
            for scale in [1.0, 2.0] {
                let panel = PopupMenuPanel(
                    menu: menu, bounds: CGSize(width: 640, height: 460),
                    metrics: PopupMetrics(minimumTargetHeight: 28, bodyFontSize: 13, textScale: scale),
                    activate: { _ in }, highlight: { _ in }, move: { _ in }, search: { _ in }, dismiss: {}
                )
                .coordinateSpace(name: "workspace")
                var images: [Data] = []
                for font in [Font.system(size: 13 * scale, design: .monospaced), .system(size: 40, design: .serif)] {
                    try render(panel.font(font)) { host in
                        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
                        host.cacheDisplay(in: host.bounds, to: bitmap)
                        images.append(try XCTUnwrap(bitmap.representation(using: .png, properties: [:])))
                    }
                }
                XCTAssertEqual(images[0], images[1], "Host font changed menu rendering at scale \(scale)")
            }
        }

        private func render<Content: View>(_ content: Content, check: (NSView) throws -> Void) rethrows {
            _ = NSApplication.shared
            let host = NSHostingView(rootView: content)
            let window = NSWindow(
                contentRect: CGRect(x: 0, y: 0, width: 640, height: 460), styleMask: [.titled], backing: .buffered,
                defer: false)
            window.isReleasedWhenClosed = false
            window.contentView = host
            defer { window.close() }
            host.layoutSubtreeIfNeeded()
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            host.layoutSubtreeIfNeeded()
            try check(host)
            XCTAssertFalse(window.isVisible)
        }

        private func buttons(in view: NSView) -> [NSButton] {
            (view as? NSButton).map { [$0] } ?? view.subviews.flatMap { buttons(in: $0) }
        }
    }
#endif
