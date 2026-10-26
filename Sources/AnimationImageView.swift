//
//  AnimationImageView.swift
//  Refreshing
//
//  Created by LC on 2023/11/1.
//

import UIKit

/// A view that plays a custom animation for `.animation` and `.textAnimation` refresh components.
///
/// A `UIImageView` subclass can conform by switching `animationImages` in `startAnimating(status:)`;
/// `stopAnimating()` is already provided by `UIImageView`.
public protocol AnimationViewWrapper: UIView {
    /// Starts the animation for the given status. May be called again with a different status
    /// without `stopAnimating()` in between, for example when going from `.release` to `.loading`.
    func startAnimating(status: RefreshStatus)
    /// Stops the animation. Called when the component is pulled back below the threshold or refreshing ends.
    func stopAnimating()
}

/// The phase an animation view is asked to animate.
public enum RefreshStatus {
    /// The component has been pulled past the threshold; releasing will trigger a refresh.
    case release
    /// The component is refreshing.
    case loading
}

/// A refresh component that shows a custom animation view filling its bounds,
/// inset by `RefreshConfiguration.contentInset`.
open class AnimationImageView: RefreshComponent {

    /// The view that plays the animation.
    public let animationView: AnimationViewWrapper
    private var isReleasable = false

    /// Creates an animation refresh component.
    /// - Parameters:
    ///   - animationView: The view that plays the animation. Its constraints are managed by the component.
    ///   - kind: The position and trigger mode of the component.
    ///   - threshold: The height of the component and the pull distance needed to trigger a refresh.
    ///   - configuration: The appearance and text. Pass `nil` to use `RefreshConfiguration.default`.
    ///   - actionHandler: Called on the main thread when a refresh begins.
    public init(animationView: AnimationViewWrapper, kind: RefreshComponent.Kind, threshold: CGFloat, configuration: RefreshConfiguration? = nil, actionHandler: @escaping () -> Void) {
        animationView.translatesAutoresizingMaskIntoConstraints = false
        self.animationView = animationView
        super.init(kind: kind, threshold: threshold, configuration: configuration, actionHandler: actionHandler)
        addSubview(animationView)
        setupConstraints()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Lays out the subviews with Auto Layout. Called once during initialization;
    /// override it to customize the layout without calling `super`.
    open func setupConstraints() {
        let inset = configuration.contentInset
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

/// A refresh component that shows a custom animation view with a text label below it.
open class AnimationTextImageView: AnimationImageView {
    
    /// The label showing the text from `RefreshConfiguration.text`.
    public lazy var textLabel: UILabel = {
        let label = UILabel.refreshLabel(configuration: configuration)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        addSubview(label)
        return label
    }()
    
    private var isHeader: Bool {
        switch kind {
        case .header:
            return true
        default:
            return false
        }
    }

    private var idleText: String {
        isHeader ? configuration.text.headIdle : configuration.text.footIdle
    }
    
    /// Creates an animation refresh component with a text label. See `AnimationImageView.init(animationView:kind:threshold:configuration:actionHandler:)`.
    public override init(animationView: AnimationViewWrapper, kind: RefreshComponent.Kind, threshold: CGFloat, configuration: RefreshConfiguration? = nil, actionHandler: @escaping () -> Void) {
        super.init(animationView: animationView, kind: kind, threshold: threshold, configuration: configuration, actionHandler: actionHandler)
        updateText(idleText)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func setupConstraints() {
        
        let inset = configuration.contentInset
        NSLayoutConstraint.activate([
            textLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -inset.right),
            textLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: inset.left),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset.bottom)
        ])
        
        NSLayoutConstraint.activate([
            animationView.rightAnchor.constraint(equalTo: rightAnchor, constant: -inset.right),
            animationView.leftAnchor.constraint(equalTo: leftAnchor, constant: inset.left),
            animationView.topAnchor.constraint(equalTo: topAnchor, constant: inset.top),
            animationView.bottomAnchor.constraint(equalTo: textLabel.topAnchor, constant: -configuration.spacing)
        ])

        textLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

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
    }

    private func updateText(_ text: String) {
        guard textLabel.text != text else { return }
        textLabel.text = text
    }

}
