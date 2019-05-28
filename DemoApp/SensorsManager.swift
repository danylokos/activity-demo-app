//
//  SensorsManager.swift
//  DemoApp
//
//  Created by Danylo Kostyshyn on 5/30/19.
//  Copyright © 2019 Danylo Kostyshyn. All rights reserved.
//

import Foundation
import CoreMotion
import RxSwift

class SensorsManager {
    
    static let shared = SensorsManager()
    
    static let updateFrequency = 50 // 50Hz

    private let updateInterval = TimeInterval(1/updateFrequency)
    
    private let motionQueue = OperationQueue()
    private let motionActivityQueue = OperationQueue()
    
    private let motionManager = CMMotionManager()
    private let motionActivityManager = CMMotionActivityManager()
//    private let altimeter = CMAltimeter()
    
    private let disposeBag = DisposeBag()
    
    var sharedObservable: Observable<(CMAccelerometerData, CMGyroData, CMMagnetometerData)>!
    var motionActivityObservable: Observable<CMMotionActivity>!

    private init() {
        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.gyroUpdateInterval = updateInterval
        motionManager.magnetometerUpdateInterval = updateInterval
        motionManager.deviceMotionUpdateInterval = updateInterval

        sharedObservable = Observable
            .zip(accelerometerDataObservable(),
                 gyroDataObservable(),
                 magnetometerDataObservable())
            .share()
        
        motionActivityObservable = motionActivityDataObservable()
            .share()
    }
    
    // MARK: -

    private func accelerometerDataObservable() -> Observable<CMAccelerometerData> {
        return Observable<CMAccelerometerData>.create { (observer) -> Disposable in
            self.motionManager.startAccelerometerUpdates(to: self.motionQueue) { (data, error) in
                if let error = error { observer.on(.error(error)) }
                if let data = data { observer.on(.next(data)) }
            }
            return Disposables.create {
                self.motionManager.stopAccelerometerUpdates()
            }
        }
    }
    
    private func gyroDataObservable() -> Observable<CMGyroData> {
        return Observable<CMGyroData>.create { (observer) -> Disposable in
            self.motionManager.startGyroUpdates(to: self.motionQueue) { (data, error) in
                if let error = error { observer.on(.error(error)) }
                if let data = data { observer.on(.next(data)) }
            }
            return Disposables.create {
                self.motionManager.stopGyroUpdates()
            }
        }
    }
    
    private func magnetometerDataObservable() -> Observable<CMMagnetometerData> {
        return Observable<CMMagnetometerData>.create { (observer) -> Disposable in
            self.motionManager.startMagnetometerUpdates(to: self.motionQueue) { (data, error) in
                if let error = error { observer.on(.error(error)) }
                if let data = data { observer.on(.next(data)) }
            }
            return Disposables.create {
                self.motionManager.stopMagnetometerUpdates()
            }
        }
    }
    
    private func motionActivityDataObservable() -> Observable<CMMotionActivity> {
        return Observable<CMMotionActivity>.create { (observer) -> Disposable in
            self.motionActivityManager.startActivityUpdates(to: self.motionActivityQueue) { (data) in
//                if let error = error { observer.on(.error(error)) }
                if let data = data { observer.on(.next(data)) }
            }
            return Disposables.create {
                self.motionActivityManager.stopActivityUpdates()
            }
        }
    }

}
