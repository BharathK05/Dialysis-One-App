//
//  ProfileSheetViewController.swift
//  Dialysis One App
//
//  Updated for Guest + Apple ID flow (no Firebase required)
//

import UIKit

struct PinnedStorage {
    static let pinnedKey = "pinned_modules"
    static let othersKey = "other_modules"
}

class ProfileSheetViewController: UIViewController {
    
    private var initialTouchPoint: CGPoint = .zero

    // MARK: UI ELEMENTS
    private let scroll = UIScrollView()
    private let content = UIStackView()
    
    private let profileImage = UIImageView()
    private let nameLabel = UILabel()
    
    private let userTypeLabel = UILabel()  // NEW: Show if Guest or Apple ID
    private let signOutButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        loadUserInfo()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(panGesture)
    }
    
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = UIColor.systemGray6
        view.layer.cornerRadius = 28
        view.clipsToBounds = true
        
        // Grabber
        let grabber = UIView()
        grabber.translatesAutoresizingMaskIntoConstraints = false
        grabber.backgroundColor = UIColor.systemGray4
        grabber.layer.cornerRadius = 2
        view.addSubview(grabber)
        
        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            grabber.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 36),
            grabber.heightAnchor.constraint(equalToConstant: 4)
        ])
        
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 10),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        content.axis = .vertical
        content.spacing = 20
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])
        
        
        // Profile Image
        profileImage.layer.cornerRadius = 45
        profileImage.layer.borderWidth = 3
        profileImage.layer.borderColor = UIColor.systemGreen.cgColor
        profileImage.clipsToBounds = true
        profileImage.image = UIImage(systemName: "person.circle")?.withTintColor(.gray, renderingMode: .alwaysOriginal)
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        profileImage.widthAnchor.constraint(equalToConstant: 90).isActive = true
        profileImage.heightAnchor.constraint(equalToConstant: 90).isActive = true
        
        // User Type Label (Guest or Apple ID)
        userTypeLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        userTypeLabel.textColor = .systemGray
        userTypeLabel.textAlignment = .center
        userTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let profileStack = UIStackView(arrangedSubviews: [profileImage, nameLabel, userTypeLabel])
        profileStack.axis = .vertical
        profileStack.alignment = .center
        profileStack.spacing = 8
        profileStack.setCustomSpacing(12, after: profileImage)
        content.setCustomSpacing(30, after: profileStack)
        
        nameLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        nameLabel.text = "Your Name"
        
        content.addArrangedSubview(profileStack)
        
        
        // Options
        var globalRowTag = 0

        content.addArrangedSubview(makeSectionHeader("Health"))
        content.addArrangedSubview(makeMultiOptionCard(["Edit Health Details","Edit Limits"], startTag: &globalRowTag))

        content.addArrangedSubview(makeSectionHeader("App Settings"))
        content.addArrangedSubview(makeMultiOptionCard(["Edit Pinned", "Notifications"], startTag: &globalRowTag))

        content.addArrangedSubview(makeSectionHeader("Privacy"))
        content.addArrangedSubview(makeMultiOptionCard(["Privacy Policy", "Terms and Conditions"], startTag: &globalRowTag))
        
        
        // MARK: - Sign Out / Reset Button
        let signOutContainer = UIView()
        signOutContainer.backgroundColor = .white
        signOutContainer.layer.cornerRadius = 12
        signOutContainer.translatesAutoresizingMaskIntoConstraints = false
        signOutContainer.heightAnchor.constraint(equalToConstant: 55).isActive = true
        
        signOutContainer.layer.shadowColor = UIColor.black.cgColor
        signOutContainer.layer.shadowOpacity = 0.07
        signOutContainer.layer.shadowRadius = 4
        signOutContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        // Button text changes based on user type
        let buttonTitle = LocalUserManager.shared.hasAppleID() ? "Sign Out" : "Reset App Data"
        signOutButton.setTitle(buttonTitle, for: .normal)
        signOutButton.setTitleColor(.systemRed, for: .normal)
        signOutButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        
        signOutButton.addTarget(self, action: #selector(signOutOrResetTapped), for: .touchUpInside)
        
        signOutContainer.addSubview(signOutButton)
        content.addArrangedSubview(signOutContainer)
        
        NSLayoutConstraint.activate([
            signOutButton.centerXAnchor.constraint(equalTo: signOutContainer.centerXAnchor),
            signOutButton.centerYAnchor.constraint(equalTo: signOutContainer.centerYAnchor)
        ])
    }
    
    private func openEditLimits() {
        let vc = EditLimitsViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }
        present(nav, animated: true)
    }

    private func openEditHealthDetails() {
        let vc = EditHealthDetailsViewController()
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }
        present(nav, animated: true)
    }
    
    // MARK: - Navigation to other screens

    private func openEditPinned() {
        let vc = EditPinnedViewController()

        vc.pinned = UserDefaults.standard.stringArray(forKey: PinnedStorage.pinnedKey) ?? ["Fluid Tracker"]
        vc.others = UserDefaults.standard.stringArray(forKey: PinnedStorage.othersKey) ??
                    ["Calorie Tracker", "Medication"]

        vc.delegate = self
        presentSheet(vc)
    }

    private func openNotifications() {
        let vc = NotificationsViewController()
        presentSheet(vc)
    }

    private func openPrivacyPolicy() {
        let vc = PrivacyPolicyViewController()
        presentSheet(vc)
    }

    private func openTerms() {
        let vc = TermsViewController()
        presentSheet(vc)
    }

    private func presentSheet(_ vc: UIViewController) {
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }
        present(nav, animated: true)
    }

    
    private func makeMultiOptionCard(_ titles: [String], startTag: inout Int) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        container.translatesAutoresizingMaskIntoConstraints = false

        var lastRow: UIView? = nil

        for title in titles {
            let row = UIView()
            row.translatesAutoresizingMaskIntoConstraints = false
            row.backgroundColor = .white
            container.addSubview(row)

            let label = UILabel()
            label.text = title
            label.font = UIFont.systemFont(ofSize: 17)
            label.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(label)

            let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
            arrow.tintColor = .systemGray3
            arrow.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(arrow)

            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                row.heightAnchor.constraint(equalToConstant: 55),

                label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                label.leadingAnchor.constraint(equalTo: row.leadingAnchor),

                arrow.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                arrow.trailingAnchor.constraint(equalTo: row.trailingAnchor)
            ])

            if let previous = lastRow {
                row.topAnchor.constraint(equalTo: previous.bottomAnchor).isActive = true
            } else {
                row.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
            }

            lastRow = row

            row.tag = startTag
            startTag += 1

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleCardTap(_:)))
            row.addGestureRecognizer(tap)

            if title != titles.last {
                let divider = UIView()
                divider.backgroundColor = UIColor.systemGray5
                divider.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(divider)

                NSLayoutConstraint.activate([
                    divider.topAnchor.constraint(equalTo: row.bottomAnchor),
                    divider.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
                    divider.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
                    divider.heightAnchor.constraint(equalToConstant: 1)
                ])
            }
        }

        lastRow?.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        return container
    }

    
    @objc private func handleCardTap(_ gesture: UITapGestureRecognizer) {
        guard let row = gesture.view else { return }
        print("Tapped row tag: \(row.tag)")

        switch row.tag {
        case 0: openEditHealthDetails()
        case 1: openEditLimits()
        case 2: openEditPinned()
        case 3: openNotifications()
        case 4: openPrivacyPolicy()
        case 5: openTerms()
        default: break
        }
    }

    
    private func showActionLoader(message: String, completion: @escaping () -> Void) {
        let loaderView = UIView(frame: view.bounds)
        loaderView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        loaderView.alpha = 0
        loaderView.isUserInteractionEnabled = true

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blur.frame = loaderView.bounds
        loaderView.addSubview(blur)

        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 20
        container.translatesAutoresizingMaskIntoConstraints = false
        loaderView.addSubview(container)

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(spinner)

        let label = UILabel()
        label.text = message
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        view.addSubview(loaderView)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: loaderView.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: loaderView.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 180),
            container.heightAnchor.constraint(equalToConstant: 120),

            spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),

            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 12),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])

        UIView.animate(withDuration: 0.25) {
            loaderView.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            completion()
            UIView.animate(withDuration: 0.3, animations: {
                loaderView.alpha = 0
            }) { _ in
                loaderView.removeFromSuperview()
            }
        }
    }

    
    
    // MARK: - Helpers
    
    private func makeSectionHeader(_ text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4)
        ])
        
        return container
    }
    
    private func loadUserInfo() {
        if let profile = ProfileManager.shared.currentProfile {
            nameLabel.text = profile.name
        } else {
            let savedName = UserDefaults.standard.string(forKey: "userFullName") ?? "User"
            nameLabel.text = savedName
        }
        
        // Show user type
        let userType = LocalUserManager.shared.getUserType()
        switch userType {
        case .guest:
            userTypeLabel.text = "Guest User"
        case .appleID:
            userTypeLabel.text = "🍎 Signed in with Apple"
        }
        
        // Load profile image if saved
        let localID = LocalUserManager.shared.getLocalUserID()
        if let imageData = UserDefaults.standard.data(forKey: "profileImage_\(localID)"),
           let image = UIImage(data: imageData) {
            profileImage.image = image
        }
    }
    
    
    // MARK: - Sign Out / Reset
    @objc func signOutOrResetTapped() {
        let hasAppleID = LocalUserManager.shared.hasAppleID()
        
        let title = hasAppleID ? "Sign Out" : "Reset App Data"
        let message = hasAppleID
            ? "Are you sure you want to sign out? Your data is backed up to iCloud."
            : "This will clear all your app data and return you to the welcome screen. Are you sure?"
        let actionTitle = hasAppleID ? "Sign Out" : "Reset"

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: actionTitle, style: .destructive, handler: { _ in
            self.performSignOutOrReset()
        }))

        present(alert, animated: true)
    }

    
    private func performSignOutOrReset() {
        let hasAppleID = LocalUserManager.shared.hasAppleID()
        let message = hasAppleID ? "Signing Out…" : "Resetting…"
        
        showActionLoader(message: message) { [weak self] in
            guard let self = self else { return }

            // Clear user data
            self.clearUserData()
            
            // Navigate back to welcome screen
            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                sceneDelegate.returnToWelcome()
            }
        }
    }
    
    private func clearUserData() {
        // Get current user ID before clearing
        let localID = LocalUserManager.shared.getLocalUserID()
        
        // Clear onboarding flag
        UserDefaults.standard.removeObject(forKey: "onboardingCompleted_\(localID)")
        
        // Clear Apple ID if exists
        if LocalUserManager.shared.hasAppleID() {
            UserDefaults.standard.removeObject(forKey: "appleUserID")
            UserDefaults.standard.removeObject(forKey: "hasSignedInWithApple")
        }
        
        // Optionally clear all user data
        // UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        print("✅ User data cleared")
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        if scroll.contentOffset.y > 0 { return }
        let touchPoint = gesture.location(in: self.view?.window)

        switch gesture.state {
        case .began:
            initialTouchPoint = touchPoint

        case .changed:
            let offset = touchPoint.y - initialTouchPoint.y
            
            if offset > 0 {
                view.frame.origin.y = offset
                view.alpha = max(1 - (offset / 350), 0.4)
            }

        case .ended, .cancelled:
            let offset = touchPoint.y - initialTouchPoint.y
            
            if offset > 140 {
                dismissWithDissolve()
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.view.frame.origin.y = 0
                    self.view.alpha = 1
                }
            }

        default: break
        }
    }

    private func dismissWithDissolve() {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.frame.origin.y = self.view.frame.size.height
            self.view.alpha = 0
        }) { _ in
            self.dismiss(animated: false)
        }
    }
}

