//
//  WelcomeAuthViewController.swift
//  Dialysis One App
//
//  Guest-first entry point with optional Apple Sign In
//

import UIKit
import AuthenticationServices

class WelcomeAuthViewController: UIViewController {

    // MARK: - UI Components

    private let backgroundImageView = UIImageView()

    private let continueAsGuestButton = UIButton(type: .system)

    // ✅ Correct Apple button type for "Continue with Apple"
    private let signInWithAppleButton = ASAuthorizationAppleIDButton(
        type: .continue,
        style: .black
    )

    private let authStack = UIStackView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupBackgroundImage()
        setupAuthStack()
    }

    // MARK: - Background Image

    private func setupBackgroundImage() {
        backgroundImageView.image = UIImage(named: "welcome")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(backgroundImageView)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // MARK: - Auth Stack

    private func setupAuthStack() {

        let primaryGreen = UIColor(hex: "7BC96F") // lighter green

        // MARK: Continue as Guest (styled to match Apple button)

        continueAsGuestButton.setTitle("Continue as Guest", for: .normal)
        continueAsGuestButton.backgroundColor = primaryGreen
        continueAsGuestButton.setTitleColor(.white, for: .normal)

        // 🔑 Match Apple button typography visually
        continueAsGuestButton.titleLabel?.font = UIFont.systemFont(
            ofSize: 16,  
            weight: .semibold
        )

        continueAsGuestButton.layer.cornerRadius = 12   // 🔑 Apple’s real radius
        continueAsGuestButton.clipsToBounds = true
        continueAsGuestButton.translatesAutoresizingMaskIntoConstraints = false
        continueAsGuestButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        continueAsGuestButton.addTarget(
            self,
            action: #selector(continueAsGuestTapped),
            for: .touchUpInside
        )

        // MARK: Continue with Apple (UNCHANGED — Apple controlled)

        signInWithAppleButton.cornerRadius = 12
        signInWithAppleButton.clipsToBounds = true
        signInWithAppleButton.translatesAutoresizingMaskIntoConstraints = false
        signInWithAppleButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        signInWithAppleButton.addTarget(
            self,
            action: #selector(signInWithAppleTapped),
            for: .touchUpInside
        )

        // MARK: Stack View

        authStack.axis = .vertical
        authStack.alignment = .fill
        authStack.spacing = 12
        authStack.translatesAutoresizingMaskIntoConstraints = false

        authStack.addArrangedSubview(continueAsGuestButton)
        authStack.addArrangedSubview(signInWithAppleButton)

        view.addSubview(authStack)

        NSLayoutConstraint.activate([
            authStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            authStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            authStack.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -32
            )
        ])
    }
    // MARK: - Actions

    @objc private func continueAsGuestTapped() {
        print("✅ User continuing as guest")
        startOnboarding()
    }

    @objc private func signInWithAppleTapped() {
        print("🍎 Continue with Apple tapped")
        performAppleSignIn()
    }

    // MARK: - Navigation

    private func startOnboarding() {
        let onboardingVC = OnboardingViewController(
            nibName: "OnboardingViewController",
            bundle: nil
        )
        navigationController?.pushViewController(onboardingVC, animated: true)
    }

    // MARK: - Apple Sign In

    private func performAppleSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(
            authorizationRequests: [request]
        )
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

// MARK: - Apple Sign In Delegates

extension WelcomeAuthViewController: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential =
                authorization.credential as? ASAuthorizationAppleIDCredential
        else { return }

        let userIdentifier = appleIDCredential.user
        LocalUserManager.shared.saveAppleUserID(userIdentifier)

        if let fullName = appleIDCredential.fullName {
            let name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            if !name.isEmpty {
                UserDefaults.standard.set(name, forKey: "userFullName")
            }
        }

        print("✅ Apple Sign In successful")
        startOnboarding()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        print("❌ Apple Sign In failed: \(error.localizedDescription)")

        let alert = UIAlertController(
            title: "Sign In Failed",
            message: "You can continue as a guest instead.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Apple Presentation Anchor

extension WelcomeAuthViewController:
    ASAuthorizationControllerPresentationContextProviding {

    func presentationAnchor(
        for controller: ASAuthorizationController
    ) -> ASPresentationAnchor {
        view.window!
    }
}

// MARK: - UIColor HEX Extension

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8) & 0xFF) / 255
        let b = CGFloat(int & 0xFF) / 255

        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
