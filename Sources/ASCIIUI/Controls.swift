import SwiftUI

public struct PopupChoice<Value: Hashable>: Equatable {
    public let value: Value
    public let title: String
    public var enabled: Bool

    public init(value: Value, title: String, enabled: Bool = true) {
        self.value = value
        self.title = title
        self.enabled = enabled
    }

    public static func hasAlternative(to selection: Value, in options: [Self]) -> Bool {
        options.contains { $0.enabled && $0.value != selection }
    }
}

public struct PopupMetrics: Equatable, Sendable {
    public let minimumTargetHeight: Double
    public let bodyFontSize: Double
    public var textScale: Double

    public static let macOS = PopupMetrics(minimumTargetHeight: 28, bodyFontSize: 13)
    public static let iOS = PopupMetrics(minimumTargetHeight: 44, bodyFontSize: 17)
    public static var platform: Self {
        #if os(macOS)
            macOS
        #else
            iOS
        #endif
    }

    public init(minimumTargetHeight: Double, bodyFontSize: Double, textScale: Double = 1) {
        self.minimumTargetHeight = minimumTargetHeight
        self.bodyFontSize = bodyFontSize
        self.textScale = textScale
    }

    public var fontSize: Double { bodyFontSize * textScale }
    public var rowHeight: Double { max(minimumTargetHeight, 24 * textScale) }
}

public enum ASCIICaption {
    public static func button(_ title: String) -> String { "[ \(title) ]" }
    public static func tab(_ title: String, selected: Bool) -> String {
        selected ? "[*\(title)*]" : "[ \(title) ]"
    }
}

public struct ASCIIButton: View {
    private let title: String
    private let accessibilityLabel: String
    private let enabled: Bool
    private let metrics: PopupMetrics
    private let action: () -> Void

    public init(
        _ title: String, accessibilityLabel: String, enabled: Bool = true,
        metrics: PopupMetrics = .platform, action: @escaping () -> Void
    ) {
        self.title = title
        self.accessibilityLabel = accessibilityLabel
        self.enabled = enabled
        self.metrics = metrics
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(verbatim: ASCIICaption.button(title)).fontDesign(.monospaced)
                .frame(minHeight: metrics.minimumTargetHeight).contentShape(Rectangle())
        }
        .buttonStyle(.borderless).disabled(!enabled).accessibilityLabel(accessibilityLabel)
    }
}

public struct ASCIITab: View {
    private let title: String
    private let selected: Bool
    private let enabled: Bool
    private let metrics: PopupMetrics
    private let action: () -> Void

    public init(
        _ title: String, selected: Bool, enabled: Bool = true, metrics: PopupMetrics = .platform,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.selected = selected
        self.enabled = enabled
        self.metrics = metrics
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(verbatim: ASCIICaption.tab(title, selected: selected)).fontDesign(.monospaced)
                .fixedSize().frame(minHeight: metrics.minimumTargetHeight).contentShape(Rectangle())
        }
        .buttonStyle(.borderless).disabled(!enabled).accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

extension View {
    public func asciiPopupSurface() -> some View {
        background(Self.popupBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(Self.popupBorder) }
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    private static var popupBackground: Color {
        #if os(macOS)
            Color(nsColor: .controlBackgroundColor)
        #else
            Color(uiColor: .secondarySystemBackground)
        #endif
    }

    private static var popupBorder: Color {
        #if os(macOS)
            Color(nsColor: .separatorColor)
        #else
            Color(uiColor: .separator)
        #endif
    }
}
