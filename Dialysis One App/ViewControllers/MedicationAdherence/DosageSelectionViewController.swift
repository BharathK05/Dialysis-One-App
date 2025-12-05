import UIKit

class DosageSelectionViewController: UIViewController {
    
    weak var flowDelegate: MedicationFlowStepDelegate?
    var initialData: MedicationFlowData?
    
    private var dosageAmount: String = ""
    private var selectedUnit: String = "mg"
    
    private let units = ["mg", "g", "mcg", "ml", "tablet", "capsule", "unit"]
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let dosageTextField = UITextField()
    private let unitLabel = UILabel()
    private let unitPickerView = UIPickerView()
    private let nextButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let data = initialData {
            dosageAmount = data.dosage
            selectedUnit = data.unit
        }
        
        setupUI()
        setupKeyboardHandling()
        dosageTextField.becomeFirstResponder()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        addTopGradientBackground()
        title = "Dosage"
        
        // Back button (default)
        navigationItem.leftBarButtonItem = nil
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Progress bar
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progress = 0.4 // Step 2 of 5
        progressBar.tintColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        progressBar.trackTintColor = UIColor.systemGray5
        contentView.addSubview(progressBar)
        
        // Title
        titleLabel.text = "Dosage"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "How much do you take?"
        subtitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // Container for dosage + unit
        let dosageContainer = UIView()
        dosageContainer.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        dosageContainer.layer.cornerRadius = 12
        dosageContainer.layer.shadowColor = UIColor.black.cgColor
        dosageContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        dosageContainer.layer.shadowRadius = 8
        dosageContainer.layer.shadowOpacity = 0.08
        dosageContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dosageContainer)
        
        // Dosage text field
        dosageTextField.placeholder = "e.g., 5"
        dosageTextField.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        dosageTextField.textAlignment = .right
        dosageTextField.keyboardType = .decimalPad
        dosageTextField.returnKeyType = .next
        dosageTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        dosageTextField.translatesAutoresizingMaskIntoConstraints = false
        dosageContainer.addSubview(dosageTextField)
        
        // Unit label
        unitLabel.text = selectedUnit
        unitLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        unitLabel.textColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        dosageContainer.addSubview(unitLabel)
        
        // Unit picker
        unitPickerView.delegate = self
        unitPickerView.dataSource = self
        if let index = units.firstIndex(of: selectedUnit) {
            unitPickerView.selectRow(index, inComponent: 0, animated: false)
        }
        unitPickerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(unitPickerView)
        
        // Next button
        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        nextButton.backgroundColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 12
        nextButton.layer.shadowColor = UIColor.black.cgColor
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        nextButton.layer.shadowRadius = 12
        nextButton.layer.shadowOpacity = 0.15
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.isEnabled = !dosageAmount.isEmpty
        nextButton.alpha = dosageAmount.isEmpty ? 0.5 : 1.0
        contentView.addSubview(nextButton)
        
        // Constraints
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
            
            progressBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            progressBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            progressBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            progressBar.heightAnchor.constraint(equalToConstant: 4),
            
            titleLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            dosageContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            dosageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            dosageContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            dosageContainer.heightAnchor.constraint(equalToConstant: 70),
            
            dosageTextField.leadingAnchor.constraint(equalTo: dosageContainer.leadingAnchor, constant: 16),
            dosageTextField.centerYAnchor.constraint(equalTo: dosageContainer.centerYAnchor),
            dosageTextField.trailingAnchor.constraint(equalTo: unitLabel.leadingAnchor, constant: -8),
            
            unitLabel.trailingAnchor.constraint(equalTo: dosageContainer.trailingAnchor, constant: -16),
            unitLabel.centerYAnchor.constraint(equalTo: dosageContainer.centerYAnchor),
            unitLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            unitPickerView.topAnchor.constraint(equalTo: dosageContainer.bottomAnchor, constant: 16),
            unitPickerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            unitPickerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            unitPickerView.heightAnchor.constraint(equalToConstant: 150),
            
            nextButton.topAnchor.constraint(equalTo: unitPickerView.bottomAnchor, constant: 24),
            nextButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            nextButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            nextButton.heightAnchor.constraint(equalToConstant: 54),
            nextButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func addTopGradientBackground() {
        let gradient = CAGradientLayer()
        let topColor = UIColor(red: 225/255, green: 245/255, blue: 235/255, alpha: 1)
        let bottomColor = UIColor(red: 200/255, green: 235/255, blue: 225/255, alpha: 1)

        gradient.colors = [topColor.cgColor, bottomColor.cgColor]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.locations = [0.0, 0.7]
        gradient.type = .axial
        gradient.frame = view.bounds
        gradient.zPosition = -1

        view.layer.insertSublayer(gradient, at: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradientLayer = view.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = keyboardFrame.height
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    // MARK: - Actions
    @objc private func textFieldDidChange() {
        dosageAmount = dosageTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        
        let isValid = !dosageAmount.isEmpty
        nextButton.isEnabled = isValid
        
        UIView.animate(withDuration: 0.2) {
            self.nextButton.alpha = isValid ? 1.0 : 0.5
        }
    }
    
    @objc private func nextTapped() {
        guard !dosageAmount.isEmpty else { return }
        
        var data = initialData ?? MedicationFlowData()
        data.dosage = dosageAmount
        data.unit = selectedUnit
        
        flowDelegate?.flowStepDidComplete(.dosage, data: data)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - UIPickerViewDelegate & DataSource
extension DosageSelectionViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return units.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return units[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedUnit = units[row]
        unitLabel.text = selectedUnit
        
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
