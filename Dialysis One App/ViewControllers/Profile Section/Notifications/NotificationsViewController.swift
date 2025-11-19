//
//  NotificationsViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 18/11/25.
//

import UIKit

final class NotificationsViewController: UIViewController {

    private let scroll = UIScrollView()
    private let content = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGray6
        title = "Notifications"
        navigationItem.leftBarButtonItem = nil

        setupUI()
    }

    // MARK: - UI Layout
    private func setupUI() {

        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        content.axis = .vertical
        content.spacing = 14
        content.translatesAutoresizingMaskIntoConstraints = false
        content.isLayoutMarginsRelativeArrangement = true

        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        // ---- Sections ----
        addDietSection()
        addFluidsSection()
        addMedicationsSection()
    }

    // MARK: - Sections

    private func addDietSection() {
        content.addArrangedSubview(makeHeader("Diet"))

        // Card — Timely Diet Reminder
        let dietCard = makeCard()
        dietCard.addArrangedSubview(makeToggleRow(title: "Timely Diet Reminder", isOn: true))
        content.addArrangedSubview(dietCard)

        // Description OUTSIDE card
        content.addArrangedSubview(makeDescription("Dialysis One will notify you when it’s time for your Meal."))

        // Card — When to Notify
        let whenCard = makeCard()
        whenCard.addArrangedSubview(makeNavRow(title: "When to Notify", action: #selector(openWhenToNotify)))
        content.addArrangedSubview(whenCard)
    }

    private func addFluidsSection() {
        content.addArrangedSubview(makeHeader("Fluids"))

        let fluidCard = makeCard()
        fluidCard.addArrangedSubview(makeToggleRow(title: "Alerts", isOn: true))
        content.addArrangedSubview(fluidCard)

        content.addArrangedSubview(makeDescription("Dialysis One will alert you if you exceed the fluid limit."))
    }

    private func addMedicationsSection() {
        content.addArrangedSubview(makeHeader("Medications"))

        // Dose Reminder
        let doseCard = makeCard()
        doseCard.addArrangedSubview(makeToggleRow(title: "Dose Reminder", isOn: true))
        content.addArrangedSubview(doseCard)

        content.addArrangedSubview(makeDescription("Dialysis One will remind you when it's time to take the medications on your schedule."))

        // Follow-Up Reminder
        let followCard = makeCard()
        followCard.addArrangedSubview(makeToggleRow(title: "Follow-Up Reminder", isOn: true))
        content.addArrangedSubview(followCard)

        content.addArrangedSubview(makeDescription("Dialysis One can send follow-up reminders if you haven’t logged a medication 30 minutes after the initial notification."))
    }


    // MARK: - Components

    private func makeHeader(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .darkGray
        return label
    }

    private func makeCard() -> UIStackView {
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 8
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layoutMargins = UIEdgeInsets(top: 14, left: 13, bottom: 14, right: 13)
        v.isLayoutMarginsRelativeArrangement = true
        return v
    }


    private func makeToggleRow(title: String, isOn: Bool) -> UIView {
        let row = UIView()
        row.heightAnchor.constraint(equalToConstant: 30).isActive = true

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16)

        let toggle = UISwitch()
        toggle.isOn = isOn

        label.translatesAutoresizingMaskIntoConstraints = false
        toggle.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(label)
        row.addSubview(toggle)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            toggle.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            toggle.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    private func makeDescription(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .gray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }


    private func makeNavRow(title: String, action: Selector) -> UIView {
        let row = UIView()
        row.heightAnchor.constraint(equalToConstant: 30).isActive = true
        row.isUserInteractionEnabled = true
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16)

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .systemGray3

        label.translatesAutoresizingMaskIntoConstraints = false
        arrow.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(label)
        row.addSubview(arrow)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            arrow.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            arrow.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    // MARK: - Navigation

    @objc private func openWhenToNotify() {
        let vc = WhenToNotifyViewController()

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }

        present(nav, animated: true)
    }
}
