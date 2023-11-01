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

    public static var padding: CGFloat = 10

    public let animationView: AnimationViewWrapper

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
        NSLayoutConstraint.activate([
            animationView.rightAnchor.constraint(equalTo: rightAnchor, constant: -AnimationImageView.padding),
            animationView.leftAnchor.constraint(equalTo: leftAnchor, constant: AnimationImageView.padding),
            animationView.topAnchor.constraint(equalTo: topAnchor, constant: AnimationImageView.padding),
            animationView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -AnimationImageView.padding)
        ])
    }
    
    open override func refreshStateDidChange(_ isRefreshing: Bool) {
        isRefreshing ? animationView.startAnimating(status: .loading) : animationView.stopAnimating()
    }
    
    open override func scrollProgressDidChange(_ progress: Float) {
        if progress == 1 {
            animationView.startAnimating(status: .release)
        } else {
            animationView.stopAnimating()
        }
    }
}

open class AnimationTextImageView: AnimationImageView {

    public static var layout = Layout()
    public struct Layout {
        let padding: CGFloat = 10
        let spacing: CGFloat = 10
    }
    
    public lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
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
    
    public init(animationView: AnimationViewWrapper, style:RefreshStyle, kind: RefreshComponent.Kind, threshold: CGFloat, actionHandler: @escaping () -> Void) {
        self.style = style
        super.init(animationView:animationView, kind: kind, threshold: threshold, actionHandler: actionHandler)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func setupConstraints() {
        NSLayoutConstraint.activate([
            textLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -AnimationTextImageView.layout.padding),
            textLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: AnimationTextImageView.layout.padding),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -AnimationTextImageView.layout.padding)
        ])
        
        NSLayoutConstraint.activate([
            animationView.rightAnchor.constraint(equalTo: rightAnchor, constant: -AnimationTextImageView.layout.padding),
            animationView.leftAnchor.constraint(equalTo: leftAnchor, constant: AnimationTextImageView.layout.padding),
            animationView.topAnchor.constraint(equalTo: topAnchor, constant: AnimationTextImageView.layout.padding),
            animationView.bottomAnchor.constraint(equalTo: textLabel.topAnchor, constant: -AnimationTextImageView.layout.spacing)
        ])

        textLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

    }

    open override func refreshStateDidChange(_ isRefreshing: Bool) {
        super.refreshStateDidChange(isRefreshing)
        textLabel.text = isRefreshing ? RefreshText.loading : (isHeader ? RefreshText.headIdle : RefreshText.footIdle)
    }

    open override func scrollProgressDidChange(_ progress: Float) {
        super.scrollProgressDidChange(progress)
        textLabel.text = progress == 1 ? RefreshText.release : (isHeader ? RefreshText.headIdle : RefreshText.footIdle)
    }

}
