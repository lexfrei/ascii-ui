import SwiftUI

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

/// An in-window menu using the owner's frozen anchor and presentation state.
/// Activation reports an index, or nil for the highlighted row. The owner must revalidate availability,
/// dismiss before invoking actions, and return focus only when an action does not transfer it elsewhere.
/// Context-menu gestures and focus-return policies belong to the host application.
public struct PopupMenuPanel: View {
    let metrics: PopupMetrics
    let activate: (Int?) -> Void
    let highlight: (Int) -> Void
    let move: (Int) -> Void
    let search: (String) -> Void
    let dismiss: () -> Void
    let menu: PopupMenuState
    let bounds: CGSize
    @FocusState private var focused: Bool
    @AccessibilityFocusState private var accessibleRow: Int?

    public init(
        menu: PopupMenuState, bounds: CGSize, metrics: PopupMetrics = .platform,
        activate: @escaping (Int?) -> Void, highlight: @escaping (Int) -> Void,
        move: @escaping (Int) -> Void, search: @escaping (String) -> Void, dismiss: @escaping () -> Void
    ) {
        self.menu = menu
        self.bounds = bounds
        self.metrics = metrics
        self.activate = activate
        self.highlight = highlight
        self.move = move
        self.search = search
        self.dismiss = dismiss
    }

    private var rowHeight: Double { metrics.rowHeight }
    private var size: CGSize {
        #if os(macOS)
            let font = NSFont.monospacedSystemFont(ofSize: metrics.fontSize, weight: .regular)
        #else
            let font = UIFont.monospacedSystemFont(ofSize: metrics.fontSize, weight: .regular)
        #endif
        let width =
            menu.items.compactMap { $0 }.map {
                ($0.title as NSString).size(withAttributes: [.font: font]).width
            }.max()
            ?? 180
        let height = menu.items.reduce(8.0) { $0 + ($1 == nil ? 9 : rowHeight) }
        let markers = (">*" as NSString).size(withAttributes: [.font: font]).width
        return CGSize(
            width: min(440 * metrics.textScale, max(220, (width + markers + 48).rounded(.up))),
            height: min(360 * metrics.textScale, max(rowHeight + 8, height)))
    }

    public var body: some View {
        let frame = PopupPlacement.frame(anchor: menu.anchor, size: size, bounds: bounds, below: true)
        ZStack(alignment: .topLeading) {
            Color.clear.contentShape(Rectangle()).onTapGesture { dismiss() }
                .accessibilityHidden(true)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if menu.items.compactMap({ $0 }).isEmpty {
                            Text("No available options").padding(8)
                        }
                        ForEach(menu.items.indices, id: \.self) { index in
                            if let item = menu.items[index] {
                                Button {
                                    activate(index)
                                } label: {
                                    HStack(spacing: 8) {
                                        Text(verbatim: menu.highlighted == index ? ">" : " ")
                                        Text(verbatim: item.selected ? "*" : " ")
                                        Text(verbatim: item.title).lineLimit(1).truncationMode(.middle)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 8).frame(height: rowHeight)
                                    .contentShape(Rectangle())
                                    .background(Color.primary.opacity(menu.highlighted == index ? 0.08 : 0))
                                }
                                .buttonStyle(.plain).disabled(!item.enabled)
                                .foregroundStyle(item.enabled ? Color.primary : Color.secondary)
                                .focusable(false)
                                .accessibilityLabel(item.title).help(item.title)
                                .accessibilityAddTraits(item.selected ? .isSelected : [])
                                .accessibilityFocused($accessibleRow, equals: index)
                                .accessibilityIdentifier("popup-option-\(index)")
                                .onHover { inside in if inside { highlight(index) } }
                                .id(index)
                            } else {
                                Divider().padding(.vertical, 4)
                            }
                        }
                    }.padding(4)
                }
                .onChange(of: menu.highlighted, initial: true) { _, index in
                    if let index {
                        proxy.scrollTo(index)
                        accessibleRow = index
                    }
                }
            }
            .frame(width: frame.width, height: frame.height)
            .font(.system(size: metrics.fontSize, weight: .regular, design: .monospaced))
            .asciiPopupSurface()
            .focusable().focusEffectDisabled().focused($focused)
            .onAppear { focused = true }
            .onKeyPress(.downArrow) {
                move(1)
                return .handled
            }
            .onKeyPress(.upArrow) {
                move(-1)
                return .handled
            }
            .onKeyPress(.return) {
                activate(nil)
                return .handled
            }
            .onKeyPress(.space) {
                activate(nil)
                return .handled
            }
            .onKeyPress(.tab) {
                dismiss()
                return .ignored
            }
            .onKeyPress(characters: .alphanumerics) { press in
                search(press.characters)
                return .handled
            }
            .onKeyPress(.escape) {
                dismiss()
                return .handled
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(menu.label).accessibilityIdentifier("popup-menu")
            .asciiPopupAnchor("popup-panel")
            .position(x: frame.midX, y: frame.midY)
        }
    }
}
