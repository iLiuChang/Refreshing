//
//  IndicatorView.swift
//  Refreshing
//
//  Created by LC on 2023/9/25.
//

import UIKit

open class IndicatorView: RefreshComponent {

    public lazy var arrowLayer: CAShapeLayer = {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 8))
        path.addLine(to: CGPoint(x: 0, y: -8))
        path.move(to: CGPoint(x: 0, y: 8))
        path.addLine(to: CGPoint(x: 5.66, y: 2.34))
        path.move(to: CGPoint(x: 0, y: 8))
        path.addLine(to: CGPoint(x: -5.66, y: 2.34))

        let layer = CAShapeLayer()
        layer.path = path.cgPath
        if self.style == .white {
            layer.strokeColor = UIColor.white.withAlphaComponent(0.8).cgColor
        } else {
            layer.strokeColor = UIColor.black.withAlphaComponent(0.8).cgColor
        }
        layer.lineWidth = 2
        layer.lineCap = .round
        return layer
    }()

    public lazy var indicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            let idr = UIActivityIndicatorView(style: .medium)
            idr.color = self.style == .white ? UIColor.white : UIColor.gray
            return idr
        } else {
            return UIActivityIndicatorView(style: self.style == .white ? .white : .gray)
        }
    }()

    public let style: RefreshStyle
    public let isHeader: Bool

    public init(isHeader: Bool, style:RefreshStyle, threshold: CGFloat, actionHandler: @escaping () -> Void) {
        self.isHeader = isHeader
        self.style = style
        super.init(kind: isHeader ? .header : .footer(false), threshold: threshold, actionHandler: actionHandler)
        layer.addSublayer(arrowLayer)
        addSubview(indicator)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        arrowLayer.position = center
        indicator.center = center
    }

    open override func refreshStateDidChange(_ isRefreshing: Bool) {
        arrowLayer.isHidden = isRefreshing
        isRefreshing ? indicator.startAnimating() : indicator.stopAnimating()
    }

    open override func scrollProgressDidChange(_ progress: Float) {
        let rotation = CATransform3DMakeRotation(CGFloat.pi, 0, 0, 1)
        if isHeader {
            arrowLayer.transform = progress == 1 ? rotation : CATransform3DIdentity
        } else {
            arrowLayer.transform = progress == 1 ? CATransform3DIdentity : rotation
        }
    }

    open override func noMoreDataStateDidChange(_ isNoMoreData: Bool) {
        arrowLayer.isHidden = isNoMoreData
    }

}

open class TextIndicatorView: IndicatorView {

    public lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = Configuration.font
        if self.style == .white {
            label.textColor = UIColor.white.withAlphaComponent(0.8)
        } else {
            label.textColor = UIColor.black.withAlphaComponent(0.8)
        }
        return label
    }()

    private var idleText: String {
        isHeader ? Configuration.text.headIdle : Configuration.text.footIdle
    }

    public override init(isHeader: Bool, style:RefreshStyle, threshold: CGFloat, actionHandler: @escaping () -> Void) {
        super.init(isHeader: isHeader, style:style, threshold: threshold, actionHandler: actionHandler)
        addSubview(textLabel)
        updateText(idleText)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        if isNoMoreData {
            textLabel.center = center
            return
        }
        arrowLayer.position = center.move(x: -textLabel.bounds.midX - 4)
        indicator.center = center.move(x: -textLabel.bounds.midX - 4)
        textLabel.center = center.move(x: indicator.bounds.midX + 4)
    }

    open override func refreshStateDidChange(_ isRefreshing: Bool) {
        super.refreshStateDidChange(isRefreshing)
        updateText(isRefreshing ? Configuration.text.loading : idleText)
    }

    open override func scrollProgressDidChange(_ progress: Float) {
        super.scrollProgressDidChange(progress)
        updateText(progress == 1 ? Configuration.text.release : idleText)
    }

    open override func noMoreDataStateDidChange(_ isNoMoreData: Bool) {
        super.noMoreDataStateDidChange(isNoMoreData)
        updateText(isNoMoreData ? Configuration.text.noMoreData : idleText)
        setNeedsLayout()
    }

    private func updateText(_ text: String) {
        guard textLabel.text != text else { return }
        textLabel.text = text
        textLabel.sizeToFit()
        setNeedsLayout()
    }

}

fileprivate extension CGPoint {
    func move(x: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + x, y: y)
    }
}

open class IndicatorAutoFooter: RefreshComponent {

    public lazy var indicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            let idr = UIActivityIndicatorView(style: .medium)
            idr.color = self.style == .white ? UIColor.white : UIColor.gray
            return idr
        } else {
            return UIActivityIndicatorView(style: self.style == .white ? .white : .gray)
        }
    }()

    public let style: RefreshStyle

    public init(style:RefreshStyle, threshold: CGFloat, actionHandler: @escaping () -> Void) {
        self.style = style
        super.init(kind: .footer(true), threshold: threshold, actionHandler: actionHandler)
        addSubview(indicator)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        indicator.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }

    open override func refreshStateDidChange(_ isRefreshing: Bool) {
        isRefreshing ? indicator.startAnimating() : indicator.stopAnimating()
    }

    open override func scrollProgressDidChange(_ progress: Float) {

    }
}

open class TextIndicatorAutoFooter: IndicatorAutoFooter {

    public lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        if self.style == .white {
            label.textColor = UIColor.white.withAlphaComponent(0.8)
        } else {
            label.textColor = UIColor.black.withAlphaComponent(0.8)
        }
        return label
    }()

    public override init(style:RefreshStyle, threshold: CGFloat, actionHandler: @escaping () -> Void) {
        super.init(style: style, threshold: threshold, actionHandler: actionHandler)
        addSubview(textLabel)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        if isNoMoreData {
            textLabel.center = center
            return
        }
        indicator.center = center.move(x: -textLabel.bounds.midX - 4)
        textLabel.center = center.move(x: indicator.bounds.midX + 4)
    }

    open override func refreshStateDidChange(_ isRefreshing: Bool) {
        super.refreshStateDidChange(isRefreshing)
        updateText(isRefreshing ? Configuration.text.loading : "")
    }

    open override func noMoreDataStateDidChange(_ isNoMoreData: Bool) {
        super.noMoreDataStateDidChange(isNoMoreData)
        updateText(isNoMoreData ? Configuration.text.noMoreData : "")
        setNeedsLayout()
    }

    private func updateText(_ text: String) {
        guard textLabel.text != text else { return }
        textLabel.text = text
        textLabel.sizeToFit()
        setNeedsLayout()
    }

}
