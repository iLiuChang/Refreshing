//
//  ViewController.swift
//  Refreshing
//
//  Created by LC on 2023/9/26.
//

import UIKit

final class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let sections = DemoCase.sections

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Refreshing"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground

        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].cases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = sections[indexPath.section].cases[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = item.subtitle
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.numberOfLines = 2
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section].cases[indexPath.row]
        navigationController?.pushViewController(RefreshListViewController(demo: item), animated: true)
    }
}

enum DemoCase {
    case indicator
    case textIndicator
    case animation
    case textAnimation
    case automaticFooter
    case noMoreData
    case customAppearance
    case beginRefreshing
    case customComponent
    case hideFooter
    case collectionView
    case paging
    case embeddedPaging

    var title: String {
        switch self {
        case .indicator: return "Indicator"
        case .textIndicator: return "Text Indicator"
        case .animation: return "Animation"
        case .textAnimation: return "Text Animation"
        case .automaticFooter: return "Automatic Footer"
        case .noMoreData: return "No More Data"
        case .customAppearance: return "Custom Appearance"
        case .beginRefreshing: return "Begin Refreshing"
        case .customComponent: return "Custom Component"
        case .hideFooter: return "Hide Footer"
        case .collectionView: return "UICollectionView"
        case .paging: return "Paging"
        case .embeddedPaging: return "Embedded Paging"
        }
    }

    var subtitle: String {
        switch self {
        case .indicator: return "rfg.addRefreshHeader(style: .indicator)"
        case .textIndicator: return "rfg.addRefreshHeader(style: .textIndicator)"
        case .animation: return "rfg.addRefreshHeader(style: .animation(view))"
        case .textAnimation: return "rfg.addRefreshHeader(style: .textAnimation(view))"
        case .automaticFooter: return "rfg.addRefreshFooter(..., automatic: true)"
        case .noMoreData: return "endFooterRefreshingWithNoMoreData() / resetNoMoreData()"
        case .customAppearance: return "RefreshConfiguration per header and footer"
        case .beginRefreshing: return "rfg.beginRefreshing() on appear"
        case .customComponent: return "addCustomRefreshHeader(RefreshComponent)"
        case .hideFooter: return "rfg.isHideRefreshFooter"
        case .collectionView: return "Works on any UIScrollView"
        case .paging: return "Load page by page until no more data"
        case .embeddedPaging: return "Paging inside a non-fullscreen card"
        }
    }

    static let sections: [(title: String, cases: [DemoCase])] = [
        ("Built-in Styles", [.indicator, .textIndicator, .animation, .textAnimation]),
        ("Footer", [.automaticFooter, .noMoreData, .paging, .embeddedPaging]),
        ("Configuration", [.customAppearance, .beginRefreshing]),
        ("Advanced", [.customComponent, .hideFooter, .collectionView]),
    ]
}

struct DemoItem {
    let title: String
    let subtitle: String
    let color: UIColor
}

