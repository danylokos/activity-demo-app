//
//  ViewController.swift
//  DemoApp
//
//  Created by Danylo Kostyshyn on 5/28/19.
//  Copyright © 2019 Danylo Kostyshyn. All rights reserved.
//

import UIKit
import CoreMotion
import RxSwift
import Charts

class MotionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    enum Sensor: Int, CaseIterable, CustomStringConvertible {
        case accelerometer
        case gyro
        case magnetometer

        var description: String {
            switch self {
            case .accelerometer:
                return "Accelerometer"
            case .gyro:
                return "Gyro"
            case .magnetometer:
                return "Magnetometer"
            }
        }
    }

    @IBOutlet var tableView: UITableView!
    
    var predictionCell: UITableViewCell!
    var predictionChartCell: UITableViewCell!
    var motionActivityCell: UITableViewCell!
    var accelerometerCell: UITableViewCell!
    var gyroCell: UITableViewCell!
    var magnetometerCell: UITableViewCell!
    var lineChartView: LineChartView!

    // MARK: -
    
    let disposeBag = DisposeBag()

    // MARK: -
    
    let cellDataFormat = "x: \t%.6f \ny: \t%.6f \nz: \t%.6f"

    func updateAccelerometerCell(_ data: CMAccelerometerData) {
        accelerometerCell?.detailTextLabel?.text =
            String(format: self.cellDataFormat, data.acceleration.x, data.acceleration.y, data.acceleration.z)
    }
    
    func updateGyroCell(_ data: CMGyroData) {
        gyroCell?.detailTextLabel?.text =
            String(format: self.cellDataFormat, data.rotationRate.x, data.rotationRate.y, data.rotationRate.z)
    }
    
    func updateMagnetometerCell(_ data: CMMagnetometerData) {
        magnetometerCell?.detailTextLabel?.text =
            String(format: self.cellDataFormat, data.magneticField.x, data.magneticField.y, data.magneticField.z)
    }
    
    func updatePredictionCell(_ value: Double) {
        let isInHands = value > 0.5
        predictionCell.backgroundColor = isInHands
            ? UIColor.red.withAlphaComponent(0.5)
            : UIColor.green.withAlphaComponent(0.5)
        predictionCell.textLabel?.text = String(format: "Prediction: %.3f, %@", value, isInHands ? "Distracted" : "Idle")
        predictionCell.textLabel?.font = UIFont.systemFont(ofSize: 20.0)
    }
    
    var dataEntries: [ChartDataEntry] = []
    
    func updatePredictionChartView(_ value: Double) {
        let timestamp = Date().timeIntervalSince1970
        let dataEntry = ChartDataEntry(x: timestamp, y: value)
        dataEntries.append(dataEntry)

        if dataEntries.count > 60 { // display only last minute of predictions
           dataEntries = Array(dataEntries.dropFirst())
        }
        
        let chartDataSet = LineChartDataSet(entries: dataEntries, label: "Prediction")
        chartDataSet.drawCirclesEnabled = false
        chartDataSet.drawValuesEnabled = false
        chartDataSet.lineWidth = 3.0
        chartDataSet.colors = [UIColor.blue.withAlphaComponent(0.5)]
        let chartData = LineChartData(dataSet: chartDataSet)
        lineChartView?.data = chartData
    }

    // MARK: -

    var isInHands = true
    
    var seconds = 0 {
        didSet {
            updateTimerLabel()
        }
    }
    
    var timer: Timer?
    
    var isRecording = false {
        didSet {
            if isRecording == true {
                seconds = 0
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [unowned self] (_) in
                    self.seconds += 1
                }
                timer?.fire()
            } else {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    func updateTimerLabel() {
        let barButtonItem = navigationItem.rightBarButtonItem
        let mins = Int(floor(Double(seconds / 60)))
        let secs = seconds % 60
        let timeString = String(format: "%02i:%02i", mins, secs)
        barButtonItem?.title = "Stop (\(timeString))"
    }

    func recordBarButtonItem() -> UIBarButtonItem {
        return UIBarButtonItem(title: isRecording ? "Stop" : "Record",
                               style: .plain, target: self, action: #selector(toggleRecordButton(_:)))
    }
    
    @objc func toggleRecordButton(_ sender: AnyObject) {
        if isRecording {
            isRecording = false
            navigationItem.rightBarButtonItem = recordBarButtonItem()
            return
        }
        
        let controller = UIAlertController(title: "Mode", message: "Select mode", preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Hands", style: .default, handler: { (alertAction) in
            self.isInHands = true
            self.logFileURL = self.generateLogFileURL()
            self.isRecording = true
            self.navigationItem.rightBarButtonItem = self.recordBarButtonItem()
        }))
        controller.addAction(UIAlertAction(title: "Pocket", style: .default, handler: { (alertAction) in
            self.isInHands = false
            self.logFileURL = self.generateLogFileURL()
            self.isRecording = true
            self.navigationItem.rightBarButtonItem = self.recordBarButtonItem()
        }))
        present(controller, animated: true, completion: nil)
    }
    
    // MARK: -
    
    let systemUptime = Date(timeIntervalSinceNow: ProcessInfo.processInfo.systemUptime)

    func maxTimestamp(_ data: (CMAccelerometerData, CMGyroData, CMMagnetometerData)) -> TimeInterval {
        let (accData, gyroData, magData) = data
        let maxRelativeTimestamp = max(max(accData.timestamp, gyroData.timestamp), magData.timestamp)
        return Date(timeInterval: maxRelativeTimestamp, since: self.systemUptime).timeIntervalSince1970
    }
    
    func logToConsole(_ data: (CMAccelerometerData, CMGyroData, CMMagnetometerData)) {
        let (accData, gyroData, magData) = data
        let timestamp = maxTimestamp(data)
        print("\n")
        print("time: \(timestamp)")
        print("acc data: \(accData)")
        print("gyro data: \(gyroData)")
        print("mag data: \(magData)")
    }

    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        return dateFormatter
    }()
    
    func generateLogFileURL() -> URL {
        let documentsDirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dateString = dateFormatter.string(from: Date())
        let fileName = "\(dateString)_\(self.isInHands ? 1 : 0).txt"
        return documentsDirURL.appendingPathComponent(fileName)
    }
    
    var logFileURL: URL!
    
    func logToFile(_ data: (CMAccelerometerData, CMGyroData, CMMagnetometerData)) {
        let (accData, gyroData, magData) = data
        let timestamp = maxTimestamp(data)
        // mode, timestamp, acc_x, acc_y, acc_z, gyro_x, gyro_y, gyro_z, mag_x, mag_y, mag_z
        let row = String(format: "%d,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n",
                         self.isInHands,
                         timestamp,
                         accData.acceleration.x, accData.acceleration.y, accData.acceleration.z,
                         gyroData.rotationRate.x, gyroData.rotationRate.y, gyroData.rotationRate.z,
                         magData.magneticField.x, magData.magneticField.y, magData.magneticField.z)
//        print("\(row)")
        if self.isRecording, self.logFileURL != nil {
            if let fileHandle = try? FileHandle(forWritingTo: self.logFileURL) {
                fileHandle.seekToEndOfFile()
                let data = row.data(using: .utf8)!
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                try? row.write(to: self.logFileURL, atomically: true, encoding: .utf8)
            }
        }
        
    }
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Motion"

        UIApplication.shared.isIdleTimerDisabled = true
        // hack
