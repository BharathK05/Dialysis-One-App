//
//  WelcomeFeaturesViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 26/11/25.
//

import UIKit
import FirebaseAuth

final class WelcomeFeaturesViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupScrollView()
        setupTitle()
        setupFeatureItems()
        setupGetStartedButton()
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 28
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48)
        ])
    }
    
    private func setupTitle() {
        let titleLabel = UILabel()
        titleLabel.text = "Welcome to Dialysis One"
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.numberOfLines = 0

        contentStack.addArrangedSubview(titleLabel)
    }

    private func setupFeatureItems() {
        let features: [(icon: String, title: String, subtitle: String)] = [
            (
                "fork.knife.circle.fill",
                "Machine-Learning Diet Tracking",
                "Analyze meals instantly using AI — get nutrient insights and dialysis-safe recommendations."
            ),
            (
                "drop.circle.fill",
                "Fluid & Medication Tracker",
                "Track daily fluid limits and get smart medication reminders to stay consistent."
            ),
            (
                "heart.circle.fill",
                "Health & Vitals Monitoring",
                "Monitor vitals with Apple Watch integration for real-time health tracking."
            )
        ]

        for f in features {
            contentStack.addArrangedSubview(makeFeatureRow(icon: f.icon, title: f.title, subtitle: f.subtitle))
        }
    }

    private func makeFeatureRow(icon: String, title: String, subtitle: String) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 16
        container.alignment = .top

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .systemGreen
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 6

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.numberOfLines = 0

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        container.addArrangedSubview(iconView)
        container.addArrangedSubview(textStack)

        return container
    }

    private func setupGetStartedButton() {
        let button = UIButton(type: .system)
        button.setTitle("Get Started", for: .normal)
        button.backgroundColor = .systemGreen
        button.tintColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        button.addTarget(self, action: #selector(onGetStarted), for: .touchUpInside)

        contentStack.addArrangedSubview(button)
    }

    @objc private func onGetStarted() {

        // Save first-launch flag
        if let user = Auth.auth().currentUser {
            let key = "featureIntroSeen_\(user.uid)"
            UserDefaults.standard.set(true, forKey: key)
        }

        // Move to next onboarding screen
        let onboardingVC = OnboardingViewController(
            nibName: "OnboardingViewController",
            bundle: nil
        )
        let nav = UINavigationController(rootViewController: onboardingVC)
        nav.setNavigationBarHidden(true, animated: false)

        // Change root
        if let window = view.window {
            window.rootViewController = nav
            window.makeKeyAndVisible()
        }
    }

    
    
}
