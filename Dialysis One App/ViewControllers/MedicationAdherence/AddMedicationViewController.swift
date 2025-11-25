import UIKit

protocol AddMedicationDelegate: AnyObject {
    func didAddMedication()
}

class AddMedicationViewController: UIViewController {
    
    weak var delegate: AddMedicationDelegate?
    private let store = MedicationStore.shared
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let nameTextField = UITextField()
    private let descriptionTextField = UITextField()
    private let dosageTextField = UITextField()
    private var selectedTimes: Set<TimeOfDay> = []
    
    private var timeButtons: [TimeOfDay: UIButton] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.78, green: 0.93, blue: 0.82, alpha: 1.0)
        title = "Add Medication"
        
        // Navigation buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Form Container
        let formCard = UIView()
        formCard.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        formCard.layer.cornerRadius = 20
        formCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(formCard)
        
        // Name Field
        let nameLabel = createLabel("Medication Name *")
        formCard.addSubview(nameLabel)
        
        nameTextField.placeholder = "e.g., Amlodipine"
        nameTextField.backgroundColor = .white
        nameTextField.layer.cornerRadius = 12
        nameTextField.font = UIFont.systemFont(ofSize: 16)
        nameTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        nameTextField.leftViewMode = .always
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        formCard.addSubview(nameTextField)
        
        // Description Field
        let descLabel = createLabel("Description")
        formCard.addSubview(descLabel)
        
        descriptionTextField.placeholder = "e.g., Blood pressure medication"
        descriptionTextField.backgroundColor = .white
        descriptionTextField.layer.cornerRadius = 12
        descriptionTextField.font = UIFont.systemFont(ofSize: 16)
        descriptionTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        descriptionTextField.leftViewMode = .always
        descriptionTextField.translatesAutoresizingMaskIntoConstraints = false
        formCard.addSubview(descriptionTextField)
        
        // Dosage Field
        let dosageLabel = createLabel("Dosage *")
        formCard.addSubview(dosageLabel)
        
        dosageTextField.placeholder = "e.g., 5mg"
        dosageTextField.backgroundColor = .white
        dosageTextField.layer.cornerRadius = 12
        dosageTextField.font = UIFont.systemFont(ofSize: 16)
        dosageTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        dosageTextField.leftViewMode = .always
        dosageTextField.translatesAutoresizingMaskIntoConstraints = false
        formCard.addSubview(dosageTextField)
        
        // Time Selection
        let timeLabel = createLabel("When to take *")
        formCard.addSubview(timeLabel)
        
        let timeStack = UIStackView()
        timeStack.axis = .horizontal
        timeStack.spacing = 12
        timeStack.distribution = .fillEqually
        timeStack.translatesAutoresizingMaskIntoConstraints = false
        formCard.addSubview(timeStack)
        
        for timeOfDay in TimeOfDay.allCases {
            let button = createTimeButton(timeOfDay)
            timeButtons[timeOfDay] = button
            timeStack.addArrangedSubview(button)
        }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            formCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            formCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            formCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            formCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            nameLabel.topAnchor.constraint(equalTo: formCard.topAnchor, constant: 24),
            nameLabel.leadingAnchor.constraint(equalTo: formCard.leadingAnchor, constant: 20),
            
            nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            nameTextField.leadingAnchor.constraint(equalTo: formCard.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: formCard.trailingAnchor, constant: -20),
            nameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            descLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            descLabel.leadingAnchor.constraint(equalTo: formCard.leadingAnchor, constant: 20),
            
            descriptionTextField.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 8),
            descriptionTextField.leadingAnchor.constraint(equalTo: formCard.leadingAnchor, constant: 20),
            descriptionTextField.trailingAnchor.constraint(equalTo: formCard.trailingAnchor, constant: -20),
            descriptionTextField.heightAnchor.constraint(equalToConstant: 50),
            
            dosageLabel.topAnchor.constraint(equalTo: descriptionTextField.bottomAnchor, constant: 20),
            dosageLabel.leadingAnchor.constraint(equalTo: formCard.leadingAnchor, constant: 20),
            
            dosageTextField.topAnchor.constraint(equalTo: dosageLabel.bottomAnchor, constant: 8),
            dosageTextField.leadingAnchor.constraint(equalTo: formCard.leadingAnchor, constant: 20),
            dosageTextField.trailingAnchor.constraint(equalTo: formCard.trailingAnchor, constant: -20),
            dosageTextField.heightAnchor.constraint(equalToConstant: 50),
            
            timeLabel.topAnchor.constraint(equalTo: dosageTextField.bottomAnchor, constant: 20),
            timeLabel.leadingAnchor.constraint(equalTo: formCard.leadingAnchor, constant: 20),
            
            timeStack.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 12),
            timeStack.leadingAnchor.constraint(equalTo: formCard.leadingAnchor, constant: 20),
            timeStack.trailingAnchor.constraint(equalTo: formCard.trailingAnchor, constant: -20),
            timeStack.heightAnchor.constraint(equalToConstant: 50),
            timeStack.bottomAnchor.constraint(equalTo: formCard.bottomAnchor, constant: -24)
        ])
    }
    
    private func createLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createTimeButton(_ timeOfDay: TimeOfDay) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(timeOfDay.rawValue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        button.setTitleColor(.darkGray, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor
        button.addTarget(self, action: #selector(timeButtonTapped(_:)), for: .touchUpInside)
        button.tag = timeOfDay.hashValue
        return button
    }
    
    @objc private func timeButtonTapped(_ sender: UIButton) {
        guard let timeOfDay = TimeOfDay.allCases.first(where: { $0.hashValue == sender.tag }) else { return }
        
        if selectedTimes.contains(timeOfDay) {
            selectedTimes.remove(timeOfDay)
            sender.backgroundColor = UIColor.white.withAlphaComponent(0.8)
            sender.setTitleColor(.darkGray, for: .normal)
            sender.layer.borderColor = UIColor.clear.cgColor
        } else {
            selectedTimes.insert(timeOfDay)
            sender.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
            sender.setTitleColor(.systemGreen, for: .normal)
            sender.layer.borderColor = UIColor.systemGreen.cgColor
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        // Validate
        guard let name = nameTextField.text, !name.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter a medication name")
            return
        }
        
        guard let dosage = dosageTextField.text, !dosage.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter the dosage")
            return
        }
        
        guard !selectedTimes.isEmpty else {
            showAlert(title: "Missing Information", message: "Please select at least one time")
            return
        }
        
        // Create medication
        let description = descriptionTextField.text?.isEmpty == false ? descriptionTextField.text! : "No description"
        let newMedication = Medication(
            name: name,
            description: description,
            times: Array(selectedTimes),
            dosage: dosage
        )
        
        // Add to store
        store.addMedication(newMedication)
        
        // Notify delegate and dismiss
        delegate?.didAddMedication()
        dismiss(animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