//        Utils.shared.keepBackgroundMotionUpdatesRunning()

        navigationItem.rightBarButtonItem = recordBarButtonItem()
        
        SensorsManager.shared.sharedObservable
            .observeOn(MainScheduler.instance)
            .buffer(timeSpan: RxTimeInterval.seconds(1),
                    count: SensorsManager.updateFrequency,
                    scheduler: MainScheduler.instance)
            .subscribe { (event) in
                switch event {
                case .next(let dataArray):
                    let pred = ModelManager.shared.predictMode(dataArray)
                    self.updatePredictionCell(pred)
                    self.updatePredictionChartView(pred)
                case .error(let error):
                    print("error: \(error)")
                case .completed: break
                }
            }
            .disposed(by: disposeBag)

        SensorsManager.shared.sharedObservable
            .observeOn(MainScheduler.instance)
            .throttle(RxTimeInterval.milliseconds(100),
                      scheduler: MainScheduler.instance)
            .subscribe { (event) in
                switch event {
                case .next(let (accData, gyroData, magData)):
                    self.updateAccelerometerCell(accData)
                    self.updateGyroCell(gyroData)
                    self.updateMagnetometerCell(magData)
                case .error(_): break
                case .completed: break
                }
            }
            .disposed(by: disposeBag)
        
        SensorsManager.shared.sharedObservable
            .subscribe { (event) in
                switch event {
                case .next(let (accData, gyroData, magData)):
//                    self.logToConsole((accData, gyroData, magData))
                    self.logToFile((accData, gyroData, magData))
                case .error(let error):
                    print("error: \(error)")
                case .completed: break
                }
            }
            .disposed(by: disposeBag)
        
        SensorsManager.shared.motionActivityObservable
            .observeOn(MainScheduler.instance)
            .subscribe { (event) in
                switch event {
                case .next(let data):
                    self.motionActivityCell?.textLabel?.text =
                        "🛑 \(data.stationary ? "✅" : "❌")\t" +
                        "🚶‍ \(data.walking ? "✅" : "❌")\t" +
                        "🏃‍ \(data.running ? "✅" : "❌")\t" +
                        "🚴‍ \(data.cycling ? "✅" : "❌")\t" +
                    "🚗 \(data.automotive ? "✅" : "❌")"
                case .error(let error):
                    print("error: \(error)")
                case .completed: break
                }
            }
            .disposed(by: disposeBag)
    }

    // MARK: - UITableViewDataSource
    
    enum Section: Int, CaseIterable {
        case prediction
        case predictionChart
        case motionActivity
        case sensors
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIdx: Int) -> Int {
        let section = Section(rawValue: sectionIdx)!
        switch section {
        case .prediction: return 1
        case .predictionChart: return 1
        case .motionActivity: return 1
        case .sensors: return Sensor.allCases.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "defaultCell"
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
        
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .prediction:
            cell.textLabel?.text = "Prediction"
            predictionCell = cell
        case .predictionChart:
            lineChartView = LineChartView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.width, height: 100.0))
            lineChartView.isUserInteractionEnabled = false
            lineChartView.legend.enabled = false
            lineChartView.xAxis.drawLabelsEnabled = false
            lineChartView.leftAxis.axisMaximum = 1.0
            lineChartView.leftAxis.axisMinimum = 0.0
            lineChartView.leftAxis.drawLabelsEnabled = false
            lineChartView.rightAxis.drawLabelsEnabled = false
            lineChartView.rightAxis.drawGridLinesEnabled = false
            lineChartView.gridBackgroundColor = .lightGray
            cell.contentView.addSubview(lineChartView)
            predictionChartCell = cell
        case .motionActivity:
            cell.textLabel?.text = "Motion"
            motionActivityCell = cell
        case .sensors:
            let sensor = Sensor(rawValue: indexPath.row)!
            cell.textLabel?.text = sensor.description
            cell.detailTextLabel?.numberOfLines = 0
            switch sensor {
            case .accelerometer:
                accelerometerCell = cell
            case .gyro:
                gyroCell = cell
            case .magnetometer:
                magnetometerCell = cell
            }
        }

        return cell
    }

    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .prediction: return 44.0
        case .predictionChart: return 100.0
        case .motionActivity: return 44.0
        case .sensors: return 90.0
        }
    }

}

