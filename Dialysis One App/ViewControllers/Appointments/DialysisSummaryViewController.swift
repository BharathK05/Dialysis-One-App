//
//  DialysisSummaryViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 26/11/25.


import UIKit

final class DialysisSummaryViewController: UIViewController {

    // MARK: - UI
    private let monthSelector = UIStackView()
    private let monthLabel = UILabel()
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)

    private let progressCard = UIView()
    private let progressRing = AppointmentCircularProgressView()

    private let progressMessageLabel = UILabel()
    private let progressSubtitleLabel = UILabel()

    private let heatmapContainer = UIView()


    private let legendStack = UIStackView()
    private let infoCard = UIView()
    private let infoLabel = UILabel()
    private var heatmapCells: [UIView] = []


    // MARK: - Data
    private var displayMonth: Date = Date()
    private var calendar = Calendar.current

    private var appointments: [Appointment] {
        AppointmentStore.shared.loadAppointments()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        title = "Dialysis Summary"

        setupMonthSelector()
        setupProgressCard()
        setupHeatmapLayout()
        setupLegendAndInfo()
        reloadData()

        NotificationCenter.default.addObserver(self, selector: #selector(onAppointmentsChanged), name: .appointmentsChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    

    // MARK: - Layout setup
    private func setupMonthSelector() {
        monthSelector.axis = .horizontal
        monthSelector.alignment = .center
        monthSelector.distribution = .equalCentering
        monthSelector.spacing = 8
        monthSelector.translatesAutoresizingMaskIntoConstraints = false

        prevButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        prevButton.tintColor = .systemGreen
        prevButton.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)

        nextButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        nextButton.tintColor = .systemGreen
        nextButton.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)

        monthLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        monthLabel.textAlignment = .center

        let headerContainer = UIView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerContainer)

        headerContainer.addSubview(monthSelector)
        monthSelector.addArrangedSubview(prevButton)
        monthSelector.addArrangedSubview(monthLabel)
        monthSelector.addArrangedSubview(nextButton)

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            monthSelector.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            monthSelector.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            monthSelector.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            monthSelector.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor)
        ])
    }

    private func setupProgressCard() {
        progressCard.backgroundColor = .white
        progressCard.layer.cornerRadius = 12
        progressCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressCard)

        progressRing.translatesAutoresizingMaskIntoConstraints = false
        progressCard.addSubview(progressRing)

        progressMessageLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        progressSubtitleLabel.font = .systemFont(ofSize: 13)
        progressSubtitleLabel.textColor = .darkGray
        progressMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        progressSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        progressCard.addSubview(progressMessageLabel)
        progressCard.addSubview(progressSubtitleLabel)

        NSLayoutConstraint.activate([
            progressCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            progressCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            progressCard.heightAnchor.constraint(equalToConstant: 110),

            progressRing.leadingAnchor.constraint(equalTo: progressCard.leadingAnchor, constant: 18),
            progressRing.centerYAnchor.constraint(equalTo: progressCard.centerYAnchor),
            progressRing.widthAnchor.constraint(equalToConstant: 70),
            progressRing.heightAnchor.constraint(equalToConstant: 70),

            progressMessageLabel.leadingAnchor.constraint(equalTo: progressRing.trailingAnchor, constant: 20),
            progressMessageLabel.topAnchor.constraint(equalTo: progressCard.topAnchor, constant: 28),
            progressMessageLabel.trailingAnchor.constraint(equalTo: progressCard.trailingAnchor, constant: -16),

            progressSubtitleLabel.leadingAnchor.constraint(equalTo: progressMessageLabel.leadingAnchor),
            progressSubtitleLabel.topAnchor.constraint(equalTo: progressMessageLabel.bottomAnchor, constant: 8),
            progressSubtitleLabel.trailingAnchor.constraint(equalTo: progressMessageLabel.trailingAnchor)
        ])
    }

    private func setupLegendAndInfo() {
        // Legend row
        legendStack.axis = .horizontal
        legendStack.spacing = 12
        legendStack.alignment = .center
        legendStack.translatesAutoresizingMaskIntoConstraints = false

        let attended = legendItem(color: UIColor.systemGreen, text: "Attended")
        let missed = legendItem(color: UIColor.systemRed, text: "Missed")
        let none = legendItem(color: UIColor.systemGray, text: "No-Session")

        legendStack.addArrangedSubview(attended)
        legendStack.addArrangedSubview(missed)
        legendStack.addArrangedSubview(none)

        view.addSubview(legendStack)
        NSLayoutConstraint.activate([
            legendStack.topAnchor.constraint(equalTo: heatmapContainer.bottomAnchor, constant: 12),
            legendStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            legendStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])

        // Info card (bottom text)
        infoCard.backgroundColor = .white
        infoCard.layer.cornerRadius = 12
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoCard)

        infoLabel.numberOfLines = 0
        infoLabel.font = .systemFont(ofSize: 14)
        infoLabel.text = "Staying consistent helps reduce hospital visits and improves comfort. You're doing great — keep going!"
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(infoLabel)

        NSLayoutConstraint.activate([
            infoCard.topAnchor.constraint(equalTo: legendStack.bottomAnchor, constant: 14),
            infoCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            infoCard.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            infoLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 12),
            infoLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 12),
            infoLabel.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -12),
            infoLabel.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -12)
        ])
    }

    private func legendItem(color: UIColor, text: String) -> UIStackView {
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 6
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 12).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 12).isActive = true

        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 13)
        lbl.text = text

        let stack = UIStackView(arrangedSubviews: [dot, lbl])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        return stack
    }

    // MARK: - Data + rendering

    @objc private func onAppointmentsChanged() {
        reloadData()
    }

    private func reloadData() {
        monthLabel.text = monthTitle(for: displayMonth)
        renderAppointmentHeatmap()
        updateProgressFor(month: displayMonth)
    }

    private func monthTitle(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "LLLL yyyy"
        return fmt.string(from: date)
    }

    @objc private func prevMonth() {
        guard let prev = calendar.date(byAdding: .month, value: -1, to: displayMonth) else { return }
        displayMonth = prev
        reloadData()
    }
    @objc private func nextMonth() {
        guard let next = calendar.date(byAdding: .month, value: 1, to: displayMonth) else { return }
        displayMonth = next
        reloadData()
    }
    
    private func generateAppointmentWeekData(for month: Date) -> [[AppointmentHeatmapStatus]] {

        guard let monthRange = calendar.dateInterval(of: .month, for: month) else { return [] }

        var days: [Date] = []
        var d = monthRange.start

        while d < monthRange.end {
            days.append(d)
            d = calendar.date(byAdding: .day, value: 1, to: d)!
        }

        var weeks: [[AppointmentHeatmapStatus]] = []
        var row: [AppointmentHeatmapStatus] = []

        let firstWeekday = calendar.component(.weekday, from: days.first!)
        let offset = (firstWeekday + 5) % 7

        for _ in 0..<offset {
            row.append(.noSession)
        }

        for date in days {
            let todaysAppointments = appointments.filter {
                calendar.isDate($0.date, inSameDayAs: date)
            }

            let status: AppointmentHeatmapStatus
            if todaysAppointments.isEmpty {
                status = .noSession
            } else {
                status = date < Date() ? .attended : .future
            }

            row.append(status)

            if row.count == 7 {
                weeks.append(row)
                row.removeAll()
            }
        }

        if !row.isEmpty {
            while row.count < 7 { row.append(.noSession) }
            weeks.append(row)
        }

        return weeks
    }
    
    private func setupHeatmapLayout() {
        heatmapContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heatmapContainer)

        NSLayoutConstraint.activate([
            heatmapContainer.topAnchor.constraint(equalTo: progressCard.bottomAnchor, constant: 20),
            heatmapContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            heatmapContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func renderAppointmentHeatmap() {

        heatmapCells.forEach { $0.removeFromSuperview() }
        heatmapCells.removeAll()

        let weekData = generateAppointmentWeekData(for: displayMonth)

        let weeksStack = UIStackView()
        weeksStack.axis = .vertical
        weeksStack.spacing = 10
        weeksStack.translatesAutoresizingMaskIntoConstraints = false

        let weekLabels = UIStackView()
        weekLabels.axis = .vertical
        weekLabels.spacing = 10
        weekLabels.translatesAutoresizingMaskIntoConstraints = false

        for (i, week) in weekData.enumerated() {

            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 8
            rowStack.distribution = .equalSpacing

            for status in week {
                let cell = AppointmentHeatmapCellView(status: status)
                cell.alpha = 0
                heatmapCells.append(cell)
                rowStack.addArrangedSubview(cell)
            }

            weeksStack.addArrangedSubview(rowStack)

            let label = UILabel()
            label.text = "w\(i + 1)"
            label.font = .systemFont(ofSize: 14)
            weekLabels.addArrangedSubview(label)
        }

        let container = UIStackView(arrangedSubviews: [weeksStack, weekLabels])
        container.axis = .horizontal
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false

        heatmapContainer.subviews.forEach { $0.removeFromSuperview() }
        heatmapContainer.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: heatmapContainer.topAnchor),
            container.leadingAnchor.constraint(equalTo: heatmapContainer.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: heatmapContainer.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: heatmapContainer.bottomAnchor)
        ])


        animateHeatmap()
    }
    
    private func animateHeatmap() {
        for (i, cell) in heatmapCells.enumerated() {
            UIView.animate(
                withDuration: 0.30,
                delay: 0.02 * Double(i),
                options: .curveEaseOut,
                animations: {
                    cell.alpha = 1
                }
            )
        }
    }



    private func isSameDay(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    private func updateProgressFor(month base: Date) {
        // appointments scheduled in this month
        guard let monthInterval = calendar.dateInterval(of: .month, for: base) else { return }
        let appointmentsInMonth = appointments.filter { $0.date >= monthInterval.start && $0.date < monthInterval.end }

        // attended: appointments in the month whose date < now (we treat as attended)
        let attended = appointmentsInMonth.filter { $0.date < Date() }.count
        let totalScheduled = appointmentsInMonth.count

        let percent: CGFloat
        if totalScheduled == 0 {
            percent = 0
        } else {
            percent = CGFloat(attended) / CGFloat(max(1, totalScheduled))
        }

        progressRing.setProgress(percent)
        let percentInt = Int(round(percent * 100))
        progressRing.centerLabelText = "\(percentInt)%"
        progressMessageLabel.text = (percentInt >= 50) ? "You're staying consistent" : "Keep improving consistency"
        progressSubtitleLabel.text = "keep up this steady progress!"
    }
}

