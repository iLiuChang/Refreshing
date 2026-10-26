//
//  IndicatorView.swift
//  Refreshing
//
//  Created by LC on 2023/9/25.
//

import UIKit

/// A pull-to-refresh header or footer showing an arrow that flips when the threshold is reached,
/// replaced by an activity indicator while refreshing.
open class IndicatorView: RefreshComponent {

    /// The arrow, drawn with `RefreshConfiguration.arrowColor`. Hidden while refreshing and in the "no more data" state.
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
        layer.lineWidth = 2
        layer.lineCap = .round
        return layer
    }()

    /// The activity indicator shown while refreshing.
    public lazy var indicator = UIActivityIndicatorView.refreshIndicator(color: configuration.indicatorColor)

    /// Whether the component is a header (`true`) or a pull-up footer (`false`).
    public let isHeader: Bool

    /// Creates an arrow refresh component.
    /// - Parameters:
    ///   - isHeader: `true` for a header, `false` for a footer that requires pulling up and releasing.
    ///   - threshold: The height of the component and the pull distance needed to trigger a refresh.
    ///   - configuration: The appearance and text. Pass `nil` to use `RefreshConfiguration.default`.
    ///   - actionHandler: Called on the main thread when a refresh begins.
    public init(isHeader: Bool, threshold: CGFloat, configuration: RefreshConfiguration? = nil, actionHandler: @escaping () -> Void) {
        self.isHeader = isHeader
        super.init(kind: isHeader ? .header : .footer(automatic: false), threshold: threshold, configuration: configuration, actionHandler: actionHandler)
        layer.addSublayer(arrowLayer)
        addSubview(indicator)
        updateArrowColor()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateArrowColor()
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

    private func updateArrowColor() {
        if #available(iOS 13.0, *) {
            arrowLayer.strokeColor = configuration.arrowColor.resolvedColor(with: traitCollection).cgColor
        } else {
            arrowLayer.strokeColor = configuration.arrowColor.cgColor
        }
    }

}

/// An `IndicatorView` with a text label next to the arrow.
open class TextIndicatorView: IndicatorView {

    /// The label showing the text from `RefreshConfiguration.text`.
    public lazy var textLabel = UILabel.refreshLabel(configuration: configuration)

    private var idleText: String {
        isHeader ? configuration.text.headIdle : configuration.text.footIdle
    }

    /// Creates an arrow refresh component with a text label. See `IndicatorView.init(isHeader:threshold:configuration:actionHandler:)`.
    public override init(isHeader: Bool, threshold: CGFloat, configuration: RefreshConfiguration? = nil, actionHandler: @escaping () -> Void) {
        super.init(isHeader: isHeader, threshold: threshold, configuration: configuration, actionHandler: actionHandler)
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
        let halfSpacing = configuration.spacing / 2
        arrowLayer.position = center.move(x: -textLabel.bounds.midX - halfSpacing)
        indicator.center = center.move(x: -textLabel.bounds.midX - halfSpacing)
        textLabel.center = center.move(x: indicator.bounds.midX + halfSpacing)
    }

    open override func refreshStateDidChange(_ isRefreshing: Bool) {
        super.refreshStateDidChange(isRefreshing)
        updateText(isRefreshing ? configuration.text.loading : idleText)
    }

    open override func scrollProgressDidChange(_ progress: Float) {
        super.scrollProgressDidChange(progress)
        updateText(progress == 1 ? configuration.text.release : idleText)
    }

    open override func noMoreDataStateDidChange(_ isNoMoreData: Bool) {
        super.noMoreDataStateDidChange(isNoMoreData)
        updateText(isNoMoreData ? configuration.text.noMoreData : idleText)
        setNeedsLayout()
    }

    private func updateText(_ text: String) {
        guard textLabel.text != text else { return }
        textLabel.text = text
        textLabel.sizeToFit()
        setNeedsLayout()
    }

}

/// A footer that starts loading automatically once the content is scrolled to the bottom,
/// showing an activity indicator while loading.
open class IndicatorAutoFooter: RefreshComponent {

    /// The activity indicator shown while loading.
    public lazy var indicator = UIActivityIndicatorView.refreshIndicator(color: configuration.indicatorColor)

    /// Creates an automatic footer.
    /// - Parameters:
    ///   - threshold: The height of the footer.
    ///   - configuration: The appearance and text. Pass `nil` to use `RefreshConfiguration.default`.
    ///   - actionHandler: Called on the main thread when loading begins.
    public init(threshold: CGFloat, configuration: RefreshConfiguration? = nil, actionHandler: @escaping () -> Void) {
        super.init(kind: .footer(automatic: true), threshold: threshold, configuration: configuration, actionHandler: actionHandler)
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

/// An `IndicatorAutoFooter` with a text label, which is empty unless loading or in the "no more data" state.
open class TextIndicatorAutoFooter: IndicatorAutoFooter {

    /// The label showing the text from `RefreshConfiguration.text`.
    public lazy var textLabel = UILabel.refreshLabel(configuration: configuration)

    /// Creates an automatic footer with a text label. See `IndicatorAutoFooter.init(threshold:configuration:actionHandler:)`.
    public override init(threshold: CGFloat, configuration: RefreshConfiguration? = nil, actionHandler: @escaping () -> Void) {
        super.init(threshold: threshold, configuration: configuration, actionHandler: actionHandler)
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
        let halfSpacing = configuration.spacing / 2
        indicator.center = center.move(x: -textLabel.bounds.midX - halfSpacing)
        textLabel.center = center.move(x: indicator.bounds.midX + halfSpacing)
    }

    open override func refreshStateDidChange(_ isRefreshing: Bool) {
        super.refreshStateDidChange(isRefreshing)
        updateText(isRefreshing ? configuration.text.loading : "")
    }

    open override func noMoreDataStateDidChange(_ isNoMoreData: Bool) {
        super.noMoreDataStateDidChange(isNoMoreData)
        updateText(isNoMoreData ? configuration.text.noMoreData : "")
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

extension UIActivityIndicatorView {
    static func refreshIndicator(color: UIColor) -> UIActivityIndicatorView {
        let indicator: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            indicator = UIActivityIndicatorView(style: .medium)
        } else {
            indicator = UIActivityIndicatorView(style: .gray)
        }
        indicator.color = color
        return indicator
    }
}

extension UILabel {
    static func refreshLabel(configuration: RefreshConfiguration) -> UILabel {
        let label = UILabel()
        label.font = configuration.font
        label.textColor = configuration.textColor
        return label
    }
}
