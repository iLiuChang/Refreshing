//
//  RefreshComponent.swift
//  Refreshing
//
//  Created by LC on 2023/9/22.
//

import UIKit

/// The base class of all refresh headers and footers.
///
/// It observes the scroll view it is added to, tracks the pull progress, adjusts the content inset
/// while refreshing and calls the action handler. Subclasses only provide the appearance by
/// overriding `refreshStateDidChange(_:)` and `scrollProgressDidChange(_:)`, which must be implemented.
///
/// Add a custom component with `UIScrollViewRefreshWrapper.addCustomRefreshHeader(_:)` or
/// `UIScrollViewRefreshWrapper.addCustomRefreshFooter(_:)`.
open class RefreshComponent: UIView {

    /// The position and trigger mode of a refresh component.
    public enum Kind {
        /// Placed above the content; triggered by pulling down past the threshold and releasing.
        case header
        /// Placed below the content. When `automatic` is `true`, the footer triggers
        /// automatically once the content is scrolled to the bottom; otherwise it requires pulling up
        /// past the threshold and releasing.
        case footer(automatic: Bool)
    }

    /// The position and trigger mode of the component.
    public let kind: Kind
    /// The height of the component, which is also the pull distance needed to trigger a refresh.
    public let threshold: CGFloat
    /// The configuration captured when the component was created.
    public let configuration: RefreshConfiguration
    /// Forces the component to be hidden (`true`) or shown (`false`).
    ///
    /// When `nil` (the default), a footer hides itself while the content is shorter than the scroll view.
    /// A hidden component never triggers a refresh.
    public var isHideRefresher: Bool? {
        didSet {
            if let hide = isHideRefresher {
                self.isHidden = hide
            }
        }
    }
    /// Whether the component is in the "no more data" state, in which it never triggers a refresh.
    ///
    /// Set by `UIScrollViewRefreshWrapper.endRefreshingWithNoMoreData()` and cleared by
    /// `UIScrollViewRefreshWrapper.resetNoMoreData()`.
    public private(set) var isNoMoreData = false {
        didSet {
            guard isNoMoreData != oldValue else { return }
            noMoreDataStateDidChange(isNoMoreData)
        }
    }
    private let actionHandler: () -> Void
    private var scrollView: UIScrollView? { superview as? UIScrollView }
    private var offsetToken: NSKeyValueObservation?
    private var stateToken: NSKeyValueObservation?
    private var sizeToken: NSKeyValueObservation?
    private var appliedInset: CGFloat = 0
    private var isRefreshing = false {
        didSet {
            guard isRefreshing != oldValue else { return }
            refreshStateDidChange(isRefreshing)
        }
    }
    private var progress: Float = 0 {
        didSet {
            guard progress != oldValue else { return }
            scrollProgressDidChange(progress)
        }
    }

    private var isAutomaticFooter: Bool {
        if case .footer(automatic: true) = kind { return true }
        return false
    }

    /// Creates a refresh component.
    /// - Parameters:
    ///   - kind: The position and trigger mode of the component.
    ///   - threshold: The height of the component and the pull distance needed to trigger a refresh.
    ///   - configuration: The appearance and text. Pass `nil` to use `RefreshConfiguration.default`.
    ///   - actionHandler: Called on the main thread when a refresh begins. Call
    ///     `UIScrollViewRefreshWrapper.endRefreshing()` when the work finishes.
    public init(kind: Kind, threshold: CGFloat, configuration: RefreshConfiguration? = nil, actionHandler: @escaping () -> Void) {
        self.kind = kind
        self.threshold = threshold
        self.configuration = configuration ?? .default
        self.actionHandler = actionHandler
        super.init(frame: .zero)

        self.autoresizingMask = .flexibleWidth
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Called when the component starts or stops refreshing. Subclasses must override this method.
    /// - Parameter isRefreshing: `true` when a refresh begins, `false` after it has ended.
    open func refreshStateDidChange(_ isRefreshing: Bool) {
        fatalError("refreshStateDidChange(_:) has not been implemented")
    }

    /// Called when the pull progress changes. Subclasses must override this method.
    ///
    /// Not called while refreshing, while hidden, or in the "no more data" state.
    /// An automatic footer receives `1` when it begins refreshing and `0` after it ends.
    /// - Parameter progress: The pull distance divided by `threshold`, clamped to `0...1`.
    ///   `1` means releasing now will trigger a refresh.
    open func scrollProgressDidChange(_ progress: Float) {
        fatalError("scrollProgressDidChange(_:) has not been implemented")
    }

    /// Called when the component enters or leaves the "no more data" state.
    /// The default implementation does nothing.
    open func noMoreDataStateDidChange(_ isNoMoreData: Bool) {
    }

    open override func willMove(toWindow newWindow: UIWindow?) {
        if newWindow == nil {
            clearObserver()
        } else {
            guard let scrollView = scrollView else { return }
            setupObserver(scrollView)
        }
    }

    open override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview !== superview, let oldScrollView = scrollView {
            cancelRefreshing(oldScrollView)
        }
        guard let scrollView = newSuperview as? UIScrollView, window != nil else {
            clearObserver()
            return
        }
        setupObserver(scrollView)
    }

