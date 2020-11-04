//
//  HistoryTableViewController.swift
//  AudioRecorder
//
//  Created by Mayank on 14/06/20.
//  Copyright © 2020 Mayank. All rights reserved.
//

import CoreData
import UIKit

class HistoryTableViewController: UIViewController {
    /// UI Outlets
    @IBOutlet var historyTableView: UITableView!

    /// coughSessions from retrieving CoreData
    var coughSessions: [NSManagedObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        historyTableView.delegate = self
        historyTableView.dataSource = self
        historyTableView.estimatedRowHeight = UITableView.automaticDimension
        historyTableView.rowHeight = 100
    }

    override func viewWillAppear(_: Bool) {
        super.viewWillAppear(true)
        retrieveCoreData()
    }

    override func viewDidAppear(_: Bool) {
        super.viewDidAppear(true)
        historyTableView.reloadData()
    }

    /// retrieve previous coughSessions from CoreData
    private func retrieveCoreData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CoughSession")
        do {
            coughSessions = try managedContext.fetch(fetchRequest)
            historyTableView.reloadData()
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
}

/// UITableViewDelegate conformance
extension HistoryTableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return coughSessions.count
    }

    /// Format Date() object to readable String
    fileprivate func getFormattedDate(coughSessiondate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let dateString = formatter.string(from: coughSessiondate)
        return dateString
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let session = coughSessions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell",
                                                 for: indexPath) as! HistoryTableViewCell
        cell.coughCountLabel?.text = "\(session.value(forKey: "count")!)"
        let coughSessionDate = session.value(forKey: "date") as? Date
        cell.dateLabel.text = getFormattedDate(coughSessiondate: coughSessionDate!)
        return cell
    }
}
