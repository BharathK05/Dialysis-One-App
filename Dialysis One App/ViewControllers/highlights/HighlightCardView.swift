//
//  HighlightCardView.swift
//  Dialysis One App
//
//  Smart Highlights System - Apple Health Style (Translucent Theme)
//  UPDATED: Frosted glass background matching Summary section
//

import UIKit

class HighlightCardView: UIView {
    
    // MARK: - Properties
    
    private let insight: HealthInsight
    private var onTap: (() -> Void)?
    
    private let containerView = UIView()
    private let iconBackgroundView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let detailLabel = UILabel()
    private let chevronView = UIImageView()
    private let miniGraphContainer = UIView()
    
    // MARK: - Initialization
    
    init(insight: HealthInsight, onTap: (() -> Void)? = nil) {
        self.insight = insight
        self.onTap = onTap
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupView() {
        // Main container - Translucent frosted glass style (matching Summary cards)
        containerView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        containerView.layer.cornerRadius = 18
        
        // Add blur effect for frosted glass look
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.cornerRadius = 18
        blurView.clipsToBounds = true
        blurView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(blurView)
        containerView.sendSubviewToBack(blurView)
        
        // Very subtle border
        containerView.layer.borderWidth = 0.5
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // Pin blur view to container
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Icon background circle (colored circle with slight transparency)
        iconBackgroundView.backgroundColor = insight.category.color.withAlphaComponent(0.2)
        iconBackgroundView.layer.cornerRadius = 16
        iconBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconBackgroundView)
        
        // Icon
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        iconView.image = UIImage(systemName: insight.category.icon, withConfiguration: iconConfig)
        iconView.tintColor = insight.category.color
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBackgroundView.addSubview(iconView)
        
        // Title
        titleLabel.text = insight.title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = insight.category.color
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Chevron (only if actionable)
        if insight.actionScreen != nil {
            let chevronConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
            chevronView.image = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
            chevronView.tintColor = UIColor.systemGray3
            chevronView.contentMode = .scaleAspectFit
            chevronView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(chevronView)
        }
        
        // Message (main headline)
        messageLabel.text = insight.message
        messageLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        messageLabel.textColor = .label
        messageLabel.numberOfLines = 2
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)
        
        // Detail (optional subtext)
        if let detail = insight.detail {
            detailLabel.text = detail
            detailLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            detailLabel.textColor = .secondaryLabel
            detailLabel.numberOfLines = 2
            detailLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(detailLabel)
        }
        
        // Mini graph/visualization if trend data exists
        if let trendData = insight.trendData {
            setupMiniGraph(with: trendData)
        }
        
        setupConstraints()
        setupGestureRecognizer()
        
