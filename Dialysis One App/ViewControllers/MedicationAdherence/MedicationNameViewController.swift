import UIKit

class MedicationNameViewController: UIViewController {
    
    weak var flowDelegate: MedicationFlowStepDelegate?
    
    private var medicationName: String = ""
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let nameTextField = UITextField()
    private let nextButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardHandling()
        nameTextField.becomeFirstResponder()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        addTopGradientBackground()
        
        // Configure navigation bar
        title = "Add Medication"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Progress bar
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progress = 0.2
        progressBar.tintColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        progressBar.trackTintColor = UIColor.systemGray5
        contentView.addSubview(progressBar)
        
        // Title
        titleLabel.text = "Medication Name"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "What medication are you taking?"
        subtitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // Text field container
        let textFieldContainer = UIView()
        textFieldContainer.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        textFieldContainer.layer.cornerRadius = 12
        textFieldContainer.layer.shadowColor = UIColor.black.cgColor
        textFieldContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        textFieldContainer.layer.shadowRadius = 8
        textFieldContainer.layer.shadowOpacity = 0.08
        textFieldContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textFieldContainer)
        
        // Name text field
        nameTextField.placeholder = "e.g., Amlodipine"
        nameTextField.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        nameTextField.textAlignment = .left
        nameTextField.returnKeyType = .next
        nameTextField.autocapitalizationType = .words
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        nameTextField.leftView = paddingView
        nameTextField.leftViewMode = .always
        nameTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        nameTextField.rightViewMode = .always
        
        textFieldContainer.addSubview(nameTextField)
        
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
        nextButton.isEnabled = false
        nextButton.alpha = 0.5
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
            
            textFieldContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            textFieldContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            textFieldContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            textFieldContainer.heightAnchor.constraint(equalToConstant: 60),
            
            nameTextField.topAnchor.constraint(equalTo: textFieldContainer.topAnchor),
            nameTextField.leadingAnchor.constraint(equalTo: textFieldContainer.leadingAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor),
            nameTextField.bottomAnchor.constraint(equalTo: textFieldContainer.bottomAnchor),
            
            nextButton.topAnchor.constraint(equalTo: textFieldContainer.bottomAnchor, constant: 32),
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
        medicationName = nameTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        
        let isValid = !medicationName.isEmpty
        nextButton.isEnabled = isValid
        
        UIView.animate(withDuration: 0.2) {
            self.nextButton.alpha = isValid ? 1.0 : 0.5
        }
    }
    
    @objc private func nextTapped() {
        guard !medicationName.isEmpty else { return }
        
        var data = MedicationFlowData()
        data.name = medicationName
        
        flowDelegate?.flowStepDidComplete(.name, data: data)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @objc private func cancelTapped() {
        flowDelegate?.flowStepDidCancel()
    }
}
