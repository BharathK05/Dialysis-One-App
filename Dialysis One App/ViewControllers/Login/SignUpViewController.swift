//
//  SignUpViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 10/11/25.
//

import UIKit
import FirebaseAuth  // ← CHANGED: Was "import Supabase"

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    
    private var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextFields()
        setupUI()
    }
    
    // MARK: - Setup UI
    func setupTextFields() {
        // Add padding to all text fields
        let textFields = [fullNameTextField, emailTextField, passwordTextField, confirmPasswordTextField]
        
        for textField in textFields {
            guard let textField = textField else { continue }
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
            textField.leftView = paddingView
            textField.leftViewMode = .always
        }
        
        // Set secure text entry for password fields
        passwordTextField?.isSecureTextEntry = true
        confirmPasswordTextField?.isSecureTextEntry = true
        
        // Set keyboard types
        emailTextField?.keyboardType = .emailAddress
        emailTextField?.autocapitalizationType = .none
        fullNameTextField?.autocapitalizationType = .words
    }
    
    func setupUI() {
        // Configure sign up button
        signUpButton?.layer.cornerRadius = 25
        signUpButton?.clipsToBounds = true
        signUpButton?.backgroundColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
    }
    
    // MARK: - Actions
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        guard !isLoading else { return }
        
        view.endEditing(true)
        
        // Get input values
        guard let fullName = fullNameTextField.text, !fullName.isEmpty else {
            showAlert(title: "Error", message: "Please enter your full name")
            return
        }
        
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email")
            return
        }
        
        // Email validation
        guard isValidEmail(email) else {
            showAlert(title: "Invalid Email", message: "Please enter a valid email address")
            return
        }
        
        guard let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter a password")
            return
        }
        
        // Password strength validation
        guard password.count >= 6 else {
            showAlert(title: "Weak Password", message: "Password must be at least 6 characters long")
            return
        }
        
        guard let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(title: "Error", message: "Please confirm your password")
            return
        }
        
        // Password match validation
        guard password == confirmPassword else {
            showAlert(title: "Password Mismatch", message: "Passwords do not match. Please try again.")
            return
        }
        
        // Show loading
        isLoading = true
        showLoadingIndicator()
        
        // ========== CHANGED: Firebase sign up instead of Supabase ==========
        FirebaseAuthManager.shared.signUp(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            
            self.hideLoadingIndicator()
            self.isLoading = false
            
            switch result {
            case .success(let user):
                print("✅ Sign up successful! User ID: \(user.uid)")
                print("📧 Verification email sent to: \(email)")
                
                // You can save fullName to UserDefaults or a separate database later
                UserDefaults.standard.set(fullName, forKey: "userFullName")
                
                self.navigateToVerifyCode(email: email)

            case .failure(let error):
                let errorMessage = FirebaseAuthManager.shared.getErrorMessage(from: error)
                self.showAlert(title: "Sign Up Failed", message: errorMessage)
                print("❌ Sign up error: \(error.localizedDescription)")
            }
        }
        // ====================================================================
    }
    
    @IBAction func signInButtonTapped(_ sender: UIButton) {
        // Dismiss to go back to sign in screen
        dismiss(animated: true)
    }
    
    func navigateToOnboarding() {
        let onboardingVC = OnboardingViewController(nibName: "OnboardingViewController", bundle: nil)
        onboardingVC.modalPresentationStyle = .fullScreen
        self.present(onboardingVC, animated: true)
    }


    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private var loadingView: UIView?
    private var activityIndicator: UIActivityIndicatorView?
    
    func showLoadingIndicator() {
        let loadingView = UIView(frame: view.bounds)
        loadingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        loadingView.tag = 999
        
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
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func showSuccessAlert() {
        let alert = UIAlertController(
            title: "Account Created! 🎉",
            message: "Your account has been created successfully!\n\nPlease check your email to verify your account before signing in.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigateToVerifyCode(email: self.emailTextField.text ?? "")
        })
        present(alert, animated: true)
    }

    func navigateToVerifyCode(email: String) {
        let verifyVC = VerifyCodeViewController(nibName: "VerifyCodeViewController", bundle: nil)
        verifyVC.email = email
        verifyVC.modalPresentationStyle = .fullScreen
        self.present(verifyVC, animated: true)
    }

}