// MARK: - CircularProgressView (simple)
final class AppointmentCircularProgressView: UIView {
    private let shapeLayer = CAShapeLayer()
    private let bgLayer = CAShapeLayer()
    private let label = UILabel()

    var centerLabelText: String? {
        didSet { label.text = centerLabelText }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupLayers()
        setupLabel()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
        setupLabel()
    }

    private func setupLabel() {
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func setupLayers() {
        bgLayer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.2).cgColor
        bgLayer.fillColor = UIColor.clear.cgColor
        bgLayer.lineWidth = 8
        layer.addSublayer(bgLayer)

        shapeLayer.strokeColor = UIColor.systemGreen.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 8
        shapeLayer.lineCap = .round
        shapeLayer.strokeEnd = 0
        layer.addSublayer(shapeLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - shapeLayer.lineWidth/2
        let startAngle = -CGFloat.pi / 2 // top
        let endAngle = startAngle + 2 * CGFloat.pi
        let path = UIBezierPath(arcCenter: center,
                                radius: radius,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)
        bgLayer.path = path.cgPath
        shapeLayer.path = path.cgPath
    }

    func setProgress(_ pct: CGFloat) {
        let to = min(max(pct, 0), 1.0)
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.45)
        shapeLayer.strokeEnd = to
        CATransaction.commit()
    }
}

