# Refreshing

![Swift](https://img.shields.io/badge/Swift-5.5%2B-orange.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%2011.0%2B-lightgrey.svg)
![Version](https://img.shields.io/badge/Version-2.0.0-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![SPM](https://img.shields.io/badge/SPM-supported-brightgreen.svg)
![CocoaPods](https://img.shields.io/badge/CocoaPods-supported-blueviolet.svg)

## Overview

A pull-to-refresh and load-more library for iOS, built as an extension on `UIScrollView`. Attach a header, a footer, or both through `scrollView.rfg`:

- **Header** — pull down past a threshold and release to refresh
- **Footer** — pull up to load more, or trigger automatically when the content reaches the bottom

## Features

- **Any UIScrollView** — works with `UITableView`, `UICollectionView`, and plain scroll views
- **Built-in Styles** — arrow indicator, text indicator, custom animation, and animation with text
- **Automatic Footer** — start loading as soon as the content is scrolled to the bottom
- **No More Data** — lock the footer after the last page and reset it when the header refreshes
- **Appearance** — global defaults or a per-component `RefreshConfiguration` (text, font, colors, spacing, insets)
- **Custom Components** — subclass `RefreshComponent` and provide only the appearance
- **Dark Mode** — built-in colors adapt to light and dark appearance
- **Safe Area** — respects `adjustedContentInset`, including navigation bars and the home indicator

## Requirements

- iOS 11.0+
- Swift 5.5+

## Installation

### CocoaPods

```ruby
pod 'Refreshing'
```

Then run:

```bash
pod install
```

### Swift Package Manager

In Xcode: **File → Add Packages…** and enter:

```
https://github.com/iLiuChang/Refreshing.git
```

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/iLiuChang/Refreshing.git", from: "2.0.0")
]
```

### Manual

1. Download the files in the `Sources` folder
2. Drag them into your Xcode project

## Usage

### Header and Footer

```swift
import Refreshing

tableView.rfg.addRefreshHeader(type: .textIndicator) { [weak self] in
    self?.reloadData()
}

tableView.rfg.addRefreshFooter(type: .textIndicator) { [weak self] in
    self?.loadMore()
}
```

End the refresh when the work finishes:

```swift
tableView.rfg.endRefreshing()
```

### Built-in Styles

| Type | Appearance |
|---|---|
| `.indicator` | Arrow that flips at the threshold, then an activity indicator |
| `.textIndicator` | Same as `.indicator`, with a text label |
| `.animation(view)` | A custom animation view filling the component |
| `.textAnimation(view)` | A custom animation view with a text label below it |

An automatic footer (`.indicator` or `.textIndicator` with `auto: true`) shows only the activity indicator, plus text while loading or when there is no more data.

### Automatic Footer

```swift
tableView.rfg.addRefreshFooter(type: .textIndicator, auto: true) { [weak self] in
    self?.loadMore()
}
```

### No More Data

```swift
tableView.rfg.endRefreshingWithNoMoreData()

// After a header refresh replaces the list:
tableView.rfg.resetNoMoreData()
```

### Custom Appearance

```swift
var configuration = RefreshConfiguration()
configuration.text.headIdle = "Pull down to refresh"
configuration.text.loading = "Refreshing..."
configuration.textColor = .systemOrange
configuration.arrowColor = .systemOrange
configuration.indicatorColor = .systemOrange

tableView.rfg.addRefreshHeader(type: .textIndicator, configuration: configuration) { [weak self] in
    self?.reloadData()
}
```

Change `RefreshConfiguration.default` to apply the same appearance to every component created afterwards. Each component copies the configuration when it is created.

### Custom Animation

Conform a view to `AnimationViewWrapper`. A `UIImageView` already implements `stopAnimating()`:

```swift
final class GIFView: UIImageView, AnimationViewWrapper {
    func startAnimating(status: RefreshStatus) {
        switch status {
        case .release:
            animationImages = releaseImages
        case .loading:
            animationImages = loadingImages
        }
        startAnimating()
    }
}

tableView.rfg.addRefreshHeader(type: .animation(GIFView()), threshold: 80) { [weak self] in
    self?.reloadData()
}
```

### Begin Refreshing

```swift
tableView.rfg.beginRefreshing()
```

### Hide a Component

```swift
tableView.rfg.isHideRefreshFooter = true
```

When `isHideRefreshFooter` is `nil`, the footer hides itself while the content is shorter than the scroll view.

### Custom Component

Subclass `RefreshComponent` and implement `refreshStateDidChange(_:)` and `scrollProgressDidChange(_:)`:

```swift
final class ProgressHeader: RefreshComponent {
    init(actionHandler: @escaping () -> Void) {
        super.init(kind: .header, threshold: 60, actionHandler: actionHandler)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func refreshStateDidChange(_ isRefreshing: Bool) {
        // show or hide the activity indicator
    }

    override func scrollProgressDidChange(_ progress: Float) {
        // progress is 0...1; 1 means releasing will trigger a refresh
    }
}

tableView.rfg.addCustomRefreshHeader(ProgressHeader { [weak self] in
    self?.reloadData()
})
```

## API Reference

### UIScrollViewRefreshWrapper

Access it through `scrollView.rfg`. A scroll view has at most one header and one footer; adding a new one replaces the existing one.

| Property / Method | Description |
|---|---|
| `isExistRefreshHeader` | Whether a header has been added. |
| `isExistRefreshFooter` | Whether a footer has been added. |
| `isHideRefreshHeader` | Forces the header hidden (`true`) or shown (`false`). |
| `isHideRefreshFooter` | Forces the footer hidden or shown. `nil` hides it while the content is shorter than the scroll view. |
| `addRefreshHeader(type:threshold:configuration:actionHandler:)` | Adds a header. `threshold` defaults to `60`. |
| `addRefreshFooter(type:auto:threshold:configuration:actionHandler:)` | Adds a footer. `auto` triggers it at the bottom without a pull. |
| `removeRefreshHeader()` | Removes the header and restores its content inset. |
| `removeRefreshFooter()` | Removes the footer and restores its content inset. |
| `beginRefreshing()` | Starts a header refresh and calls its action handler. |
| `endRefreshing()` | Ends refreshing of both the header and the footer. |
| `endRefreshingWithNoMoreData()` | Ends refreshing and puts the footer into the "no more data" state. |
| `resetNoMoreData()` | Clears the "no more data" state so the footer can load again. |
| `addCustomRefreshHeader(_:)` | Adds a custom `RefreshComponent` whose `kind` is `.header`. |
| `addCustomRefreshFooter(_:)` | Adds a custom `RefreshComponent` whose `kind` is `.footer`. |

### RefreshConfiguration

| Property | Description |
|---|---|
| `text` | Strings for idle, release, loading, and no more data. |
| `font` | Font of the text. Defaults to system 14 pt. |
| `textColor` | Text color. Adapts to light and dark mode. |
| `arrowColor` | Arrow color for `.indicator` and `.textIndicator`. |
| `indicatorColor` | Activity indicator color. |
| `contentInset` | Insets inside `.animation` and `.textAnimation`. |
| `spacing` | Distance between the indicator or animation view and the text. |
| `default` | Used when no configuration is passed. Later changes do not affect existing components. |

### RefreshComponent

| Property / Method | Description |
|---|---|
| `kind` | `.header`, or `.footer(auto)`. |
| `threshold` | Height of the component and the pull distance that triggers a refresh. |
| `configuration` | The configuration captured at creation. |
| `isHideRefresher` | Forces the component hidden or shown. A hidden component never triggers. |
| `isNoMoreData` | Whether the component is in the "no more data" state. |
| `refreshStateDidChange(_:)` | Required override. Called when refreshing starts or stops. |
| `scrollProgressDidChange(_:)` | Required override. Pull progress in `0...1`. |
| `noMoreDataStateDidChange(_:)` | Optional override. Called when entering or leaving "no more data". |

## Architecture

`UIScrollView.rfg` returns a `UIScrollViewRefreshWrapper` that keeps at most one header and one footer as associated objects, inserted at the back of the scroll view.

`RefreshComponent` observes `contentOffset`, the pan gesture state, and — for footers — `contentSize`. Pulling past `threshold` and releasing calls the action handler and increases `contentInset` so the component stays visible. `endRefreshing()` animates the inset back. An automatic footer skips the pull and starts loading once the content is scrolled to the bottom. While one component is refreshing, the other will not start.

Built-in styles are subclasses that only update their appearance. `IndicatorView` draws an arrow and swaps it for an activity indicator. `AnimationImageView` forwards `.release` and `.loading` to an `AnimationViewWrapper`.

## License

MIT License. See [LICENSE](LICENSE) for details.
