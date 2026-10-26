//
//  RefreshConfiguration.swift
//  Refreshing
//
//  Created by LC on 2025/9/16.
//

import UIKit

/// The text, colors and layout of the built-in refresh components.
///
/// Change `RefreshConfiguration.default` to affect every component created afterwards, or pass a
/// customized copy when adding a single header or footer:
///
/// ```swift
/// var configuration = RefreshConfiguration.default
/// configuration.textColor = .white
/// tableView.rfg.addRefreshHeader(style: .textIndicator, configuration: configuration) { ... }
/// ```
public struct RefreshConfiguration {

    /// The text shown by the text styles.
    public struct Text {
        /// Shown by a header before it is pulled past the threshold.
        public var headIdle: String = "Pull down to refresh"
        /// Shown by a footer before it is pulled past the threshold.
        public var footIdle: String = "Pull up to load more"
        /// Shown once the component has been pulled past the threshold.
        public var release: String = "Release to refresh"
        /// Shown while refreshing.
        public var loading: String = "Loading..."
        /// Shown by a footer in the "no more data" state.
        public var noMoreData: String = "No more data"

        /// Creates text with the default English strings.
        public init() {}
    }

    /// The text shown by `.textIndicator` and `.textAnimation`.
    public var text = Text()
    /// The font of the text.
    public var font: UIFont = .systemFont(ofSize: 14)
    /// The color of the text. Defaults to black in light mode and white in dark mode.
    public var textColor: UIColor = .refreshDynamic(light: UIColor.black.withAlphaComponent(0.8), dark: UIColor.white.withAlphaComponent(0.8))
    /// The color of the arrow in `.indicator` and `.textIndicator`. Defaults to black in light mode and white in dark mode.
    public var arrowColor: UIColor = .refreshDynamic(light: UIColor.black.withAlphaComponent(0.8), dark: UIColor.white.withAlphaComponent(0.8))
    /// The color of the activity indicator. Defaults to gray in light mode and white in dark mode.
    public var indicatorColor: UIColor = .refreshDynamic(light: .gray, dark: .white)
    /// The insets of the content inside the component. Only applies to `.animation` and `.textAnimation`.
    public var contentInset: UIEdgeInsets = .zero
    /// The distance between the arrow or activity indicator and the text,
    /// or between the animation view and the text in `.textAnimation`.
    public var spacing: CGFloat = 8

    /// Creates a configuration with the built-in values, ignoring any changes made to `RefreshConfiguration.default`.
    public init() {}

    /// The configuration used when none is passed.
    ///
    /// Each component copies the configuration when it is created; later changes do not affect existing components.
    @MainActor public static var `default` = RefreshConfiguration()
}

private extension UIColor {
    static func refreshDynamic(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { $0.userInterfaceStyle == .dark ? dark : light }
        }
        return light
    }
}
