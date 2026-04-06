//
//  ReliefGuideViewController.swift
//  ReliefGuide
//
//  Created by user@100 on 11/11/25.
//

import UIKit

// ---------------------------
// SymptomGridCell (Modern Collection View Cell)
// ---------------------------
class SymptomGridCell: UICollectionViewCell {
    static let reuseIdentifier = "SymptomGridCell"

    let iconView = UIImageView()
    let titleLabel = UILabel()
    let cardView = UIView()
    
    // Severity Badge UI
    let severityBadge = UIView()
    let severityLabel = UILabel()
    let severityDot = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        // Liquid glass effect: translucent light green with a slightly thicker white border
        cardView.backgroundColor = UIColor(red: 230/255, green: 250/255, blue: 240/255, alpha: 0.55)
        cardView.layer.cornerRadius = 16 // HIG Standard
        cardView.layer.shadowColor = UIColor(red: 0, green: 80/255, blue: 50/255, alpha: 1).cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)
        cardView.layer.shadowRadius = 16
        cardView.layer.borderWidth = 1.0
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor
        
        // Severity Badge Setup
        severityBadge.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        severityBadge.layer.cornerRadius = 10
        severityBadge.translatesAutoresizingMaskIntoConstraints = false
        
        severityDot.layer.cornerRadius = 4
        severityDot.translatesAutoresizingMaskIntoConstraints = false
        
        severityLabel.font = .systemFont(ofSize: 11, weight: .bold)
        severityLabel.textColor = .secondaryLabel
        severityLabel.translatesAutoresizingMaskIntoConstraints = false
        
        severityBadge.addSubview(severityDot)
        severityBadge.addSubview(severityLabel)
        cardView.addSubview(severityBadge)

        let iconContainer = UIView()
        iconContainer.backgroundColor = (UIColor(named: "AppGreen") ?? .systemGreen).withAlphaComponent(0.12)
        iconContainer.layer.cornerRadius = 20
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        
        iconView.contentMode = .scaleAspectFill
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.clipsToBounds = true
        
        iconContainer.addSubview(iconView)
        
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        cardView.addSubview(iconContainer)
        cardView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            // Badge layout (top right)
            severityBadge.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            severityBadge.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            severityBadge.heightAnchor.constraint(equalToConstant: 22),
            
            severityDot.centerYAnchor.constraint(equalTo: severityBadge.centerYAnchor),
            severityDot.leadingAnchor.constraint(equalTo: severityBadge.leadingAnchor, constant: 8),
            severityDot.widthAnchor.constraint(equalToConstant: 8),
            severityDot.heightAnchor.constraint(equalToConstant: 8),
            
            severityLabel.centerYAnchor.constraint(equalTo: severityBadge.centerYAnchor),
            severityLabel.leadingAnchor.constraint(equalTo: severityDot.trailingAnchor, constant: 4),
            severityLabel.trailingAnchor.constraint(equalTo: severityBadge.trailingAnchor, constant: -8),

            iconContainer.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            iconContainer.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 72),
            iconContainer.heightAnchor.constraint(equalToConstant: 72),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -16)
        ])
    }
}

// ---------------------------
// ReliefGuideViewController
// ---------------------------
final class ReliefGuideViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTextField: UISearchTextField!

    // Local fallback image path for quick testing (use only during dev)
    // You uploaded this file earlier; change if you use a different test image.
    private let localTestImagePath = "/mnt/data/Screenshot 2025-11-25 at 11.33.29 AM.png"

    // MARK: - Full symptom dataset (exact names as you provided)
    var symptoms: [SymptomDetail] = [
        SymptomDetail(
            title: "Fatigue / Tiredness",
            reason: "Sudden fluid & toxin shifts, low BP",
            detailedReason: """
            Fatigue is one of the most common post-dialysis symptoms. During dialysis, your body undergoes rapid fluid removal and changes in electrolytes, which can lead to sudden drops in blood pressure. These shifts can make you feel extremely tired or drained even during normal activities.
            """,
            imageName: "fatigue_header",            // <- exact name you provided
            severity: .high,
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
            severity: .moderate,
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
            severity: .moderate,
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
            severity: .high,
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
            severity: .moderate,
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

    private var collectionView: UICollectionView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide legacy UI
        tableView.isHidden = true
        
        // Sort symptoms securely by priority (High severity first)
        symptoms.sort { $0.severity.rawValue > $1.severity.rawValue }
        
        // Setup Modern Grid Collection View
        setupCollectionView()
        
        AppTourManager.shared.register(view: collectionView, for: "relief.grid")
        addTopGradientBackground()
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, env) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                                  heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(190))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 8, bottom: 40, trailing: 8)
            return section
        }
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(SymptomGridCell.self, forCellWithReuseIdentifier: SymptomGridCell.reuseIdentifier)
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Pin to where the old table view was roughly, below the search label
        // We can just pin it to the safe area but offset it so it's below the header in the XIB
        // The XIB has a label "Symptoms" at y=197. Let's pin collection view top to tableView's top to preserve XIB layout positioning
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: tableView.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?.first?.frame = view.bounds

        AppTourManager.shared.register(view: collectionView, for: "relief.grid")
    }


    // MARK: - Collection View DataSource & Delegate

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return symptoms.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SymptomGridCell.reuseIdentifier, for: indexPath) as! SymptomGridCell
        
        let symptom = symptoms[indexPath.item]
        cell.titleLabel.text = symptom.title
        
        // Populate Severity UI
        cell.severityLabel.text = symptom.severity.text.uppercased()
        cell.severityDot.backgroundColor = symptom.severity.color
        
        if let imageName = symptom.imageName, let img = UIImage(named: imageName) {
            cell.iconView.image = img
        } else if FileManager.default.fileExists(atPath: localTestImagePath),
                  let data = try? Data(contentsOf: URL(fileURLWithPath: localTestImagePath)),
                  let img = UIImage(data: data) {
            cell.iconView.image = img
        } else {
            cell.iconView.image = UIImage(named: "symptom_placeholder")
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("didSelectItemAt item:", indexPath.item)
        print("navigationController:", navigationController as Any)
        
        let nibName = "SymptomDetailViewController"
        let detailVC = SymptomDetailViewController(nibName: nibName, bundle: nil)
        let selectedDetail = symptoms[indexPath.item]
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
