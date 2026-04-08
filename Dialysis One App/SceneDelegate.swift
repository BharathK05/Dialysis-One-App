//
//  SceneDelegate.swift
//  Dialysis One App
//
//  Updated for Guest + Apple ID flow
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private var mainStoryboardName: String? {
        if let name = Bundle.main.object(forInfoDictionaryKey: "UIMainStoryboardFile") as? String {
            return name
        }
        return nil
    }

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        ProfileManager.shared.initializeContainer()

        // Initialize local user ID immediately (creates if doesn't exist)
        let _ = LocalUserManager.shared.getOrCreateLocalUserID()
        
        // Show splash
        if let storyboardName = mainStoryboardName {
            let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
            if let initialVC = storyboard.instantiateInitialViewController() {
                initialVC.view.frame = UIScreen.main.bounds
                initialVC.view.setNeedsLayout()
                initialVC.view.layoutIfNeeded()
                initialVC.loadViewIfNeeded()

                let renderer = UIGraphicsImageRenderer(bounds: initialVC.view.bounds)
                let snapshotImage = renderer.image { _ in
                    initialVC.view.drawHierarchy(in: initialVC.view.bounds, afterScreenUpdates: true)
                }
                let snapshotSwiftUIImage = Image(uiImage: snapshotImage)

                showSplash(with: snapshotSwiftUIImage, in: window)
                return
            }
        }
        
        showSplash(with: nil, in: window)
    }

    private func showSplash(with snapshot: Image?, in window: UIWindow) {
        let targetFontSize: CGFloat = 64.0
        let subtitleSize: CGFloat = 16.0

        let splash = LogoTextSplashView(
            homeSnapshot: snapshot,
            targetFontSize: targetFontSize,
            subtitleSize: subtitleSize
        ) { [weak self] in
            self?.showAppRoot()
        }

        window.rootViewController = UIHostingController(rootView: splash)
        window.makeKeyAndVisible()
    }
    
    // MARK: - 🎯 ROOT SELECTION LOGIC

    private func showAppRoot() {
        DispatchQueue.main.async {
            guard let window = self.window else { return }

            // Onboarding-complete flag is the canonical "user has been through setup" signal.
            // It is set by LocalUserManager.markOnboardingCompleted() at the end of onboarding,
            // regardless of whether the user signed in with Apple or chose Guest.
            let isOnboardingDone = LocalUserManager.shared.isOnboardingCompleted()

            // Belt-and-suspenders: also respect an existing Apple ID or guest flag so that
            // users who updated the app mid-session are never stuck on the welcome screen.
            let hasSession = LocalUserManager.shared.hasAppleID()
                          || LocalUserManager.shared.isGuestUser()

            if isOnboardingDone || hasSession {
                // Returning user → skip welcome, go directly to the main app
                self.showMainApp(in: window)
            } else {
                // First-time user → show welcome / auth screen
                self.showWelcome(in: window)
            }
        }
    }

    
    // MARK: - Navigation Methods
    
    private func showWelcome(in window: UIWindow) {
        let welcomeVC = WelcomeAuthViewController()
        let nav = UINavigationController(rootViewController: welcomeVC)
        nav.setNavigationBarHidden(true, animated: false)

        UIView.transition(
            with: window,
            duration: 0.35,
            options: .transitionCrossDissolve,
            animations: {
                window.rootViewController = nav
            },
            completion: nil
        )
    }
    
    private func showMainApp(in window: UIWindow) {
        let main = MainTabBarController()
        
        UIView.transition(
            with: window,
            duration: 0.35,
            options: .transitionCrossDissolve,
            animations: {
                window.rootViewController = main
            },
            completion: nil
        )
    }
    
    // MARK: - 🆕 PUBLIC METHOD FOR SIGN OUT / RESET
    
    /// Called from ProfileSheetViewController when user signs out or resets
    func returnToWelcome() {
        guard let window = window else { return }
        
        // Smoothly transition back to welcome screen
        let welcomeVC = WelcomeAuthViewController()
        let nav = UINavigationController(rootViewController: welcomeVC)
        nav.setNavigationBarHidden(true, animated: false)

        UIView.transition(
            with: window,
            duration: 0.4,
            options: .transitionCrossDissolve,
            animations: {
                window.rootViewController = nav
            },
            completion: { _ in
                print("✅ Returned to welcome screen")
            }
        )
    }
}
