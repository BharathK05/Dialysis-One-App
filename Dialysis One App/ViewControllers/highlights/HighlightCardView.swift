//
//  HighlightCardView.swift
//  Dialysis One App
//
//  Redesigned to match the screenshot:
//  • Full-width white card, rounded corners, subtle shadow
//  • Left accent bar (4 pt, full-height inset)
//  • Icon + CATEGORY LABEL row (top-left)  •  Chevron (top-right)
//  • Large bold metric value (accent color)
//  • Subtitle description label
//  • Simple L-shaped sparkline, bottom-right
//

import UIKit

// MARK: - HighlightCardView

final class HighlightCardView: UIView {

    // MARK: - Data
    private let report: InsightReport
    private var onTap: (() -> Void)?

    // MARK: - Subviews
    private let containerView  = UIView()
    private let accentBar      = UIView()
    private let iconView       = UIImageView()
    private let categoryLabel  = UILabel()
    private let chevronView    = UIImageView()
    private let metricLabel    = UILabel()
    private let subtitleLabel  = UILabel()
    private let sparkline      = CornerSparklineView()

    // MARK: - Init

    init(report: InsightReport, onTap: (() -> Void)? = nil) {
        self.report = report
        self.onTap  = onTap
        super.init(frame: .zero)
        build()
        populate()
    }

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
        containerView.backgroundColor    = .white
        containerView.layer.cornerRadius = 18
        containerView.layer.shadowColor  = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.06
        containerView.layer.shadowOffset  = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius  = 8
        containerView.layer.masksToBounds = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        // ── Left accent bar ───────────────────────────────────────────────
        accentBar.layer.cornerRadius  = 3
        accentBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        accentBar.clipsToBounds       = true
        accentBar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(accentBar)

        // ── Category icon ─────────────────────────────────────────────────
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconView)

        // ── Category label ────────────────────────────────────────────────
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(categoryLabel)

        // ── Chevron ───────────────────────────────────────────────────────
        let chevrCfg = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevronView.image       = UIImage(systemName: "chevron.right", withConfiguration: chevrCfg)
        chevronView.tintColor   = UIColor.systemGray3
        chevronView.contentMode = .scaleAspectFit
        chevronView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(chevronView)

        // ── Metric (big number) ───────────────────────────────────────────
        metricLabel.font          = UIFont.systemFont(ofSize: 30, weight: .bold)
        metricLabel.numberOfLines = 1
        metricLabel.adjustsFontSizeToFitWidth = true
        metricLabel.minimumScaleFactor = 0.7
        metricLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(metricLabel)

        // ── Subtitle (e.g. "Adherence", "Avg per day") ─────────────────
        subtitleLabel.font      = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = UIColor(white: 0.42, alpha: 1)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)

        // ── Sparkline (L-shaped) ──────────────────────────────────────────
        sparkline.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(sparkline)

        // ── Constraints ───────────────────────────────────────────────────
        NSLayoutConstraint.activate([
            // Outer frame
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 108),

            // Accent bar — full height with 12pt inset top/bottom, flush left
            accentBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            accentBar.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            accentBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            accentBar.widthAnchor.constraint(equalToConstant: 4),

            // Icon — top row, left side
            iconView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 18),
            iconView.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 14),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),

            // Category label — same row as icon
            categoryLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            categoryLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 7),
            categoryLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronView.leadingAnchor, constant: -8),

            // Chevron — top-right
            chevronView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            chevronView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -18),
            chevronView.widthAnchor.constraint(equalToConstant: 12),
            chevronView.heightAnchor.constraint(equalToConstant: 14),

            // Metric label — below icon row
            metricLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 10),
            metricLabel.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 14),
            metricLabel.trailingAnchor.constraint(lessThanOrEqualTo: sparkline.leadingAnchor, constant: -12),

            // Subtitle — just below metric
            subtitleLabel.topAnchor.constraint(equalTo: metricLabel.bottomAnchor, constant: 3),
            subtitleLabel.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: 14),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: sparkline.leadingAnchor, constant: -12),
            subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -18),

            // Sparkline — bottom-right corner
            sparkline.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            sparkline.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -18),
            sparkline.widthAnchor.constraint(equalToConstant: 60),
            sparkline.heightAnchor.constraint(equalToConstant: 38),
        ])

        // Tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true

        // Entrance animation start state
        alpha     = 0
        transform = CGAffineTransform(translationX: 0, y: 10)
    }

    // MARK: - Populate

    private func populate() {
        let color = report.accentColor

        // Accent bar
        accentBar.backgroundColor = color

        // Icon
        let iconCfg = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        iconView.image     = UIImage(systemName: report.category.icon, withConfiguration: iconCfg)
        iconView.tintColor = color

        // Category label — uppercase + letter spacing
        let attrs = NSAttributedString(
            string: report.title.uppercased(),
            attributes: [
                .kern:             0.8,
                .font:             UIFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor:  color
            ])
        categoryLabel.attributedText = attrs

        // Metric
        metricLabel.text      = report.primaryValue
        metricLabel.textColor = color

        // Subtitle — human-readable description
        subtitleLabel.text = subtitleText(for: report)

        // Sparkline — pass recent values + color
        sparkline.setColor(color)
        let values = report.graphData.values
        sparkline.setValues(values.isEmpty ? [0, 1] : values)
    }

    private func subtitleText(for report: InsightReport) -> String {
        switch report.category {
        case .medication:
            return "Adherence"
        case .fluids:
            return "Avg per day"
        case .potassium:
            return "Avg Potassium/day"
        case .sodium:
            return "Avg Sodium/day"
        case .protein:
            return "Avg Protein/day"
        default:
            return report.primaryLabel.isEmpty ? report.timeRangeLabel : report.primaryLabel
        }
    }

    // MARK: - Entrance Animation

    func animateIn(delay: TimeInterval = 0) {
        UIView.animate(
            withDuration: 0.5, delay: delay,
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
        UIView.animate(withDuration: 0.09, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        } completion: { _ in
            UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5,
                           options: [.curveEaseIn, .allowUserInteraction]) {
                self.transform = .identity
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.onTap?() }
    }
}