        // Add subtle entrance animation
        setupEntranceAnimation()
    }
    
    private func setupConstraints() {
        var constraints: [NSLayoutConstraint] = [
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Icon background circle
            iconBackgroundView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            iconBackgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconBackgroundView.widthAnchor.constraint(equalToConstant: 32),
            iconBackgroundView.heightAnchor.constraint(equalToConstant: 32),
            
            // Icon inside circle
            iconView.centerXAnchor.constraint(equalTo: iconBackgroundView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackgroundView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),
            
            // Title label
            titleLabel.centerYAnchor.constraint(equalTo: iconBackgroundView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconBackgroundView.trailingAnchor, constant: 10),
            
            // Message label
            messageLabel.topAnchor.constraint(equalTo: iconBackgroundView.bottomAnchor, constant: 14),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
        ]
        
        // Chevron constraints (if present)
        if insight.actionScreen != nil {
            constraints += [
                chevronView.centerYAnchor.constraint(equalTo: iconBackgroundView.centerYAnchor),
                chevronView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                chevronView.widthAnchor.constraint(equalToConstant: 13),
                chevronView.heightAnchor.constraint(equalToConstant: 13),
                titleLabel.trailingAnchor.constraint(equalTo: chevronView.leadingAnchor, constant: -8)
            ]
        } else {
            constraints.append(
                titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
            )
        }
        
        // Detail label or mini graph constraints
        if insight.detail != nil {
            constraints += [
                detailLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 6),
                detailLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                detailLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                detailLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
            ]
        } else if insight.trendData != nil {
            constraints += [
                miniGraphContainer.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 12),
                miniGraphContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                miniGraphContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                miniGraphContainer.heightAnchor.constraint(equalToConstant: 40),
                miniGraphContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
            ]
        } else {
            constraints.append(
                messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
            )
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupMiniGraph(with trendData: HealthInsight.TrendData) {
        miniGraphContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(miniGraphContainer)
        
        // Simple sparkline-style graph
        let graphView = MiniSparklineView(data: trendData.values, color: insight.category.color)
        graphView.translatesAutoresizingMaskIntoConstraints = false
        miniGraphContainer.addSubview(graphView)
        
        NSLayoutConstraint.activate([
            graphView.topAnchor.constraint(equalTo: miniGraphContainer.topAnchor),
            graphView.leadingAnchor.constraint(equalTo: miniGraphContainer.leadingAnchor),
            graphView.trailingAnchor.constraint(equalTo: miniGraphContainer.trailingAnchor),
            graphView.bottomAnchor.constraint(equalTo: miniGraphContainer.bottomAnchor)
        ])
    }
    
    private func setupGestureRecognizer() {
        if insight.actionScreen != nil || onTap != nil {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            addGestureRecognizer(tapGesture)
            isUserInteractionEnabled = true
        }
    }
    
    private func setupEntranceAnimation() {
        // Start slightly below and transparent
        self.transform = CGAffineTransform(translationX: 0, y: 10)
        self.alpha = 0
    }
    
    func animateIn(delay: TimeInterval = 0) {
        UIView.animate(
            withDuration: 0.6,
            delay: delay,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.3,
            options: [.curveEaseOut, .allowUserInteraction]
        ) {
            self.transform = .identity
            self.alpha = 1
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleTap() {
        // Apple-style haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        // Smooth scale animation (like Apple Health cards)
        UIView.animate(
            withDuration: 0.12,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: {
                self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
                self.containerView.backgroundColor = UIColor.white.withAlphaComponent(0.7)
            }
        ) { _ in
            UIView.animate(
                withDuration: 0.12,
                delay: 0,
                options: [.curveEaseIn, .allowUserInteraction],
                animations: {
                    self.transform = .identity
                    self.containerView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
                }
            )
        }
        
        // Trigger action after animation starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.onTap?()
        }
    }
}

// MARK: - Mini Sparkline Graph View

class MiniSparklineView: UIView {
    
    private let data: [Double]
    private let color: UIColor
    
    init(data: [Double], color: UIColor) {
        self.data = data
        self.color = color
        super.init(frame: .zero)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard !data.isEmpty else { return }
        
        let path = UIBezierPath()
        let maxValue = data.max() ?? 1
        let minValue = data.min() ?? 0
        let range = maxValue - minValue
        
        let spacing = rect.width / CGFloat(data.count - 1)
        
        for (index, value) in data.enumerated() {
            let x = CGFloat(index) * spacing
            let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
            let y = rect.height - (CGFloat(normalizedValue) * rect.height)
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        // Stroke the line
        color.setStroke()
        path.lineWidth = 2.0
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
        
        // Fill area under line with gradient
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.close()
        
        color.withAlphaComponent(0.15).setFill()
        path.fill()
    }
}

// MARK: - Highlights Container with Apple-style animations

class HighlightsContainerView: UIView {
    
    private let stackView = UIStackView()
    private var insights: [HealthInsight] = []
    private var cardViews: [HighlightCardView] = []
    
    var onCardTapped: ((HealthInsight.DestinationScreen) -> Void)?
    
    init() {
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(with insights: [HealthInsight]) {
        self.insights = insights
        
        // Remove old cards with fade out
        let oldCards = cardViews
        cardViews.removeAll()
        
        UIView.animate(withDuration: 0.25) {
            oldCards.forEach { $0.alpha = 0 }
        } completion: { _ in
            oldCards.forEach { $0.removeFromSuperview() }
        }
        
        // Add new cards with staggered animation
        for (index, insight) in insights.enumerated() {
            let card = HighlightCardView(insight: insight) { [weak self] in
                guard let screen = insight.actionScreen else { return }
                self?.onCardTapped?(screen)
            }
            
            stackView.addArrangedSubview(card)
            cardViews.append(card)
            
            // Staggered entrance animation (Apple Health style)
            card.animateIn(delay: Double(index) * 0.08)
        }
        
        // Haptic feedback for important alerts
        if insights.contains(where: { $0.priority == .critical }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            }
        }
    }
    
    func refresh() {
        let newInsights = HighlightsInsightEngine.shared.generateInsights()
        configure(with: newInsights)
    }
}
