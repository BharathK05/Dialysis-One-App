//
//  TermsViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 18/11/25.
//

import UIKit

final class TermsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGray6
        //title = "Terms & Conditions"

        // REMOVE Back Button
        navigationItem.hidesBackButton = true

        setupScrollContent()
    }

    private func setupScrollContent() {

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false

        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -40),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        let header = UILabel()
        header.text = "Terms & Conditions"
        header.font = UIFont.boldSystemFont(ofSize: 22)
        header.textColor = .label
        header.textAlignment = .center

        let text = UILabel()
        text.font = UIFont.systemFont(ofSize: 16)
        text.numberOfLines = 0
        text.textColor = .darkGray
        text.text =
        """
        By using the Dialysis One app, you agree to follow these terms and conditions.

        The app provides tools for fluid tracking, medication scheduling, and health monitoring. It is not a substitute for medical diagnosis or professional healthcare advice.

        You are responsible for ensuring the accuracy of the data you input. The app is provided “as-is” without warranties of any kind.

        We reserve the right to update features, modify services, or revise these terms at any time.

        Placeholder content — final legal terms will be added later.
        """
        
        text.textAlignment = .justified

        content.addArrangedSubview(header)
        content.addArrangedSubview(text)
    }
}

