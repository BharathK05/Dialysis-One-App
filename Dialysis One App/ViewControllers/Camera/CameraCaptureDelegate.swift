import UIKit

protocol CameraCaptureDelegate: AnyObject {
    func cameraCaptureDidCaptureFood(image: UIImage, result: FoodRecognitionResult)
    func cameraCaptureDidCancel()
}
