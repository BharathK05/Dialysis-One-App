//
//  ReliefGuideViewController.swift
//  ReliefGuide
//
//  Created by user@100 on 11/11/25.
//

import UIKit

// ---------------------------
// ReliefGuideViewController
// ---------------------------
final class ReliefGuideViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTextField: UISearchTextField!

    // Local fallback image path for quick testing (use only during dev)
    // You uploaded this file earlier; change if you use a different test image.
    private let localTestImagePath = "/mnt/data/Screenshot 2025-11-25 at 11.33.29 AM.png"

    // MARK: - Full symptom dataset (exact names as you provided)
    let symptoms: [SymptomDetail] = [
        SymptomDetail(
            title: "Fatigue / Tiredness",
            reason: "Sudden fluid & toxin shifts, low BP",
            detailedReason: """
            Fatigue is one of the most common post-dialysis symptoms. During dialysis, your body undergoes rapid fluid removal and changes in electrolytes, which can lead to sudden drops in blood pressure. These shifts can make you feel extremely tired or drained even during normal activities.
            """,
            imageName: "fatigue_header",            // <- exact name you provided
            cures: [
                .init(text: "Take short rest after dialysis", isGood: true, imageName: "rest_icon"),
                .init(text: "Do light stretching", isGood: true, imageName: "stretch_icon"),
                .init(text: "Maintain a balanced sleep schedule", isGood: true, imageName: "sleep_icon"),
                .init(text: "Overexert yourself", isGood: false, imageName: "no_running_icon"),
                .init(text: "Skip rest periods", isGood: false, imageName: "no_rest_icon")
            ]
        ),

        SymptomDetail(
            title: "Headache",
            reason: "Blood pressure fluctuations",
            detailedReason: """
            Headaches after dialysis often occur due to fluctuations in blood pressure or rapid removal of fluid and toxins. These shifts can create pressure changes that manifest as mild to severe headaches.
            """,
            imageName: "headache_header",          // <- exact name you provided
            cures: [
                .init(text: "Hydrate within prescribed limits", isGood: true, imageName: "water_limit_icon"),
                .init(text: "Rest in a quiet, dim room", isGood: true, imageName: "rest_darkroom_icon"),
                .init(text: "Monitor your blood pressure regularly", isGood: true, imageName: "bp_icon"),
                .init(text: "Ignore persistent headaches", isGood: false, imageName: "no_ignore_icon"),
                .init(text: "Consume excessive caffeine or salt", isGood: false, imageName: "no_salt_icon")
            ]
        ),

        SymptomDetail(
            title: "Nausea or Vomiting",
            reason: "Electrolyte shifts, rapid toxin removal",
            detailedReason: """
            Nausea or vomiting during or after dialysis is usually caused by sudden shifts in electrolytes such as potassium and sodium. Rapid removal of toxins can also upset your digestive system.
            """,
            imageName: "nausea_header",            // <- exact name you provided
            cures: [
                .init(text: "Eat small, light meals before dialysis", isGood: true, imageName: "light_meal_icon"),
                .init(text: "Keep dry snacks like crackers handy", isGood: true, imageName: "crackers_icon"),
                .init(text: "Inform the care team if nausea continues", isGood: true, imageName: "report_icon"),
                .init(text: "Eat heavy, spicy, or oily foods", isGood: false, imageName: "no_spicyfood_icon"),
                .init(text: "Ignore frequent nausea", isGood: false, imageName: "no_ignore_icon")
            ]
        ),

        SymptomDetail(
            title: "Dizziness / Lightheadedness",
            reason: "Drop in blood pressure",
            detailedReason: """
            Dizziness after dialysis typically results from a sudden drop in blood pressure due to rapid fluid removal. You may feel unsteady, lightheaded, or weak, especially when standing up quickly.
            """,
            imageName: "dizziness_header",         // <- exact name you provided
            cures: [
                .init(text: "Stand up slowly after dialysis", isGood: true, imageName: "stand_slow_icon"),
                .init(text: "Elevate your legs while resting", isGood: true, imageName: "legs_up_icon"),
                .init(text: "Sit or lie down when dizzy", isGood: true, imageName: "sit_down_icon"),
                .init(text: "Make sudden movements", isGood: false, imageName: "no_fastmove_icon"),
                .init(text: "Walk alone when dizzy", isGood: false, imageName: "no_walkalone_icon")
            ]
        ),

        SymptomDetail(
            title: "Muscle Cramps",
            reason: "Rapid fluid removal, electrolyte imbalance",
            detailedReason: """
            Muscle cramps during dialysis often occur because of rapid fluid removal or shifts in electrolytes such as sodium, calcium, or magnesium. Cramps typically affect the legs and can be painful.
            """,
            imageName: "cramps_header",            // <- exact name you provided
            cures: [
                .init(text: "Stretch gently during cramps", isGood: true, imageName: "stretch_icon"),
                .init(text: "Use warm compresses", isGood: true, imageName: "warm_compress_icon"),
                .init(text: "Discuss fluid removal rate with your doctor", isGood: true, imageName: "doctor_icon"),
                .init(text: "Massage aggressively", isGood: false, imageName: "no_aggressive_icon"),
                .init(text: "Delay reporting frequent cramps", isGood: false, imageName: "no_delay_icon")
            ]
        ),
    ]
    
    private func addTopGradientBackground() {
            let gradient = CAGradientLayer()
            let topColor = UIColor(red: 225/255, green: 245/255, blue: 235/255, alpha: 1)
            let bottomColor = UIColor(red: 200/255, green: 235/255, blue: 225/255, alpha: 1)

            gradient.colors = [topColor.cgColor, bottomColor.cgColor]
            gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
            gradient.locations = [0.0, 0.7]
            gradient.type = .axial
            gradient.frame = view.bounds
            gradient.zPosition = -1

            view.layer.insertSublayer(gradient, at: 0)
        }

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
        tableView.allowsSelection = true   // ensure selection enabled

        // REGISTER THE CELL XIB (if not already registered via storyboard)
        let nib = UINib(nibName: "SymptomTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "SymptomCell")

        tableView.reloadData()
        addTopGradientBackground()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?.first?.frame = view.bounds


        AppTourManager.shared.register(view: tableView, for: "relief.table")
    }


    // MARK: - Table View DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return symptoms.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SymptomCell",
                                                 for: indexPath) as! SymptomTableViewCell

        let symptom = symptoms[indexPath.row]
        cell.titleLabel.text = symptom.title
        cell.subtitleLabel.text = symptom.reason

        // Configure icon image view (left square) using exact imageName values
        if let imageName = symptom.imageName {
            // primary: load from asset catalog by name
            if let img = UIImage(named: imageName) {
                cell.iconImageView.image = img
            } else {
                // fallback: attempt to load the local file path (useful for quick testing)
                // Note: replace or remove this for production — prefer adding assets to Assets.xcassets
                if FileManager.default.fileExists(atPath: localTestImagePath),
                   let data = try? Data(contentsOf: URL(fileURLWithPath: localTestImagePath)),
                   let img = UIImage(data: data) {
                    cell.iconImageView.image = img
                } else {
                    // final fallback placeholder (make sure you have this in assets)
                    cell.iconImageView.image = UIImage(named: "symptom_placeholder")
                }
            }
        } else {
            cell.iconImageView.image = UIImage(named: "symptom_placeholder")
        }

        // nice thumbnail styling (make sure your XIB does not override these)
        cell.iconImageView.contentMode = .scaleAspectFill
        cell.iconImageView.clipsToBounds = true
        cell.iconImageView.layer.cornerRadius = 10

        // transparent background so gradient shows through
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear

        // ensure the cell shows selection so taps are obvious
        cell.selectionStyle = .default
        

        return cell
    }

    // MARK: - Table View Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Debug prints — useful if this ever fails again
        print("didSelectRowAt row:", indexPath.row)
        print("navigationController:", navigationController as Any)

        tableView.deselectRow(at: indexPath, animated: true)

        // Instantiate the detail view controller (xib name must match)
        let nibName = "SymptomDetailViewController"
        let detailVC = SymptomDetailViewController(nibName: nibName, bundle: nil)

        // Pass the selected model
        let selectedDetail = symptoms[indexPath.row]
        detailVC.symptom = selectedDetail

        // Preferred: push using navigation controller if available
        if let nav = navigationController {
            nav.pushViewController(detailVC, animated: true)
            return
        }

        // Fallback: present modally inside a UINavigationController to get a back bar button
        let fallbackNav = UINavigationController(rootViewController: detailVC)
        fallbackNav.modalPresentationStyle = .fullScreen
        present(fallbackNav, animated: true)
    }
}
