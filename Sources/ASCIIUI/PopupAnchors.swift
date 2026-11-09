import SwiftUI

public struct PopupAnchors: PreferenceKey {
    public static let defaultValue: [String: CGRect] = [:]
    public static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue().filter { $0.value.width > 0 && $0.value.height > 0 }) { _, new in new }
    }
}

extension View {
    public func asciiPopupAnchor(_ id: String, coordinateSpace: String = "workspace") -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: PopupAnchors.self, value: [id: geometry.frame(in: .named(coordinateSpace))])
            }
        }
    }

}
