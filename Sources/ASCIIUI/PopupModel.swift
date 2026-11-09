import SwiftUI

public struct PopupItem {
    public let title: String
    public var selected = false
    public var enabled = true
    public let action: () -> Void

    public init(
        title: String, selected: Bool = false, enabled: Bool = true, action: @escaping () -> Void
    ) {
        self.title = title
        self.selected = selected
        self.enabled = enabled
        self.action = action
    }
}

public struct PopupMenuState: Identifiable {
    public let id = UUID()
    public let source: String
    public let label: String
    public let anchor: CGRect
    public let items: [PopupItem?]
    public var highlighted: Int?
    private var query = ""
    private var lastSearch = -Double.infinity

    public init(source: String, label: String, anchor: CGRect, items: [PopupItem?]) {
        self.source = source
        self.label = label
        self.anchor = anchor
        self.items = items
        highlighted =
            items.indices.first { items[$0]?.enabled == true && items[$0]?.selected == true }
            ?? items.indices.first { items[$0]?.enabled == true }
    }

    public mutating func move(_ offset: Int) {
        let enabled = items.indices.filter { items[$0]?.enabled == true }
        guard !enabled.isEmpty else { return }
        let current = highlighted.flatMap { enabled.firstIndex(of: $0) } ?? 0
        highlighted = enabled[(current + offset % enabled.count + enabled.count) % enabled.count]
        query = ""
    }

    public mutating func search(_ text: String, now: Double) {
        if now - lastSearch > 1 { query = "" }
        lastSearch = now
        query += text.lowercased()
        func match(_ prefix: String) -> Int? {
            items.indices.first {
                items[$0]?.enabled == true && items[$0]?.title.lowercased().hasPrefix(prefix) == true
            }
        }
        if let index = match(query) {
            highlighted = index
        } else {
            query = text.lowercased()
            if let index = match(query) { highlighted = index }
        }
    }
}

public enum PopupPlacement {
    public static func frame(anchor: CGRect, size: CGSize, bounds: CGSize, below: Bool = false)
        -> CGRect
    {
        let margin = max(0, min(8, bounds.width / 4, bounds.height / 4))
        let area = CGRect(origin: .zero, size: bounds).insetBy(dx: margin, dy: margin)
        let size = CGSize(width: min(size.width, area.width), height: min(size.height, area.height))
        let x = min(max(anchor.minX, area.minX), area.maxX - size.width)
        let y = min(max(anchor.minY, area.minY), area.maxY - size.height)
        let side = [CGPoint(x: anchor.maxX + 8, y: y), CGPoint(x: anchor.minX - size.width - 8, y: y)]
        let vertical = [
            CGPoint(x: x, y: anchor.maxY + 8), CGPoint(x: x, y: anchor.minY - size.height - 8),
        ]
        for origin in below ? vertical + side : side + vertical {
            let frame = CGRect(origin: origin, size: size)
            if area.contains(frame) { return frame }
        }
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}
