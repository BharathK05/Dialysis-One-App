import UIKit

class NutrientsViewController: UIViewController {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel = UILabel()
    private let caloriesTextField = UITextField()
    private let waterTextField = UITextField()
    
    private let nextButton = UIButton(type: .system)
    private let defaultButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 250/255, green: 252/255, blue: 251/255, alpha: 1.0)
        setupUI()
        setupKeyboardDismissal()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        setupScrollView()
        setupTitle()
        setupCaloriesField()
        setupWaterField()
        setupButtons()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupTitle() {
        titleLabel.text = "Set your daily nutrient limits\n& fluid intake."
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = UIColor(red: 106/255, green: 156/255, blue: 137/255, alpha: 1.0)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Add subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Customize your daily targets to match your health goals"
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .darkGray
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40)
        ])
    }
    
    private func setupCaloriesField() {
        let container = createInputContainer(
            icon: "flame.fill",
            iconColor: UIColor(red: 255/255, green: 149/255, blue: 0/255, alpha: 1.0),
            label: "Total Calories",
            placeholder: "e.g., 2000",
            unit: "Kcal",
            textField: caloriesTextField
        )
        
        contentView.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.subviews[1].bottomAnchor, constant: 50),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            container.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func setupWaterField() {
        let container = createInputContainer(
            icon: "drop.fill",
            iconColor: UIColor(red: 0/255, green: 122/255, blue: 255/255, alpha: 1.0),
            label: "Water Intake",
            placeholder: "e.g., 2.5",
            unit: "L",
            textField: waterTextField
        )
        
        contentView.addSubview(container)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.subviews[contentView.subviews.count - 2].bottomAnchor, constant: 20),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            container.heightAnchor.constraint(equalToConstant: 80),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -200)
        ])
    }
    
    private func createInputContainer(icon: String, iconColor: UIColor, label: String, placeholder: String, unit: String, textField: UITextField) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 20
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 8
        container.layer.shadowOpacity = 0.08
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon background circle
        let iconBackground = UIView()
        iconBackground.backgroundColor = iconColor.withAlphaComponent(0.15)
        iconBackground.layer.cornerRadius = 22
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconBackground)
        
        // Icon
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: iconConfig))
        iconView.tintColor = iconColor
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconBackground.addSubview(iconView)
        
        // Label
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        labelView.textColor = .darkGray
        labelView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(labelView)
        
        // Text Field
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        textField.textAlignment = .left
        textField.textColor = .black
        textField.keyboardType = .decimalPad
        textField.backgroundColor = UIColor(red: 248/255, green: 248/255, blue: 250/255, alpha: 1.0)
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor(red: 230/255, green: 230/255, blue: 235/255, alpha: 1.0).cgColor
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // Add padding to text field
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 40))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        container.addSubview(textField)
        
        // Unit Label
        let unitLabel = UILabel()
        unitLabel.text = unit
        unitLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        unitLabel.textColor = .darkGray
        unitLabel.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 245/255, alpha: 1.0)
        unitLabel.textAlignment = .center
        unitLabel.layer.cornerRadius = 10
        unitLabel.clipsToBounds = true
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(unitLabel)
        
        NSLayoutConstraint.activate([
            iconBackground.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconBackground.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 44),
            iconBackground.heightAnchor.constraint(equalToConstant: 44),
            
            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),
            
            labelView.leadingAnchor.constraint(equalTo: iconBackground.trailingAnchor, constant: 16),
            labelView.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            
            textField.leadingAnchor.constraint(equalTo: labelView.leadingAnchor),
            textField.topAnchor.constraint(equalTo: labelView.bottomAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: unitLabel.leadingAnchor, constant: -10),
            textField.heightAnchor.constraint(equalToConstant: 40),
            
            unitLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            unitLabel.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            unitLabel.widthAnchor.constraint(equalToConstant: 50),
            unitLabel.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        return container
    }
    
    private func setupButtons() {
        // Next Button
        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        nextButton.backgroundColor = UIColor(red: 106/255, green: 156/255, blue: 137/255, alpha: 1.0)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 16
        nextButton.layer.shadowColor = UIColor(red: 106/255, green: 156/255, blue: 137/255, alpha: 1.0).cgColor
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        nextButton.layer.shadowRadius = 12
        nextButton.layer.shadowOpacity = 0.3
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
        // Add touch animation
        nextButton.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        nextButton.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        view.addSubview(nextButton)
        
        // Default Button
        defaultButton.setTitle("Use default values", for: .normal)
        defaultButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        defaultButton.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 247/255, alpha: 1.0)
        defaultButton.setTitleColor(UIColor(red: 106/255, green: 156/255, blue: 137/255, alpha: 1.0), for: .normal)
        defaultButton.layer.cornerRadius = 16
        defaultButton.layer.borderWidth = 1.5
        defaultButton.layer.borderColor = UIColor(red: 220/255, green: 220/255, blue: 225/255, alpha: 1.0).cgColor
        defaultButton.translatesAutoresizingMaskIntoConstraints = false
        defaultButton.addTarget(self, action: #selector(useDefaultValues), for: .touchUpInside)
        
        // Add touch animation
        defaultButton.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        defaultButton.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        view.addSubview(defaultButton)
        
        NSLayoutConstraint.activate([
            defaultButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            defaultButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            defaultButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            defaultButton.heightAnchor.constraint(equalToConstant: 56),
            
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            nextButton.bottomAnchor.constraint(equalTo: defaultButton.topAnchor, constant: -16),
            nextButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            sender.alpha = 0.8
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = .identity
            sender.alpha = 1.0
        }
    }
    
    // MARK: - Actions
    @objc private func nextButtonTapped() {
        // Validate and save user input
        let calories = Int(caloriesTextField.text ?? "") ?? 2000
        let water = Double(waterTextField.text ?? "") ?? 2.5
        
        saveNutrientValues(calories: calories, water: water)
        finishOnboarding()
    }
    
    @objc private func useDefaultValues() {
        // Use default values
        saveNutrientValues(calories: 2000, water: 2.5)
        finishOnboarding()
    }
    
    private func saveNutrientValues(calories: Int, water: Double) {
        guard let uid = FirebaseAuthManager.shared.getUserID() else { return }
        
        // Save to UserDefaults or your data manager
        UserDataManager.shared.save("totalCalories", value: calories, uid: uid)
        UserDataManager.shared.save("waterGoal", value: Int(water * 1000), uid: uid) // Convert to ml
        
        // You can add more nutrient values here if needed
        UserDataManager.shared.save("potassiumGoal", value: 90, uid: uid)
        UserDataManager.shared.save("sodiumGoal", value: 70, uid: uid)
        UserDataManager.shared.save("proteinGoal", value: 110, uid: uid)
    }
    
    private func finishOnboarding() {
        // Mark onboarding as completed
        if let uid = FirebaseAuthManager.shared.getUserID() {
            UserDefaults.standard.set(true, forKey: "onboardingCompleted_\(uid)")
        }
        
        goToHome()
    }
    
    private func goToHome() {
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            sceneDelegate.window?.rootViewController = MainTabBarController()
            sceneDelegate.window?.makeKeyAndVisible()
        }
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // Keyboard notifications
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardFrame.height
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
