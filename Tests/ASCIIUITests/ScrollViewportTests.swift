#if os(macOS)
    import AppKit
    import SwiftUI
    import XCTest

    @testable import ASCIIUI

    @MainActor
    final class ScrollViewportTests: XCTestCase {
        func testAttachmentReportsClipSizeAsynchronouslyOnMainThread() {
            let fixture = Fixture()
            defer { fixture.close() }
            var reports: [CGSize] = []
            let probe = ScrollViewportRepresentable.Probe()
            probe.update = {
                XCTAssertTrue(Thread.isMainThread)
                reports.append($0)
            }
            fixture.document.addSubview(probe)
            XCTAssertTrue(reports.isEmpty)
            settle()
            XCTAssertEqual(reports, [fixture.scroll.contentView.bounds.size])
            probe.connect()
            settle()
            XCTAssertEqual(reports.count, 1)
        }

        func testAttachedResizeReportsSizeButOriginChangesDoNot() {
            let fixture = Fixture()
            defer { fixture.close() }
            var reports: [CGSize] = []
            let probe = ScrollViewportRepresentable.Probe()
            probe.update = { reports.append($0) }
            fixture.document.addSubview(probe)
            settle()
            fixture.scroll.contentView.scroll(to: CGPoint(x: 20, y: 40))
            settle()
            XCTAssertEqual(reports.count, 1)
            fixture.window.setContentSize(CGSize(width: 500, height: 350))
            settle()
            XCTAssertEqual(reports.count, 2)
            XCTAssertEqual(reports.last, fixture.scroll.contentView.bounds.size)
        }

        func testNearestNestedClipIsObserved() {
            let fixture = Fixture()
            defer { fixture.close() }
            let inner = NSScrollView(frame: CGRect(x: 0, y: 0, width: 180, height: 120))
            let document = NSView(frame: CGRect(x: 0, y: 0, width: 800, height: 800))
            inner.documentView = document
            fixture.document.addSubview(inner)
            var reports: [CGSize] = []
            let probe = ScrollViewportRepresentable.Probe()
            probe.update = { reports.append($0) }
            document.addSubview(probe)
            settle()
            XCTAssertEqual(reports, [inner.contentView.bounds.size])
            fixture.window.setContentSize(CGSize(width: 500, height: 350))
            settle()
            XCTAssertEqual(reports.count, 1)
            inner.setFrameSize(CGSize(width: 200, height: 140))
            settle()
            XCTAssertEqual(reports.count, 2)
            XCTAssertEqual(reports.last, inner.contentView.bounds.size)
        }

        func testReattachmentToSameClipRejectsPreviousQueuedReport() {
            let fixture = Fixture()
            defer { fixture.close() }
            var reports: [CGSize] = []
            let probe = ScrollViewportRepresentable.Probe()
            probe.update = { reports.append($0) }
            fixture.document.addSubview(probe)
            probe.removeFromSuperview()
            fixture.document.addSubview(probe)
            settle()
            XCTAssertEqual(reports, [fixture.scroll.contentView.bounds.size])
        }

        func testReattachmentToDifferentClipRejectsPreviousQueuedReport() {
            let first = Fixture()
            let second = Fixture()
            defer {
                first.close()
                second.close()
            }
            var reports: [CGSize] = []
            let probe = ScrollViewportRepresentable.Probe()
            probe.update = { reports.append($0) }
            first.document.addSubview(probe)
            probe.removeFromSuperview()
            second.document.addSubview(probe)
            settle()
            XCTAssertEqual(reports, [second.scroll.contentView.bounds.size])
            first.window.setContentSize(CGSize(width: 500, height: 350))
            settle()
            XCTAssertEqual(reports.count, 1)
        }

        func testSupersededQueuedSizeIsNotDelivered() {
            let fixture = Fixture()
            defer { fixture.close() }
            var reports: [CGSize] = []
            let probe = ScrollViewportRepresentable.Probe()
            probe.update = { reports.append($0) }
            fixture.document.addSubview(probe)
            fixture.scroll.contentView.setBoundsSize(CGSize(width: 250, height: 200))
            NotificationCenter.default.post(
                name: NSView.boundsDidChangeNotification, object: fixture.scroll.contentView)
            settle()
            XCTAssertEqual(reports, [fixture.scroll.contentView.bounds.size])
        }

        func testQueuedSizeReturningToInitialValueIsDeliveredOnce() {
            let fixture = Fixture()
            defer { fixture.close() }
            var reports: [CGSize] = []
            let probe = ScrollViewportRepresentable.Probe()
            probe.update = { reports.append($0) }
            fixture.document.addSubview(probe)
            let initial = fixture.scroll.contentView.bounds.size
            fixture.scroll.contentView.setBoundsSize(CGSize(width: 250, height: 200))
            fixture.scroll.contentView.setBoundsSize(initial)
            settle()
            XCTAssertEqual(reports, [initial])
        }

        func testDisconnectRejectsQueuedAndSubsequentNotifications() {
            let fixture = Fixture()
            defer { fixture.close() }
            var reports: [CGSize] = []
            let probe = ScrollViewportRepresentable.Probe()
            probe.update = { reports.append($0) }
            fixture.document.addSubview(probe)
            probe.disconnect()
            settle()
            fixture.window.setContentSize(CGSize(width: 500, height: 350))
            settle()
            XCTAssertTrue(reports.isEmpty)
        }

        func testDismantlingDisconnectsProbeWhileStillAttached() {
            let fixture = Fixture()
            defer { fixture.close() }
            var reports: [CGSize] = []
            let probe = ScrollViewportRepresentable.Probe()
            probe.update = { reports.append($0) }
            fixture.document.addSubview(probe)
            ScrollViewportRepresentable.dismantleNSView(probe, coordinator: ())
            settle()
            fixture.window.setContentSize(CGSize(width: 500, height: 350))
            settle()
            XCTAssertTrue(probe.window === fixture.window)
            XCTAssertTrue(reports.isEmpty)
        }

        func testDetachedProbeDoesNotReceiveQueuedReportsOrRetainItself() {
            let fixture = Fixture()
            defer { fixture.close() }
            var reports: [CGSize] = []
            weak var released: NSView?
            autoreleasepool {
                let probe = ScrollViewportRepresentable.Probe()
                released = probe
                probe.update = { reports.append($0) }
                fixture.document.addSubview(probe)
                probe.removeFromSuperview()
            }
            settle()
            XCTAssertNil(released)
            XCTAssertTrue(reports.isEmpty)
        }

        func testProbeDoesNotInterceptPointerOrAccessibility() {
            let probe = ScrollViewportRepresentable.Probe(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            XCTAssertNil(probe.hitTest(CGPoint(x: 50, y: 50)))
            XCTAssertFalse(probe.isAccessibilityElement())
            XCTAssertFalse(probe.acceptsFirstResponder)
        }

        func testSwiftUIRemovalDismantlesRetainedProbe() throws {
            let fixture = Fixture()
            defer { fixture.close() }
            var reports: [CGSize] = []
            let host = NSHostingView(rootView: AnyView(ScrollViewportReader { reports.append($0) }))
            host.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
            fixture.document.addSubview(host)
            settle()
            let probe = try XCTUnwrap(findProbe(in: host))
            XCTAssertEqual(reports.last, fixture.scroll.contentView.bounds.size)
            host.rootView = AnyView(EmptyView())
            settle()
            let count = reports.count
            XCTAssertNil(findProbe(in: host))
            fixture.window.setContentSize(CGSize(width: 500, height: 350))
            settle()
            XCTAssertEqual(reports.count, count)
            XCTAssertNil(probe.window)
        }

        private func findProbe(in view: NSView) -> ScrollViewportRepresentable.Probe? {
            if let probe = view as? ScrollViewportRepresentable.Probe { return probe }
            return view.subviews.lazy.compactMap { self.findProbe(in: $0) }.first
        }

        private func settle() {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        @MainActor
        private final class Fixture {
            let window: NSWindow
            let scroll: NSScrollView
            let document: NSView
            private let keyWindow: NSWindow?

            init() {
                _ = NSApplication.shared
                keyWindow = NSApp.keyWindow
                scroll = NSScrollView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
                document = NSView(frame: CGRect(x: 0, y: 0, width: 800, height: 800))
                scroll.documentView = document
                window = NSWindow(contentRect: scroll.frame, styleMask: [.titled], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false
                window.contentView = scroll
            }

            func close() {
                XCTAssertFalse(window.isVisible)
                XCTAssertTrue(NSApp.keyWindow === keyWindow)
                window.close()
            }
        }
    }
#endif
