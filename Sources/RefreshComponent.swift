//
//  RefreshComponent.swift
//  Refreshing
//
//  Created by LC on 2023/9/22.
//

import UIKit
open class RefreshComponent: UIView {

    public enum Kind {
        case header
        case footer(Bool)
    }

    public let kind: Kind
    public let threshold: CGFloat
    public var isHideRefresher: Bool? {
        didSet {
            if let hide = isHideRefresher {
                self.isHidden = hide
            }
        }
    }
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

    private var isAutoFooter: Bool {
        if case .footer(true) = kind { return true }
        return false
    }

    public init(kind: Kind, threshold: CGFloat, actionHandler: @escaping () -> Void) {
        self.kind = kind
        self.threshold = threshold
        self.actionHandler = actionHandler
        super.init(frame: .zero)

        self.autoresizingMask = .flexibleWidth
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func refreshStateDidChange(_ isRefreshing: Bool) {
        fatalError("refreshStateDidChange(_:) has not been implemented")
    }

    open func scrollProgressDidChange(_ progress: Float) {
        fatalError("scrollProgressDidChange(_:) has not been implemented")
    }

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
                self?.frame = CGRect(x: 0, y: scrollView.contentSize.height, width: scrollView.bounds.width, height: self?.threshold ?? 0)
                if self?.isHideRefresher == nil {
                    self?.isHidden = scrollView.contentSize.height <= scrollView.bounds.height
                }
            }
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
        case .footer(let auto):
            if scrollView.contentSize.height <= scrollView.bounds.height { break }
            if auto {
                if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom {
                    beginRefreshing()
                }
            } else {
                progress = Float(min(1, max(0, (scrollView.contentOffset.y + scrollView.bounds.height - scrollView.contentSize.height - scrollView.adjustedContentInset.bottom) / threshold)))
            }
        }
    }

    private func scrollViewDidEndDragging(_ scrollView: UIScrollView) {
        if isHidden || isNoMoreData || isAutoFooter { return }
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
                case .footer(let auto):
                    scrollView.contentInset.bottom += self.threshold
                    if auto {
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
