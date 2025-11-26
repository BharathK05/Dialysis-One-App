//
//  UIViewController+TopMost.swift
//  Dialysis One App
//
//  Created by user@1 on 26/11/25.
//

import Foundation
import UIKit

extension UIViewController {
    static func topMostViewController() -> UIViewController? {
        guard let keyWindow = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        var top = keyWindow.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
