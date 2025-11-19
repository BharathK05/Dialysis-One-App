//
//  EditMedicinesViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 18/11/25.
//

import UIKit

class EditMedicinesViewController: UIViewController {

    private let scroll = UIScrollView()
    private let content = UIStackView()

    // Static medications for now (will be replaced by Firebase later)
    private var meds: [String: [String]] = [
        "Morning": ["Tablet 1", "Tablet 2", "Tablet 3"],
        "Afternoon": ["Tablet 2", "Tablet 3", "Tablet 4"],
        "Evening": ["Tablet 1", "Tablet 3", "Tablet 4"]
    ]

    // Track selected med per section
    private var selected: [String: String?] = [
        "Morning": nil,
        "Afternoon": nil,
        "Evening": nil
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNav()
        setupUI()
    }

    // MARK: - NAV
    private func setupNav() {
        title = "Edit Medications"

        let removeBtn = UIBarButtonItem(
            title: "Remove",
            style: .plain,
            target: self,
            action: #selector(removeSelected)
        )
        removeBtn.tintColor = .systemRed   // 🔥 make red
        navigationItem.rightBarButtonItem = removeBtn
        
    }

    @objc private func removeSelected() {
        var removedAnything = false

        for (section, selectedName) in selected {
            if let selectedMed = selectedName {
                meds[section]?.removeAll(where: { $0 == selectedMed })
                selected[section] = nil
                removedAnything = true
            }
        }

        if !removedAnything {
            let alert = UIAlertController(title: "Nothing Selected",
                                          message: "Tap a medicine to select it before removing.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        reloadUI()
    }

    // MARK: - UI
    private func setupUI() {
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 28

        // Grabber
        let grabber = UIView()
        grabber.backgroundColor = .systemGray4
        grabber.layer.cornerRadius = 3
        grabber.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(grabber)

        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            grabber.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 36),
            grabber.heightAnchor.constraint(equalToConstant: 4)
        ])

        // Scroll
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 10),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Stack
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

        // Build sections
        buildSections()
    }

    private func buildSections() {
        content.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for section in ["Morning", "Afternoon", "Evening"] {
            content.addArrangedSubview(makeSectionHeader(section))
            content.addArrangedSubview(makeMedicineCard(section))
        }
    }

    private func reloadUI() {
        buildSections()
    }

    // MARK: - Section Header
    private func makeSectionHeader(_ title: String) -> UIView {
        let label = UILabel()
        label.text = title.uppercased()
        label.font = UIFont.boldSystemFont(ofSize: 13)
        label.textColor = .gray

        let view = UIView()
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            label.topAnchor.constraint(equalTo: view.topAnchor),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }

    // MARK: - Medicine Card
    private func makeMedicineCard(_ section: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false

        var lastRow: UIView?
        let items = meds[section] ?? []

        for (index, medName) in items.enumerated() {

            let row = UIView()
            row.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(row)

            // Radio Button
            let radio = UIImageView()
            radio.image = UIImage(systemName:
                selected[section] == medName ? "largecircle.fill.circle" : "circle"
            )
            radio.tintColor = selected[section] == medName ? .systemBlue : .gray
            radio.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(radio)

            // Medicine label
            let label = UILabel()
            label.text = medName
            label.font = UIFont.systemFont(ofSize: 17)
            label.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(label)

            // Click area
            let button = UIButton()
            button.tag = index
            button.addAction(UIAction(handler: { _ in
                self.selected[section] = medName
                self.reloadUI()
            }), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(button)

            // Layout
            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                row.heightAnchor.constraint(equalToConstant: 52),

                radio.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                radio.leadingAnchor.constraint(equalTo: row.leadingAnchor),

                label.leadingAnchor.constraint(equalTo: radio.trailingAnchor, constant: 12),
                label.centerYAnchor.constraint(equalTo: row.centerYAnchor),

                button.topAnchor.constraint(equalTo: row.topAnchor),
                button.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                button.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: row.trailingAnchor)
            ])

            if let prev = lastRow {
                row.topAnchor.constraint(equalTo: prev.bottomAnchor).isActive = true
            } else {
                row.topAnchor.constraint(equalTo: card.topAnchor).isActive = true
            }

            // Divider
            if index < items.count - 1 {
                let div = UIView()
                div.backgroundColor = .systemGray5
                div.translatesAutoresizingMaskIntoConstraints = false
                card.addSubview(div)

                NSLayoutConstraint.activate([
                    div.heightAnchor.constraint(equalToConstant: 1),
                    div.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
                    div.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
                    div.topAnchor.constraint(equalTo: row.bottomAnchor)
                ])
            }

            lastRow = row
        }

        lastRow?.bottomAnchor.constraint(equalTo: card.bottomAnchor).isActive = true
        return card
    }
}
