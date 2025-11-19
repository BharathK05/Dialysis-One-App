//
//  EditLimitsViewController.swift
//  Dialysis One App
//

import UIKit

class EditLimitsViewController: UIViewController {

    private let scroll = UIScrollView()
    private let content = UIStackView()

    // Stored values
    private var limits: [String: String] = [
        "Total Calorie": "2000 kcal",
        "Sodium": "70 mg",
        "Potassium": "90 mg",
        "Protein": "110 gm",
        "Total Intake": "250 ml"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupUI()
    }

    // MARK: - Nav Bar
    private func setupNavBar() {
        title = "Edit Limits"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(saveAndDismiss)
        )
    }

    @objc private func saveAndDismiss() {
        dismiss(animated: true)
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 28
        view.clipsToBounds = true

        // Grabber
        let grabber = UIView()
        grabber.translatesAutoresizingMaskIntoConstraints = false
        grabber.backgroundColor = UIColor.systemGray4
        grabber.layer.cornerRadius = 2
        view.addSubview(grabber)

        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            grabber.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 36),
            grabber.heightAnchor.constraint(equalToConstant: 4)
        ])

        // ScrollView
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 10),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Content stack
        content.axis = .vertical
        content.spacing = 22
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 50),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        // SECTIONS
        content.addArrangedSubview(makeSectionHeader("Diet"))
        content.addArrangedSubview(makeEditableCard([
            "Total Calorie",
            "Sodium",
            "Potassium",
            "Protein"
        ]))

        content.addArrangedSubview(makeSectionHeader("Fluid"))
        content.addArrangedSubview(makeEditableCard(["Total Intake"]))
        
        content.addArrangedSubview(makeSectionHeader("Medication"))
        content.addArrangedSubview(makeNavigationCard("Edit Medicines"))
    }

    // MARK: - Section Header
    private func makeSectionHeader(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - Editable Card
    private func makeEditableCard(_ items: [String]) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false

        var lastRow: UIView?

        for (index, title) in items.enumerated() {

            let row = UIView()
            row.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(row)

            let label = UILabel()
            label.text = title
            label.font = UIFont.systemFont(ofSize: 17)
            label.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(label)

            let valueLabel = UILabel()
            valueLabel.text = limits[title]
            valueLabel.textColor = .systemGray
            valueLabel.font = UIFont.systemFont(ofSize: 16)
            valueLabel.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(valueLabel)

            let editIcon = UIImageView(image: UIImage(systemName: "square.and.pencil"))
            editIcon.tintColor = .systemBlue
            editIcon.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(editIcon)

            // Button on row
            let button = UIButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tag = index
            button.addAction(UIAction(handler: { _ in
                self.showEditPopup(title: title)
            }), for: .touchUpInside)
            row.addSubview(button)

            // Layout
            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                row.heightAnchor.constraint(equalToConstant: 52),

                label.centerYAnchor.constraint(equalTo: row.centerYAnchor),

                editIcon.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                editIcon.centerYAnchor.constraint(equalTo: row.centerYAnchor),

                valueLabel.trailingAnchor.constraint(equalTo: editIcon.leadingAnchor, constant: -8),
                valueLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

                button.topAnchor.constraint(equalTo: row.topAnchor),
                button.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                button.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: row.trailingAnchor)
            ])

            if let previous = lastRow {
                row.topAnchor.constraint(equalTo: previous.bottomAnchor).isActive = true
            } else {
                row.topAnchor.constraint(equalTo: card.topAnchor).isActive = true
            }

            // Divider
            if index < items.count - 1 {
                let divider = UIView()
                divider.backgroundColor = UIColor.systemGray5
                divider.translatesAutoresizingMaskIntoConstraints = false
                card.addSubview(divider)

                NSLayoutConstraint.activate([
                    divider.topAnchor.constraint(equalTo: row.bottomAnchor),
                    divider.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
                    divider.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
                    divider.heightAnchor.constraint(equalToConstant: 1)
                ])
            }

            lastRow = row
        }

        lastRow?.bottomAnchor.constraint(equalTo: card.bottomAnchor).isActive = true

        return card
    }
    
    // MARK: - Navigation Card (Edit Medicines)
    private func makeNavigationCard(_ title: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 55).isActive = true

        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(label)

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .systemGray3
        arrow.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(arrow)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            arrow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            arrow.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        // Make whole card tappable
        let tap = UITapGestureRecognizer(target: self, action: #selector(openEditMedicines))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true

        return card
    }
    
    @objc private func openEditMedicines() {
        let vc = EditMedicinesViewController()

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet

        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }

        present(nav, animated: true)
    }



    // MARK: - Value Editing Popup
    private func showEditPopup(title: String) {

        let current = limits[title] ?? ""
        let numberOnly = current.components(separatedBy: " ").first ?? ""

        let suffix = current.components(separatedBy: " ").last ?? ""

        let alert = UIAlertController(title: title, message: "Enter new value", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.keyboardType = .numberPad
            textField.text = numberOnly   // only numeric part
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            guard let newVal = alert.textFields?.first?.text, !newVal.isEmpty else { return }

            self?.limits[title] = "\(newVal) \(suffix)"
            self?.reload()
        }))

        present(alert, animated: true)
    }

    private func reload() {
        content.arrangedSubviews.forEach { $0.removeFromSuperview() }
        setupUI()
    }
}
