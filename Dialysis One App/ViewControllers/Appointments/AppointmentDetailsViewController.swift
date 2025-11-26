//
//  AppointmentDetailsViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 20/11/25.
//

import UIKit

final class AppointmentDetailsViewController: UIViewController {

    private var tableView: UITableView!
    private var appointments: [Appointment] = []
    private var upcoming: [Appointment] = []
    private var past: [Appointment] = []

    private let summaryContainer = UIStackView()
    private let listTitleLabel = UILabel()
    private let dialysisButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.systemGray6
        title = "Appointments"

        setupNavigationBar()
        setupSummaryCards()
        setupListTitle()
        setupTableView()
        setupDialysisButton()

        loadAppointments()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAppointmentsChanged),
            name: .appointmentsChanged,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAppointments()
    }

    // MARK: - NAV BAR
    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(false, animated: false)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Add",
            style: .plain,
            target: self,
            action: #selector(addTapped)
        )
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func addTapped() {
        let addVC = AddAppointmentViewController()
        addVC.onSave = { [weak self] in
            self?.loadAppointments()
            NotificationCenter.default.post(name: .appointmentsChanged, object: nil)
        }

        let nav = UINavigationController(rootViewController: addVC)
        present(nav, animated: true)
    }

    // MARK: - Load Appointments
    private func loadAppointments() {
        appointments = AppointmentStore.shared.loadAppointments()

        upcoming = appointments.filter { $0.date >= Date() }.sorted { $0.date < $1.date }
        past = appointments.filter { $0.date < Date() }.sorted { $0.date > $1.date }

        updateSummaryCards()
        tableView.reloadData()
    }

    @objc private func onAppointmentsChanged() {
        loadAppointments()
    }

    // MARK: - SUMMARY CARDS (TOP)
    private func setupSummaryCards() {
        summaryContainer.axis = .horizontal
        summaryContainer.spacing = 16
        summaryContainer.distribution = .fillEqually
        summaryContainer.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(summaryContainer)

        NSLayoutConstraint.activate([
            summaryContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            summaryContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            summaryContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            summaryContainer.heightAnchor.constraint(equalToConstant: 110)
        ])
    }

    private func updateSummaryCards() {
        summaryContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let upcomingCard = SummaryCardView(
            icon: UIImage(systemName: "clock")!,
            iconTint: .systemGreen,
            count: upcoming.count,
            title: "Upcoming"
        )

        let pastCard = SummaryCardView(
            icon: UIImage(systemName: "checkmark")!,
            iconTint: .systemGreen,
            count: past.count,
            title: "Past"
        )

        summaryContainer.addArrangedSubview(upcomingCard)
        summaryContainer.addArrangedSubview(pastCard)
    }

    // MARK: - LIST TITLE
    private func setupListTitle() {
        listTitleLabel.text = "List of Appointments"
        listTitleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        listTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(listTitleLabel)

        NSLayoutConstraint.activate([
            listTitleLabel.topAnchor.constraint(equalTo: summaryContainer.bottomAnchor, constant: 28),
            listTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }

    // MARK: - TABLE VIEW
    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(AppointmentCell.self, forCellReuseIdentifier: "AppointmentCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 80
        tableView.backgroundColor = .clear

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: listTitleLabel.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -120)
        ])
    }
    
    @objc private func openDialysisSummary() {
        let summaryVC = DialysisSummaryViewController()
        navigationController?.pushViewController(summaryVC, animated: true)
    }


    // MARK: - DIALYSIS BUTTON
    private func setupDialysisButton() {
        dialysisButton.setTitle("View Dialysis Summary", for: .normal)
        dialysisButton.setTitleColor(.white, for: .normal)
        dialysisButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        dialysisButton.backgroundColor = .systemGreen
        dialysisButton.layer.cornerRadius = 16
        dialysisButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(dialysisButton)
        
        dialysisButton.addTarget(self, action: #selector(openDialysisSummary), for: .touchUpInside)

        NSLayoutConstraint.activate([
            dialysisButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dialysisButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            dialysisButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            dialysisButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
}



// MARK: - TableView DataSource/Delegate
extension AppointmentDetailsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (section == 0 ? upcoming.count : past.count)
    }

    func numberOfSections(in tableView: UITableView) -> Int { return 2 }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Upcoming" : "Past"
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "AppointmentCell", for: indexPath) as! AppointmentCell

        let appointment = (indexPath.section == 0) ? upcoming[indexPath.row] : past[indexPath.row]

        cell.configure(with: appointment, isUpcoming: indexPath.section == 0)

        return cell
    }

    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            let appointment = indexPath.section == 0 ? upcoming[indexPath.row] : past[indexPath.row]
            AppointmentStore.shared.delete(appointment.id)
            NotificationCenter.default.post(name: .appointmentsChanged, object: nil)
            loadAppointments()
        }
    }
}

//
// MARK: - SummaryCardView
//
final class SummaryCardView: UIView {

    init(icon: UIImage, iconTint: UIColor, count: Int, title: String) {
        super.init(frame: .zero)

        backgroundColor = UIColor.white.withAlphaComponent(0.6)
        layer.cornerRadius = 22

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blur.frame = bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        layer.masksToBounds = true
        addSubview(blur)

        let iconView = UIImageView(image: icon)
        iconView.tintColor = iconTint
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let countLabel = UILabel()
        countLabel.text = "\(count)"
        countLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        countLabel.textAlignment = .center

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .darkGray
        titleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [iconView, countLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        iconView.heightAnchor.constraint(equalToConstant: 28).isActive = true
        iconView.widthAnchor.constraint(equalToConstant: 28).isActive = true
    }

    required init?(coder: NSCoder) { fatalError() }
}

//
// MARK: - Appointment Cell
//
final class AppointmentCell: UITableViewCell {

    private let iconView = UIImageView()
    private let hospitalLabel = UILabel()
    private let dateLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .none

        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)

        hospitalLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        hospitalLabel.translatesAutoresizingMaskIntoConstraints = false

        dateLabel.font = .systemFont(ofSize: 14)
        dateLabel.textColor = .darkGray
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        timeLabel.font = .systemFont(ofSize: 14)
        timeLabel.textColor = .darkGray
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(hospitalLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            hospitalLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            hospitalLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            dateLabel.leadingAnchor.constraint(equalTo: hospitalLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: hospitalLabel.bottomAnchor, constant: 4),

            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            timeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with appointment: Appointment, isUpcoming: Bool) {
        hospitalLabel.text = appointment.hospitalName
        dateLabel.text = appointment.date.formatted(date: .long, time: .omitted)
        timeLabel.text = appointment.date.formatted(date: .omitted, time: .shortened)

        if isUpcoming {
            iconView.image = UIImage(systemName: "clock.circle.fill")
            iconView.tintColor = .systemGreen
        } else {
            iconView.image = UIImage(systemName: "checkmark.circle.fill")
            iconView.tintColor = .systemGray3
        }
    }

    required init?(coder: NSCoder) { fatalError() }
}


extension Notification.Name {
    static let appointmentsChanged = Notification.Name("appointmentsChanged")
}

