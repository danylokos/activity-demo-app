//
//  BeaconsViewController.swift
//  DemoApp
//
//  Created by Danylo Kostyshyn on 6/3/19.
//  Copyright © 2019 Danylo Kostyshyn. All rights reserved.
//

import UIKit
import RxSwift

class BeaconsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!

    private let disposeBag = DisposeBag()
    
    private var beaconCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "iBeacon"
        
        LocationManager.shared.beaconSubject
            .share()
            .observeOn(MainScheduler.instance)
            .subscribe { (event) in
                switch event {
                case .next(let beacon):
                    self.beaconCell.textLabel?.text = String(format: "prox: %d, accu: %.3f, rssi: %d",
                                                             beacon.proximity.rawValue, beacon.accuracy, beacon.rssi)
                    self.beaconCell.detailTextLabel?.text = beacon.proximityUUID.uuidString
                default: break
                }
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "defaultCell"
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
        beaconCell = cell
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
