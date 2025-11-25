import UIKit

final class NutrientBalanceViewController: UIViewController {

    // MARK: - Constants for easy tuning
    private enum Spacing {
        static let topNav: CGFloat = 12
        static let dateToGauge: CGFloat = 24
        static let gaugeToNutrients: CGFloat = 36
        static let nutrientsToSegment: CGFloat = 28
        static let segmentToCard: CGFloat = 22
        static let contentCardPadding: CGFloat = 20
    }

    // MARK: - Views

    private let gradientView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("‹", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        b.tintColor = .black
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Nutrient Balance"
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        return l
    }()

    private let datePill: UILabel = {
        let l = UILabel()
        l.text = "Sep 15, 2025"
        l.textAlignment = .center
        l.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        l.backgroundColor = UIColor(white: 1.0, alpha: 0.4)
        l.layer.cornerRadius = 16
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // horseshoe gauge
    private let gaugeView = HorseshoeGaugeView()

    // nutrient cards container
    private let nutrientsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.distribution = .fillEqually
        s.alignment = .center
        s.spacing = 12
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // segmented control styled
    private let mealsSegmented: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Breakfast","Lunch","Dinner"])
        sc.selectedSegmentIndex = 1
        sc.translatesAutoresizingMaskIntoConstraints = false

        sc.backgroundColor = UIColor(white: 1.0, alpha: 0.3)
        sc.selectedSegmentTintColor = .white
        sc.setTitleTextAttributes([.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)], for: .selected)
        sc.setTitleTextAttributes([.foregroundColor: UIColor.black.withAlphaComponent(0.7), .font: UIFont.systemFont(ofSize: 14, weight: .regular)], for: .normal)
        sc.layer.cornerRadius = 18
        sc.clipsToBounds = true
        return sc
    }()

    // content card
    private let contentCard: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        v.layer.cornerRadius = 18
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset = CGSize(width: 0, height: 6)
        v.layer.shadowRadius = 12
        return v
    }()

    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 14
        s.alignment = .fill
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureNavigationBar()
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        setupLayout()
        populateNutrientCards()
        populateContentRows()

        gaugeView.maxValue = 2000
        gaugeView.currentValue = 1450
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setGradient()
    }

    // MARK: - Setup

    private func configureNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupLayout() {
        view.addSubview(gradientView)
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Top area: back, title, edit
        gradientView.addSubview(backButton)
        gradientView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: gradientView.safeAreaLayoutGuide.topAnchor, constant: Spacing.topNav),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor)
        ])

        // Date pill
        gradientView.addSubview(datePill)
        NSLayoutConstraint.activate([
            datePill.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            datePill.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            datePill.heightAnchor.constraint(equalToConstant: 34),
            datePill.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])

        // Gauge
        gradientView.addSubview(gaugeView)
        gaugeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gaugeView.topAnchor.constraint(equalTo: datePill.bottomAnchor, constant: Spacing.dateToGauge),
            gaugeView.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            gaugeView.widthAnchor.constraint(equalToConstant: 300),
            gaugeView.heightAnchor.constraint(equalToConstant: 160)
        ])

        // Nutrient cards (no background)
        gradientView.addSubview(nutrientsStack)
        NSLayoutConstraint.activate([
            nutrientsStack.topAnchor.constraint(equalTo: gaugeView.bottomAnchor, constant: Spacing.gaugeToNutrients),
            nutrientsStack.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 18),
            nutrientsStack.trailingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: -18),
            nutrientsStack.heightAnchor.constraint(equalToConstant: 72)
        ])

        // Meals segmented control
        gradientView.addSubview(mealsSegmented)
        NSLayoutConstraint.activate([
            mealsSegmented.topAnchor.constraint(equalTo: nutrientsStack.bottomAnchor, constant: Spacing.nutrientsToSegment),
            mealsSegmented.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            mealsSegmented.widthAnchor.constraint(equalTo: gradientView.widthAnchor, multiplier: 0.86),
            mealsSegmented.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Content card
        gradientView.addSubview(contentCard)
        NSLayoutConstraint.activate([
            contentCard.topAnchor.constraint(equalTo: mealsSegmented.bottomAnchor, constant: Spacing.segmentToCard),
            contentCard.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 18),
            contentCard.trailingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: -18),
            contentCard.bottomAnchor.constraint(equalTo: gradientView.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])

        contentCard.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentCard.topAnchor, constant: Spacing.contentCardPadding),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: contentCard.bottomAnchor, constant: -Spacing.contentCardPadding),
            contentStack.leadingAnchor.constraint(equalTo: contentCard.leadingAnchor, constant: Spacing.contentCardPadding),
            contentStack.trailingAnchor.constraint(equalTo: contentCard.trailingAnchor, constant: -Spacing.contentCardPadding)
        ])
    }

    private func setGradient() {
        guard gradientView.layer.sublayers?.first(where: { $0.name == "bgGradient" }) == nil else { return }
        let g = CAGradientLayer()
        g.name = "bgGradient"
        g.frame = gradientView.bounds
        g.colors = [
            UIColor(red: 200/255, green: 240/255, blue: 210/255, alpha: 1).cgColor,
            UIColor(red: 235/255, green: 250/255, blue: 245/255, alpha: 1).cgColor
        ]
        g.startPoint = CGPoint(x: 0.5, y: 0)
        g.endPoint = CGPoint(x: 0.5, y: 1)
        gradientView.layer.insertSublayer(g, at: 0)
    }

    // MARK: - Populate small components

    private func populateNutrientCards() {
        let potassium = nutrientCard(title: "Potassium", value: "78/90mg", color: UIColor.systemGreen)
        let sodium = nutrientCard(title: "Sodium", value: "45/70mg", color: UIColor.systemOrange)
        let protein = nutrientCard(title: "Protein", value: "95/110mg", color: UIColor.systemYellow)

        nutrientsStack.addArrangedSubview(potassium)
        nutrientsStack.addArrangedSubview(sodium)
        nutrientsStack.addArrangedSubview(protein)
    }

    private func nutrientCard(title: String, value: String, color: UIColor) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.04
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.layer.shadowRadius = 8

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.textAlignment = .center

        // colored underline
        let underline = UIView()
        underline.translatesAutoresizingMaskIntoConstraints = false
        underline.backgroundColor = color
        underline.layer.cornerRadius = 1.5

        container.addSubview(titleLabel)
        container.addSubview(underline)
        container.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 72),

            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            underline.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            underline.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            underline.widthAnchor.constraint(equalToConstant: 40),
            underline.heightAnchor.constraint(equalToConstant: 3),

            valueLabel.topAnchor.constraint(equalTo: underline.bottomAnchor, constant: 8),
            valueLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])

        return container
    }

    // content rows in card
    private func populateContentRows() {
        let rowsData: [(String, String, String)] = [
            ("Rice", "200 gm", "250 kcal"),
            ("Curd", "50 ml", "30 kcal"),
            ("Pickle", "0.5 Tbs", "5 kcal")
        ]

        for item in rowsData {
            contentStack.addArrangedSubview(makeRow(left: item.0, center: item.1, right: item.2))
        }
    }

    private func makeRow(left: String, center: String, right: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(red: 210/255, green: 238/255, blue: 220/255, alpha: 1)
        container.layer.cornerRadius = 22
        container.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let leftLabel = UILabel()
        leftLabel.text = left
        leftLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        leftLabel.translatesAutoresizingMaskIntoConstraints = false

        let centerLabel = UILabel()
        centerLabel.text = center
        centerLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        centerLabel.translatesAutoresizingMaskIntoConstraints = false
        centerLabel.textAlignment = .center

        let rightLabel = UILabel()
        rightLabel.text = right
        rightLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        rightLabel.translatesAutoresizingMaskIntoConstraints = false
        rightLabel.textAlignment = .right

        container.addSubview(leftLabel)
        container.addSubview(centerLabel)
        container.addSubview(rightLabel)

        NSLayoutConstraint.activate([
            leftLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            leftLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            centerLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            centerLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            rightLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),
            rightLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }
}

