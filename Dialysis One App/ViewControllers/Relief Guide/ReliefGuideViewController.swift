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


    
    override func viewDidLoad() {
            super.viewDidLoad()

            // Remove default separators
            tableView.separatorStyle = .none
            tableView.backgroundColor = .clear

            // Allow auto height for dynamic subtitle wrapping
            tableView.rowHeight = UITableView.automaticDimension
            tableView.estimatedRowHeight = 112

            // Register cell (if storyboard prototype cell has Identifier)
            tableView.dataSource = self
            tableView.delegate = self
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
        // (icon/tint styling you already did)

        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }


        // MARK: - Optional Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let vc = storyboard?.instantiateViewController(
            withIdentifier: "SymptomDetailVC"
        ) as? SymptomDetailViewController else { return }

        let selectedTitle = symptomTitles[indexPath.row]

        // Copy base detail, but override the title for the screen header
        let detail = SymptomDetail(
            title: selectedTitle,
            reason: baseDetail.reason,
            cures: baseDetail.cures
        )

        vc.symptom = detail
        navigationController?.pushViewController(vc, animated: true)
    }



}
