//
//  UIScrollView+Refresh.swift
//  Refreshing
//
//  Created by LC on 2023/9/22.
//

import UIKit

private var RefreshHeaderKey: UInt8 = 0
private var RefreshFooterKey: UInt8 = 0
private var TempRefreshFooterKey: UInt8 = 0

extension UIScrollView {
    /// The entry point for adding and controlling the refresh header and footer of this scroll view.
    public var rfg: UIScrollViewRefreshWrapper {
        UIScrollViewRefreshWrapper(self)
    }
}

/// The built-in styles of refresh components.
public enum RefreshType {
    /// An arrow that flips when the threshold is reached, replaced by an activity indicator while refreshing.
    /// An automatic footer only shows the activity indicator.
    case indicator
    /// Same as `.indicator`, with a text label next to it.
    case textIndicator
    /// A custom animation view that fills the component.
    case animation(AnimationViewWrapper)
    /// A custom animation view with a text label below it.
    case textAnimation(AnimationViewWrapper)
}

/// Adds, removes and controls the refresh header and footer of a scroll view.
///
/// Access it through `UIScrollView.rfg`. A scroll view has at most one header and one footer;
/// adding a new one replaces the existing one.
@MainActor
public struct UIScrollViewRefreshWrapper {

    let base: UIScrollView
    init(_ base: UIScrollView) {
        self.base = base
    }

    /// Whether a refresh header has been added.
    public var isExistRefreshHeader: Bool { _header != nil }
    /// Whether a refresh footer has been added.
    public var isExistRefreshFooter: Bool { _footer != nil }

    /// Forces the header to be hidden (`true`) or shown (`false`). See `RefreshComponent.isHideRefresher`.
    public var isHideRefreshHeader: Bool? {
        get { _header?.isHideRefresher }
        nonmutating set { _header?.isHideRefresher = newValue }
    }

    /// Forces the footer to be hidden (`true`) or shown (`false`).
    ///
    /// When `nil` (the default), the footer hides itself while the content is shorter than the scroll view.
    public var isHideRefreshFooter: Bool? {
        get { _footer?.isHideRefresher }
        nonmutating set { _footer?.isHideRefresher = newValue }
    }

    /// Adds a refresh header, replacing the existing one.
    /// - Parameters:
    ///   - type: The style of the header.
    ///   - threshold: The height of the header and the pull distance needed to trigger a refresh.
    ///   - configuration: The appearance and text. Pass `nil` to use `RefreshConfiguration.default`.
    ///   - actionHandler: Called on the main thread when a refresh begins. Call `endRefreshing()` when the work finishes.
    public func addRefreshHeader(type: RefreshType = .indicator, threshold: CGFloat = 60, configuration: RefreshConfiguration? = nil, actionHandler: @escaping (()->())) {
        switch type {
        case .indicator:
            _header = IndicatorView(isHeader: true, threshold: threshold, configuration: configuration, actionHandler: actionHandler)
        case .textIndicator:
            _header = TextIndicatorView(isHeader: true, threshold: threshold, configuration: configuration, actionHandler: actionHandler)
        case .animation(let view):
            _header = AnimationImageView(animationView: view, kind: .header, threshold: threshold, configuration: configuration, actionHandler: actionHandler)
        case .textAnimation(let view):
            _header = AnimationTextImageView(animationView: view, kind: .header, threshold: threshold, configuration: configuration, actionHandler: actionHandler)
        }
    }
    
    /// Adds a refresh footer, replacing the existing one.
    /// - Parameters:
    ///   - type: The style of the footer.
    ///   - auto: When `true`, the footer triggers automatically once the content is scrolled to the bottom;
    ///     otherwise it requires pulling up past the threshold and releasing.
    ///   - threshold: The height of the footer and the pull distance needed to trigger a refresh.
    ///   - configuration: The appearance and text. Pass `nil` to use `RefreshConfiguration.default`.
    ///   - actionHandler: Called on the main thread when loading begins. Call `endRefreshing()` or
    ///     `endRefreshingWithNoMoreData()` when the work finishes.
    public func addRefreshFooter(type: RefreshType = .indicator, auto: Bool = false, threshold: CGFloat = 60, configuration: RefreshConfiguration? = nil, actionHandler: @escaping (()->())) {
        switch type {
        case .indicator:
            if auto {
                _footer = IndicatorAutoFooter(threshold: threshold, configuration: configuration, actionHandler: actionHandler)
            } else {
                _footer = IndicatorView(isHeader: false, threshold: threshold, configuration: configuration, actionHandler: actionHandler)
            }
        case .textIndicator:
            if auto {
                _footer = TextIndicatorAutoFooter(threshold: threshold, configuration: configuration, actionHandler: actionHandler)
            } else {
                _footer = TextIndicatorView(isHeader: false, threshold: threshold, configuration: configuration, actionHandler: actionHandler)
            }
        case .animation(let view):
            _footer = AnimationImageView(animationView: view, kind: .footer(auto), threshold: threshold, configuration: configuration, actionHandler: actionHandler)
        case .textAnimation(let view):
            _footer = AnimationTextImageView(animationView: view, kind: .footer(auto), threshold: threshold, configuration: configuration, actionHandler: actionHandler)
        }
    }
    
    /// Removes the refresh header. If it is refreshing, the content inset it added is restored.
    public func removeRefreshHeader() {
        _header = nil
    }

    /// Removes the refresh footer. If it is refreshing, the content inset it added is restored.
    public func removeRefreshFooter() {
        _footer = nil
    }

    /// Starts a header refresh programmatically, scrolling to show the header and calling its action handler.
    ///
    /// Does nothing if there is no header, the header is already refreshing, or the footer is refreshing.
    public func beginRefreshing() {
        _header?.beginRefreshing()
    }

    /// Ends refreshing of both the header and the footer, restoring the content inset with an animation.
    public func endRefreshing() {
        _header?.endRefreshing()
        _footer?.endRefreshing()
    }

    /// Ends refreshing of both the header and the footer, and puts the footer into the "no more data" state.
    ///
    /// In that state the footer shows `RefreshConfiguration.Text.noMoreData` (text styles only) and no longer
    /// triggers loading until `resetNoMoreData()` is called.
    public func endRefreshingWithNoMoreData() {
        _header?.endRefreshing()
        _footer?.endRefreshingWithNoMoreData()
    }

    /// Takes the footer out of the "no more data" state so that it can trigger loading again,
    /// for example after the header has refreshed the content.
    public func resetNoMoreData() {
        _footer?.resetNoMoreData()
    }

    /// Adds a custom refresh header, replacing the existing one.
    /// The component's `kind` should be `.header`.
    public func addCustomRefreshHeader(_ header: RefreshComponent) {
        _header = header
    }

    /// Adds a custom refresh footer, replacing the existing one.
    /// The component's `kind` should be `.footer`.
    public func addCustomRefreshFooter(_ footer: RefreshComponent) {
        _footer = footer
    }
    
    private var _header: RefreshComponent? {
        get {  objc_getAssociatedObject(base, &RefreshHeaderKey) as? RefreshComponent }
        nonmutating set {
            _header?.removeFromSuperview()
            objc_setAssociatedObject(base, &RefreshHeaderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let v = newValue {
                base.insertSubview(v, at: 0)
            }
        }
    }

    private var _footer: RefreshComponent? {
        get { objc_getAssociatedObject(base, &RefreshFooterKey) as? RefreshComponent }
        nonmutating set {
            _footer?.removeFromSuperview()
            objc_setAssociatedObject(base, &RefreshFooterKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let v = newValue {
                base.insertSubview(v, at: 0)
            }
        }
    }

}
