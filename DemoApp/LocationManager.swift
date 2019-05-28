//
//  LocationManager.swift
//  DemoApp
//
//  Created by Danylo Kostyshyn on 5/31/19.
//  Copyright © 2019 Danylo Kostyshyn. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreLocation
import UserNotifications
import RxSwift

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()

    private let disposeBag = DisposeBag()
    
    let beaconSubject = PublishSubject<CLBeacon>()

    private func beaconRegion() -> CLBeaconRegion {
        let UUIDString = "FB7825AA-FE0C-4BE9-B3F2-50FC673B37AD"
        let region = CLBeaconRegion(proximityUUID: UUID(uuidString: UUIDString)!,
                              major: 0,
                              minor: 0,
                              identifier: "TestBeacon")
        region.notifyEntryStateOnDisplay = true
        return region
    }

    private func testRegion() -> CLBeaconRegion {
        let UUIDString = "18F17185-AB14-2018-0329-000000000015"
        let region = CLBeaconRegion(proximityUUID: UUID(uuidString: UUIDString)!,
                                    major: 1,
                                    minor: 1,
                                    identifier: "TestBeacon")
        region.notifyEntryStateOnDisplay = true
        return region
    }

    override init() {
        super.init()
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true

//        let region = beaconRegion()
        let region = testRegion()
        locationManager.startRangingBeacons(in: region)
        locationManager.startMonitoring(for: region)

        beaconSubject
            .share()
            .observeOn(MainScheduler.instance)
            .filter({ (beacon) -> Bool in
                return beacon.rssi != 0
            })
            .throttle(RxTimeInterval.milliseconds(5000),
                      scheduler: MainScheduler.instance)
            .subscribe { (event) in
                switch event {
                case .next(let beacon):
                    switch beacon.proximity {
                    case .immediate, .near:
                        if ModelManager.shared.latestPrediction > 0.5 {
                            self.postLocalNotification()
                        }
                    default: break
                    }
                default: break
                }
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(#function)
        print(error)
    }

    // MARK: - CLLocationManagerDelegate - Ranging Events

    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        for beacon in beacons {
//            guard beacon.rssi != 0 else { continue }
            
            print("Found beacon: \(beacon.proximityUUID), " +
                "prox: \(beacon.proximity.rawValue), " +
                "acc: \(beacon.accuracy), " +
                "rssi: \(beacon.rssi)")
            beaconSubject.onNext(beacon)
        }
    }

    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print(#function)
        print(error)
    }
    
    // MARK: - CLLocationManagerDelegate - Region Events

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print(#function)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print(#function)
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        print(#function)
        print("state: \(state.rawValue)")
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print(#function)
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print(#function)
    }

    // MARK: -
    
    func postLocalNotification() {
        let content = UNMutableNotificationContent()
        content.sound = .defaultCritical
        content.title = "Beware!"
        content.body = "You are crossing the road!"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(0.1), repeats: false)
        let request = UNNotificationRequest(identifier: "TestNotification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error { print(error) }
        }
    }
}