    private func setupObserver(_ scrollView: UIScrollView) {
        offsetToken = scrollView.observe(\.contentOffset) { [weak self] scrollView, _ in
            self?.scrollViewDidScroll(scrollView)
        }
        stateToken = scrollView.observe(\.panGestureRecognizer.state) { [weak self] scrollView, _ in
            guard scrollView.panGestureRecognizer.state == .ended else { return }
            self?.scrollViewDidEndDragging(scrollView)
        }
        switch kind {
        case .header:
            frame = CGRect(x: 0, y: -threshold, width: scrollView.bounds.width, height: threshold)
        default:
            sizeToken = scrollView.observe(\.contentSize) { [weak self] scrollView, _ in
                self?.updateFooterFrame(scrollView)
                if self?.isHideRefresher == nil {
                    self?.isHidden = scrollView.contentSize.height <= scrollView.bounds.height
                }
            }
        }
    }

    private func updateFooterFrame(_ scrollView: UIScrollView) {
        let systemInsetBottom = scrollView.adjustedContentInset.bottom - scrollView.contentInset.bottom
        let newFrame = CGRect(x: 0, y: scrollView.contentSize.height + systemInsetBottom, width: scrollView.bounds.width, height: threshold)
        if frame != newFrame {
            frame = newFrame
        }
    }

    private func clearObserver() {
        offsetToken?.invalidate()
        stateToken?.invalidate()
        sizeToken?.invalidate()
    }

    private func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isRefreshing || isHidden || isNoMoreData { return }

        switch kind {
        case .header:
            progress = Float(min(1, max(0, -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top) / threshold)))
        case .footer(let automatic):
            if scrollView.contentSize.height <= scrollView.bounds.height { break }
            if automatic {
                if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom {
                    beginRefreshing()
                }
            } else {
                progress = Float(min(1, max(0, (scrollView.contentOffset.y + scrollView.bounds.height - scrollView.contentSize.height - scrollView.adjustedContentInset.bottom) / threshold)))
            }
        }
    }

    private func scrollViewDidEndDragging(_ scrollView: UIScrollView) {
        if isHidden || isNoMoreData || isAutomaticFooter { return }
        if isRefreshing || progress < 1 { return }
        beginRefreshing()
    }

    func beginRefreshing() {
        guard let scrollView = scrollView, !isRefreshing, !isNoMoreData,
              !isOtherComponentRefreshing(in: scrollView) else { return }
        progress = 1
        isRefreshing = true
        DispatchQueue.main.async {
            guard self.isRefreshing, self.scrollView === scrollView else { return }
            self.appliedInset = self.threshold
            UIView.animate(withDuration: 0.3) {
                switch self.kind {
                case .header:
                    scrollView.contentInset.top += self.threshold
                    scrollView.contentOffset.y = -scrollView.adjustedContentInset.top
                case .footer(let automatic):
                    scrollView.contentInset.bottom += self.threshold
                    if automatic {
                        scrollView.contentOffset.y = scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
                    }
                }
            }
            self.actionHandler()
        }
    }

    func endRefreshing(completion: (() -> Void)? = nil) {
        guard let scrollView = scrollView, isRefreshing else { completion?(); return }

        DispatchQueue.main.async {
            guard self.isRefreshing, self.scrollView === scrollView else { completion?(); return }
            let inset = self.appliedInset
            self.appliedInset = 0
            UIView.animate(withDuration: 0.3, animations: {
                self.removeInset(inset, from: scrollView)
                self.adjustContentOffsetIfNeeded(scrollView)
            }, completion: { _ in
                self.isRefreshing = false
                self.progress = 0
                completion?()
            })
        }
    }

    func endRefreshingWithNoMoreData() {
        endRefreshing { [weak self] in
            self?.isNoMoreData = true
        }
    }

    func resetNoMoreData() {
        isNoMoreData = false
    }

    private func cancelRefreshing(_ scrollView: UIScrollView) {
        guard isRefreshing else { return }
        removeInset(appliedInset, from: scrollView)
        appliedInset = 0
        isRefreshing = false
        progress = 0
    }

    private func removeInset(_ inset: CGFloat, from scrollView: UIScrollView) {
        guard inset != 0 else { return }
        switch kind {
        case .header:
            scrollView.contentInset.top -= inset
        case .footer:
            scrollView.contentInset.bottom -= inset
        }
    }

    private func adjustContentOffsetIfNeeded(_ scrollView: UIScrollView) {
        guard !scrollView.isDragging else { return }
        let minOffsetY = -scrollView.adjustedContentInset.top
        let maxOffsetY = max(minOffsetY, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
        let offsetY = min(max(scrollView.contentOffset.y, minOffsetY), maxOffsetY)
        if offsetY != scrollView.contentOffset.y {
            scrollView.contentOffset.y = offsetY
        }
    }

    private func isOtherComponentRefreshing(in scrollView: UIScrollView) -> Bool {
        scrollView.subviews.contains { view in
            guard let component = view as? RefreshComponent, component !== self else { return false }
            return component.isRefreshing
        }
    }

}
