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
    public var rfg: UIScrollViewRefreshWrapper {
        get { UIScrollViewRefreshWrapper(self) }
        set {}
    }
}

public enum RefreshType {
    case indicator(RefreshStyle)
    case textIndicator(RefreshStyle)
}

public enum RefreshStyle {
    case black
    case white
}

public struct UIScrollViewRefreshWrapper {

    let base: UIScrollView
    init(_ base: UIScrollView) {
        self.base = base
    }

    public var isExistRefreshHeader: Bool { _header != nil }
    public var isExistRefreshFooter: Bool { _footer != nil }

    public mutating func addRefreshHeader(type: RefreshType = .indicator(.black), threshold: CGFloat = 60, actionHandler: @escaping (()->())) {
        switch type {
        case .indicator(let style):
            _header = IndicatorView(isHeader: true, style: style, threshold: threshold, actionHandler: actionHandler)
        case .textIndicator(let style):
            _header = TextIndicatorView(isHeader: true, style: style, threshold: threshold, actionHandler: actionHandler)
        }
    }
    
    public mutating func addRefreshFooter(type: RefreshType = .indicator(.black), auto: Bool = false, threshold: CGFloat = 60, actionHandler: @escaping (()->())) {
        switch type {
        case .indicator(let style):
            if auto {
                _footer = IndicatorAutoFooter(style: style, threshold: threshold, actionHandler: actionHandler)
            } else {
                _footer = IndicatorView(isHeader: false, style: style, threshold: threshold, actionHandler: actionHandler)
            }
        case .textIndicator(let style):
            if auto {
                _footer = TextIndicatorAutoFooter(style: style, threshold: threshold, actionHandler: actionHandler)
            } else {
                _footer = TextIndicatorView(isHeader: false, style: style, threshold: threshold, actionHandler: actionHandler)
            }
        }
    }
    
    public mutating func removeRefreshHeader() {
        _header = nil
    }

    public mutating func removeRefreshFooter() {
        _footer = nil
    }

    public mutating func resetRefreshFooter() {
        _footer = _tempFooter
    }

    public func beginRefreshing() {
        _header?.beginRefreshing()
    }

    public func endRefreshing() {
        _header?.endRefreshing()
        _footer?.endRefreshing()
    }

    public mutating func addCustomRefreshHeader(_ header: RefreshComponent) {
        _header = header
    }

    public mutating func addCustomRefreshFooter(_ footer: RefreshComponent) {
        _footer = footer
    }
    
    private var _header: RefreshComponent? {
        get {  objc_getAssociatedObject(base, &RefreshHeaderKey) as? RefreshComponent }
        set {
            _header?.removeFromSuperview()
            objc_setAssociatedObject(base, &RefreshHeaderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let v = newValue {
                base.insertSubview(v, at: 0)
            }
        }
    }

    private var _footer: RefreshComponent? {
        get { objc_getAssociatedObject(base, &RefreshFooterKey) as? RefreshComponent }
        set {
            _footer?.removeFromSuperview()
            objc_setAssociatedObject(base, &RefreshFooterKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if let v = newValue {
                base.insertSubview(v, at: 0)
            }
        }
    }

    private var _tempFooter: RefreshComponent? {
        get { objc_getAssociatedObject(base, &TempRefreshFooterKey) as? RefreshComponent }
        set { objc_setAssociatedObject(base, &TempRefreshFooterKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}


