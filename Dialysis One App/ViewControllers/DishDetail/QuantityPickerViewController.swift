//
//  QuantityPickerViewController.swift
//  Dialysis One App
//
//  Created by user@1 on 22/01/26.
//


import UIKit

final class QuantityPickerViewController: UIViewController {

    var options: [Double] = []
    var selectedValue: Double = 1.0
    var portionType: String = ""
    var onSelect: ((Double) -> Void)?

    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTable()
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

extension QuantityPickerViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let value = options[indexPath.row]
        cell.textLabel?.text = portionType == "BOWL"
            ? String(format: "%.1f", value)
            : String(format: "%.0f", value)

        if value == selectedValue {
            cell.accessoryType = .checkmark
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let value = options[indexPath.row]
        onSelect?(value)
        dismiss(animated: true)
    }
}
