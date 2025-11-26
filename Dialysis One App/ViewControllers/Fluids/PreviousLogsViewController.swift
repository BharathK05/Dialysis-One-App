import UIKit

// MARK: - Heatmap Status

enum HydrationStatusType {
    case completed    // Exceeded
    case halfway      // In-Range
    case partial      // Halfway
    case noLog        // No log

    var color: UIColor {
        switch self {
        case .completed:
            return UIColor(hex: 0x47A8F2)          // Exceeded
        case .halfway:
            return UIColor(hex: 0x86CBFF)          // In-Range (UPDATED)
        case .partial:
            return UIColor(hex: 0x82B9E3)          // Halfway
        case .noLog:
            return UIColor(hex: 0xD9D9D9)
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

// MARK: - Soft Card

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

// MARK: - Previous Logs Screen

class PreviousLogsViewController: UIViewController {

    // MARK: UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let waveView = WaveView()

    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()

    private let yesterdayLabel = UILabel()
    private let yesterdayCard = SoftCardView()

    private let monthlySummaryLabel = UILabel()

    // Month control (calendar badge)
    private let monthBadgeContainer = UIView()
    private let prevMonthButton = UIButton(type: .system)
    private let nextMonthButton = UIButton(type: .system)
    private let monthLabel = UILabel()

    // Heatmap stacks
    private let daysStack = UIStackView()
    private let weeksStack = UIStackView()
    private let weekLabelsStack = UIStackView()
    private let legendStack = UIStackView()

    private var heatmapCells: [UIView] = []

    // MARK: Calendar

    private let calendar = Calendar.current
    private var currentMonthDate = Date()   // normalized in viewDidLoad

    private let dayKeyFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Normalize to first of the month
        let comps = calendar.dateComponents([.year, .month], from: Date())
        currentMonthDate = calendar.date(from: comps) ?? Date()

        setupBase()
        setupHeader()
        setupYesterdaySection()
        setupMonthlySummarySection()
        setupWaveBackground()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)

        // Refresh month label + heatmap when coming back from Home
        updateMonthLabel()
        buildHeatmap()
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

    // MARK: - Yesterday card

    private func setupYesterdaySection() {
        yesterdayLabel.text = "Yesterday"
        yesterdayLabel.textColor = UIColor(hex: 0x152B3C)
        yesterdayLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        yesterdayLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(yesterdayLabel)

        yesterdayCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(yesterdayCard)

        let messageLabel = UILabel()
        messageLabel.text = "Enter your fluid intake everyday to have a track of it!"
        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        messageLabel.textColor = UIColor(hex: 0x152B3C)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        yesterdayCard.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            yesterdayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            yesterdayLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 35),

            yesterdayCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            yesterdayCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            yesterdayCard.topAnchor.constraint(equalTo: yesterdayLabel.bottomAnchor, constant: 12),

            messageLabel.leadingAnchor.constraint(equalTo: yesterdayCard.leadingAnchor, constant: 18),
            messageLabel.trailingAnchor.constraint(equalTo: yesterdayCard.trailingAnchor, constant: -18),
            messageLabel.topAnchor.constraint(equalTo: yesterdayCard.topAnchor, constant: 14),
            messageLabel.bottomAnchor.constraint(equalTo: yesterdayCard.bottomAnchor, constant: -14)
        ])
    }

    // MARK: - Monthly Summary + Heatmap

    private func setupMonthlySummarySection() {
        monthlySummaryLabel.text = "Monthly Summary"
        monthlySummaryLabel.textColor = UIColor(hex: 0x152B3C)
        monthlySummaryLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        monthlySummaryLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(monthlySummaryLabel)

        setupMonthBadge()

        // Day headers (Mo–Su)
        daysStack.axis = .horizontal
        daysStack.alignment = .center
        daysStack.distribution = .equalSpacing
        daysStack.translatesAutoresizingMaskIntoConstraints = false

        let days = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        for d in days {
            let lbl = UILabel()
            lbl.text = d
            lbl.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            lbl.textColor = UIColor(hex: 0x152B3C)
            daysStack.addArrangedSubview(lbl)
        }
        contentView.addSubview(daysStack)

        // Weeks + week labels
        weeksStack.axis = .vertical
        weeksStack.spacing = 10
        weeksStack.translatesAutoresizingMaskIntoConstraints = false

        weekLabelsStack.axis = .vertical
        weekLabelsStack.alignment = .leading
        weekLabelsStack.spacing = 10
        weekLabelsStack.translatesAutoresizingMaskIntoConstraints = false

        let gridContainer = UIStackView(arrangedSubviews: [weeksStack, weekLabelsStack])
        gridContainer.axis = .horizontal
        gridContainer.alignment = .top
        gridContainer.spacing = 8
        gridContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gridContainer)

        // Legend
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

        legendStack.addArrangedSubview(legendItem(color: HydrationStatusType.completed.color, text: "Exceeded"))
        legendStack.addArrangedSubview(legendItem(color: HydrationStatusType.halfway.color,   text: "In-Range"))
        legendStack.addArrangedSubview(legendItem(color: HydrationStatusType.partial.color,   text: "Halfway"))
        legendStack.addArrangedSubview(legendItem(color: HydrationStatusType.noLog.color,     text: "No log"))
        contentView.addSubview(legendStack)

        // Info card
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

            monthBadgeContainer.centerYAnchor.constraint(equalTo: monthlySummaryLabel.centerYAnchor),
            monthBadgeContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

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

        updateMonthLabel()
        buildHeatmap()
    }

    // MARK: Month badge

    private func setupMonthBadge() {
        monthBadgeContainer.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        monthBadgeContainer.layer.cornerRadius = 18
        monthBadgeContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(monthBadgeContainer)

        prevMonthButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        prevMonthButton.tintColor = UIColor(hex: 0x43A7EF)
        prevMonthButton.addTarget(self, action: #selector(prevMonthTapped), for: .touchUpInside)

        nextMonthButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        nextMonthButton.tintColor = UIColor(hex: 0x43A7EF)
        nextMonthButton.addTarget(self, action: #selector(nextMonthTapped), for: .touchUpInside)

        let calendarIcon = UIImageView(image: UIImage(systemName: "calendar"))
        calendarIcon.tintColor = UIColor(hex: 0x43A7EF)
        calendarIcon.translatesAutoresizingMaskIntoConstraints = false

        monthLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        monthLabel.textColor = UIColor(hex: 0x152B3C)
        monthLabel.translatesAutoresizingMaskIntoConstraints = false

        let centerStack = UIStackView(arrangedSubviews: [calendarIcon, monthLabel])
        centerStack.axis = .horizontal
        centerStack.alignment = .center
        centerStack.spacing = 6

        let badgeStack = UIStackView(arrangedSubviews: [prevMonthButton, centerStack, nextMonthButton])
        badgeStack.axis = .horizontal
        badgeStack.alignment = .center
        badgeStack.spacing = 8
        badgeStack.translatesAutoresizingMaskIntoConstraints = false

        monthBadgeContainer.addSubview(badgeStack)

        NSLayoutConstraint.activate([
            badgeStack.leadingAnchor.constraint(equalTo: monthBadgeContainer.leadingAnchor, constant: 10),
            badgeStack.trailingAnchor.constraint(equalTo: monthBadgeContainer.trailingAnchor, constant: -10),
            badgeStack.topAnchor.constraint(equalTo: monthBadgeContainer.topAnchor, constant: 4),
            badgeStack.bottomAnchor.constraint(equalTo: monthBadgeContainer.bottomAnchor, constant: -4),

            calendarIcon.widthAnchor.constraint(equalToConstant: 16),
            calendarIcon.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    private func updateMonthLabel() {
        let df = DateFormatter()
        df.dateFormat = "MMM yyyy"
        monthLabel.text = df.string(from: currentMonthDate)
    }

    // MARK: - Data helpers

    // MARK: - Data helpers
    private func dailyConsumed(for date: Date) -> Int {
        // Use the SAME UID string that you use in Home / HydrationStatus
        let uid = "defaultUser"

        let today = calendar.startOfDay(for: Date())
        let thisDay = calendar.startOfDay(for: date)

        if today == thisDay {
            // Today uses the same key as Home / HydrationStatus
            return UserDataManager.shared.loadInt("waterConsumed",
                                                  uid: uid,
                                                  defaultValue: 0)
        } else {
            // Per-day key (if you later save past days)
            let key = "waterConsumed_" + dayKeyFormatter.string(from: date)
            return UserDataManager.shared.loadInt(key,
                                                  uid: uid,
                                                  defaultValue: 0)
        }
    }


    private func statusFor(consumed: Int, goal: Int) -> HydrationStatusType {
        guard consumed > 0, goal > 0 else { return .noLog }

        let ratio = Double(consumed) / Double(goal)

        if ratio > 1.0 {
            return .completed          // Exceeded
        } else if ratio > 0.5 {
            return .halfway            // In-Range
        } else {
            return .partial            // Halfway
        }
    }

    // MARK: - Build 4-week heatmap

    private func buildHeatmap() {
        // Clear old rows & labels
        weeksStack.arrangedSubviews.forEach {
            weeksStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        weekLabelsStack.arrangedSubviews.forEach {
            weekLabelsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        heatmapCells.forEach { $0.removeFromSuperview() }
        heatmapCells.removeAll()

        let comps = calendar.dateComponents([.year, .month], from: currentMonthDate)
        guard let firstOfMonth = calendar.date(from: DateComponents(year: comps.year,
                                                                    month: comps.month,
                                                                    day: 1)),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return
        }

        let numberOfDays = range.count

        // Same UID constant as in dailyConsumed / Home / HydrationStatus
        let uid = "defaultUser"
        let goal = UserDataManager.shared.loadInt("waterGoal",
                                                  uid: uid,
                                                  defaultValue: 2500)


        let maxWeeks = 4  // ALWAYS 4 rows: w1–w4

        for weekIndex in 0..<maxWeeks {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.alignment = .center
            rowStack.distribution = .equalSpacing
            rowStack.translatesAutoresizingMaskIntoConstraints = false

            let startDay = weekIndex * 7 + 1

            for col in 0..<7 {
                let dayNumber = startDay + col
                let cell: HeatmapCellView

                if dayNumber >= 1 && dayNumber <= numberOfDays {
                    let date = calendar.date(byAdding: .day,
                                             value: dayNumber - 1,
                                             to: firstOfMonth)!
                    let consumed = dailyConsumed(for: date)
                    let status = statusFor(consumed: consumed, goal: goal)
                    cell = HeatmapCellView(status: status)
                } else {
                    cell = HeatmapCellView(status: .noLog)
                    cell.alpha = 0.25
                }

                // Start hidden for animation
                cell.alpha = 0
                heatmapCells.append(cell)
                rowStack.addArrangedSubview(cell)
            }

            weeksStack.addArrangedSubview(rowStack)

            // Week labels aligned row-by-row
            let weekLabel = UILabel()
            weekLabel.text = "w\(weekIndex + 1)"
            weekLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            weekLabel.textColor = UIColor(hex: 0x152B3C)
            weekLabelsStack.addArrangedSubview(weekLabel)
        }

        weeksStack.layoutIfNeeded()
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

    @objc private func prevMonthTapped() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonthDate) {
            currentMonthDate = newDate
            updateMonthLabel()
            buildHeatmap()
            animateHeatmapCells()
        }
    }

    @objc private func nextMonthTapped() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonthDate) {
            currentMonthDate = newDate
            updateMonthLabel()
            buildHeatmap()
            animateHeatmapCells()
        }
    }
}
