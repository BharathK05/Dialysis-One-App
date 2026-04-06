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
        let topColor = UIColor(red: 225/255, green: 245/255, blue: 235/255, alpha: 1)
        let bottomColor = UIColor(red: 200/255, green: 235/255, blue: 225/255, alpha: 1)

        // 🎨 Gradient color blend
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]

        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)

        // 💡 Key part: change the "locations"
        gradientLayer.locations = [0.0, 0.7] as [NSNumber]

        // 👀 Optional: smoother blending curve
        gradientLayer.type = .axial

        // Make sure gradient covers the full frame
        gradientLayer.frame = bounds
    }
}
