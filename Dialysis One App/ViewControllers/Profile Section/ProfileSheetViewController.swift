//
//  ProfileSheetViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 17/11/25.
//

import UIKit
import FirebaseAuth

class ProfileSheetViewController: UIViewController {

    // MARK: UI ELEMENTS
    private let scroll = UIScrollView()
    private let content = UIStackView()
    
    private let profileImage = UIImageView()
    private let nameLabel = UILabel()
    
    private let signOutButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        loadUserInfo()
    }
    
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = UIColor.systemGray6
        view.layer.cornerRadius = 28
        view.clipsToBounds = true
        
        // Grabber
        let grabber = UIView()
        grabber.backgroundColor = UIColor.systemGray3
        grabber.layer.cornerRadius = 3
        grabber.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(grabber)
        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            grabber.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 40),
            grabber.heightAnchor.constraint(equalToConstant: 5)
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
        profileImage.clipsToBounds = true
        profileImage.image = UIImage(systemName: "person.circle")?.withTintColor(.gray, renderingMode: .alwaysOriginal)
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        profileImage.widthAnchor.constraint(equalToConstant: 90).isActive = true
        profileImage.heightAnchor.constraint(equalToConstant: 90).isActive = true
        
        let profileStack = UIStackView(arrangedSubviews: [profileImage, nameLabel])
        profileStack.axis = .vertical
        profileStack.alignment = .center
        profileStack.spacing = 12
        
        nameLabel.font = UIFont.boldSystemFont(ofSize: 22)
        nameLabel.text = "Your Name"
        
        content.addArrangedSubview(profileStack)
        
        
        // Options
        content.addArrangedSubview(makeOption(title: "Edit Health Details"))
        content.addArrangedSubview(makeOption(title: "Edit Limits"))
        content.addArrangedSubview(makeSectionHeader("App Settings"))
        content.addArrangedSubview(makeOption(title: "Edit Pinned"))
        content.addArrangedSubview(makeOption(title: "Notifications"))
        content.addArrangedSubview(makeSectionHeader("Privacy"))
        content.addArrangedSubview(makeOption(title: "Privacy Policy"))
        content.addArrangedSubview(makeOption(title: "Terms and Conditions"))
        
        
        // Sign Out Button
        signOutButton.setTitle("Sign Out", for: .normal)
        signOutButton.setTitleColor(.systemRed, for: .normal)
        signOutButton.layer.cornerRadius = 12
        signOutButton.backgroundColor = .white
        signOutButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        content.addArrangedSubview(signOutButton)
    }
    
    private func showSignOutLoader(completion: @escaping () -> Void) {
        let loaderView = UIView(frame: view.bounds)
        loaderView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        loaderView.alpha = 0
        loaderView.isUserInteractionEnabled = true  // Prevents taps during transition

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
        label.text = "Signing Out…"
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {  // Adjust delay here
            completion()
            UIView.animate(withDuration: 0.3, animations: {
                loaderView.alpha = 0
            }) { _ in
                loaderView.removeFromSuperview()
            }
        }
    }

    
    
    // MARK: - Helpers
    
    private func makeOption(title: String) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.contentHorizontalAlignment = .left
        
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.heightAnchor.constraint(equalToConstant: 55).isActive = true
        
        button.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func makeSectionHeader(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = .darkGray
        return label
    }
    
    private func loadUserInfo() {
        let email = Auth.auth().currentUser?.email ?? ""
        nameLabel.text = email.components(separatedBy: "@").first?.capitalized
    }
    
    
    // MARK: - Sign Out
    @objc func signOutTapped() {

        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive, handler: { _ in
            self.performSignOut()
        }))

        present(alert, animated: true)
    }

    
    private func performSignOut() {
        showSignOutLoader { [weak self] in
            guard let self = self else { return }

            do {
                try Auth.auth().signOut()
            } catch {
                print("Sign out failed:", error.localizedDescription)
            }

            // IMPORTANT: Do NOT dismiss the sheet first.
            // We directly replace the window root to avoid flicker.

            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else { return }

            let signInVC = SignInViewController(nibName: "SignInViewController", bundle: nil)
            signInVC.modalPresentationStyle = .fullScreen

            UIView.transition(with: window,
                              duration: 0.4,
                              options: .transitionCrossDissolve,
                              animations: {
                window.rootViewController = signInVC
            })
        }
    }


}

