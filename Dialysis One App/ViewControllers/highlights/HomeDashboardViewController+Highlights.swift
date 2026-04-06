//
//  HomeDashboardViewController+Highlights.swift
//  Dialysis One App
//
//  Insight system integration.
//  Cards are powered by InsightDataEngine — every value is computed from logs.
//

import UIKit
import SwiftUI

// MARK: - Highlights Section

extension HomeDashboardViewController {

    /// Call in viewDidLoad() after setupSummarySection()
    func setupHighlightsSection() {
        // Section title
        let label = UILabel()
        label.text  = "Highlights"
        label.font  = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        self.highlightsLabel = label

        // Create initial empty reports list
        let reports = InsightDataEngine.shared.generateHomeInsightReports()
        
        let swiftUIView = InsightsSwiftUIList(reports: reports) { [weak self] report in
            self?.openInsightDetail(report: report)
        }
        
        // Host in UIHostingController
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        addChild(hostingController)
        contentView.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Store reference to update later
        self.highlightsHostingController = hostingController

        // Layout
        let anchor = findSummaryBottomView()
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: anchor.bottomAnchor, constant: 28),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            hostingController.view.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            hostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
        ])

        setupHighlightsObservers()
    }

    /// Refresh insight cards from latest logs (call whenever data changes)
    func refreshHighlights() {
        let newReports = InsightDataEngine.shared.generateHomeInsightReports()
        let swiftUIView = InsightsSwiftUIList(reports: newReports) { [weak self] report in
            self?.openInsightDetail(report: report)
        }
        
        if let hostingController = highlightsHostingController as? UIHostingController<InsightsSwiftUIList> {
            hostingController.rootView = swiftUIView
        } else {
            // First time setup is handled in setupHighlightsSection
        }
    }

    // MARK: - Navigation

    func openInsightDetail(report: InsightReport) {
        let detail = InsightDetailViewController(report: report)
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.pushViewController(detail, animated: true)
    }

    // MARK: - Helpers

    private func findSummaryBottomView() -> UIView {
        if let stack = summaryCardsStackView { return stack }
        for sub in contentView.subviews {
            if let stack = sub as? UIStackView, !stack.arrangedSubviews.isEmpty { return stack }
        }
        return contentView
    }
}

// MARK: - Notification Observers

extension HomeDashboardViewController {

    func setupHighlightsObservers() {
        let names: [Notification.Name] = [
            .mealsDidUpdate,
            NSNotification.Name("medicationsDidUpdate"),
            NSNotification.Name("fluidDidUpdate"),
        ]
        for name in names {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleDataUpdateForHighlights),
                name: name,
                object: nil
            )
        }
    }

    @objc private func handleDataUpdateForHighlights() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshHighlights()
        }
    }
}
