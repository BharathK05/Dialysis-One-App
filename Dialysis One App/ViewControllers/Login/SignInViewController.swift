//
//  SignInViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 08/11/25.
//

import UIKit
import FirebaseAuth  

class SignInViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    private var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let emailPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: emailTextField.frame.height))
        emailTextField.leftView = emailPaddingView
        emailTextField.leftViewMode = .always
        
        let PasswordPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: passwordTextField.frame.height))
        passwordTextField.leftView = PasswordPaddingView
        passwordTextField.leftViewMode = .always
    }
    
    @IBAction func signInButtonTapped(_ sender: UIButton) {
        guard !isLoading else { return }
        
        view.endEditing(true)
        
        // Get input values
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(message: "Please enter email")
            return
        }
        
        guard let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter password")
            return
        }
        
        // Show loading
        isLoading = true
        showLoadingIndicator()
        
        // ========== CHANGED: Firebase sign in instead of Supabase ==========
        FirebaseAuthManager.shared.signIn(email: email, password: password) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.hideLoadingIndicator()
                self.isLoading = false

                switch result {
                case .success(let user):
                    if !user.isEmailVerified {
                        self.showAlert(message: "Please verify your email before signing in.")
                        try? Auth.auth().signOut()
                        return
                    }

                    print("Login successful! User ID: \(user.uid)")
                    self.handlePostLoginFlow(for: user)

                case .failure(let error):
                    let errorMessage = FirebaseAuthManager.shared.getErrorMessage(from: error)
                    self.showAlert(message: errorMessage)
                    print("Login error: \(error.localizedDescription)")
                }
            }
        }

        // ====================================================================
    }
    
    func showOnboarding() {
        let onboardingVC = OnboardingViewController(
            nibName: "OnboardingViewController",
            bundle: nil
        )

        let nav = UINavigationController(rootViewController: onboardingVC)
        nav.modalPresentationStyle = .fullScreen

        present(nav, animated: true)
    }

    
    func handlePostLoginFlow(for user: User) {

        let onboardingKey = "onboardingCompleted_\(user.uid)"
        let isOnboardingCompleted = UserDefaults.standard.bool(forKey: onboardingKey)

        if !isOnboardingCompleted {
            showOnboarding()
        } else {
            switchToMainApp()
        }
    }


    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        let SignUpVC = SignUpViewController(nibName: "SignUpViewController", bundle: nil)
        SignUpVC.modalPresentationStyle = .fullScreen
        present(SignUpVC, animated: true)
    }
    
    @IBAction func forgotPasswordButtonTapped(_ sender: UIButton) {
        let forgotPasswordVC = ForgotPasswordViewController(nibName: "ForgotPasswordViewController", bundle: nil)
        forgotPasswordVC.modalPresentationStyle = .pageSheet
        if let sheet = forgotPasswordVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(forgotPasswordVC, animated: true)
    }
    
    // MARK: - Navigation
    func switchToMainApp() {
        guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {
            return
        }

        let tabBar = MainTabBarController()
        sceneDelegate.window?.rootViewController = tabBar
        sceneDelegate.window?.makeKeyAndVisible()
    }

    
    // MARK: - Loading Indicator
    private var loadingView: UIView?
    private var activityIndicator: UIActivityIndicatorView?
    
    func showLoadingIndicator() {
        let loadingView = UIView(frame: view.bounds)
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.center = loadingView.center
        activityIndicator.startAnimating()
        
        loadingView.addSubview(activityIndicator)
        view.addSubview(loadingView)
        
        self.loadingView = loadingView
        self.activityIndicator = activityIndicator
    }
    
    func hideLoadingIndicator() {
        activityIndicator?.stopAnimating()
        loadingView?.removeFromSuperview()
        loadingView = nil
        activityIndicator = nil
    }
    
    // MARK: - Alert
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
