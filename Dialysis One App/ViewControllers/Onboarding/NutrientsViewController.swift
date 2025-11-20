//
//  NutrientsViewController.swift
//  Dialysis One App
//
//  Created by user@1 on 12/11/25.
//

import UIKit

class NutrientsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNextButton()

        // Do any additional setup after loading the view.
    }
    
    private func setupNextButton() {
        let nextButton = UIButton(type: .system)
        nextButton.setTitle("Finish", for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        nextButton.backgroundColor = UIColor(red: 106/255, green: 156/255, blue: 137/255, alpha: 1.0)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 12
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(finishOnboarding), for: .touchUpInside)
        view.addSubview(nextButton)

        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            nextButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    @objc private func finishOnboarding() {

        // mark onboarding finished
        if let uid = FirebaseAuthManager.shared.getUserID() {
            UserDefaults.standard.set(true, forKey: "onboardingCompleted_\(uid)")
        }

        goToHome()
    }
    
    private func goToHome() {
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.window?.rootViewController = MainTabBarController()
            sceneDelegate.window?.makeKeyAndVisible()
        }
    }




    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
