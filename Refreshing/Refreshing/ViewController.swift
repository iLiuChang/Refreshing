//
//  ViewController.swift
//  Refreshing
//
//  Created by LC on 2023/9/26.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource {

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

        tableView.rfg.addRefreshHeader(type: .textIndicator(.white), height: 60) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: {
                self.count = 10
                tableView.reloadData()
                tableView.rfg.endRefreshing()
            })

        }

        tableView.rfg.addRefreshFooter(type: .textIndicator(.white), auto: false, height: 60) {
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

