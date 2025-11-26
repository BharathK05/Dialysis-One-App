//
//  SceneDelegate.swift
//  Dialysis One App
//
//  Created by user@22 on 08/11/25.
//
import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)

        let user = Auth.auth().currentUser

        if let u = user, u.isEmailVerified {

            let onboardingKey = "onboardingCompleted_\(u.uid)"
            let introKey = "featureIntroSeen_\(u.uid)"

            let introSeen = UserDefaults.standard.bool(forKey: introKey)
            let onboardingDone = UserDefaults.standard.bool(forKey: onboardingKey)

            // 1️⃣ User logged in but has never seen feature introduction
            if introSeen == false {
                let introVC = WelcomeFeaturesViewController()
                introVC.modalPresentationStyle = .fullScreen
                window?.rootViewController = introVC
            }
            // 2️⃣ Show onboarding only if feature intro is done but onboarding not completed
            else if onboardingDone == false {
                let onboardingVC = OnboardingViewController(
                    nibName: "OnboardingViewController",
                    bundle: nil
                )
                let nav = UINavigationController(rootViewController: onboardingVC)
                nav.setNavigationBarHidden(true, animated: false)
                window?.rootViewController = nav
            }
            // 3️⃣ Everything completed — go to home
            else {
                window?.rootViewController = MainTabBarController()
            }
        }
        // USER NOT LOGGED IN
        else {
            let loginVC = SignInViewController(nibName: "SignInViewController", bundle: nil)
            let nav = UINavigationController(rootViewController: loginVC)
            nav.setNavigationBarHidden(true, animated: false)
            window?.rootViewController = nav
        }

        window?.makeKeyAndVisible()
    }
}
