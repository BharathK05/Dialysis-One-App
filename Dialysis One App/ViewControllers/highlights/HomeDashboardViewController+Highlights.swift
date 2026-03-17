//
//  HomeDashboardViewController+Highlights.swift
//  Dialysis One App
//
//  Smart Highlights System - Integration with Home Dashboard
//  FIXED: Unique selector name to avoid conflicts
//

import UIKit

// MARK: - Extension for Highlights Section

extension HomeDashboardViewController {
    
    // NOTE: Make sure these properties are added to HomeDashboardViewController class:
    // var highlightsContainer: HighlightsContainerView?
    // var highlightsLabel: UILabel?
    // var summaryCardsStackView: UIStackView? // Reference to summary section bottom
    
    /// Call this method in viewDidLoad() after setupSummarySection()
    func setupHighlightsSection() {
        // Title Label
        let label = UILabel()
        label.text = "Highlights"
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        // Store reference
        self.highlightsLabel = label
        
        // Container for highlight cards
        let container = HighlightsContainerView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        
        // Store reference
        self.highlightsContainer = container
        
        // Handle card taps
        container.onCardTapped = { [weak self] destination in
            self?.navigateToScreen(destination)
        }
        
        // Layout constraints
        // Find the last view in Summary section
        let summaryBottomView = findSummaryBottomView()
        
        NSLayoutConstraint.activate([
            // Label positioning - 24pt below summary section
            label.topAnchor.constraint(equalTo: summaryBottomView.bottomAnchor, constant: 24),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            // Container positioning
            container.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 14),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Update content view bottom constraint to include highlights
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
        
        // Generate and display insights
        refreshHighlights()
    }
    
    /// Call this whenever data updates (meals added, medications taken, etc.)
    func refreshHighlights() {
        highlightsContainer?.refresh()
    }
    
    /// Navigate to appropriate screen when card is tapped
    private func navigateToScreen(_ destination: HealthInsight.DestinationScreen) {
        let viewController: UIViewController
        
        switch destination {
        case .nutrientBalance:
            viewController = NutrientBalanceViewController()
        case .hydrationStatus:
            viewController = HydrationStatusViewController()
        case .medicationAdherence:
            viewController = MedicationAdherenceViewController()
        case .healthAndVitals:
            viewController = HealthAndVitalsViewController()
        }
        
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    /// Helper to find the bottom-most view in Summary section
    private func findSummaryBottomView() -> UIView {
        // If you have a reference to summaryCardsStackView, use it:
        if let summaryStack = summaryCardsStackView {
            return summaryStack
        }
        
        // Otherwise, try to find it by searching for a stack view in contentView
        // This looks for the first UIStackView that contains the summary cards
        for subview in contentView.subviews {
            if let stackView = subview as? UIStackView,
               stackView.arrangedSubviews.count > 0 {
                // This is likely the summary cards stack
                return stackView
            }
        }
        
        // Fallback: return contentView itself (will need adjustment)
        return contentView
    }
}

// MARK: - Notification Observers

extension HomeDashboardViewController {
    
    /// Add these observers to viewDidLoad() to auto-refresh highlights
    func setupHighlightsObservers() {
        // Refresh when meals update
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataUpdateForHighlights),
            name: .mealsDidUpdate,
            object: nil
        )
        
        // Refresh when medications update
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataUpdateForHighlights),
            name: NSNotification.Name("medicationsDidUpdate"),
            object: nil
        )
        
        // Refresh when fluid is logged
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataUpdateForHighlights),
            name: NSNotification.Name("fluidDidUpdate"),
            object: nil
        )
    }
    
    @objc private func handleDataUpdateForHighlights() {
        // Small delay to ensure data is saved
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshHighlights()
        }
    }
}