// MARK: - Appointment Heatmap Status

enum AppointmentHeatmapStatus {
    case attended
    case missed
    case noSession
    case future

    var color: UIColor {
        switch self {
        case .attended: return UIColor.systemGreen
        case .missed: return UIColor.systemRed
        case .noSession: return UIColor.systemGray4
        case .future: return UIColor.systemGray5
        }
    }
}

// MARK: - Appointment Heatmap Cell

final class AppointmentHeatmapCellView: UIView {
    init(status: AppointmentHeatmapStatus) {
        super.init(frame: .zero)
        backgroundColor = status.color
        layer.cornerRadius = 8
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

// MARK: - DayCell
final class DayCell: UIView {
    enum Status {
        case attended
        case missed
        case noSession
    }
    private let circle = UIView()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        circle.layer.cornerRadius = 18
        circle.translatesAutoresizingMaskIntoConstraints = false

        addSubview(circle)
        addSubview(label)

        NSLayoutConstraint.activate([
            circle.centerXAnchor.constraint(equalTo: centerXAnchor),
            circle.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            circle.widthAnchor.constraint(equalToConstant: 36),
            circle.heightAnchor.constraint(equalToConstant: 36),

            label.topAnchor.constraint(equalTo: circle.bottomAnchor, constant: 4),
            label.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    func configure(day: Int, status: Status) {
        label.text = "\(day)"
        switch status {
        case .attended:
            circle.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.85)
            label.textColor = .black
        case .missed:
            circle.backgroundColor = UIColor.systemRed.withAlphaComponent(0.85)
            label.textColor = .black
        case .noSession:
            circle.backgroundColor = UIColor.systemGray4
            label.textColor = .black
        }
    }

    func configureEmpty() {
        label.text = ""
        circle.backgroundColor = .clear
    }

    
}
