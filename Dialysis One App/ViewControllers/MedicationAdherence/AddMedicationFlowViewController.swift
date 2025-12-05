import UIKit

// MARK: - Medication Flow Data Model
struct MedicationFlowData {
    var name: String = ""
    var dosage: String = ""
    var unit: String = "mg"
    var selectedTimes: Set<TimeOfDay> = []
    var description: String = ""
    var instructions: String = ""
}

// MARK: - Flow Delegate
protocol AddMedicationFlowDelegate: AnyObject {
    func medicationFlowDidComplete(_ data: MedicationFlowData)
    func medicationFlowDidCancel()
}

// MARK: - Main Flow Coordinator
class AddMedicationFlowViewController: UINavigationController {
    
    weak var flowDelegate: AddMedicationFlowDelegate?
    private var flowData = MedicationFlowData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(red: 0.78, green: 0.93, blue: 0.82, alpha: 1.0)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.tintColor = .systemBlue
        
        // Start flow
        let nameVC = MedicationNameViewController()
        nameVC.flowDelegate = self
        setViewControllers([nameVC], animated: false)
    }
    
    // MARK: - Flow Navigation
    func updateFlowData(_ data: MedicationFlowData) {
        self.flowData = data
    }
    
    func getFlowData() -> MedicationFlowData {
        return flowData
    }
}

// MARK: - Flow Step Delegate
extension AddMedicationFlowViewController: MedicationFlowStepDelegate {
    func flowStepDidComplete(_ step: MedicationFlowStep, data: MedicationFlowData) {
        updateFlowData(data)
        
        switch step {
        case .name:
            let dosageVC = DosageSelectionViewController()
            dosageVC.flowDelegate = self
            dosageVC.initialData = flowData
            pushViewController(dosageVC, animated: true)
            
        case .dosage:
            let timeVC = TimeSchedulingViewController()
            timeVC.flowDelegate = self
            timeVC.initialData = flowData
            pushViewController(timeVC, animated: true)
            
        case .time:
            let infoVC = AdditionalInfoViewController()
            infoVC.flowDelegate = self
            infoVC.initialData = flowData
            pushViewController(infoVC, animated: true)
            
        case .info:
            let reviewVC = MedicationReviewViewController()
            reviewVC.flowDelegate = self
            reviewVC.medicationData = flowData
            pushViewController(reviewVC, animated: true)
            
        case .review:
            // Flow complete
            flowDelegate?.medicationFlowDidComplete(flowData)
            dismiss(animated: true)
        }
    }
    
    func flowStepDidCancel() {
        flowDelegate?.medicationFlowDidCancel()
        dismiss(animated: true)
    }
}

// MARK: - Flow Step Protocol
enum MedicationFlowStep {
    case name, dosage, time, info, review
}

protocol MedicationFlowStepDelegate: AnyObject {
    func flowStepDidComplete(_ step: MedicationFlowStep, data: MedicationFlowData)
    func flowStepDidCancel()
}
