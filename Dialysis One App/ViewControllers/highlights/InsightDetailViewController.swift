//
//  InsightDetailViewController.swift
//  Dialysis One App
//
//  Full Apple Health–style insight detail screen.
//  Built from InsightReport — every value is computed, nothing hardcoded.
//

import UIKit

// MARK: - InsightDetailViewController

final class InsightDetailViewController: UIViewController {

    // MARK: - State

    private var report: InsightReport
    private let initialCategory: HealthInsight.InsightCategory
    private var currentWindow: InsightTimeWindow = .week

    // MARK: - Init

    /// Primary init: accepts a pre-computed InsightReport (from home screen cards)
    init(report: InsightReport) {
        self.report          = report
        self.initialCategory = report.category
        super.init(nibName: nil, bundle: nil)
    }

    /// Convenience: accepts the legacy HealthInsight (auto-generates a report)
    convenience init(insight: HealthInsight) {
        let engine = InsightDataEngine.shared
        let report: InsightReport
        switch insight.category {
        case .medication:  report = engine.medicationReport(window: .week)
        case .fluids:      report = engine.fluidReport(window: .week)
        default:           report = engine.nutrientReport(window: .week, focus: insight.category)
        }
        self.init(report: report)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI

    private let scrollView       = UIScrollView()
    private let contentStack     = UIStackView()

    // Segment control
    private let segmentControl   = UISegmentedControl()

    // Hero
    private let heroCard         = UIView()
    private let primaryValueLabel = UILabel()
    private let primaryLabelLabel = UILabel()
    private let trendBadge       = UIView()
    private let trendBadgeLabel  = UILabel()
    private let timeRangeLabel   = UILabel()

    // Chart
    private let chartCard       = UIView()
    private var barChart:        InsightBarChartView?
    private var lineChart:       InsightLineChartView?

    // Summary
    private let summaryCard     = UIView()
    private let summaryLabel    = UILabel()

    // Why — explanation
    private let whyCard         = UIView()
    private let whyBody         = UILabel()

    // Heatmap
    private var heatmapCard:    UIView?
    private var heatmapView:    InsightHeatmapView?

    // Secondary metrics
    private let secondaryCard   = UIView()
    private var secondaryStack  = UIStackView()

    // CTA
    private let ctaButton       = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = report.title
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.tintColor = report.accentColor

        buildLayout()
        populate(with: report, animate: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateChart()
        heatmapView?.animateIn()
    }

    // MARK: - Build Static Layout

    private func buildLayout() {
        // Scroll
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentStack.axis    = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])

