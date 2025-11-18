//
//  PrivacyPolicyViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 18/11/25.
//

import UIKit

final class PrivacyPolicyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGray6
        //title = "Privacy Policy"

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
            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 5),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -40),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        // Title Header Inside Page
        let header = UILabel()
        header.text = "Privacy Policy"
        header.font = UIFont.boldSystemFont(ofSize: 22)
        header.textColor = .label
        header.textAlignment = .center

        let text = UILabel()
        text.font = UIFont.systemFont(ofSize: 16)
        text.numberOfLines = 0
        text.textColor = .darkGray
        text.text =
        """
        Your privacy is important to us. This Privacy Policy outlines how your data is collected, used, and protected within the Dialysis One app.

        We collect information to improve your health tracking experience. This may include profile data, app usage analytics, and health-related inputs.

        Your information is never sold or shared with third-party advertisers. Data is securely stored and used only to enhance your app experience.

        You may request deletion of your data at any time through the app settings.

        This is placeholder content. A full legal privacy policy will be inserted later.
        """
        
        text.textAlignment = .justified

        content.addArrangedSubview(header)
        content.addArrangedSubview(text)
    }
}


