//
//  ViewController.swift
//  Refreshing
//
//  Created by LC on 2023/9/26.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource {

    class GIF: UIImageView, AnimationViewWrapper {
        
        let loading = (1...60).map{UIImage(named: "dropdown_anim__000\($0)")!}
        let release = (1...3).map{UIImage(named: "dropdown_loading_0\($0)")!}

        init() {
            super.init(frame: .zero)
            contentMode = .scaleAspectFit
            animationDuration = 0.5
            image = loading.first
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func startAnimating(status: RefreshStatus) {
            switch status {
            case .loading:
                animationImages = loading
            case .release:
                animationImages = release
            }
            self.startAnimating()
        }
        
    }
    var count = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .gray
        let tableView = UITableView()
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.rowHeight = 120
        tableView.backgroundColor = .clear
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)

        tableView.rfg.addRefreshHeader(type: .textAnimation(GIF(), .white), threshold: 80) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: {
                self.count = 10
                tableView.reloadData()
                tableView.rfg.endRefreshing()
            })

        }

        tableView.rfg.addRefreshFooter(type: .textAnimation(GIF(), .white), auto: false, threshold: 80) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: {
                self.count += 10
                tableView.reloadData()
                tableView.rfg.endRefreshing()
            })
        }

        tableView.rfg.beginRefreshing()
        // Do any additional setup after loading the view.
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return count
    }

}

