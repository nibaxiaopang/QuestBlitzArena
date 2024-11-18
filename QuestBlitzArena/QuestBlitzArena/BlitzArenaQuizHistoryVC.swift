//
//  QuizHistoryVC.swift
//  QuestBlitzArena
//
//  Created by QuestBlitzArena on 2024/11/18.
//

import UIKit

class BlitzArenaQuizHistoryVC: UIViewController, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var history: [BlitzArenaHistoryRecord] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        tableView.dataSource = self
        loadHistory()
        if history.isEmpty == true {
            showAlert(message: "history is Empty")
        }
    }
    
    
    @IBAction func BackBtnTApped(_ sender: Any) {
        
        navigationController?.popViewController(animated: true)
    }
    
    func loadHistory() {
        if let historyArray = UserDefaults.standard.array(forKey: "history") as? [[String: Any]] {
            for record in historyArray {
                if let score = record["right"] as? Int
                  {
                    history.append(BlitzArenaHistoryRecord(score: score))
                }
            }
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return history.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
        
        let record = history[indexPath.row]
        
        // Apply Avenir Next font
        if let label = cell.textLabel {
            label.text = "Your Score Is: \(record.score)"
            label.font = UIFont(name: "AvenirNext-Bold", size: 17)
        }
        
        return cell
    }
    
    @IBAction func toggleEditingMode(_ sender: UIBarButtonItem) {
        // Toggles editing mode for the table view
        tableView.isEditing = !tableView.isEditing
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Remove the record from the history array
            history.remove(at: indexPath.row)
            
            // Delete the corresponding record from UserDefaults
            var historyArray = UserDefaults.standard.array(forKey: "history") as? [[String: Any]] ?? []
            historyArray.remove(at: indexPath.row)
            UserDefaults.standard.set(historyArray, forKey: "history")
            
            // Delete the row from the table view
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func okButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    func showAlert(message: String) {
            let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                self.okButtonTapped()
            }
            alert.addAction(okAction)
            present(alert, animated: true, completion: nil)
        }
}