// MARK: - HorseshoeGaugeView

final class HorseshoeGaugeView: UIView {

    private let centerLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        return l
    }()

    private let subLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor(white: 0.4, alpha: 1)
        l.textAlignment = .center
        return l
    }()

    var maxValue: CGFloat = 2000 {
        didSet { setNeedsDisplay() }
    }
    var currentValue: CGFloat = 1450 {
        didSet { setNeedsLayout(); setNeedsDisplay() }
    }

    private let trackWidth: CGFloat = 20

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupLabels()
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLabels() {
        addSubview(centerLabel)
        addSubview(subLabel)
        centerLabel.font = UIFont.systemFont(ofSize: 28, weight: .regular)
        centerLabel.text = "\(Int(currentValue)) Kcal"
        subLabel.text = "of \(Int(maxValue)) kcal"

        NSLayoutConstraint.activate([
            centerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 5),

            subLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subLabel.topAnchor.constraint(equalTo: centerLabel.bottomAnchor, constant: 2)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        centerLabel.text = "\(Int(currentValue)) Kcal"
        subLabel.text = "of \(Int(maxValue)) kcal"
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawHorseshoe(in: rect)
    }

    private func drawHorseshoe(in rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()

        let centerPoint = CGPoint(x: rect.midX, y: rect.maxY - 10)
        let radius: CGFloat = 115 // increased by approximately 1cm (37 points)

        // Horseshoe goes from about 200° to 340° (140° total arc)
        let startAngle = CGFloat(200) * .pi / 180
        let endAngle = CGFloat(340) * .pi / 180

        // Background track (light gray)
        let bgPath = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        UIColor(red: 210/255, green: 230/255, blue: 215/255, alpha: 1).setStroke()
        bgPath.lineWidth = trackWidth
        bgPath.lineCapStyle = .round
        bgPath.stroke()

        // Progress arc with gradient
        let fraction = min(max(currentValue / maxValue, 0), 1)
        let progEndAngle = startAngle + (endAngle - startAngle) * fraction

        let progPath = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: startAngle, endAngle: progEndAngle, clockwise: true)

        // Create gradient clipped to progress path
        ctx.saveGState()
        ctx.addPath(progPath.cgPath)
        ctx.setLineWidth(trackWidth)
        ctx.setLineCap(.round)
        ctx.replacePathWithStrokedPath()
        ctx.clip()

        let colors = [
            UIColor(red: 140/255, green: 190/255, blue: 145/255, alpha: 1).cgColor,
            UIColor(red: 180/255, green: 225/255, blue: 175/255, alpha: 1).cgColor
        ]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 1]) {
            let startPoint = CGPoint(x: rect.minX, y: centerPoint.y)
            let endPoint = CGPoint(x: rect.maxX, y: centerPoint.y)
            ctx.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        }
        ctx.restoreGState()

        // White knob at the end
        let knobAngle = progEndAngle
        let knobCenter = CGPoint(x: centerPoint.x + radius * cos(knobAngle), y: centerPoint.y + radius * sin(knobAngle))
        let knobPath = UIBezierPath(arcCenter: knobCenter, radius: 8, startAngle: 0, endAngle: 2 * .pi, clockwise: true)

        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: 3), blur: 6, color: UIColor(white: 0.0, alpha: 0.15).cgColor)
        UIColor.white.setFill()
        knobPath.fill()
        ctx.restoreGState()

        ctx.restoreGState()
    }
}
