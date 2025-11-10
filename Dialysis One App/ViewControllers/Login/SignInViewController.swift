//
//  SignInViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 08/11/25.
//

import UIKit

class SignInViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    
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
            
            // VALIDATION: Only allow user@email.com / user
            if email.lowercased() == "user@email.com" && password == "user" {
                // Login successful
                print("Login successful!")
                navigateToTabBar()
            } else {
                // Login failed
                showAlert(message: "Invalid email or password")
            }
    }
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        
        let SignUpVC = SignUpViewController(nibName: "SignUpViewController", bundle: nil)
            SignUpVC.modalPresentationStyle = .fullScreen
            present(SignUpVC, animated: true)
    }
    
    // MARK: - Navigation
    func navigateToTabBar() {
        let tabBarController = MainTabBarController()
        tabBarController.modalPresentationStyle = .fullScreen
        present(tabBarController, animated: true)
    }
    
    // MARK: - Alert
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    

}
