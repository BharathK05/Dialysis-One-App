//
//  WhenToNotifyViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 18/11/25.
//

import UIKit

final class WhenToNotifyViewController: UIViewController {

    private let types = ["Breakfast", "Lunch", "Dinner"]
    private var selectedType = "Breakfast"

    private let timePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .time
        dp.preferredDatePickerStyle = .compact
        dp.translatesAutoresizingMaskIntoConstraints = false
        return dp
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGray6
        title = "When to Notify"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(done)
        )

        setupUI()
    }

    @objc private func done() {
        dismiss(animated: true)
    }

    private func setupUI() {

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            card.heightAnchor.constraint(equalToConstant: 120)
        ])

        // Type Row
        let typeRow = makeRow(title: "Type", value: selectedType)
        typeRow.tag = 100
        typeRow.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(openTypePicker)
        ))

        // Time Row
        let timeRow = UIView()
        timeRow.translatesAutoresizingMaskIntoConstraints = false

        let timeLabel = UILabel()
        timeLabel.text = "Time"
        timeLabel.font = UIFont.systemFont(ofSize: 16)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        timeRow.addSubview(timeLabel)
        timeRow.addSubview(timePicker)

        NSLayoutConstraint.activate([
            timeLabel.leadingAnchor.constraint(equalTo: timeRow.leadingAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: timeRow.centerYAnchor),

            timePicker.trailingAnchor.constraint(equalTo: timeRow.trailingAnchor),
            timePicker.centerYAnchor.constraint(equalTo: timeRow.centerYAnchor)
        ])

        // Stack rows
        let stack = UIStackView(arrangedSubviews: [typeRow, timeRow])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
    }

    private func makeRow(title: String, value: String) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 16)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 16)
        valueLabel.textColor = .systemGray

        let arrow = UIImageView(image: UIImage(systemName: "chevron.down"))
        arrow.tintColor = .systemGray3

        label.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        arrow.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(label)
        row.addSubview(valueLabel)
        row.addSubview(arrow)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            arrow.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            arrow.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            valueLabel.trailingAnchor.constraint(equalTo: arrow.leadingAnchor, constant: -6),
            valueLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    @objc private func openTypePicker() {
        let alert = UIAlertController(title: "Meal Type", message: nil, preferredStyle: .actionSheet)

        types.forEach { type in
            alert.addAction(UIAlertAction(title: type, style: .default, handler: { _ in
                self.selectedType = type
                self.viewDidLoad() // refresh UI (quick approach)
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
