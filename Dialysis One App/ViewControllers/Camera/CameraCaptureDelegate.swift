import UIKit

protocol CameraCaptureDelegate: AnyObject {
    func cameraCaptureDidCaptureFood(image: UIImage, foods: [DetectedFood])
    func cameraCaptureDidRequestRescan()
    func cameraCaptureDidCancel()
}
