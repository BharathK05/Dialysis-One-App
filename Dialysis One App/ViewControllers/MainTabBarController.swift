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
        let homeVC = HomeViewController(nibName: "HomeViewController", bundle: nil)
        let healthandvitalsVC = HealthAndVitalsViewController(nibName: "HealthAndVitalsViewController", bundle: nil)
        let reliefguideVC = ReliefGuideViewController(nibName: "ReliefGuideViewController", bundle: nil)
        
        // Set tab bar items
        homeVC.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        healthandvitalsVC.tabBarItem = UITabBarItem(
            title: "Health and Vitals",
            image: UIImage(systemName: "heart.text.clipboard"),
            selectedImage: UIImage(systemName: "heart.text.clipboard.fill")
        )
        
        reliefguideVC.tabBarItem = UITabBarItem(
            title: "Relief Guide",
            image: UIImage(systemName: "stethoscope"),
            selectedImage: UIImage(systemName: "stethoscope")
        )
        
        // Add to tab bar
        viewControllers = [homeVC, healthandvitalsVC, reliefguideVC]
    }
    
    func customizeTabBar() {
        // Match your design colors
        tabBar.tintColor = UIColor(red: 0.3, green: 0.7, blue: 0.5, alpha: 1.0) // Green
        tabBar.unselectedItemTintColor = .systemGray
        tabBar.backgroundColor = .white
    }
}
