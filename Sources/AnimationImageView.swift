//
//  AnimationImageView.swift
//  Refreshing
//
//  Created by LC on 2023/11/1.
//

import UIKit

public protocol AnimationViewWrapper: UIView {
    func startAnimating(status: RefreshStatus)
    func stopAnimating()
}

public enum RefreshStatus {
    case release
    case loading
}

open class AnimationImageView: RefreshComponent {

    public let animationView: AnimationViewWrapper
    private var isReleasable = false

    public init(animationView: AnimationViewWrapper, kind: RefreshComponent.Kind, threshold: CGFloat, actionHandler: @escaping () -> Void) {
        animationView.translatesAutoresizingMaskIntoConstraints = false
        self.animationView = animationView
        super.init(kind: kind, threshold: threshold, actionHandler: actionHandler)
        addSubview(animationView)
        setupConstraints()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func setupConstraints() {
        let inset = Configuration.animationImageLayout.edgeInset
        NSLayoutConstraint.activate([
            animationView.rightAnchor.constraint(equalTo: rightAnchor, constant: -inset.right),
            animationView.leftAnchor.constraint(equalTo: leftAnchor, constant: inset.left),
            animationView.topAnchor.constraint(equalTo: topAnchor, constant: inset.top),
            animationView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset.bottom)
        ])
    }
    
    open override func refreshStateDidChange(_ isRefreshing: Bool) {
        isRefreshing ? animationView.startAnimating(status: .loading) : animationView.stopAnimating()
    }
    
    open override func scrollProgressDidChange(_ progress: Float) {
        let releasable = progress == 1
        guard releasable != isReleasable else { return }
        isReleasable = releasable
        if releasable {
            animationView.startAnimating(status: .release)
        } else {
            animationView.stopAnimating()
        }
    }
}

open class AnimationTextImageView: AnimationImageView {
    
    public lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = Configuration.font
        if self.style == .white {
            label.textColor = UIColor.white.withAlphaComponent(0.8)
        } else {
            label.textColor = UIColor.black.withAlphaComponent(0.8)
        }
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        addSubview(label)
        return label
    }()

    public let style: RefreshStyle
    
    private var isHeader: Bool {
        switch kind {
        case .header:
            return true
        default:
            return false
        }
    }

    private var idleText: String {
        isHeader ? Configuration.text.headIdle : Configuration.text.footIdle
    }
    
    public init(animationView: AnimationViewWrapper, style:RefreshStyle, kind: RefreshComponent.Kind, threshold: CGFloat, actionHandler: @escaping () -> Void) {
        self.style = style
        super.init(animationView:animationView, kind: kind, threshold: threshold, actionHandler: actionHandler)
        updateText(idleText)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func setupConstraints() {
        
        let inset = Configuration.animationTextImageLayout.edgeInset
        NSLayoutConstraint.activate([
            textLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -inset.right),
            textLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: inset.left),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset.bottom)
        ])
        
        NSLayoutConstraint.activate([
            animationView.rightAnchor.constraint(equalTo: rightAnchor, constant: -inset.right),
            animationView.leftAnchor.constraint(equalTo: leftAnchor, constant: inset.left),
            animationView.topAnchor.constraint(equalTo: topAnchor, constant: inset.top),
            animationView.bottomAnchor.constraint(equalTo: textLabel.topAnchor, constant: -Configuration.animationTextImageLayout.spacing)
        ])

        textLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

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
    }

    private func updateText(_ text: String) {
        guard textLabel.text != text else { return }
        textLabel.text = text
    }

}