final class RefreshListViewController: UIViewController, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let demo: DemoCase
    private let pageSize = 16
    private let totalPages = 4
    private var page = 1
    private var items: [DemoItem] = []
    private var didBeginOnAppear = false

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        tableView.alwaysBounceVertical = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return collectionView
    }()

    private var scrollView: UIScrollView {
        demo == .collectionView ? collectionView : tableView
    }

    private var isPaging: Bool {
        demo == .paging || demo == .noMoreData || demo == .embeddedPaging
    }

    init(demo: DemoCase) {
        self.demo = demo
        super.init(nibName: nil, bundle: nil)
        title = demo.title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never

        if demo == .embeddedPaging {
            installEmbeddedTableView()
        } else {
            let contentView = demo == .collectionView ? collectionView : tableView
            contentView.frame = view.bounds
            contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(contentView)
        }

        if demo == .hideFooter {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Hide Footer",
                style: .plain,
                target: self,
                action: #selector(toggleFooter)
            )
        }

        if demo != .beginRefreshing {
            items = makePage(1)
        }

        installRefreshers()
        reload()
    }

    private func installEmbeddedTableView() {
        view.backgroundColor = .systemGroupedBackground

        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        let caption = UILabel()
        caption.text = "List is embedded in a card, not full screen."
        caption.font = .preferredFont(forTextStyle: .footnote)
        caption.textColor = .secondaryLabel
        caption.numberOfLines = 0
        caption.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(caption)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.layer.cornerRadius = 0
        card.addSubview(tableView)

        NSLayoutConstraint.activate([
            caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            caption.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            caption.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            card.topAnchor.constraint(equalTo: caption.bottomAnchor, constant: 12),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            card.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),

            tableView.topAnchor.constraint(equalTo: card.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard demo == .beginRefreshing, !didBeginOnAppear else { return }
        didBeginOnAppear = true
        scrollView.rfg.beginRefreshing()
    }

    private func installRefreshers() {
        switch demo {
        case .indicator, .collectionView:
            addHeader(style: .indicator)
            addFooter(style: .indicator)

        case .textIndicator:
            addHeader(style: .textIndicator)
            addFooter(style: .textIndicator)

        case .animation:
            var configuration = RefreshConfiguration.default
            configuration.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
            addHeader(style: .animation(DemoGIFView()), threshold: 80, configuration: configuration)
            addFooter(style: .animation(DemoGIFView()), threshold: 80, configuration: configuration)

        case .textAnimation:
            var configuration = RefreshConfiguration.default
            configuration.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 4, right: 0)
            configuration.spacing = 6
            addHeader(style: .textAnimation(DemoGIFView()), threshold: 80, configuration: configuration)
            addFooter(style: .textAnimation(DemoGIFView()), threshold: 80, configuration: configuration)

        case .automaticFooter:
            addHeader(style: .textIndicator)
            addFooter(style: .textIndicator, automatic: true)

        case .noMoreData:
            addHeader(style: .textIndicator)
            addFooter(style: .textIndicator)

        case .customAppearance:
            var header = RefreshConfiguration()
            header.text.headIdle = "Pull down to refresh"
            header.text.release = "Release to refresh"
            header.text.loading = "Refreshing..."
            header.font = .systemFont(ofSize: 13, weight: .medium)
            header.textColor = .systemOrange
            header.arrowColor = .systemOrange
            header.indicatorColor = .systemOrange
            header.spacing = 6
            addHeader(style: .textIndicator, configuration: header)

            var footer = header
            footer.text.footIdle = "Pull up to load more"
            footer.text.noMoreData = "That's all"
            footer.textColor = .systemTeal
            footer.arrowColor = .systemTeal
            footer.indicatorColor = .systemTeal
            addFooter(style: .textIndicator, configuration: footer)

        case .beginRefreshing, .hideFooter, .paging, .embeddedPaging:
            addHeader(style: .textIndicator)
            addFooter(style: .textIndicator)

        case .customComponent:
            scrollView.rfg.addCustomRefreshHeader(ProgressRefreshHeader { [weak self] in
                self?.refresh()
            })
            addFooter(style: .textIndicator)
        }
    }

    private func addHeader(style: RefreshStyle, threshold: CGFloat = 60, configuration: RefreshConfiguration? = nil) {
        scrollView.rfg.addRefreshHeader(style: style, threshold: threshold, configuration: configuration) { [weak self] in
            self?.refresh()
        }
    }

    private func addFooter(style: RefreshStyle, automatic: Bool = false, threshold: CGFloat = 60, configuration: RefreshConfiguration? = nil) {
        scrollView.rfg.addRefreshFooter(style: style, automatic: automatic, threshold: threshold, configuration: configuration) { [weak self] in
            self?.loadMore()
        }
    }

    private func refresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            self.page = 1
            self.items = self.makePage(1)
            self.scrollView.rfg.resetNoMoreData()
            self.reload()
            self.scrollView.rfg.endRefreshing()
        }
    }

    private func loadMore() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else { return }
            let nextPage = self.page + 1
            self.items.append(contentsOf: self.makePage(nextPage))
            self.page = nextPage
            self.reload()
            if self.isPaging, self.page >= self.totalPages {
                self.scrollView.rfg.endFooterRefreshingWithNoMoreData()
            } else {
                self.scrollView.rfg.endRefreshing()
            }
        }
    }

    private func makePage(_ page: Int) -> [DemoItem] {
        let palette: [UIColor] = [.systemBlue, .systemTeal, .systemOrange, .systemPink, .systemPurple, .systemGreen, .systemIndigo, .systemRed]
        return (1...pageSize).map { index in
            DemoItem(
                title: "Page \(page) · \(index)",
                subtitle: "id \(Int.random(in: 1000...9999))",
                color: palette.randomElement()!.withAlphaComponent(0.25)
            )
        }
    }

    private func reload() {
        if demo == .collectionView {
            collectionView.reloadData()
        } else {
            tableView.reloadData()
        }
    }

    @objc private func toggleFooter() {
        let hidden = !(scrollView.rfg.isHideRefreshFooter ?? false)
        scrollView.rfg.isHideRefreshFooter = hidden
        navigationItem.rightBarButtonItem?.title = hidden ? "Show Footer" : "Hide Footer"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = items[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = item.subtitle
        content.secondaryTextProperties.color = .secondaryLabel
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as? UICollectionViewFlowLayout
        let inset = layout?.sectionInset ?? .zero
        let spacing = layout?.minimumInteritemSpacing ?? 12
        let width = (collectionView.bounds.width - inset.left - inset.right - spacing) / 2
        return CGSize(width: max(floor(width), 0), height: 120)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let item = items[indexPath.item]
        cell.contentView.backgroundColor = item.color
        cell.contentView.layer.cornerRadius = 10
        let titleLabel = cell.contentView.viewWithTag(1) as? UILabel ?? {
            let label = UILabel()
            label.tag = 1
            label.font = .preferredFont(forTextStyle: .headline)
            label.textAlignment = .center
            label.numberOfLines = 2
            cell.contentView.addSubview(label)
            return label
        }()
        let subtitleLabel = cell.contentView.viewWithTag(2) as? UILabel ?? {
            let label = UILabel()
            label.tag = 2
            label.font = .preferredFont(forTextStyle: .footnote)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            cell.contentView.addSubview(label)
            return label
        }()
        titleLabel.frame = CGRect(x: 8, y: 28, width: cell.contentView.bounds.width - 16, height: 44)
        subtitleLabel.frame = CGRect(x: 8, y: 72, width: cell.contentView.bounds.width - 16, height: 20)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        return cell
    }
}

