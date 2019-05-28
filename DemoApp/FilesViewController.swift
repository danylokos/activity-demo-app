//
//  FilesViewController.swift
//  DemoApp
//
//  Created by Danylo Kostyshyn on 5/30/19.
//  Copyright © 2019 Danylo Kostyshyn. All rights reserved.
//

import UIKit
import QuickLook

class FilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, QLPreviewControllerDataSource {

    @IBOutlet var tableView: UITableView!
    
    private var files = [String]()
    
    var documentsDirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Files"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadData()
    }
    
    private func reloadData() {
        files = (try? FileManager.default.contentsOfDirectory(atPath: documentsDirURL.path)) ?? []
        files.sort()
        tableView.reloadData()
    }

    private func fileSize(at URL: URL) -> String? {
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: URL.path)
            if let size = attrs[.size] as? UInt64 {
                return byteCountFormatter.string(fromByteCount: Int64(size))
            }
        } catch { }
        return nil
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    lazy var byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "defaultCell"
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        
        let fileName = files[indexPath.row]
        cell.textLabel?.text = "\(fileName)"
        
        let fileURL = documentsDirURL.appendingPathComponent(fileName)
        if let fileSize = fileSize(at: fileURL) {
            cell.textLabel?.text = "\(fileName) (\(fileSize))"
        }

        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    var selectedIndex = 0
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        
        let controller = QLPreviewController()
        controller.dataSource = self
        present(controller, animated: true, completion: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let fileName = files[indexPath.row]
        let fileURL = documentsDirURL.appendingPathComponent(fileName)
        do {
            try? FileManager.default.removeItem(at: fileURL)
            files.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    // MARK: - QLPreviewControllerDataSource
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let fileName = files[selectedIndex]
        let fileURL = documentsDirURL.appendingPathComponent(fileName)
        return fileURL as QLPreviewItem
    }
}
