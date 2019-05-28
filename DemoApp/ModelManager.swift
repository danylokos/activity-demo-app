//
//  ModelManager.swift
//  DemoApp
//
//  Created by Danylo Kostyshyn on 5/30/19.
//  Copyright © 2019 Danylo Kostyshyn. All rights reserved.
//

import Foundation
import CoreML
import CoreMotion

class ModelManager {
    
    static let shared = ModelManager()

    let model = DemoModel()

    private init() { }
    
    private(set) var latestPrediction: Double = -1.0
    
    // MARK: -
    
    func predictMode(_ dataArray: [(CMAccelerometerData, CMGyroData, CMMagnetometerData)]) -> Double {
        // 1. Unroll array of 3 data sources into an array of single vectors
        // [[x1, y1, z1, x2, y2, z2, x3, y3, z3]]
        var dataItems = [[Double]]()
        for (accData, gyroData, magData) in dataArray {
            let data = [accData.acceleration.x, accData.acceleration.y, accData.acceleration.z,
                        gyroData.rotationRate.x, gyroData.rotationRate.y, gyroData.rotationRate.z,
                        magData.magneticField.x, magData.magneticField.y, magData.magneticField.z]
            dataItems.append(data)
        }
        
        // 2. Create MLMultiArray of 450x1 dimensions and populate it with data
        guard let inputData = try? MLMultiArray(shape: [450], dataType: .float32) else { return 0.0 }
        for (dataItemIndex, dataItem) in dataItems.enumerated() {
            for featureIndex in 0..<9 {
                let feature = dataItem[featureIndex]
                let inputDataIndex = dataItemIndex + featureIndex * 50
                inputData[inputDataIndex] = NSNumber(value: feature)
            }
        }
        
        // 3. Create input object for model
        let modelInput = DemoModelInput(input: inputData)
        let options = MLPredictionOptions()
        options.usesCPUOnly = true // iOS doesn't allow to perform any code on GPU in background
        
        // 4. Predict!
        do {
            let modelOutput = try model.prediction(input: modelInput, options: options)
            let prediction = modelOutput.output[0].doubleValue
            latestPrediction = prediction
            return prediction
        } catch {
            print("\(error)")
        }
        return 0.0
    }
    
}
