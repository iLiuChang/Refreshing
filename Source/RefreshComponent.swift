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

    private let kind: Kind
    private let threshold: CGFloat
    private let actionHandler: () -> Void
    private var scrollView: UIScrollView? { superview as? UIScrollView }
    private var offsetToken: NSKeyValueObservation?
    private var stateToken: NSKeyValueObservation?
    private var sizeToken: NSKeyValueObservation?
    private var beginContentInset = UIEdgeInsets.zero
    private var isRefreshing = false {
        didSet { refreshStateDidChange(isRefreshing) }
    }
    private var progress: Float = 0 {
        didSet { scrollProgressDidChange(progress) }
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
    
    open override func willMove(toWindow newWindow: UIWindow?) {
        if newWindow == nil {
            clearObserver()
        } else {
            guard let scrollView = scrollView else { return }
            setupObserver(scrollView)
        }
    }

    open override func willMove(toSuperview newSuperview: UIView?) {
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
                self?.isHidden = scrollView.contentSize.height <= scrollView.bounds.height
            }
        }
    }

    private func clearObserver() {
        offsetToken?.invalidate()
        stateToken?.invalidate()
        sizeToken?.invalidate()
    }

    private func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isRefreshing { return }

        switch kind {
        case .header:
            progress = Float(min(1, max(0, -(scrollView.contentOffset.y + scrollView.contentInsetTop) / threshold)))
        case .footer(let auto):
            if scrollView.contentSize.height <= scrollView.bounds.height { break }
            if auto {
                if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInsetBottom {
                    beginRefreshing()
                }
            } else {
                progress = Float(min(1, max(0, (scrollView.contentOffset.y + scrollView.bounds.height - scrollView.contentSize.height - scrollView.contentInsetBottom) / threshold)))
            }
        }
    }

    private func scrollViewDidEndDragging(_ scrollView: UIScrollView) {
        var isAuto = false
        switch kind {
        case .footer(let auto):
            isAuto = auto
        default:
            isAuto = false
        }
        if isRefreshing || progress < 1 || isAuto { return }
        beginRefreshing()
    }

    func beginRefreshing() {
        guard let scrollView = scrollView, !isRefreshing else { return }
        beginContentInset = scrollView.contentInset
        progress = 1
        isRefreshing = true
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: {
                switch self.kind {
                case .header:
                    scrollView.contentOffset.y = -self.threshold - scrollView.contentInsetTop
                    scrollView.contentInset.top += self.threshold
                case .footer(let auto):
                    if auto {
                        scrollView.contentOffset.y = self.threshold + scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInsetBottom
                    }
                    scrollView.contentInset.bottom += self.threshold
                }
            }, completion: { _ in
                self.actionHandler()
            })
        }
    }

    func endRefreshing(completion: (() -> Void)? = nil) {
        guard let scrollView = scrollView else { return }
        guard isRefreshing else { completion?(); return }

        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: {
                scrollView.contentInset = self.beginContentInset
            }, completion: { _ in
                self.isRefreshing = false
                self.progress = 0
                completion?()
            })
        }
    }

}


private extension UIScrollView {
    var contentInsetTop: CGFloat {
        return contentInset.top + adjustedContentInset.top
    }

    var contentInsetBottom: CGFloat {
        return contentInset.bottom + adjustedContentInset.bottom
    }
}
