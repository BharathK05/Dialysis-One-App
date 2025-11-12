//
//  VerifyCodeViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 11/11/25.
//

import UIKit
import FirebaseAuth

class VerifyCodeViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var emailDisplayLabel: UILabel!
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var email: String = ""
    private var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        titleLabel.text = "Check Your Email"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        
        descriptionLabel.text = "We've sent a password reset link to:"
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .systemGray
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        emailDisplayLabel.text = email
        emailDisplayLabel.font = UIFont.boldSystemFont(ofSize: 16)
        emailDisplayLabel.textColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
        emailDisplayLabel.textAlignment = .center
        emailDisplayLabel.numberOfLines = 0
        
        verifyButton.setTitle("Open Email App", for: .normal)
        verifyButton.backgroundColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
        verifyButton.setTitleColor(.white, for: .normal)
        verifyButton.layer.cornerRadius = 25
        verifyButton.clipsToBounds = true
        verifyButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        resendButton.setTitle("Resend Link", for: .normal)
        resendButton.setTitleColor(UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0), for: .normal)
        resendButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        
        cancelButton.setTitle("Back to Sign In", for: .normal)
        cancelButton.setTitleColor(.systemGray, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    }
    
    @IBAction func verifyButtonTapped(_ sender: UIButton) {
        //Try default Mail app first
            if let mailURL = URL(string: "message://"), UIApplication.shared.canOpenURL(mailURL) {
                UIApplication.shared.open(mailURL) { _ in
                    self.dismiss(animated: true)  // Optional: close screen after opening
                }
                return
            }
            
            // Try Gmail
            if let gmailURL = URL(string: "googlegmail://"), UIApplication.shared.canOpenURL(gmailURL) {
                UIApplication.shared.open(gmailURL) { _ in
                    self.dismiss(animated: true)
                }
                return
            }
            
            // Try Outlook
            if let outlookURL = URL(string: "ms-outlook://"), UIApplication.shared.canOpenURL(outlookURL) {
                UIApplication.shared.open(outlookURL) { _ in
                    self.dismiss(animated: true)
                }
                return
            }
            
            // Fallback message if no email apps available
            showAlert(
                title: "Info",
                message: "No email app found. Please check your inbox manually for the password reset link."
            )
    }
    
    @IBAction func resendButtonTapped(_ sender: UIButton) {
        guard !isLoading else { return }
        
        isLoading = true
        showLoadingIndicator()
        
        FirebaseAuthManager.shared.sendPasswordResetEmail(email: email) { [weak self] result in
            guard let self = self else { return }
            
            self.hideLoadingIndicator()
            self.isLoading = false
            
            switch result {
            case .success:
                print("✅ Password reset link resent to: \(self.email)")
                self.showSuccessAlert(message: "Password reset link has been resent to \(self.email)")
                
            case .failure(let error):
                let errorMessage = FirebaseAuthManager.shared.getErrorMessage(from: error)
                self.showAlert(title: "Error", message: errorMessage)
                print("❌ Resend error: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
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
    
    // MARK: - Alerts
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func showSuccessAlert(message: String) {
        let alert = UIAlertController(title: "Success ✅", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func showInfoMessage() {
        let alert = UIAlertController(
            title: "Check Your Email 📧",
            message: "Click the link in the email we sent to \(email) to reset your password.\n\nThe link will open Firebase where you can set your new password.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got It", style: .default))
        present(alert, animated: true)
    }
}
