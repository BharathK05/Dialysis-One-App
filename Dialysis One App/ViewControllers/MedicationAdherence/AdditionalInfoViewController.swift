import UIKit

class AdditionalInfoViewController: UIViewController {
    
    weak var flowDelegate: MedicationFlowStepDelegate?
    var initialData: MedicationFlowData?
    
    private var medicationDescription: String = ""
    private var instructions: String = ""
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let descriptionTextField = UITextField()
    private let instructionsLabel = UILabel()
    private let instructionsTextView = UITextView()
    private let nextButton = UIButton(type: .system)
    private let skipButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let data = initialData {
            medicationDescription = data.description
            instructions = data.instructions
        }
        
        setupUI()
        setupKeyboardHandling()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        addTopGradientBackground()
        title = "Additional Info"
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Progress bar
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progress = 0.8
        progressBar.tintColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        progressBar.trackTintColor = UIColor.systemGray5
        contentView.addSubview(progressBar)
        
        // Title
        titleLabel.text = "Additional Info"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "Optional details (you can skip this)"
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .left
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // Description label
        descriptionLabel.text = "Description"
        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionLabel)
        
        // Description text field
        descriptionTextField.placeholder = "e.g., Blood pressure medication"
        descriptionTextField.text = medicationDescription
        descriptionTextField.font = UIFont.systemFont(ofSize: 16)
        descriptionTextField.backgroundColor = .white
        descriptionTextField.layer.cornerRadius = 12
        descriptionTextField.layer.shadowColor = UIColor.black.cgColor
        descriptionTextField.layer.shadowOffset = CGSize(width: 0, height: 2)
        descriptionTextField.layer.shadowRadius = 8
        descriptionTextField.layer.shadowOpacity = 0.08
        descriptionTextField.returnKeyType = .next
        descriptionTextField.delegate = self
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        descriptionTextField.leftView = paddingView
        descriptionTextField.leftViewMode = .always
        descriptionTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        descriptionTextField.rightViewMode = .always
        
        descriptionTextField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionTextField)
        
        // Instructions label
        instructionsLabel.text = "Instructions (Optional)"
        instructionsLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        instructionsLabel.textColor = .secondaryLabel
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(instructionsLabel)
        
        // Instructions text view
        instructionsTextView.text = instructions
        instructionsTextView.font = UIFont.systemFont(ofSize: 16)
        instructionsTextView.backgroundColor = .white
        instructionsTextView.layer.cornerRadius = 12
        instructionsTextView.layer.shadowColor = UIColor.black.cgColor
        instructionsTextView.layer.shadowOffset = CGSize(width: 0, height: 2)
        instructionsTextView.layer.shadowRadius = 8
        instructionsTextView.layer.shadowOpacity = 0.08
        instructionsTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        instructionsTextView.delegate = self
        instructionsTextView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(instructionsTextView)
        
        if instructions.isEmpty {
            instructionsTextView.text = "e.g., Take with food"
            instructionsTextView.textColor = .placeholderText
        }
        
        // Skip button
        skipButton.setTitle("Skip", for: .normal)
        skipButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        skipButton.setTitleColor(UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0), for: .normal)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(skipButton)
        
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
            
            descriptionLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            descriptionTextField.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            descriptionTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            descriptionTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            descriptionTextField.heightAnchor.constraint(equalToConstant: 52),
            
            instructionsLabel.topAnchor.constraint(equalTo: descriptionTextField.bottomAnchor, constant: 24),
            instructionsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            instructionsTextView.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 8),
            instructionsTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            instructionsTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            instructionsTextView.heightAnchor.constraint(equalToConstant: 100),
            
            skipButton.topAnchor.constraint(equalTo: instructionsTextView.bottomAnchor, constant: 20),
            skipButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            skipButton.heightAnchor.constraint(equalToConstant: 44),
            
            nextButton.topAnchor.constraint(equalTo: skipButton.bottomAnchor, constant: 8),
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
    @objc private func nextTapped() {
        proceedToNextStep()
    }
    
    @objc private func skipTapped() {
        proceedToNextStep()
    }
    
    private func proceedToNextStep() {
        medicationDescription = descriptionTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        instructions = instructionsTextView.textColor == .placeholderText ? "" : instructionsTextView.text?.trimmingCharacters(in: .whitespaces) ?? ""
        
        var data = initialData ?? MedicationFlowData()
        data.description = medicationDescription.isEmpty ? "No description" : medicationDescription
        data.instructions = instructions
        
        flowDelegate?.flowStepDidComplete(.info, data: data)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - UITextFieldDelegate
extension AdditionalInfoViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        instructionsTextView.becomeFirstResponder()
        return true
    }
}

// MARK: - UITextViewDelegate
extension AdditionalInfoViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "e.g., Take with food"
            textView.textColor = .placeholderText
        }
    }
}
