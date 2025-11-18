//
//  EditPinnedViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 18/11/25.
//

import UIKit

protocol EditPinnedDelegate: AnyObject {
    func didUpdatePinned(pinned: [String], others: [String])
}

final class EditPinnedViewController: UIViewController {

    weak var delegate: EditPinnedDelegate?

    // Data from Profile VC
    var pinned: [String] = []        // Example: ["Fluid Tracker"]
    var others: [String] = []        // Example: ["Calorie Tracker", "Medication"]

    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let pinnedStack = UIStackView()
    private let othersStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGray6
        navigationItem.hidesBackButton = true
        setupNavBar()
        setupUI()
        reloadUI()
        
    }

    // MARK: - Nav Bar
    private func setupNavBar() {
        title = "Edit Pinned"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(done)
        )
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    @objc private func done() {
        delegate?.didUpdatePinned(pinned: pinned, others: others)
        dismiss(animated: true)
    }

    // MARK: - UI Setup
    private func setupUI() {

        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        content.axis = .vertical
        content.spacing = 24
        content.translatesAutoresizingMaskIntoConstraints = false

        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        // Section headers
        let pinnedTitle = makeSectionTitle("Pinned")
        let othersTitle = makeSectionTitle("Others")

        pinnedStack.axis = .vertical
        pinnedStack.spacing = 10

        othersStack.axis = .vertical
        othersStack.spacing = 10

        content.addArrangedSubview(pinnedTitle)
        content.addArrangedSubview(pinnedStack)

        content.addArrangedSubview(othersTitle)
        content.addArrangedSubview(othersStack)
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .darkGray
        return label
    }

    // MARK: - Build List
    private func reloadUI() {
        pinnedStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        othersStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for item in pinned {
            pinnedStack.addArrangedSubview(makeRow(item: item, isPinned: true))
        }

        for item in others {
            othersStack.addArrangedSubview(makeRow(item: item, isPinned: false))
        }
    }

    private func makeRow(item: String, isPinned: Bool) -> UIView {

        let row = UIView()
        row.backgroundColor = .white
        row.layer.cornerRadius = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = isPinned ? .systemRed : .systemGreen
        icon.image = UIImage(systemName: isPinned ? "minus.circle.fill" : "plus.circle.fill")
        icon.widthAnchor.constraint(equalToConstant: 26).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 26).isActive = true

        let label = UILabel()
        label.text = item
        label.font = UIFont.systemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(icon)
        row.addSubview(label)

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 14),
            icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 14),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        // Button tap
        let tap = UITapGestureRecognizer(target: self, action: isPinned ? #selector(removePinned(_:)) : #selector(addPinned(_:)))
        row.addGestureRecognizer(tap)

        row.tag = item.hashValue
        return row
    }

    // MARK: - Row Actions
    @objc private func addPinned(_ g: UITapGestureRecognizer) {
        guard let row = g.view,
              let lbl = row.subviews.first(where: { $0 is UILabel }) as? UILabel,
              let item = lbl.text else { return }

        others.removeAll(where: { $0 == item })
        pinned.append(item)

        reloadUI()
    }

    @objc private func removePinned(_ g: UITapGestureRecognizer) {
        guard let row = g.view,
              let lbl = row.subviews.first(where: { $0 is UILabel }) as? UILabel,
              let item = lbl.text else { return }

        pinned.removeAll(where: { $0 == item })
        others.append(item)

        reloadUI()
    }
}
