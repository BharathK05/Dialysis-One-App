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
        view.backgroundColor = .systemBackground
        
        // Configure navigation bar
        title = "Step 1 of 5"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Progress container for custom progress bar
        let progressContainer = UIView()
        progressContainer.backgroundColor = UIColor.systemGray5.withAlphaComponent(0.5)
        progressContainer.layer.cornerRadius = 4
        progressContainer.clipsToBounds = true
        progressContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(progressContainer)
        
        let progressFill = UIView()
        progressFill.backgroundColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        progressFill.layer.cornerRadius = 4
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressContainer.addSubview(progressFill)
        
        // Icon
        let iconView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)
        iconView.image = UIImage(systemName: "pills.circle.fill", withConfiguration: config)
        iconView.tintColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)
        
        // Title
        titleLabel.text = "Add Medication"
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .heavy)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "What medication are you taking?"
        subtitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // Text field container
        let textFieldContainer = UIView()
        textFieldContainer.backgroundColor = AppTheme.glassCard
        textFieldContainer.layer.cornerRadius = 20
        textFieldContainer.layer.borderWidth = 1
        textFieldContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        textFieldContainer.layer.shadowColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0).cgColor
        textFieldContainer.layer.shadowOffset = CGSize(width: 0, height: 6)
        textFieldContainer.layer.shadowRadius = 16
        textFieldContainer.layer.shadowOpacity = 0.15
        textFieldContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textFieldContainer)
        
        let pillIcon = UIImageView(image: UIImage(systemName: "pill"))
        pillIcon.tintColor = .systemGray2
        pillIcon.translatesAutoresizingMaskIntoConstraints = false
        pillIcon.setContentHuggingPriority(.required, for: .horizontal)
        textFieldContainer.addSubview(pillIcon)
        
        // Name text field
        nameTextField.placeholder = "e.g., Amlodipine"
        nameTextField.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        nameTextField.textColor = .label
        nameTextField.textAlignment = .left
        nameTextField.returnKeyType = .next
        nameTextField.autocapitalizationType = .words
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        textFieldContainer.addSubview(nameTextField)
        
        // Next button
        nextButton.setTitle("Continue", for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        nextButton.backgroundColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 18
        nextButton.layer.shadowColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0).cgColor
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        nextButton.layer.shadowRadius = 14
        nextButton.layer.shadowOpacity = 0.3
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.isEnabled = false
        nextButton.alpha = 0.4
        contentView.addSubview(nextButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            progressContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            progressContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            progressContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            progressContainer.heightAnchor.constraint(equalToConstant: 8),
            
            progressFill.topAnchor.constraint(equalTo: progressContainer.topAnchor),
            progressFill.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressContainer.bottomAnchor),
            progressFill.widthAnchor.constraint(equalTo: progressContainer.widthAnchor, multiplier: 0.2), // Step 1
            
            iconView.topAnchor.constraint(equalTo: progressContainer.bottomAnchor, constant: 48),
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),
            
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            textFieldContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            textFieldContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            textFieldContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            textFieldContainer.heightAnchor.constraint(equalToConstant: 72),
            
            pillIcon.leadingAnchor.constraint(equalTo: textFieldContainer.leadingAnchor, constant: 20),
            pillIcon.centerYAnchor.constraint(equalTo: textFieldContainer.centerYAnchor),
            pillIcon.widthAnchor.constraint(equalToConstant: 24),
            pillIcon.heightAnchor.constraint(equalToConstant: 24),
            
            nameTextField.leadingAnchor.constraint(equalTo: pillIcon.trailingAnchor, constant: 16),
            nameTextField.centerYAnchor.constraint(equalTo: textFieldContainer.centerYAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor, constant: -20),
            nameTextField.bottomAnchor.constraint(equalTo: textFieldContainer.bottomAnchor),
            
            nextButton.topAnchor.constraint(equalTo: textFieldContainer.bottomAnchor, constant: 48),
            nextButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            nextButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            nextButton.heightAnchor.constraint(equalToConstant: 60),
            nextButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private var backgroundGradientLayer: CAGradientLayer?
    
    private func addTopGradientBackground() {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.locations = [0.0, 0.7]
        gradient.type = .axial
        gradient.frame = view.bounds
        gradient.zPosition = -1
        view.layer.insertSublayer(gradient, at: 0)
        self.backgroundGradientLayer = gradient
        updateGradientColors()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateGradientColors()
        }
    }
    
    private func updateGradientColors() {
        backgroundGradientLayer?.colors = [
            AppTheme.gradientTop.resolvedColor(with: traitCollection).cgColor,
            AppTheme.gradientBottom.resolvedColor(with: traitCollection).cgColor
        ]
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer?.frame = view.bounds
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
