//
//  ViewController.swift
//  CoreMLSampler
//
//  Created by Daisuke Majima on 2024/01/17.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var tableView = UITableView()
    var features = ["DetectBarcode"]

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupview()
    }
    
    func setupview() {
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let segueIdentifier = features[indexPath.row]
        performSegue(withIdentifier: segueIdentifier, sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return features.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var cc = cell.defaultContentConfiguration()
        cc.text = features[indexPath.row]
        cell.contentConfiguration = cc
        return cell
    }

}