        buildSegmentControl()
        buildHeroCard()
        buildChartCard()
        buildSummaryCard()
        buildSecondaryCard()
        buildWhyCard()
        buildHeatmapIfNeeded()
        buildCTAButton()
    }

    // MARK: - Segment Control

    private func buildSegmentControl() {
        for (i, w) in InsightTimeWindow.allCases.enumerated() {
            segmentControl.insertSegment(withTitle: w.segmentTitle, at: i, animated: false)
        }
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmentControl.translatesAutoresizingMaskIntoConstraints = false

        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(segmentControl)
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 4),
            segmentControl.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -4),
            segmentControl.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            segmentControl.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            segmentControl.heightAnchor.constraint(equalToConstant: 36),
        ])
        contentStack.addArrangedSubview(wrapper)
    }

    // MARK: - Hero Section

    private func buildHeroCard() {
        heroCard.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(heroCard)

        // Icon circle
        let iconBg = UIView()
        iconBg.layer.cornerRadius = 24
        iconBg.translatesAutoresizingMaskIntoConstraints = false

        let iconCfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iconView)

        // Large value
        primaryValueLabel.font          = UIFont.systemFont(ofSize: 48, weight: .bold)
        primaryValueLabel.textAlignment = .center
        primaryValueLabel.adjustsFontSizeToFitWidth = true
        primaryValueLabel.translatesAutoresizingMaskIntoConstraints = false

        // Primary label
        primaryLabelLabel.font          = UIFont.systemFont(ofSize: 14, weight: .regular)
        primaryLabelLabel.textColor     = .secondaryLabel
        primaryLabelLabel.textAlignment = .center
        primaryLabelLabel.translatesAutoresizingMaskIntoConstraints = false

        // Time range
        timeRangeLabel.font          = UIFont.systemFont(ofSize: 12, weight: .regular)
        timeRangeLabel.textColor     = .tertiaryLabel
        timeRangeLabel.textAlignment = .center
        timeRangeLabel.translatesAutoresizingMaskIntoConstraints = false

        // Trend badge
        trendBadge.layer.cornerRadius = 12
        trendBadge.translatesAutoresizingMaskIntoConstraints = false

        trendBadgeLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        trendBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        trendBadge.addSubview(trendBadgeLabel)

        heroCard.addSubview(iconBg)
        heroCard.addSubview(iconView)
        heroCard.addSubview(primaryValueLabel)
        heroCard.addSubview(primaryLabelLabel)
        heroCard.addSubview(timeRangeLabel)
        heroCard.addSubview(trendBadge)

        // Store refs for populate
        self.heroIconBg   = iconBg
        self.heroIconView = iconView

        NSLayoutConstraint.activate([
            iconBg.topAnchor.constraint(equalTo: heroCard.topAnchor, constant: 24),
            iconBg.centerXAnchor.constraint(equalTo: heroCard.centerXAnchor),
            iconBg.widthAnchor.constraint(equalToConstant: 48),
            iconBg.heightAnchor.constraint(equalToConstant: 48),

            iconView.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            primaryValueLabel.topAnchor.constraint(equalTo: iconBg.bottomAnchor, constant: 14),
            primaryValueLabel.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor, constant: 24),
            primaryValueLabel.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor, constant: -24),

            primaryLabelLabel.topAnchor.constraint(equalTo: primaryValueLabel.bottomAnchor, constant: 4),
            primaryLabelLabel.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor, constant: 24),
            primaryLabelLabel.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor, constant: -24),

            trendBadge.topAnchor.constraint(equalTo: primaryLabelLabel.bottomAnchor, constant: 10),
            trendBadge.centerXAnchor.constraint(equalTo: heroCard.centerXAnchor),

            trendBadgeLabel.topAnchor.constraint(equalTo: trendBadge.topAnchor, constant: 5),
            trendBadgeLabel.bottomAnchor.constraint(equalTo: trendBadge.bottomAnchor, constant: -5),
            trendBadgeLabel.leadingAnchor.constraint(equalTo: trendBadge.leadingAnchor, constant: 12),
            trendBadgeLabel.trailingAnchor.constraint(equalTo: trendBadge.trailingAnchor, constant: -12),

            timeRangeLabel.topAnchor.constraint(equalTo: trendBadge.bottomAnchor, constant: 8),
            timeRangeLabel.leadingAnchor.constraint(equalTo: heroCard.leadingAnchor, constant: 24),
            timeRangeLabel.trailingAnchor.constraint(equalTo: heroCard.trailingAnchor, constant: -24),
            timeRangeLabel.bottomAnchor.constraint(equalTo: heroCard.bottomAnchor, constant: -24),
        ])
    }

    private var heroIconBg:   UIView?
    private var heroIconView: UIImageView?

    // MARK: - Chart Section

    private func buildChartCard() {
        chartCard.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(chartCard)
        chartCard.heightAnchor.constraint(equalToConstant: 200).isActive = true

        let header = makeSectionHeader("TREND")
        chartCard.addSubview(header)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: chartCard.topAnchor, constant: 16),
            header.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor, constant: 18),
        ])
    }

    private func installBarChart(in card: UIView, values: [Double], labels: [String], goalValue: Double?, color: UIColor) {
        barChart?.removeFromSuperview()
        lineChart?.removeFromSuperview()

        var cfg = InsightBarChartView.Config()
        cfg.barColor     = color
        cfg.trackColor   = color.withAlphaComponent(0.08)
        cfg.todayIndex   = values.count - 1   // last bar = today
        cfg.showGoalLine = goalValue != nil

        let chart = InsightBarChartView(config: cfg)
        chart.configure(values: values, labels: labels, goalValue: goalValue)
        chart.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(chart)
        barChart = chart

        NSLayoutConstraint.activate([
            chart.topAnchor.constraint(equalTo: card.topAnchor, constant: 40),
            chart.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            chart.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            chart.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
        ])
    }

    private func installLineChart(in card: UIView, values: [Double], labels: [String], goalValue: Double?, color: UIColor) {
        barChart?.removeFromSuperview()
        lineChart?.removeFromSuperview()

        var cfg = InsightLineChartView.Config()
        cfg.lineColor = color
        cfg.showGoalLine = goalValue != nil

        let chart = InsightLineChartView(config: cfg)
        chart.configure(values: values, labels: labels, goalValue: goalValue)
        chart.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(chart)
        lineChart = chart

        NSLayoutConstraint.activate([
            chart.topAnchor.constraint(equalTo: card.topAnchor, constant: 40),
            chart.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            chart.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            chart.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
        ])
    }

    // MARK: - Summary Section

    private func buildSummaryCard() {
        summaryCard.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(summaryCard)

        let header = makeSectionHeader("SUMMARY")
        summaryLabel.font          = UIFont.systemFont(ofSize: 15, weight: .regular)
        summaryLabel.textColor     = .secondaryLabel
        summaryLabel.numberOfLines = 0
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false

        summaryCard.addSubview(header)
        summaryCard.addSubview(summaryLabel)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: summaryCard.topAnchor, constant: 16),
            header.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 18),
            header.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -18),

            summaryLabel.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 10),
            summaryLabel.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 18),
            summaryLabel.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -18),
            summaryLabel.bottomAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: -18),
        ])
    }

    // MARK: - Secondary Metrics Section

    private func buildSecondaryCard() {
        secondaryCard.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(secondaryCard)

        let header = makeSectionHeader("DETAILS")
        secondaryStack = UIStackView()
        secondaryStack.axis = .vertical
        secondaryStack.spacing = 0
        secondaryStack.translatesAutoresizingMaskIntoConstraints = false

        secondaryCard.addSubview(header)
        secondaryCard.addSubview(secondaryStack)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: secondaryCard.topAnchor, constant: 16),
            header.leadingAnchor.constraint(equalTo: secondaryCard.leadingAnchor, constant: 18),

            secondaryStack.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            secondaryStack.leadingAnchor.constraint(equalTo: secondaryCard.leadingAnchor),
            secondaryStack.trailingAnchor.constraint(equalTo: secondaryCard.trailingAnchor),
            secondaryStack.bottomAnchor.constraint(equalTo: secondaryCard.bottomAnchor, constant: -4),
        ])
    }

    // MARK: - Why Section

    private func buildWhyCard() {
        whyCard.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(whyCard)

        let header = makeSectionHeader("WHY THIS MATTERS")
        whyBody.font          = UIFont.systemFont(ofSize: 15, weight: .regular)
        whyBody.textColor     = .secondaryLabel
        whyBody.numberOfLines = 0
        whyBody.translatesAutoresizingMaskIntoConstraints = false

        whyCard.addSubview(header)
        whyCard.addSubview(whyBody)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: whyCard.topAnchor, constant: 16),
            header.leadingAnchor.constraint(equalTo: whyCard.leadingAnchor, constant: 18),

            whyBody.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 10),
            whyBody.leadingAnchor.constraint(equalTo: whyCard.leadingAnchor, constant: 18),
            whyBody.trailingAnchor.constraint(equalTo: whyCard.trailingAnchor, constant: -18),
            whyBody.bottomAnchor.constraint(equalTo: whyCard.bottomAnchor, constant: -18),
        ])
    }

    // MARK: - Heatmap (medication only)

    private func buildHeatmapIfNeeded() {
        guard initialCategory == .medication else { return }

        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(card)
        heatmapCard = card

        let header = makeSectionHeader("CALENDAR")
        let hm = InsightHeatmapView()
        hm.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(header)
        card.addSubview(hm)
        heatmapView = hm

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            header.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),

            hm.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            hm.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            hm.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            hm.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            hm.heightAnchor.constraint(greaterThanOrEqualToConstant: 160),
        ])
    }

    // MARK: - CTA Button

    private func buildCTAButton() {
        ctaButton.layer.cornerRadius = 14
        ctaButton.titleLabel?.font   = UIFont.systemFont(ofSize: 17, weight: .semibold)
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)

        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(wrapper)
        wrapper.addSubview(ctaButton)

        NSLayoutConstraint.activate([
            ctaButton.topAnchor.constraint(equalTo: wrapper.topAnchor),
            ctaButton.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            ctaButton.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            ctaButton.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
            ctaButton.heightAnchor.constraint(equalToConstant: 54),
        ])
    }

    // MARK: - Populate (Data → UI)

    private func populate(with report: InsightReport, animate: Bool) {
        let color = report.accentColor

        // Hero
        heroIconBg?.backgroundColor = color.withAlphaComponent(0.12)
        let iconCfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        heroIconView?.image    = UIImage(systemName: report.category.icon, withConfiguration: iconCfg)
        heroIconView?.tintColor = color

        primaryValueLabel.text  = report.primaryValue
        primaryValueLabel.textColor = report.trend == .decreased ? UIColor.systemOrange : color

        primaryLabelLabel.text  = report.primaryLabel
        timeRangeLabel.text     = report.timeRangeLabel

        trendBadgeLabel.text     = "\(report.trend.symbol) \(String(format: "%.0f%%", report.trendDelta)) \(report.comparisonText)"
        trendBadge.backgroundColor = report.trend.color.withAlphaComponent(0.12)
        trendBadgeLabel.textColor  = report.trend.color

        // Chart
        switch report.category {
        case .fluids:
            installLineChart(in: chartCard, values: report.graphData.values, labels: report.graphData.labels, goalValue: report.graphData.goalValue, color: color)
        default:
            installBarChart(in: chartCard, values: report.graphData.values, labels: report.graphData.labels, goalValue: report.graphData.goalValue, color: color)
        }

        // Summary
        summaryLabel.text = report.summaryText

        // Secondary metrics
        for v in secondaryStack.arrangedSubviews { v.removeFromSuperview() }
        for (i, metric) in report.secondaryMetrics.enumerated() {
            let row = makeSecondaryRow(metric: metric, color: color, showDivider: i < report.secondaryMetrics.count - 1)
            secondaryStack.addArrangedSubview(row)
        }

        // Why
        whyBody.text = whyText(for: report.category)

        // Heatmap
        if let hm = report.heatmapData, let hmView = heatmapView {
            hmView.configure(data: hm, color: color)
        }

        // CTA
        ctaButton.setTitle(ctaTitle(for: report.actionScreen), for: .normal)
        ctaButton.backgroundColor = color
        ctaButton.layer.shadowColor   = color.cgColor
        ctaButton.layer.shadowOpacity = 0.25
        ctaButton.layer.shadowOffset  = CGSize(width: 0, height: 4)
        ctaButton.layer.shadowRadius  = 10

        if animate {
            UIView.transition(with: contentStack, duration: 0.25, options: [.transitionCrossDissolve]) {}
        }
    }

    private func animateChart() {
        barChart?.animateIn()
        lineChart?.animateIn()
    }

    // MARK: - Segment Changed

    @objc private func segmentChanged() {
        let idx = segmentControl.selectedSegmentIndex
        guard idx < InsightTimeWindow.allCases.count else { return }
        currentWindow = InsightTimeWindow.allCases[idx]

        // Recompute data
        let engine = InsightDataEngine.shared
        switch initialCategory {
        case .medication:
            report = engine.medicationReport(window: currentWindow)
        case .fluids:
            report = engine.fluidReport(window: currentWindow)
        default:
            report = engine.nutrientReport(window: currentWindow, focus: initialCategory)
        }

        UIView.animate(withDuration: 0.2, animations: {
            self.heroCard.alpha    = 0
            self.chartCard.alpha   = 0
            self.summaryCard.alpha = 0
        }) { _ in
            self.populate(with: self.report, animate: false)
            UIView.animate(withDuration: 0.25) {
                self.heroCard.alpha    = 1
                self.chartCard.alpha   = 1
                self.summaryCard.alpha = 1
            } completion: { _ in
                self.animateChart()
                self.heatmapView?.animateIn()
            }
        }
    }

    // MARK: - CTA

    @objc private func ctaTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        UIView.animate(withDuration: 0.1) { self.ctaButton.transform = CGAffineTransform(scaleX: 0.96, y: 0.96) }
        completion: { _ in UIView.animate(withDuration: 0.2) { self.ctaButton.transform = .identity } }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let vc: UIViewController
            switch self.report.actionScreen {
            case .nutrientBalance:      vc = NutrientBalanceViewController()
            case .hydrationStatus:      vc = HydrationStatusViewController()
            case .medicationAdherence:  vc = MedicationAdherenceViewController()
            case .healthAndVitals:      vc = HealthAndVitalsViewController()
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    // MARK: - Helpers

    private func makeSecondaryRow(metric: SecondaryMetric, color: UIColor, showDivider: Bool) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let iconCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let icon = UIImageView(image: UIImage(systemName: metric.iconName, withConfiguration: iconCfg))
        icon.tintColor   = color
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let labelL = UILabel()
        labelL.text      = metric.label
        labelL.font      = UIFont.systemFont(ofSize: 15, weight: .regular)
        labelL.textColor = .label
        labelL.translatesAutoresizingMaskIntoConstraints = false

        let valueL = UILabel()
        valueL.text      = metric.value
        valueL.font      = UIFont.systemFont(ofSize: 15, weight: .semibold)
        valueL.textColor = .label
        valueL.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(icon)
        row.addSubview(labelL)
        row.addSubview(valueL)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 18),
            icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20),

            labelL.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            labelL.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            valueL.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -18),
            valueL.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            labelL.trailingAnchor.constraint(lessThanOrEqualTo: valueL.leadingAnchor, constant: -8),

            row.heightAnchor.constraint(equalToConstant: 36),
        ])

        if showDivider {
            let div = UIView()
            div.backgroundColor = .separator.withAlphaComponent(0.5)
            div.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(div)
            NSLayoutConstraint.activate([
                div.leadingAnchor.constraint(equalTo: labelL.leadingAnchor),
                div.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                div.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                div.heightAnchor.constraint(equalToConstant: 0.5),
            ])
        }
        return row
    }

    private func styleCard(_ view: UIView) {
        // Obsolete: layout is now compact and flat.
    }

    private func makeSectionHeader(_ text: String) -> UILabel {
        let l = UILabel()
        let attrs = NSAttributedString(
            string: text,
            attributes: [
                .kern: 0.8,
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: UIColor.tertiaryLabel
            ])
        l.attributedText = attrs
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    private func ctaTitle(for screen: HealthInsight.DestinationScreen) -> String {
        switch screen {
        case .nutrientBalance:      return "View Nutrition"
        case .hydrationStatus:      return "View Hydration"
        case .medicationAdherence:  return "View Medications"
        case .healthAndVitals:      return "View Health & Vitals"
        }
    }

    private func whyText(for category: HealthInsight.InsightCategory) -> String {
        switch category {
        case .medication:
            return "Missed doses reduce treatment effectiveness.\nConsistent adherence is critical for outcomes."
        case .fluids:
            return "Excess fluid increases blood pressure.\nStaying within limits reduces heart strain."
        case .potassium:
            return "High potassium causes dangerous heart rhythms.\nMonitor dietary intake between sessions."
        case .sodium:
            return "Excess sodium increases thirst and fluid retention.\nReduced intake controls blood pressure."
        case .protein:
            return "Adequate protein prevents muscle wasting.\nWorking within targets avoids excess waste buildup."
        case .weight:
            return "Rapid weight gain indicates fluid retention.\nMonitoring weight helps adjust treatment promptly."
        case .general:
            return "Consistent tracking provides actionable data.\nThis helps to personalise your care plan."
        }
    }
}
