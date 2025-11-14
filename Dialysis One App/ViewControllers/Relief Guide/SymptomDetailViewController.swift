//
//  SymptomDetailViewController.swift
//  ReliefGuide
//
//  Created by user@100 on 12/11/25.
//

import UIKit

final class SymptomDetailViewController: UIViewController {

    var symptom: SymptomDetail!   // set this before pushing

    // UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground   // gradient sits behind if you add one
        navigationItem.title = symptom.title

        buildLayout()
        populate()
    }

    private func buildLayout() {
        // Scroll view + content view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)  // allow under home indicator
        ])

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        // Vertical stack in content view
        contentView.addSubview(stack)
        stack.axis = .vertical
        stack.spacing = 40  // ⬅️ increase spacing between each section
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),    // ⬅️ more top padding
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -60) // ⬅️ more bottom padding
        ])
    }

    private func populate() {
        // Reason heading
        let reasonHeader = makeSectionHeader("Reason")
        stack.addArrangedSubview(reasonHeader)

        // Reason card
        let reasonCard = makeCardLabel(text: symptom.reason)
        stack.addArrangedSubview(reasonCard)

        // Cure heading
        let cureHeader = makeSectionHeader("Cure")
        stack.addArrangedSubview(cureHeader)

        // Cure list
        let cureList = UIStackView()
        cureList.axis = .vertical
        cureList.spacing = 16
        stack.addArrangedSubview(cureList)

        symptom.cures.forEach { item in
            cureList.addArrangedSubview(makeCureRow(text: item.text, isGood: item.isGood))
        }
    }

    // MARK: - Small UI helpers

    private func makeSectionHeader(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = UIColor(named: "AppGreen") ?? .systemGreen
        return label
    }

    private func makeCardLabel(text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 22

        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 17)
        label.textColor = .label

        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])
        return container
    }

    private func makeCureRow(text: String, isGood: Bool) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 16

        let icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true
        icon.contentMode = .scaleAspectFit
        icon.image = UIImage(systemName: isGood ? "checkmark.circle.fill" : "xmark.circle.fill")
        icon.tintColor = isGood ? (UIColor(named: "AppGreen") ?? .systemGreen) : .systemRed

        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textColor = .secondaryLabel

        row.addArrangedSubview(icon)
        row.addArrangedSubview(label)
        return row
    }
}
