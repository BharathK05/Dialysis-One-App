//
//  MainTabBarController.swift
//  Dialysis One App
//
//  Created by user@22 on 08/11/25.
//

import Foundation
import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        customizeTabBar()
    }
    
    func setupTabs() {
        // Create view controllers from XIBs
        let homeVC = HomeDashboardViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        
        let healthandvitalsVC = HealthAndVitalsViewController()
        let vitalsNav = UINavigationController(rootViewController: healthandvitalsVC)
        
        let reliefguideVC = ReliefGuideViewController(nibName: "ReliefGuideViewController", bundle: nil)
        
        // Set tab bar items ON THE NAVIGATION CONTROLLERS
        homeNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        vitalsNav.tabBarItem = UITabBarItem(
            title: "Health and Vitals",
            image: UIImage(systemName: "heart.text.clipboard"),
            selectedImage: UIImage(systemName: "heart.text.clipboard.fill")
        )
        
        reliefguideVC.tabBarItem = UITabBarItem(
            title: "Relief Guide",
            image: UIImage(systemName: "stethoscope"),
            selectedImage: UIImage(systemName: "stethoscope")
        )
        
        // Add NAVIGATION CONTROLLERS to tab bar
        viewControllers = [homeNav, vitalsNav, reliefguideVC]
    }
    
    func customizeTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()   // ← THIS makes it transparent
        appearance.backgroundColor = .clear               // No color
        appearance.shadowColor = .clear                   // No top border line

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance

        tabBar.tintColor = UIColor(red: 0.3, green: 0.7, blue: 0.5, alpha: 1.0) // Selected
        tabBar.unselectedItemTintColor = .systemGray     // Unselected
    }

}
