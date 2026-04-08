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

        let text = UITextView()
        text.backgroundColor = .clear
        text.isEditable = false
        text.isScrollEnabled = false
        text.font = UIFont.systemFont(ofSize: 16)
        text.textColor = .darkGray
        
        let linkText = "The privacy policy is in this link: https://dialysisone.vercel.app/privacy"
        let attributedString = NSMutableAttributedString(string: linkText)
        let linkRange = (linkText as NSString).range(of: "https://dialysisone.vercel.app/privacy")
        attributedString.addAttribute(.link, value: "https://dialysisone.vercel.app/privacy", range: linkRange)
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSRange(location: 0, length: linkText.count))
        
        text.attributedText = attributedString
        text.textAlignment = .center
        text.linkTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        text.translatesAutoresizingMaskIntoConstraints = false

        content.addArrangedSubview(header)
        content.addArrangedSubview(text)
    }
}


