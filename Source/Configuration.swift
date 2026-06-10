//
//  Configuration.swift
//  Refreshing
//
//  Created by LC on 2025/9/16.
//

import UIKit

public struct Configuration {
    public static var font = UIFont.systemFont(ofSize: 14)
    public static var text = Text()
    public static var animationImageLayout = AnimationImageLayout()
    public static var animationTextImageLayout = AnimationTextImageLayout()

    public struct Text {
        public var loading: String = "Loading..."
        public var headIdle: String = "Pull down to refresh"
        public var footIdle: String = "Pull up to load more"
        public var release: String = "Release to refresh"
    }

    public struct AnimationImageLayout {
        public var edgeInset: UIEdgeInsets = .zero
    }
    
    public struct AnimationTextImageLayout {
        public var edgeInset: UIEdgeInsets = .zero
        public var spacing: CGFloat = 10
    }
}

