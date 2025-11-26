//
//  EditAppointmentViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 26/11/25.
//

import UIKit

final class EditAppointmentViewController: UIViewController, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate{

    var appointment: Appointment
    var onSave: (() -> Void)?

    private let hospitalField = UITextField()
    private let calendarView = UICalendarView()
    private let timePicker = UIDatePicker()

    private var selectedDate: Date
    private var selectedTime: Date

    init(appointment: Appointment) {
        self.appointment = appointment
        self.selectedDate = appointment.date
        self.selectedTime = appointment.date
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGray6
        title = "Edit Appointment"

        setupNav()
        setupUI()
        prefill()
    }

    private func setupNav() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
    }

    @objc private func backTapped() { dismiss(animated: true) }

    private func setupUI() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scroll.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        // Hospital Name Card reused from AddAppointment (same code)
        let hospitalCard = createCard()
        content.addSubview(hospitalCard)

        let titleLabel = UILabel()
        titleLabel.text = "Hospital Name"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        hospitalCard.addSubview(titleLabel)

        hospitalField.font = .systemFont(ofSize: 16)
        hospitalField.translatesAutoresizingMaskIntoConstraints = false
        hospitalCard.addSubview(hospitalField)

        NSLayoutConstraint.activate([
            hospitalCard.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            hospitalCard.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            hospitalCard.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            hospitalCard.heightAnchor.constraint(equalToConstant: 120),

            titleLabel.topAnchor.constraint(equalTo: hospitalCard.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: hospitalCard.leadingAnchor, constant: 16),

            hospitalField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            hospitalField.leadingAnchor.constraint(equalTo: hospitalCard.leadingAnchor, constant: 16),
            hospitalField.trailingAnchor.constraint(equalTo: hospitalCard.trailingAnchor, constant: -16)
        ])

        // Calendar Card
        let calendarCard = createCard()
        content.addSubview(calendarCard)

        let calTitle = UILabel()
        calTitle.text = "Select Date"
        calTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        calTitle.translatesAutoresizingMaskIntoConstraints = false
        calendarCard.addSubview(calTitle)

        let selection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = selection
        calendarView.delegate = self
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarCard.addSubview(calendarView)

        NSLayoutConstraint.activate([
            calendarCard.topAnchor.constraint(equalTo: hospitalCard.bottomAnchor, constant: 20),
            calendarCard.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            calendarCard.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            calendarCard.heightAnchor.constraint(equalToConstant: 380),

            calTitle.topAnchor.constraint(equalTo: calendarCard.topAnchor, constant: 16),
            calTitle.leadingAnchor.constraint(equalTo: calendarCard.leadingAnchor, constant: 16),

            calendarView.topAnchor.constraint(equalTo: calTitle.bottomAnchor, constant: 10),
            calendarView.leadingAnchor.constraint(equalTo: calendarCard.leadingAnchor, constant: 10),
            calendarView.trailingAnchor.constraint(equalTo: calendarCard.trailingAnchor, constant: -10),
            calendarView.bottomAnchor.constraint(equalTo: calendarCard.bottomAnchor, constant: -10)
        ])

        // Time Card
        let timeCard = createCard()
        content.addSubview(timeCard)

        let timeTitle = UILabel()
        timeTitle.text = "Select Time"
        timeTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        timeTitle.translatesAutoresizingMaskIntoConstraints = false
        timeCard.addSubview(timeTitle)

        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .compact
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        timePicker.addTarget(self, action: #selector(timeChanged(_:)), for: .valueChanged)
        timeCard.addSubview(timePicker)

        NSLayoutConstraint.activate([
            timeCard.topAnchor.constraint(equalTo: calendarCard.bottomAnchor, constant: 20),
            timeCard.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            timeCard.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            timeCard.heightAnchor.constraint(equalToConstant: 90),

            timeTitle.topAnchor.constraint(equalTo: timeCard.topAnchor, constant: 16),
            timeTitle.leadingAnchor.constraint(equalTo: timeCard.leadingAnchor, constant: 16),

            timePicker.trailingAnchor.constraint(equalTo: timeCard.trailingAnchor, constant: -16),
            timePicker.centerYAnchor.constraint(equalTo: timeCard.centerYAnchor)
        ])

        // Save button
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save Changes", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        saveButton.backgroundColor = UIColor.systemGreen
        saveButton.tintColor = .white
        saveButton.layer.cornerRadius = 25
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        content.addSubview(saveButton)

        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: timeCard.bottomAnchor, constant: 40),
            saveButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 55),
            saveButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20)
        ])
    }

    private func createCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func prefill() {
        hospitalField.text = appointment.hospitalName
        timePicker.date = appointment.date

        // Pre-select date
        let comps = Calendar.current.dateComponents([.day, .month, .year], from: appointment.date)
        (calendarView.selectionBehavior as? UICalendarSelectionSingleDate)?
            .setSelected(comps, animated: false)
    }

    @objc private func timeChanged(_ sender: UIDatePicker) {
        selectedTime = sender.date
    }
    
    // MARK: - Calendar Delegate
    func dateSelection(_ selection: UICalendarSelectionSingleDate,
                       didSelectDate dateComponents: DateComponents?) {
        if let comps = dateComponents,
           let date = Calendar.current.date(from: comps) {
            selectedDate = date
        }
    }


    @objc private func saveTapped() {

        guard let hospital = hospitalField.text, !hospital.isEmpty else { return }

        let dateOnly = selectedDate   // <-- selectedDate is NOT Optional

        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: selectedTime)

        let finalDate = cal.date(
            bySettingHour: comps.hour ?? 9,
            minute: comps.minute ?? 0,
            second: 0,
            of: dateOnly
        )!

        let updated = Appointment(
            id: appointment.id,
            hospitalName: hospital,
            date: finalDate,
            notes: appointment.notes
        )

        AppointmentStore.shared.updateAppointment(updated)

        NotificationCenter.default.post(name: .appointmentsChanged, object: nil)
        onSave?()
        dismiss(animated: true)
    }

}
