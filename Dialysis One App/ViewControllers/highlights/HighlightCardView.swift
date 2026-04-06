//
//  HighlightCardView.swift
//  Dialysis One App
//
//  Apple Health–style home insight cards.
//  Powered by InsightReport — all values computed, none hardcoded.
//

import UIKit

// MARK: - HighlightCardView (InsightReport-powered)

final class HighlightCardView: UIView {

    // MARK: - Data

    private let report: InsightReport
    private var onTap: (() -> Void)?

    // MARK: - Subviews

    private let containerView   = UIView()
    private let accentBar       = UIView()
    private let iconBg          = UIView()
    private let iconView        = UIImageView()
    private let categoryLabel   = UILabel()
    private let chevronView     = UIImageView()
    private let metricLabel     = UILabel()
    private let trendLabel      = UILabel()
    private let timeLabel       = UILabel()
    private let sparklineView   = InsightSparklineView()

    // MARK: - Init

    init(report: InsightReport, onTap: (() -> Void)? = nil) {
        self.report = report
        self.onTap  = onTap
        super.init(frame: .zero)
        build()
        populate()
    }

    /// Legacy init — auto-converts HealthInsight into InsightReport
    convenience init(insight: HealthInsight, onTap: (() -> Void)? = nil) {
        let engine = InsightDataEngine.shared
        let report: InsightReport
        switch insight.category {
        case .medication: report = engine.medicationReport(window: .week)
        case .fluids:     report = engine.fluidReport(window: .week)
        default:          report = engine.nutrientReport(window: .week, focus: insight.category)
        }
        self.init(report: report, onTap: onTap)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build

    private func build() {
        // ── Container ──────────────────────────────────────────────────────
        containerView.backgroundColor    = .secondarySystemGroupedBackground
        containerView.layer.cornerRadius = 20
        containerView.layer.shadowColor  = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.07
        containerView.layer.shadowOffset  = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius  = 12
        containerView.layer.masksToBounds = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        // ── Left accent bar ──────────────────────────────────────────────
        accentBar.layer.cornerRadius  = 3
        accentBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        accentBar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(accentBar)

        // ── Icon circle ────────────────────────────────────────────────────
        iconBg.layer.cornerRadius = 18
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconBg)

        let iconCfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iconView)

        // ── Category label (uppercase tracked) ─────────────────────────────
        categoryLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(categoryLabel)

        // ── Chevron ────────────────────────────────────────────────────────
        let chevrCfg = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        chevronView.image       = UIImage(systemName: "chevron.right", withConfiguration: chevrCfg)
        chevronView.tintColor   = .tertiaryLabel
        chevronView.contentMode = .scaleAspectFit
        chevronView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(chevronView)

        // ── Sparkline ──────────────────────────────────────────────────────
        sparklineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(sparklineView)

        // ── Bold metric label ──────────────────────────────────────────────
        metricLabel.font          = UIFont.systemFont(ofSize: 22, weight: .bold)
        metricLabel.numberOfLines = 1
        metricLabel.adjustsFontSizeToFitWidth = true
        metricLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(metricLabel)

        // ── Trend subtext ──────────────────────────────────────────────────
        trendLabel.font          = UIFont.systemFont(ofSize: 12, weight: .medium)
        trendLabel.numberOfLines = 1
        trendLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(trendLabel)

        // ── Footer time range ──────────────────────────────────────────────
        timeLabel.font          = UIFont.systemFont(ofSize: 11, weight: .regular)
        timeLabel.textColor     = .tertiaryLabel
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(timeLabel)

        // ── Constraints ────────────────────────────────────────────────────
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            accentBar.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            accentBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
            accentBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            accentBar.widthAnchor.constraint(equalToConstant: 4),

