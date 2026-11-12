import SwiftUI

/// A synchronous field that commits on submit, focus loss and removal.
/// The host owns validation, normalization and Escape handling.
public struct CommittedTextField: View {
    private let title: String
    private let value: String
    private let identifier: String
    private let commitValue: (String) -> Bool
    @State private var draft: CommittedTextState
    @FocusState private var focused: Bool

    public init(
        _ title: String, value: String, identifier: String = "", commit: @escaping (String) -> Bool
    ) {
        self.title = title
        self.value = value
        self.identifier = identifier
        commitValue = commit
        _draft = State(initialValue: CommittedTextState(value: value))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: $draft.text)
                .labelsHidden().textFieldStyle(.roundedBorder).focused($focused)
                .accessibilityLabel(title).accessibilityIdentifier(identifier)
                .onSubmit(commit)
            if draft.invalid { Text("Invalid value").foregroundStyle(.primary).accessibilityLabel("Invalid \(title)") }
        }
        .onChange(of: focused) { _, editing in if !editing { commit() } }
        .onChange(of: value) { old, new in draft.receive(new, replacing: old, focused: focused) }
        .onDisappear(perform: commit)
    }

    private func commit() { draft.commit(commitValue) }
}

struct CommittedTextState {
    var text: String
    private(set) var baseline: String
    private(set) var invalid = false

    init(value: String) {
        text = value
        baseline = value
    }

    mutating func receive(_ value: String, replacing old: String, focused: Bool) {
        if !focused || text == old {
            text = value
            invalid = false
        }
        baseline = value
    }

    mutating func commit(_ accept: (String) -> Bool) {
        guard text != baseline else { return }
        if accept(text) {
            baseline = text
            invalid = false
        } else {
            invalid = true
        }
    }
}
