//
//  AddAppointmentViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 25/11/25.
//


import UIKit

final class AddAppointmentViewController: UIViewController, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {

    // Callback to refresh list when saved
    var onSave: (() -> Void)?

    // UI Elements
    private let hospitalField = UITextField()
    private let calendarView = UICalendarView()
    private let timePicker = UIDatePicker()
    private var selectedDate: Date?
    private var selectedTime: Date = Date()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.systemGray6
        setupNavigationBar()
        setupUI()
    }

    // MARK: - Navigation Bar
    private func setupNavigationBar() {
        title = "Add Appointment"

        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backButton.tintColor = UIColor.systemGreen
        navigationItem.leftBarButtonItem = backButton
    }

    @objc private func backTapped() {
        dismiss(animated: true)
    }

    // MARK: - UI Setup
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
        
        hospitalField.tintColor = .systemGreen
        timePicker.tintColor = .systemGreen
        calendarView.tintColor = .systemGreen

        // ------------- Hospital Name Card -------------
        let hospitalCard = createCard()
        content.addSubview(hospitalCard)

        let hospitalTitle = UILabel()
        hospitalTitle.text = "Hospital Name"
        hospitalTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        hospitalTitle.translatesAutoresizingMaskIntoConstraints = false
        hospitalCard.addSubview(hospitalTitle)

        hospitalField.placeholder = "Enter hospital name"
        hospitalField.font = .systemFont(ofSize: 16)
        hospitalField.translatesAutoresizingMaskIntoConstraints = false
        hospitalCard.addSubview(hospitalField)

        let divider = UIView()
        divider.backgroundColor = .lightGray
        divider.translatesAutoresizingMaskIntoConstraints = false
        hospitalCard.addSubview(divider)

        NSLayoutConstraint.activate([
            hospitalCard.topAnchor.constraint(equalTo: content.topAnchor, constant: 30),
            hospitalCard.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            hospitalCard.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            hospitalCard.heightAnchor.constraint(equalToConstant: 135),

            hospitalTitle.topAnchor.constraint(equalTo: hospitalCard.topAnchor, constant: 16),
            hospitalTitle.leadingAnchor.constraint(equalTo: hospitalCard.leadingAnchor, constant: 16),

            hospitalField.topAnchor.constraint(equalTo: hospitalTitle.bottomAnchor, constant: 20),
            hospitalField.leadingAnchor.constraint(equalTo: hospitalCard.leadingAnchor, constant: 16),
            hospitalField.trailingAnchor.constraint(equalTo: hospitalCard.trailingAnchor, constant: -16),

            divider.topAnchor.constraint(equalTo: hospitalField.bottomAnchor, constant: 14),
            divider.leadingAnchor.constraint(equalTo: hospitalCard.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: hospitalCard.trailingAnchor, constant: -16),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])

        // ------------- Calendar Card -------------
        let calendarCard = createCard()
        content.addSubview(calendarCard)
        let selection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = selection


        let calendarTitle = UILabel()
        calendarTitle.text = "Select Date"
        calendarTitle.font = .systemFont(ofSize: 16, weight: .semibold)
        calendarTitle.translatesAutoresizingMaskIntoConstraints = false
        calendarCard.addSubview(calendarTitle)

        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.layer.cornerRadius = 16
        calendarView.clipsToBounds = true
        calendarView.delegate = self
        calendarCard.addSubview(calendarView)

        NSLayoutConstraint.activate([
            calendarCard.topAnchor.constraint(equalTo: hospitalCard.bottomAnchor, constant: 20),
            calendarCard.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            calendarCard.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            calendarCard.heightAnchor.constraint(equalToConstant: 380),

            calendarTitle.topAnchor.constraint(equalTo: calendarCard.topAnchor, constant: 16),
            calendarTitle.leadingAnchor.constraint(equalTo: calendarCard.leadingAnchor, constant: 16),

            calendarView.topAnchor.constraint(equalTo: calendarTitle.bottomAnchor, constant: 10),
            calendarView.leadingAnchor.constraint(equalTo: calendarCard.leadingAnchor, constant: 10),
            calendarView.trailingAnchor.constraint(equalTo: calendarCard.trailingAnchor, constant: -10),
            calendarView.bottomAnchor.constraint(equalTo: calendarCard.bottomAnchor, constant: -10)
        ])

        // ------------- Time Picker Card -------------
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
            timeCard.topAnchor.constraint(equalTo: calendarCard.bottomAnchor, constant: 10),
            timeCard.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            timeCard.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            timeCard.heightAnchor.constraint(equalToConstant: 100),

            timeTitle.topAnchor.constraint(equalTo: timeCard.topAnchor, constant: 20),
            timeTitle.leadingAnchor.constraint(equalTo: timeCard.leadingAnchor, constant: 16),

            timePicker.trailingAnchor.constraint(equalTo: timeCard.trailingAnchor, constant: -16),
            timePicker.centerYAnchor.constraint(equalTo: timeTitle.centerYAnchor)
        ])


        // ------------- Add Button -------------
        let addButton = UIButton(type: .system)
        addButton.setTitle("Add Appointment", for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        addButton.backgroundColor = UIColor.systemGreen
        addButton.tintColor = .white
        addButton.layer.cornerRadius = 25
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        content.addSubview(addButton)

        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: timeCard.bottomAnchor, constant: 40),
            addButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            addButton.heightAnchor.constraint(equalToConstant: 55),
            addButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20)
        ])
    }

    private func createCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }

    // MARK: - Time Picker
    @objc private func timeChanged(_ sender: UIDatePicker) {
        selectedTime = sender.date
    }

    // MARK: - Save Appointment
    @objc private func saveTapped() {
        guard let hospital = hospitalField.text, !hospital.isEmpty else {
            showError("Please enter a hospital name.")
            return
        }

        guard let date = selectedDate else {
            showError("Please select a date.")
            return
        }

        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute], from: selectedTime)

        guard let finalDate = calendar.date(
            bySettingHour: time.hour ?? 9,
            minute: time.minute ?? 0,
            second: 0,
            of: date
        ) else { return }

        let newAppointment = Appointment(
            id: UUID(),
            hospitalName: hospital,
            date: finalDate,
            notes: nil
        )

        AppointmentStore.shared.addAppointment(newAppointment)

        NotificationCenter.default.post(name: .appointmentsChanged, object: nil)
        onSave?()
        dismiss(animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Missing Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Calendar Delegate Methods
    func calendarView(_ calendarView: UICalendarView, didSelectDate dateComponents: DateComponents?) {
        if let comps = dateComponents,
           let date = Calendar.current.date(from: comps) {
            selectedDate = date
        }
    }

    func dateSelection(_ selection: UICalendarSelectionSingleDate,
                       didSelectDate dateComponents: DateComponents?) {
        if let comps = dateComponents,
           let date = Calendar.current.date(from: comps) {
            selectedDate = date
        }
    }

}




