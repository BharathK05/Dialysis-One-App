//
//  SceneDelegate.swift
//  Dialysis One App
//
//  Created by user@22 on 08/11/25.
//

import UIKit
import SwiftUI
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // If your storyboard filename is different, Info.plist usually contains the key UIMainStoryboardFile.
    // We'll attempt to read it; if not present or storyboard missing, we'll gracefully fall back.
    private var mainStoryboardName: String? {
        // Attempt to read the "Main storyboard file base name" from Info.plist
        if let name = Bundle.main.object(forInfoDictionaryKey: "UIMainStoryboardFile") as? String {
            return name
        }
        // Otherwise you can hardcode a fallback here, e.g. "Main" or nil to force fallback behavior.
        return nil
    }

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // If we have a storyboard name, try to instantiate and snapshot its initial VC;
        // if not, show the splash with no snapshot fallback.
        if let storyboardName = mainStoryboardName {
            let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
            if let initialVC = storyboard.instantiateInitialViewController() {
                // Prepare the view for snapshot (best-effort)
                initialVC.view.frame = UIScreen.main.bounds
                initialVC.view.setNeedsLayout()
                initialVC.view.layoutIfNeeded()
                initialVC.loadViewIfNeeded()

                // Render snapshot of the view hierarchy
                let renderer = UIGraphicsImageRenderer(bounds: initialVC.view.bounds)
                let snapshotImage = renderer.image { _ in
                    // Use afterScreenUpdates: true to get final rendered state
                    initialVC.view.drawHierarchy(in: initialVC.view.bounds, afterScreenUpdates: true)
                }
                let snapshotSwiftUIImage = Image(uiImage: snapshotImage)

                // Show splash with snapshot
                showSplash(with: snapshotSwiftUIImage, in: window)
                return
            } else {
                // storyboard exists but no initial VC — fallback
                showSplash(with: nil, in: window)
                return
            }
        } else {
            // No storyboard name found in Info.plist — fallback
            showSplash(with: nil, in: window)
            return
        }
    }

    // Show the SwiftUI splash; when it completes it will call showAppRoot()
    private func showSplash(with snapshot: Image?, in window: UIWindow) {
        // Choose a target font size that will fit on one line. Try 64 or 68 — tweak if you want larger/smaller.
        let targetFontSize: CGFloat = 64.0
        let subtitleSize: CGFloat = 16.0

        // Create the splash using the initializer that matches your current LogoTextSplashView file.
        // The completion closure will call showAppRoot() when the animation finishes.
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
    
    func switchToWelcome() {
        guard let window = window else { return }

        let welcomeVC = WelcomeAuthViewController()
        let nav = UINavigationController(rootViewController: welcomeVC)
        

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


    // MARK: - Your existing app-root selection logic (unchanged)
    private func showAppRoot() {
        DispatchQueue.main.async {
            guard let window = self.window else { return }

            let user = Auth.auth().currentUser

            if let u = user, u.isEmailVerified {

                let onboardingKey = "onboardingCompleted_\(u.uid)"
                let onboardingDone = UserDefaults.standard.bool(forKey: onboardingKey)

                if onboardingDone == false {
                    let onboardingVC = OnboardingViewController(
                        nibName: "OnboardingViewController",
                        bundle: nil
                    )

                    let nav = UINavigationController(rootViewController: onboardingVC)
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
                    return
                } else {
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
                    return
                }

            } else {
                let welcomeVC = WelcomeAuthViewController()
                let nav = UINavigationController(rootViewController: welcomeVC)
            

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
        }
    }

}
