#if os(macOS)
    import AppKit
    import ASCIIUI
    import SwiftUI
    import XCTest

    @MainActor
    final class CommittedFieldRenderingTests: XCTestCase {
        func testExternalValueUpdatesAnUnfocusedField() throws {
            let model = Model()
            try render(FieldHost(model: model)) { host in
                let input = try field(in: host)
                XCTAssertEqual(input.stringValue, "Original")
                model.value = "External"
                settle(host)
                XCTAssertEqual(try field(in: host).stringValue, "External")
                XCTAssertTrue(model.commits.isEmpty)
            }
        }

        func testUnchangedRemovalDoesNotCommit() {
            let model = Model()
            render(FieldHost(model: model)) { host in
                model.visible = false
                settle(host)
                XCTAssertTrue(model.commits.isEmpty)
            }
        }

        func testChangedDraftCommitsOnRemoval() throws {
            let model = Model()
            try render(FieldHost(model: model)) { host in
                replaceText("Edited", in: try field(in: host))
                settle(host)
                model.visible = false
                settle(host)
                XCTAssertEqual(model.commits, ["Edited"])
            }
        }

        func testSubmitDoesNotCommitAgainOnRemoval() throws {
            let model = Model()
            try render(FieldHost(model: model)) { host in
                let input = try field(in: host)
                replaceText("Edited", in: input)
                settle(host)
                let action = try XCTUnwrap(input.action)
                XCTAssertTrue(input.sendAction(action, to: input.target))
                settle(host)
                XCTAssertEqual(model.commits, ["Edited"])
                model.visible = false
                settle(host)
                XCTAssertEqual(model.commits, ["Edited"])
            }
        }

        func testHostNormalizationFollowsExternalValueChanges() throws {
            for draft in [" Original ", " Edited "] {
                let model = Model()
                model.normalize = true
                try render(FieldHost(model: model)) { host in
                    let input = try field(in: host)
                    replaceText(draft, in: input)
                    settle(host)
                    let action = try XCTUnwrap(input.action)
                    XCTAssertTrue(input.sendAction(action, to: input.target))
                    settle(host)
                    let normalized = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    XCTAssertEqual(model.value, normalized)
                    XCTAssertEqual(model.commits, [draft])
                    XCTAssertEqual(input.stringValue, normalized == "Original" ? draft : normalized)
                }
            }
        }

        func testRejectedSubmissionPreservesDraftAndAddsFeedback() throws {
            let model = Model()
            model.accepted = false
            try render(FieldHost(model: model)) { host in
                let input = try field(in: host)
                let height = host.fittingSize.height
                replaceText("Rejected", in: input)
                settle(host)
                let action = try XCTUnwrap(input.action)
                XCTAssertTrue(input.sendAction(action, to: input.target))
                settle(host)
                XCTAssertEqual(model.commits, ["Rejected"])
                XCTAssertEqual(try field(in: host).stringValue, "Rejected")
                XCTAssertGreaterThan(host.fittingSize.height, height)
            }
        }

        private func replaceText(_ text: String, in field: NSTextField) {
            field.stringValue = text
            field.delegate?.controlTextDidChange?(
                Notification(name: NSControl.textDidChangeNotification, object: field))
        }

        private func field(in view: NSView) throws -> NSTextField {
            try XCTUnwrap(fields(in: view).first { $0.isEditable })
        }

        private func fields(in view: NSView) -> [NSTextField] {
            (view as? NSTextField).map { [$0] } ?? view.subviews.flatMap { fields(in: $0) }
        }

        private func settle(_ view: NSView) {
            for _ in 0..<3 {
                view.layoutSubtreeIfNeeded()
                RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            }
        }

        private final class Model: ObservableObject {
            @Published var value = "Original"
            @Published var visible = true
            var accepted = true
            var normalize = false
            var commits: [String] = []
        }

        private struct FieldHost: View {
            @ObservedObject var model: Model

            var body: some View {
                VStack {
                    if model.visible {
                        CommittedTextField("Name", value: model.value, identifier: "committed-name") { value in
                            model.commits.append(value)
                            if model.accepted && model.normalize {
                                model.value = value.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                            return model.accepted
                        }
                    }
                }
            }
        }
    }
#endif
