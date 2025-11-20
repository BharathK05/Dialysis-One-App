import UIKit

// MARK: - Heatmap Status

enum HydrationStatusType {
    case completed    // 47A8F2
    case halfway      // 65B3EE
    case partial      // 82B9E3
    case noLog        // D9D9D9

    var color: UIColor {
        switch self {
        case .completed: return UIColor(hex: 0x47A8F2)
        case .halfway:   return UIColor(hex: 0x65B3EE)
        case .partial:   return UIColor(hex: 0x82B9E3)
        case .noLog:     return UIColor(hex: 0xD9D9D9)
        }
    }
}

// MARK: - Heatmap Cell

class HeatmapCellView: UIView {
    init(status: HydrationStatusType) {
        super.init(frame: .zero)
        backgroundColor = status.color
        layer.cornerRadius = 8
        layer.masksToBounds = true
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 28),
            heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Soft Card (lower-opacity gradient)

class SoftCardView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        layer.cornerRadius = 20
        layer.masksToBounds = true

        gradientLayer.colors = [
            UIColor(hex: 0xF5F5F5, alpha: 0.55).cgColor,
            UIColor(hex: 0x93C3E8, alpha: 0.40).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

// MARK: - Log Row (inside Yesterday card)

class LogRowView: UIView {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let timeLabel = UILabel()

    init(title: String, subtitle: String, time: String, systemIcon: String) {
        super.init(frame: .zero)
        setup(title: title, subtitle: subtitle, time: time, systemIcon: systemIcon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(title: String, subtitle: String, time: String, systemIcon: String) {
        translatesAutoresizingMaskIntoConstraints = false

        iconView.image = UIImage(systemName: systemIcon)
        iconView.tintColor = UIColor(hex: 0x152B3C)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = UIColor(hex: 0x152B3C)

        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .darkGray

        timeLabel.text = time
        timeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        timeLabel.textColor = UIColor(hex: 0x152B3C)
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)

        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 2
        labelsStack.translatesAutoresizingMaskIntoConstraints = false

        let mainStack = UIStackView(arrangedSubviews: [iconView, labelsStack, UIView(), timeLabel])
        mainStack.axis = .horizontal
        mainStack.alignment = .center
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(mainStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 48),

            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22)
        ])
    }
}

// MARK: - Previous Logs Screen

class PreviousLogsViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let waveView = WaveView()

    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()

    private let yesterdayLabel = UILabel()
    private let yesterdayCard = SoftCardView()

    private let monthlySummaryLabel = UILabel()
    private let legendStack = UIStackView()

    private var heatmapCells: [UIView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupBase()
        setupHeader()
        setupYesterdaySection()
        setupMonthlySummarySection()
        setupWaveBackground()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateHeatmapCells()
    }

    // MARK: - ScrollView base

    private func setupBase() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    // MARK: - Header

    private func setupHeader() {
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = UIColor(hex: 0x43A7EF)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        titleLabel.text = "Previous Logs"
        titleLabel.textColor = UIColor(hex: 0x152B3C)
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(backButton)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.widthAnchor.constraint(equalToConstant: 28),
            backButton.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor)
        ])
    }

    // MARK: - Yesterday (single table card)

    private func setupYesterdaySection() {
        yesterdayLabel.text = "Yesterday"
        yesterdayLabel.textColor = UIColor(hex: 0x152B3C)
        yesterdayLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        yesterdayLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(yesterdayLabel)

        yesterdayCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(yesterdayCard)

        let row1 = LogRowView(title: "Water",  subtitle: "75 ml",  time: "04:30 PM", systemIcon: "drop")
        let row2 = LogRowView(title: "Coffee", subtitle: "25 ml",  time: "12:00 PM", systemIcon: "cup.and.saucer")
        let row3 = LogRowView(title: "Juice",  subtitle: "50 ml",  time: "03:00 PM", systemIcon: "takeoutbag.and.cup.and.straw")
        let row4 = LogRowView(title: "Water",  subtitle: "150 ml", time: "06:30 PM", systemIcon: "drop")

        let rows = [row1, row2, row3, row4]

        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        verticalStack.spacing = 0
        verticalStack.translatesAutoresizingMaskIntoConstraints = false

        for (index, row) in rows.enumerated() {
            verticalStack.addArrangedSubview(row)
            if index < rows.count - 1 {
                let sep = UIView()
                sep.backgroundColor = UIColor.black.withAlphaComponent(0.06)
                sep.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    sep.heightAnchor.constraint(equalToConstant: 0.8)
                ])
                verticalStack.addArrangedSubview(sep)
            }
        }

        yesterdayCard.addSubview(verticalStack)

        NSLayoutConstraint.activate([
            yesterdayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            // 35pt spacing from header
            yesterdayLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 35),

            yesterdayCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            yesterdayCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            yesterdayCard.topAnchor.constraint(equalTo: yesterdayLabel.bottomAnchor, constant: 12),

            verticalStack.leadingAnchor.constraint(equalTo: yesterdayCard.leadingAnchor),
            verticalStack.trailingAnchor.constraint(equalTo: yesterdayCard.trailingAnchor),
            verticalStack.topAnchor.constraint(equalTo: yesterdayCard.topAnchor, constant: 8),
            verticalStack.bottomAnchor.constraint(equalTo: yesterdayCard.bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Monthly Summary + Heatmap + Info

    private func setupMonthlySummarySection() {
        monthlySummaryLabel.text = "Monthly Summary"
        monthlySummaryLabel.textColor = UIColor(hex: 0x152B3C)
        monthlySummaryLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        monthlySummaryLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(monthlySummaryLabel)

        let monthBadge = UILabel()
        monthBadge.text = "This month"
        monthBadge.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        monthBadge.textColor = UIColor(hex: 0x43A7EF)
        monthBadge.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        monthBadge.textAlignment = .center
        monthBadge.layer.cornerRadius = 10
        monthBadge.clipsToBounds = true
        monthBadge.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(monthBadge)

        let days = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        let daysStack = UIStackView()
        daysStack.axis = .horizontal
        daysStack.alignment = .center
        daysStack.distribution = .equalSpacing
        daysStack.translatesAutoresizingMaskIntoConstraints = false

        for d in days {
            let lbl = UILabel()
            lbl.text = d
            lbl.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            lbl.textColor = UIColor(hex: 0x152B3C)
            daysStack.addArrangedSubview(lbl)
        }
        contentView.addSubview(daysStack)

        let weekData: [[HydrationStatusType]] = [
            [.completed, .completed, .completed, .noLog,     .completed, .completed, .completed],
            [.completed, .halfway,   .halfway,   .completed,  .completed, .completed, .noLog],
            [.partial,   .partial,   .completed, .partial,    .partial,   .completed, .completed],
            [.completed, .completed, .noLog,     .partial,    .completed, .completed, .completed]
        ]

        let weeksStack = UIStackView()
        weeksStack.axis = .vertical
        weeksStack.spacing = 10
        weeksStack.translatesAutoresizingMaskIntoConstraints = false

        let weekLabelsStack = UIStackView()
        weekLabelsStack.axis = .vertical
        weekLabelsStack.alignment = .leading
        weekLabelsStack.spacing = 10
        weekLabelsStack.translatesAutoresizingMaskIntoConstraints = false

        heatmapCells.removeAll()

        for (index, week) in weekData.enumerated() {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.alignment = .center
            rowStack.distribution = .equalSpacing
            rowStack.translatesAutoresizingMaskIntoConstraints = false

            for status in week {
                let cell = HeatmapCellView(status: status)
                cell.alpha = 0
                heatmapCells.append(cell)
                rowStack.addArrangedSubview(cell)
            }
            weeksStack.addArrangedSubview(rowStack)

            let weekLabel = UILabel()
            weekLabel.text = "w\(index + 1)"
            weekLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            weekLabel.textColor = UIColor(hex: 0x152B3C)
            weekLabelsStack.addArrangedSubview(weekLabel)
        }

        let gridContainer = UIStackView(arrangedSubviews: [weeksStack, weekLabelsStack])
        gridContainer.axis = .horizontal
        gridContainer.alignment = .top
        gridContainer.spacing = 8
        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gridContainer)

        legendStack.axis = .horizontal
        legendStack.alignment = .center
        legendStack.distribution = .equalSpacing
        legendStack.spacing = 16
        legendStack.translatesAutoresizingMaskIntoConstraints = false

        func legendItem(color: UIColor, text: String) -> UIStackView {
            let dot = UIView()
            dot.backgroundColor = color
            dot.layer.cornerRadius = 6
            dot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 12),
                dot.heightAnchor.constraint(equalToConstant: 12)
            ])

            let label = UILabel()
            label.text = text
            label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            label.textColor = UIColor(hex: 0x152B3C)

            let stack = UIStackView(arrangedSubviews: [dot, label])
            stack.axis = .horizontal
            stack.alignment = .center
            stack.spacing = 4
            return stack
        }

        // Updated labels: Exceeded / In-Range / Halfway / No log
        legendStack.addArrangedSubview(legendItem(color: HydrationStatusType.completed.color, text: "Exceeded"))
        legendStack.addArrangedSubview(legendItem(color: HydrationStatusType.halfway.color,   text: "In-Range"))
        legendStack.addArrangedSubview(legendItem(color: HydrationStatusType.partial.color,   text: "Halfway"))
        legendStack.addArrangedSubview(legendItem(color: HydrationStatusType.noLog.color,     text: "No log"))
        contentView.addSubview(legendStack)

        let infoCard = SoftCardView()
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        infoCard.layer.cornerRadius = 18

        let infoIcon = UIImageView(image: UIImage(systemName: "calendar.badge.clock"))
        infoIcon.tintColor = UIColor(hex: 0x152B3C)
        infoIcon.translatesAutoresizingMaskIntoConstraints = false
        infoIcon.setContentHuggingPriority(.required, for: .horizontal)

        let infoLabel = UILabel()
        infoLabel.text = "More blue squares mean more days meeting your target. Plan fluids around busy days to keep your streak going."
        infoLabel.numberOfLines = 0
        infoLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        infoLabel.textColor = UIColor(hex: 0x152B3C)
        infoLabel.translatesAutoresizingMaskIntoConstraints = false

        let infoStack = UIStackView(arrangedSubviews: [infoIcon, infoLabel])
        infoStack.axis = .horizontal
        infoStack.alignment = .top
        infoStack.spacing = 10
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        infoCard.addSubview(infoStack)
        contentView.addSubview(infoCard)

        NSLayoutConstraint.activate([
            monthlySummaryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            monthlySummaryLabel.topAnchor.constraint(equalTo: yesterdayCard.bottomAnchor, constant: 32),

            monthBadge.centerYAnchor.constraint(equalTo: monthlySummaryLabel.centerYAnchor),
            monthBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            monthBadge.heightAnchor.constraint(equalToConstant: 22),
            monthBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),

            daysStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            daysStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -80),
            daysStack.topAnchor.constraint(equalTo: monthlySummaryLabel.bottomAnchor, constant: 16),

            gridContainer.leadingAnchor.constraint(equalTo: daysStack.leadingAnchor),
            gridContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            gridContainer.topAnchor.constraint(equalTo: daysStack.bottomAnchor, constant: 12),

            weeksStack.widthAnchor.constraint(equalTo: daysStack.widthAnchor),

            legendStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            legendStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            legendStack.topAnchor.constraint(equalTo: gridContainer.bottomAnchor, constant: 20),

            infoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoCard.topAnchor.constraint(equalTo: legendStack.bottomAnchor, constant: 28),
            infoCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            infoStack.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 14),
            infoStack.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -14),
            infoStack.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 12),
            infoStack.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -12),

            infoIcon.widthAnchor.constraint(equalToConstant: 20),
            infoIcon.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    // MARK: - Waves Background

    private func setupWaveBackground() {
        waveView.translatesAutoresizingMaskIntoConstraints = false
        waveView.level = 0.55

        view.insertSubview(waveView, at: 0)

        NSLayoutConstraint.activate([
            waveView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            waveView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            waveView.topAnchor.constraint(equalTo: view.topAnchor),
            waveView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Animation

    private func animateHeatmapCells() {
        for (index, cell) in heatmapCells.enumerated() {
            UIView.animate(withDuration: 0.35,
                           delay: 0.02 * Double(index),
                           options: [.curveEaseOut],
                           animations: { cell.alpha = 1 },
                           completion: nil)
        }
    }

    // MARK: - Actions

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}
