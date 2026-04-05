//
//  WelcomeAuthViewController.swift
//  Dialysis One App
//
//  Redesigned: structured layout, Apple-first button order,
//  ghost guest button, headline with bold keywords, fade-in animation,
//  haptic feedback, and proper guest/Apple session handling.
//

import UIKit
import AuthenticationServices

class WelcomeAuthViewController: UIViewController {

    // MARK: - UI Components

    /// Root container that receives the fade-in / slide-up animation
    private let contentContainer = UIView()

    /// "DialysisOne" wordmark at the top
    private let logoLabel = UILabel()

    /// The app mockup / preview image — aspect-fit, constrained height
    private let welcomeImageView = UIImageView()

    /// Multi-line headline with bold keywords
    private let headlineLabel = UILabel()

    /// Primary CTA — Apple Sign-In (top)
    private let signInWithAppleButton = ASAuthorizationAppleIDButton(
        type: .continue,
        style: .black
    )

    /// Secondary CTA — Guest (bottom, outlined)
    private let continueAsGuestButton = UIButton(type: .system)

    /// Vertical stack holding both CTAs
    private let authStack = UIStackView()

    /// Small trust / clarity note below buttons
    private let microcopyLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupContentContainer()
        setupLogoLabel()
        setupWelcomeImage()
        setupHeadlineLabel()
        setupAuthStack()
        setupMicrocopyLabel()
        setupConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playFadeInAnimation()
    }

    // MARK: - Background

    private func setupBackground() {
        // Mint → light-teal gradient matching the splash screen
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(hex: "E1F5EB").cgColor,
            UIColor(hex: "C8EBE1").cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint   = CGPoint(x: 0.5, y: 1)
        gradient.frame      = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
        view.backgroundColor = UIColor(hex: "E1F5EB")
    }

    // MARK: - Content Container

    private func setupContentContainer() {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        // Start invisible for the fade-in; actual animation in viewDidAppear
        contentContainer.alpha = 0
        view.addSubview(contentContainer)
    }

    // MARK: - Logo Label

    private func setupLogoLabel() {
        logoLabel.text          = "DialysisOne"
        logoLabel.textAlignment = .center
        logoLabel.textColor     = .black

        // Try the custom font; fall back to a serif system font
        let customFontName = "FONTSPRINGDEMO-TheSeasonsBold"
        if let customFont = UIFont(name: customFontName, size: 36) {
            logoLabel.font = customFont
        } else {
            logoLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        }

        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(logoLabel)
    }

    // MARK: - Welcome / Mockup Image

    private func setupWelcomeImage() {
        welcomeImageView.image       = UIImage(named: "welcome")
        welcomeImageView.contentMode = .scaleAspectFit   // ✅ never stretches
        welcomeImageView.clipsToBounds = true
        welcomeImageView.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(welcomeImageView)
    }

    // MARK: - Headline Label

    private func setupHeadlineLabel() {
        headlineLabel.numberOfLines    = 0
        headlineLabel.textAlignment    = .center
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false

        headlineLabel.attributedText = buildHeadlineAttributedText()
        contentContainer.addSubview(headlineLabel)
    }

    /// Builds the headline with selective bold on "diet", "fluids", "health"
    private func buildHeadlineAttributedText() -> NSAttributedString {
        let baseFont  = UIFont.systemFont(ofSize: 17, weight: .regular)
        let boldFont  = UIFont.systemFont(ofSize: 17, weight: .semibold)
        let textColor = UIColor.black.withAlphaComponent(0.82)

        let paragraphStyle              = NSMutableParagraphStyle()
        paragraphStyle.alignment        = .center
        paragraphStyle.lineHeightMultiple = 1.28

        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font            : baseFont,
            .foregroundColor : textColor,
            .paragraphStyle  : paragraphStyle
        ]
        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font            : boldFont,
            .foregroundColor : textColor,
            .paragraphStyle  : paragraphStyle
        ]

        let fullText = "Stay on top of your dialysis\ndiet, fluids, and health — effortlessly"
        let attributed = NSMutableAttributedString(string: fullText, attributes: baseAttrs)

        // Bold only the key words
        for word in ["diet", "fluids", "health"] {
            var searchRange = fullText.startIndex..<fullText.endIndex
            while let range = fullText.range(of: word, options: .caseInsensitive, range: searchRange) {
                let nsRange = NSRange(range, in: fullText)
                attributed.addAttributes(boldAttrs, range: nsRange)
                searchRange = range.upperBound..<fullText.endIndex
            }
        }

        return attributed
    }

    // MARK: - Auth Stack

    private func setupAuthStack() {
        setupAppleButton()
        setupGuestButton()

        authStack.axis      = .vertical
        authStack.alignment = .fill
        authStack.spacing   = 14
        authStack.translatesAutoresizingMaskIntoConstraints = false

        // ✅ Apple FIRST, Guest SECOND
        authStack.addArrangedSubview(signInWithAppleButton)
        authStack.addArrangedSubview(continueAsGuestButton)

        contentContainer.addSubview(authStack)
    }

    private func setupAppleButton() {
        signInWithAppleButton.cornerRadius  = 12
        signInWithAppleButton.clipsToBounds = true
        signInWithAppleButton.translatesAutoresizingMaskIntoConstraints = false
        signInWithAppleButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        signInWithAppleButton.addTarget(
            self,
            action: #selector(signInWithAppleTapped),
            for: .touchUpInside
        )
    }

    private func setupGuestButton() {
        continueAsGuestButton.setTitle("Continue as Guest", for: .normal)
        continueAsGuestButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        // ✅ Outlined / ghost style — clearly secondary
        continueAsGuestButton.backgroundColor                   = .clear
        continueAsGuestButton.layer.borderWidth                 = 1.5
        continueAsGuestButton.layer.borderColor                 = UIColor.black.withAlphaComponent(0.45).cgColor
        continueAsGuestButton.setTitleColor(UIColor.black.withAlphaComponent(0.75), for: .normal)
        continueAsGuestButton.layer.cornerRadius                = 12
        continueAsGuestButton.clipsToBounds                     = true
        continueAsGuestButton.translatesAutoresizingMaskIntoConstraints = false
        continueAsGuestButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        // Subtle press scale animation
        continueAsGuestButton.addTarget(self, action: #selector(buttonTouchDown(_:)),  for: .touchDown)
        continueAsGuestButton.addTarget(self, action: #selector(buttonTouchUp(_:)),    for: [.touchUpInside, .touchUpOutside, .touchCancel])
        continueAsGuestButton.addTarget(self, action: #selector(continueAsGuestTapped), for: .touchUpInside)
    }

    // MARK: - Microcopy Label

    private func setupMicrocopyLabel() {
        microcopyLabel.text          = "No account required. You can sign in later."
        microcopyLabel.font          = UIFont.systemFont(ofSize: 13, weight: .regular)
        microcopyLabel.textColor     = UIColor.black.withAlphaComponent(0.45)
        microcopyLabel.textAlignment = .center
        microcopyLabel.numberOfLines = 1
        microcopyLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.addSubview(microcopyLabel)
    }

    // MARK: - Auto Layout

    private func setupConstraints() {
        let screenHeight = UIScreen.main.bounds.height
        // Image fills ~55% of screen height on all device sizes
        let imageHeight  = screenHeight * 0.52

        NSLayoutConstraint.activate([

            // ── contentContainer fills the view ──────────────────────────
            contentContainer.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // ── Logo ──────────────────────────────────────────────────────
            logoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            logoLabel.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            logoLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentContainer.leadingAnchor, constant: 16),
            logoLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentContainer.trailingAnchor, constant: -16),

            // ── Mockup image ──────────────────────────────────────────────
            welcomeImageView.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 12),
            welcomeImageView.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            welcomeImageView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            welcomeImageView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            welcomeImageView.heightAnchor.constraint(equalToConstant: imageHeight),

            // ── Headline ──────────────────────────────────────────────────
            headlineLabel.topAnchor.constraint(equalTo: welcomeImageView.bottomAnchor, constant: 16),
            headlineLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 28),
            headlineLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -28),

            // ── Auth stack ────────────────────────────────────────────────
            authStack.topAnchor.constraint(greaterThanOrEqualTo: headlineLabel.bottomAnchor, constant: 20),
            authStack.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 24),
            authStack.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -24),

            // ── Microcopy ─────────────────────────────────────────────────
            microcopyLabel.topAnchor.constraint(equalTo: authStack.bottomAnchor, constant: 12),
            microcopyLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            microcopyLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            microcopyLabel.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -20
            )
        ])
    }

    // MARK: - Fade-In Animation

    private func playFadeInAnimation() {
        contentContainer.alpha     = 0
        contentContainer.transform = CGAffineTransform(translationX: 0, y: 24)

        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                self.contentContainer.alpha     = 1
                self.contentContainer.transform = .identity
            }
        )
    }

    // MARK: - Button Press Animations

    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12) {
            sender.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }

    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12) {
            sender.transform = .identity
        }
    }

    // MARK: - Actions

    @objc private func continueAsGuestTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        LocalUserManager.shared.setGuestUser(true)
        print("✅ User continuing as guest")
        navigateToOnboarding()
    }

    @objc private func signInWithAppleTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        print("🍎 Continue with Apple tapped")
        performAppleSignIn()
    }

    // MARK: - Navigation

    private func navigateToOnboarding() {
        let onboardingVC = OnboardingViewController(
            nibName: "OnboardingViewController",
            bundle: nil
        )
        navigationController?.pushViewController(onboardingVC, animated: true)
    }

    // MARK: - Apple Sign-In

    private func performAppleSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request  = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate                  = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension WelcomeAuthViewController: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            showErrorAlert(message: "Unable to read Apple credentials. Please try again.")
            return
        }

        let userIdentifier = credential.user
        LocalUserManager.shared.saveAppleUserID(userIdentifier)
        LocalUserManager.shared.setGuestUser(false)

        // fullName is only provided on FIRST sign-in; nil on returning users — handle gracefully
        if let fullName = credential.fullName {
            let name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if !name.isEmpty {
                UserDefaults.standard.set(name, forKey: "userFullName")
            }
        }

        // email is optional on returning users — do NOT fail if nil
        if let email = credential.email {
            UserDefaults.standard.set(email, forKey: "userEmail")
        }

        print("✅ Apple Sign-In successful — userID: \(userIdentifier)")
        DispatchQueue.main.async { [weak self] in
            self?.navigateToOnboarding()
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        // ASAuthorizationError.canceled means user dismissed sheet — not a real error
        let asError = error as? ASAuthorizationError
        if asError?.code == .canceled { return }

        print("❌ Apple Sign-In failed: \(error.localizedDescription)")
        showErrorAlert(message: "Sign in failed. You can continue as a guest instead.")
    }

    // MARK: - Error Alert

    private func showErrorAlert(message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(
                title: "Sign In Failed",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension WelcomeAuthViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // view.window is guaranteed to be non-nil when a button tap triggers this
        return view.window!
    }
}

// MARK: - UIColor HEX convenience

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >>  8) & 0xFF) / 255
        let b = CGFloat( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