            iconBg.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            iconBg.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 12),
            iconBg.widthAnchor.constraint(equalToConstant: 36),
            iconBg.heightAnchor.constraint(equalToConstant: 36),

            iconView.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 15),
            iconView.heightAnchor.constraint(equalToConstant: 15),

            categoryLabel.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            categoryLabel.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 10),

            chevronView.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            chevronView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            chevronView.widthAnchor.constraint(equalToConstant: 11),
            chevronView.heightAnchor.constraint(equalToConstant: 11),
            categoryLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronView.leadingAnchor, constant: -8),

            sparklineView.topAnchor.constraint(equalTo: iconBg.bottomAnchor, constant: 12),
            sparklineView.leadingAnchor.constraint(equalTo: iconBg.leadingAnchor),
            sparklineView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            sparklineView.heightAnchor.constraint(equalToConstant: 36),

            metricLabel.topAnchor.constraint(equalTo: sparklineView.bottomAnchor, constant: 10),
            metricLabel.leadingAnchor.constraint(equalTo: iconBg.leadingAnchor),
            metricLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),

            trendLabel.topAnchor.constraint(equalTo: metricLabel.bottomAnchor, constant: 4),
            trendLabel.leadingAnchor.constraint(equalTo: iconBg.leadingAnchor),
            trendLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),

            timeLabel.topAnchor.constraint(equalTo: trendLabel.bottomAnchor, constant: 6),
            timeLabel.leadingAnchor.constraint(equalTo: iconBg.leadingAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -14),
        ])

        // Gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true

        // Start hidden for entrance animation
        alpha     = 0
        transform = CGAffineTransform(translationX: 0, y: 8)
    }

    // MARK: - Populate

    private func populate() {
        let color = report.accentColor

        accentBar.backgroundColor = color
        iconBg.backgroundColor    = color.withAlphaComponent(0.15)

        let iconCfg = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        iconView.image    = UIImage(systemName: report.category.icon, withConfiguration: iconCfg)
        iconView.tintColor = color

        // Category label with letter spacing
        let categoryAttrs = NSAttributedString(
            string: report.title.uppercased(),
            attributes: [
                .kern: 0.8,
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: color
            ])
        categoryLabel.attributedText = categoryAttrs

        // Sparkline
        sparklineView.configure(values: report.graphData.values, color: color)

        // Bold metric
        metricLabel.text      = "\(report.primaryValue) \(report.primaryLabel)"
        metricLabel.textColor = color

        // Trend subtext
        let trendSymbol = report.trend.symbol
        trendLabel.text      = "\(trendSymbol) \(report.comparisonText)"
        trendLabel.textColor = report.trend.color

        // Time label
        timeLabel.text = report.timeRangeLabel
    }

    // MARK: - Entrance Animation

    func animateIn(delay: TimeInterval = 0) {
        UIView.animate(
            withDuration: 0.55, delay: delay,
            usingSpringWithDamping: 0.82, initialSpringVelocity: 0.2,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.transform = .identity
            self.alpha     = 1
        }
    }

    // MARK: - Tap

    @objc private func handleTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        UIView.animate(
            withDuration: 0.10, delay: 0,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            self.containerView.backgroundColor = UIColor.tertiarySystemGroupedBackground
        } completion: { _ in
            UIView.animate(
                withDuration: 0.18, delay: 0,
                usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5,
                options: [.curveEaseIn, .allowUserInteraction]
            ) {
                self.transform = .identity
                self.containerView.backgroundColor = .secondarySystemGroupedBackground
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.onTap?()
        }
    }
}

// MARK: - HighlightsContainerView

final class HighlightsContainerView: UIView {

    private let stackView = UIStackView()
    private var cardViews: [HighlightCardView] = []

    var onCardTapped: ((InsightReport) -> Void)?

    init() {
        super.init(frame: .zero)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        stackView.axis    = .vertical
        stackView.spacing = 14
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(with reports: [InsightReport]) {
        let old = cardViews
        cardViews.removeAll()

        UIView.animate(withDuration: 0.15) { old.forEach { $0.alpha = 0 } } completion: { _ in
            old.forEach { self.stackView.removeArrangedSubview($0); $0.removeFromSuperview() }
        }

        for (i, rep) in reports.enumerated() {
            let card = HighlightCardView(report: rep) { [weak self] in
                self?.onCardTapped?(rep)
            }
            stackView.addArrangedSubview(card)
            cardViews.append(card)
            card.animateIn(delay: Double(i) * 0.07)
        }

        if reports.contains(where: { $0.trend == .decreased && $0.category == .medication }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }
    }

    func refresh() {
        let reports = InsightDataEngine.shared.generateHomeInsightReports()
        configure(with: reports)
    }
}