extension ProfileSheetViewController: EditPinnedDelegate {
    func didUpdatePinned(pinned: [String], others: [String]) {
        UserDefaults.standard.set(pinned, forKey: PinnedStorage.pinnedKey)
        UserDefaults.standard.set(others, forKey: PinnedStorage.othersKey)

        print("Saved pinned:", pinned)
        print("Saved others:", others)
    }
}

extension ProfileSheetViewController: EditHealthDetailsDelegate {
    func editHealthDetailsDidSave(firstName: String?,
                                  lastName: String?,
                                  age: Int?,
                                  gender: String?,
                                  heightCm: Int?,
                                  bloodGroup: String?,
                                  ckdStage: String?,
                                  dialysisFrequency: [String],
                                  profileImage: UIImage?) {
        // Update profile image if provided
        if let img = profileImage {
            DispatchQueue.main.async {
                self.profileImage.image = img
            }
            
            // Save to UserDefaults
            let localID = LocalUserManager.shared.getLocalUserID()
            if let imageData = img.jpegData(compressionQuality: 0.8) {
                UserDefaults.standard.set(imageData, forKey: "profileImage_\(localID)")
            }
        }

        // Update name label
        if let f = firstName, !f.isEmpty {
            var display = f
            if let l = lastName, !l.isEmpty { display += " " + l }
            
            DispatchQueue.main.async {
                self.nameLabel.text = display
            }
            
            // Save full name
            UserDefaults.standard.set(display, forKey: "userFullName")
        }
    }
}
