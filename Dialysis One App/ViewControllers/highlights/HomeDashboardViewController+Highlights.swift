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
 
        let container = HighlightsContainerView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        self.highlightsContainer = container
        
        container.onCardTapped = { [weak self] report in
            self?.openInsightDetail(report: report)
        }
 
        // Layout
        let anchor = findSummaryBottomView()
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: anchor.bottomAnchor, constant: 28),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
 
            container.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 14),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
        ])
        
        let reports = InsightDataEngine.shared.generateHomeInsightReports()
        container.configure(with: reports)
 
        setupHighlightsObservers()
    }

    /// Refresh insight cards from latest logs (call whenever data changes)
    func refreshHighlights() {
        highlightsContainer?.refresh()
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
