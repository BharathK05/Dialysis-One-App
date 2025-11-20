//
//  ReliefGuideViewController.swift
//  ReliefGuide
//
//  Created by user@100 on 11/11/25.
//

import UIKit

final class ReliefGuideViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTextField: UISearchTextField!
    // Removed separate symptoms string list; using symptomDetail for source of truth

    struct CureItem {
        let text: String
        let isGood: Bool   // true = ✅, false = ❌
    }

    // Show these as headings in the list
    let symptomTitles = [
        "Fatigue / Tiredness",
        "Headache",
        "Nausea or Vomiting",
        "Dizziness",
        "Muscle Cramps"
    ]

    // One detail payload used for all (you can edit later per symptom)
    let baseDetail = SymptomDetail(
        title: "Placeholder",
        reason: "Sudden fluid and toxin shifts can disrupt normal body function and cause fatigue or tiredness.",
        cures: [
            .init(text: "Stay hydrated", isGood: true),
            .init(text: "Maintain a balanced diet rich in iron and vitamins", isGood: true),
            .init(text: "Rest between activities", isGood: true),
            .init(text: "Consume too much caffeine", isGood: false),
            .init(text: "Skip meals or overexert yourself", isGood: false)
        ]
    )

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        AppTourManager.shared.register(view: tableView, for: "relief.table")

        // TABLE VIEW SETUP
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 112

        // REGISTER THE CELL XIB
        // Make sure the XIB file is named "SymptomTableViewCell.xib"
        // and inside that XIB the cell's Reuse Identifier is "SymptomCell"
        let nib = UINib(nibName: "SymptomTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "SymptomCell")

        tableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        AppTourManager.shared.register(view: tableView, for: "relief.table")
    }


    // MARK: - Table View DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        symptomTitles.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SymptomCell",
                                                 for: indexPath) as! SymptomTableViewCell

        let title = symptomTitles[indexPath.row]
        cell.titleLabel.text = title
        cell.subtitleLabel.text = baseDetail.reason   // same short description for all

        // transparent background so gradient shows through
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear

        return cell
    }

    // MARK: - Table View Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Create detail VC from its XIB instead of storyboard
        let detailVC = SymptomDetailViewController(
            nibName: "SymptomDetailViewController",
            bundle: nil
        )

        let selectedTitle = symptomTitles[indexPath.row]

        // Copy base detail, but override the title for the screen header
        let detail = SymptomDetail(
            title: selectedTitle,
            reason: baseDetail.reason,
            cures: baseDetail.cures
        )

        detailVC.symptom = detail
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