// MARK: - CornerSparklineView

/// Draws the "L-shaped rising line" sparkline visible in the screenshot.
/// Uses the last few data points and fits them into a small rect,
/// producing a line that rises toward the top-right corner.
final class CornerSparklineView: UIView {

    private var values: [Double] = [0, 0.3, 0.7, 1]
    private var color: UIColor   = .systemBlue

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) { fatalError() }

    func setValues(_ v: [Double]) {
        // Keep last 7 points max for sparkline
        values = Array(v.suffix(7))
        setNeedsDisplay()
    }

    func setColor(_ c: UIColor) {
        color = c
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard values.count > 1 else { return }

        let maxV  = values.max() ?? 1
        let minV  = values.min() ?? 0
        let range = maxV - minV > 0 ? maxV - minV : 1

        // Map to a smaller inset rect so it looks like the screenshot
        let inset: CGFloat = 3
        let drawRect = rect.insetBy(dx: inset, dy: inset)
        let stepX = drawRect.width / CGFloat(values.count - 1)

        func pt(_ i: Int) -> CGPoint {
            let x = drawRect.minX + CGFloat(i) * stepX
            let norm = CGFloat((values[i] - minV) / range)
            let y = drawRect.maxY - norm * drawRect.height
            return CGPoint(x: x, y: y)
        }

        let path = UIBezierPath()
        path.move(to: pt(0))
        for i in 1..<values.count {
            path.addLine(to: pt(i))
        }

        color.setStroke()
        path.lineWidth     = 2.0
        path.lineCapStyle  = .round
        path.lineJoinStyle = .round
        path.stroke()
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
        stackView.axis         = .vertical
        stackView.spacing      = 14
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

        UIView.animate(withDuration: 0.12) {
            old.forEach { $0.alpha = 0 }
        } completion: { _ in
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

        // Haptic nudge if medication is declining
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
