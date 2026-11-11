# ASCIIUI

SwiftUI controls, in-window popup menus and anchor placement for macOS 14+ and iOS 17+. Licensed under BSD-3-Clause.

## Standalone menu

Add the `ASCIIUI` package product to your target. The host owns presentation, action validation and focus return; no application model or presentation controller is required.

```swift
import ASCIIUI
import SwiftUI

struct MenuExample: View {
    @State private var selection = "One"
    @State private var menu: PopupMenuState?
    @State private var anchors: [String: CGRect] = [:]
    @FocusState private var triggerFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ASCIIButton(selection, accessibilityLabel: "Choice") {
                    if menu != nil {
                        dismiss()
                    } else {
                        menu = PopupMenuState(
                            source: "choice", label: "Choice",
                            anchor: anchors["choice"] ?? .zero,
                            items: ["One", "Two"].map { value in
                                PopupItem(title: value, selected: value == selection) {
                                    selection = value
                                }
                            })
                    }
                }
                .focused($triggerFocused)
                .asciiPopupAnchor("choice")
                .padding()

                if let menu {
                    PopupMenuPanel(
                        menu: menu, bounds: geometry.size,
                        activate: activate,
                        highlight: { index in
                            if menu.items.indices.contains(index), menu.items[index]?.enabled == true {
                                self.menu?.highlighted = index
                            }
                        },
                        move: { self.menu?.move($0) },
                        search: { self.menu?.search($0, now: ProcessInfo.processInfo.systemUptime) },
                        dismiss: dismiss
                    ).id(menu.id)
                }
            }
        }
        .coordinateSpace(name: "workspace")
        .onPreferenceChange(PopupAnchors.self) { anchors = $0 }
    }

    private func activate(_ index: Int?) {
        guard let menu, let index = index ?? menu.highlighted,
            menu.items.indices.contains(index), let item = menu.items[index], item.enabled
        else { return }
        dismiss()
        item.action()
    }

    private func dismiss() {
        menu = nil
        triggerFocused = true
    }
}
```

`PopupMenuState.anchor` is a frozen rectangle in the panel host's `workspace` coordinate space, with the origin at the top-left. Capture the trigger's anchor when opening, not on every layout update. `bounds` is the size of that same host. `PopupAnchors` reports trigger rectangles and the displayed `popup-panel` rectangle. Standalone triggers can use `asciiPopupAnchor(_:coordinateSpace:)` with another named coordinate space; the panel's reported rectangle uses `workspace`.

A nil item is a separator. Disabled items cannot receive keyboard selection. `PopupChoice.hasAlternative(to:in:)` preserves optional selections and allows a sole enabled replacement for a missing selection. `activate(nil)` requests the highlighted row; the panel never invokes an item's action itself. Revalidate changing availability in the host, dismiss before invoking an action, and do not return focus to the trigger when the action opens an editor.

## Metrics and platform support

`PopupMetrics.platform` uses a 28-point minimum target and 13-point monospaced menu text on macOS, and a 44-point minimum target and 17-point monospaced menu text on iOS. Menu measurement and rendering use the same font. Set `textScale` on a copy of the platform metrics to scale menu typography and row geometry. The host can map its text-size preferences or Dynamic Type scale into this value. Buttons and tabs inherit the host's text size.

The panel supports arrow keys, Return/Space activation, typeahead, Escape/Tab dismissal, outside-tap dismissal and scrolling to the highlighted row. Context-menu invocation gestures are host-owned; no AppKit or iPad context-interaction adapter is supplied.

## Committed text fields

`CommittedTextField` attempts a synchronous commit on submission, focus loss and removal. Return `true` to accept the draft or `false` to retain it with inline validation feedback. Unchanged drafts do not invoke the callback; rejected drafts can be retried on later commit triggers.

```swift
CommittedTextField("Name", value: name, identifier: "item-name") { draft in
    let value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty else { return false }
    name = value
    return true
}
```

The host owns the current `name`, validation and normalization. External values replace unfocused text or text equal to the previous external value, while focused dirty drafts remain intact. Acceptance records the raw draft as the local baseline; normalization does not guarantee an immediate canonical display when the external value stays unchanged.

Escape handling remains application-owned. Asynchronous forms and editors requiring explicit Save/Cancel should retain their own drafts and ordinary `TextField` bindings instead of using this commit-on-removal control.

## Verification

```bash
swift test
swift format lint --strict --recursive Sources Tests Package.swift
```

Tests cover menu navigation, disabled rows and separators, typeahead, optional choices, placement and hidden-window macOS rendering. Rendering checks include stable tab widths and menu-font independence from the host. They do not prove real pointer/keyboard event delivery or VoiceOver behavior. iOS 17 simulator sources are compiler-checked; iOS runtime interaction and iPad context gestures have not been validated.
