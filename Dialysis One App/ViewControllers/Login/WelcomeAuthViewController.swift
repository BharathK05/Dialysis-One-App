//
//  WelcomeAuthViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 16/12/25.
//

import UIKit

class WelcomeAuthViewController: UIViewController {

    // MARK: - UI Components
    private let backgroundImageView = UIImageView()
    private let createAccountButton = UIButton(type: .system)
    private let loginButton = UIButton(type: .system)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupBackgroundImage()
        setupButtons()
    }

    // MARK: - Setup UI

    private func setupBackgroundImage() {
        backgroundImageView.image = UIImage(named: "welcome")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true

        view.addSubview(backgroundImageView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupButtons() {

        let primaryGreen = UIColor(hex: "63B356")

        // Create Account Button
        createAccountButton.setTitle("Create account", for: .normal)
        createAccountButton.backgroundColor = primaryGreen
        createAccountButton.setTitleColor(.white, for: .normal)
        createAccountButton.layer.cornerRadius = 20
        createAccountButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        createAccountButton.addTarget(self, action: #selector(createAccountTapped), for: .touchUpInside)

        // Sign In Button
        loginButton.setTitle("Sign In", for: .normal)
        loginButton.setTitleColor(primaryGreen, for: .normal)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        view.addSubview(createAccountButton)
        view.addSubview(loginButton)

        createAccountButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            createAccountButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            createAccountButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // lifted up
            createAccountButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -100
            ),
            createAccountButton.heightAnchor.constraint(equalToConstant: 56),

            loginButton.topAnchor.constraint(equalTo: createAccountButton.bottomAnchor, constant: 16),
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }


    // MARK: - Actions

    @objc private func createAccountTapped() {
        let signUpVC = SignUpViewController(nibName: "SignUpViewController", bundle: nil)
        navigationController?.pushViewController(signUpVC, animated: true)
    }

    @objc private func loginTapped() {
        let signInVC = SignInViewController(nibName: "SignInViewController", bundle: nil)
        navigationController?.pushViewController(signInVC, animated: true)
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8) & 0xFF) / 255
        let b = CGFloat(int & 0xFF) / 255

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