final class DemoGIFView: UIImageView, AnimationViewWrapper {

    private let loadingImages = (1...60).compactMap { UIImage(named: "dropdown_anim__000\($0)") }
    private let releaseImages = (1...3).compactMap { UIImage(named: "dropdown_loading_0\($0)") }

    init() {
        super.init(frame: .zero)
        contentMode = .scaleAspectFit
        animationDuration = 0.5
        image = loadingImages.first
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating(status: RefreshStatus) {
        switch status {
        case .loading:
            animationImages = loadingImages
        case .release:
            animationImages = releaseImages
        }
        startAnimating()
    }
}

final class ProgressRefreshHeader: RefreshComponent {

    private let trackLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.tertiaryLabel.cgColor
        layer.lineWidth = 3
        return layer
    }()

    private let progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.systemBlue.cgColor
        layer.lineWidth = 3
        layer.lineCap = .round
        layer.strokeEnd = 0
        return layer
    }()

    private let percentLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.text = "0%"
        return label
    }()

    private let indicator = UIActivityIndicatorView(style: .medium)

    init(actionHandler: @escaping () -> Void) {
        super.init(kind: .header, threshold: 70, actionHandler: actionHandler)
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
        addSubview(percentLabel)
        addSubview(indicator)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY - 6)
        let radius: CGFloat = 14
        // Start at 12 o'clock so progress grows clockwise without rotating the layer.
        // Setting `frame` after a non-identity `transform` leaves the layer position undefined.
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: .pi * 1.5,
            clockwise: true
        ).cgPath
        trackLayer.frame = bounds
        trackLayer.path = path
        progressLayer.frame = bounds
        progressLayer.path = path
        percentLabel.frame = CGRect(x: 0, y: center.y + radius + 4, width: bounds.width, height: 16)
        indicator.center = center
    }

    override func refreshStateDidChange(_ isRefreshing: Bool) {
        trackLayer.isHidden = isRefreshing
        progressLayer.isHidden = isRefreshing
        percentLabel.isHidden = isRefreshing
        isRefreshing ? indicator.startAnimating() : indicator.stopAnimating()
    }

    override func scrollProgressDidChange(_ progress: Float) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        progressLayer.strokeEnd = CGFloat(progress)
        CATransaction.commit()
        percentLabel.text = "\(Int(progress * 100))%"
    }
}
