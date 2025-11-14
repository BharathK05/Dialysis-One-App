//
//  GradientView.swift
//  ReliefGuide
//
//  Created by user@100 on 09/11/25.
//

import UIKit

final class GradientView: UIView {

    // You can tweak these asset color names to match your project
    @IBInspectable var topColorName: String = "AppGradientTop"
    @IBInspectable var bottomColorName: String = "AppGradientBottom"

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let gradientLayer = layer as? CAGradientLayer else { return }

        // Fetch the top and bottom colors
        let topColor = UIColor(named: topColorName) ?? UIColor.systemGreen.withAlphaComponent(0.35)
        let bottomColor = UIColor(named: bottomColorName) ?? UIColor.systemTeal.withAlphaComponent(0.15)

        // 🎨 Gradient color blend
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]

        // 📍 Adjust the points to shift more of the bottom color upward
        // startPoint.y = 0.0 means top of the screen
        // endPoint.y = 1.0 means bottom of the screen
        // but we’ll tweak the location weights to give more dominance to the bottom color
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)

        // 💡 Key part: change the "locations"
        // Default is [0.0, 1.0] → even blend
        // We'll push bottom color dominance (e.g., 70% bottom)
        gradientLayer.locations = [0.0, 0.7] as [NSNumber]

        // 👀 Optional: smoother blending curve
        gradientLayer.type = .axial

        // Make sure gradient covers the full frame
        gradientLayer.frame = bounds
    }
}
