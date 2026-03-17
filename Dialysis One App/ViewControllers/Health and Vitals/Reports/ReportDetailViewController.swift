//
//  ReportDetailViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 31/01/26.
//


import UIKit

final class ReportDetailViewController: UIViewController {

    private let segmented = UISegmentedControl(items: ["Preview", "Insights"])
    private let container = UIView()

    private let previewVC: ReportPreviewViewController
    private let insightsVC: ReportInsightsViewController

    init(report: BloodReport, allReports: [BloodReport]) {

        // Preview
        let p = ReportPreviewViewController()
        p.fileURL = report.attachmentURL
        p.reportTitle = report.title
        self.previewVC = p

        // Insights

        self.insightsVC = ReportInsightsViewController(
            report: report,
            allReports: allReports
        )

        super.init(nibName: nil, bundle: nil)
        
        self.hidesBottomBarWhenPushed = true
        
        print("🧠 Stored extracted text length:", report.extractedText?.count ?? 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Report"

        setupSegmented()
        setupContainer()

        // Default: Preview
        switchTo(previewVC)
    }

    private func setupSegmented() {
        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        segmented.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmented)

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func setupContainer() {
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func segmentChanged() {
        if segmented.selectedSegmentIndex == 0 {
            switchTo(previewVC)
        } else {
            switchTo(insightsVC)
        }
    }

    private func switchTo(_ vc: UIViewController) {

        // Remove current child
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }

        // Add new child
        addChild(vc)
        container.addSubview(vc.view)
        vc.view.frame = container.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.didMove(toParent: self)
    }
}
