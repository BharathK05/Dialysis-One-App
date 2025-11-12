//
//  ForgotPasswordViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 11/11/25.
//

import UIKit
import FirebaseAuth

class ForgotPasswordViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var sendCodeButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    private var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        titleLabel.text = "Forgot Password?"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        
        descriptionLabel.text = "Enter your email address and we'll send you a link to reset your password"
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .systemGray
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: emailTextField.frame.height))
        emailTextField.leftView = paddingView
        emailTextField.leftViewMode = .always
        emailTextField.placeholder = "Enter Your Email Address"
        emailTextField.borderStyle = .roundedRect
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        
        sendCodeButton.setTitle("Send Reset Link", for: .normal)
        sendCodeButton.backgroundColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
        sendCodeButton.setTitleColor(.white, for: .normal)
        sendCodeButton.layer.cornerRadius = 25
        sendCodeButton.clipsToBounds = true
        sendCodeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.systemGray, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    }
    
    @IBAction func sendCodeButtonTapped(_ sender: UIButton) {
        guard !isLoading else { return }
        
        view.endEditing(true)
        
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email address")
            return
        }
        
        guard isValidEmail(email) else {
            showAlert(title: "Invalid Email", message: "Please enter a valid email address")
            return
        }
        
        isLoading = true
        showLoadingIndicator()
        
        // Send password reset email via Firebase
        FirebaseAuthManager.shared.sendPasswordResetEmail(email: email) { [weak self] result in
            guard let self = self else { return }
            
            self.hideLoadingIndicator()
            self.isLoading = false
            
            switch result {
            case .success:
                print("✅ Password reset email sent to: \(email)")
                self.navigateToVerificationCode(email: email)
                
            case .failure(let error):
                let errorMessage = FirebaseAuthManager.shared.getErrorMessage(from: error)
                self.showAlert(title: "Error", message: errorMessage)
                print("❌ Reset email error: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    // MARK: - Navigation
    func navigateToVerificationCode(email: String) {
        let verifyVC = VerifyCodeViewController(nibName: "VerifyCodeViewController", bundle: nil)
        verifyVC.email = email
        verifyVC.modalPresentationStyle = .pageSheet
        
        if let sheet = verifyVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
        dismiss(animated: true) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                
                topVC.present(verifyVC, animated: true)
            }
        }
    }
    
    // MARK: - Validation
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Loading Indicator
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
    
    // MARK: - Alert
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
