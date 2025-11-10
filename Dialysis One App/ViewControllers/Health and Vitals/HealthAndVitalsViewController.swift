//
//  HealthAndVitalsViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 08/11/25.
//

import UIKit

class HealthAndVitalsViewController: UIViewController {
    
    @IBOutlet weak var connectButton: UIButton!
    
    @IBOutlet weak var addReportButton: UIButton!
    
    @IBOutlet weak var reportsContainerView: UIStackView!
    
    // MARK: - Properties
    var reports: [BloodReport] = []
    var isAppleWatchConnected = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadReports()
    }
    
    // MARK: - Setup
    func setupUI() {
        connectButton.layer.cornerRadius = 22
    }
    
    // MARK: - IBActions
    @IBAction func connectToAppleWatchTapped(_ sender: UIButton) {
        showConnectToAppleWatchPopup()
    }
    
    @IBAction func addReportTapped(_ sender: UIButton) {
        showAddReportScreen()
    }
    
    // MARK: - Apple Watch Connection
    func showConnectToAppleWatchPopup() {
        let alert = UIAlertController(
            title: "Connect to Apple Watch",
            message: "Allow Dialysis One to read Blood Pressure and Blood Oxygen from your Apple Watch.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Not Now", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Connect", style: .default) { [weak self] _ in
            self?.simulateAppleWatchConnection()
        })
        
        present(alert, animated: true)
    }
    
    func simulateAppleWatchConnection() {
        // Show success popup
        let alert = UIAlertController(
            title: "Apple Watch Connected",
            message: nil,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Close", style: .default) { [weak self] _ in
            self?.isAppleWatchConnected = true
            
            // Change connect button to "Connected" state
            self?.connectButton.setTitle("Connected", for: .normal)
            self?.connectButton.backgroundColor = UIColor.systemGreen
            self?.connectButton.isEnabled = false
            
            print("Apple Watch connected!")
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Add Report
    func showAddReportScreen() {
        let addReportVC = AddReportViewController(nibName: "AddReportViewController", bundle: nil)
        addReportVC.delegate = self
        let navController = UINavigationController(rootViewController: addReportVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    // MARK: - Reports Management
    func loadReports() {
        // Load saved reports (for now, just empty)
        reports = []
        displayReports()
    }
    
    func displayReports() {
        // Find the stack view by tag inside the container if available, otherwise search the root view
        guard let stackView = reportsContainerView.viewWithTag(100) as? UIStackView else {
                print("❌ Stack view not found with tag 100")
                return
            }
        
        // Clear existing report cards
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // If no reports, show empty state
        if reports.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No reports added yet"
            emptyLabel.font = UIFont.systemFont(ofSize: 14)
            emptyLabel.textColor = .systemGray
            emptyLabel.textAlignment = .center
            stackView.addArrangedSubview(emptyLabel)
            return
        }
        
        // Add report cards with real data
        for report in reports {
            let reportCard = ReportCardView(frame: CGRect(x: 0, y: 0, width: 353, height: 80))
            
            // Pass the report data (title, type, date, thumbnail from form)
            reportCard.report = report
            
            // Handle tap to show preview
            reportCard.onTap = { [weak self] in
                self?.showReportPreview(report: report)
            }
            
            stackView.addArrangedSubview(reportCard)
            
            // Add height constraint
            reportCard.heightAnchor.constraint(equalToConstant: 80).isActive = true
        }
        
        print("Displayed \(reports.count) reports")
    }
    
    func showReportPreview(report: BloodReport) {
        guard let fileURL = report.attachmentURL else {
            showAlert(message: "No attachment found")
            return
        }
        
        let previewVC = ReportPreviewViewController(nibName: "ReportPreviewViewController", bundle: nil)
        previewVC.reportURL = fileURL
        previewVC.reportTitle = report.title
        navigationController?.pushViewController(previewVC, animated: true)
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - AddReportDelegate
extension HealthAndVitalsViewController: AddReportDelegate {
    func didAddReport(report: BloodReport) {
        print("✅ Report received in Health & Vitals:")
        print("   Title: \(report.title)")
        print("   Type: \(report.type)")
        
        reports.append(report)
        displayReports()
        
        print("✅ Total reports now: \(reports.count)")
    }
}

