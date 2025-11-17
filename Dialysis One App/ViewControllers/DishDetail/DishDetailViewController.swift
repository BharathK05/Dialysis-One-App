//
//  DishDetailViewController.swift
//  Redesigned with quantity controls and proper CKD limits
//
import UIKit

class DishDetailViewController: UIViewController {
    
    // MARK: - Properties
    var recognitionResult: FoodRecognitionResult!
    var foodImage: UIImage!
    
    private var selectedPortion: PortionSize = .medium
    private var quantity: Int = 1
    private var scaledNutrients: ScaledNutrients?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Close button (top right)
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .systemGray
        button.backgroundColor = .clear
        return button
    }()
    
    private let foodImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        return iv
    }()
    
    private let dishNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    // Calories card (large, prominent)
    private let caloriesCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray6
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let caloriesLabel: UILabel = {
        let label = UILabel()
        label.text = "Calories"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .systemGray
        return label
    }()
    
    private let caloriesValueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    // Nutrient indicators (colored dots with labels)
    private let nutrientsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()
    
    // Quantity controls
    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.text = "Quantity"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private let quantityControl: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let minusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("−", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .regular)
        button.tintColor = .label
        return button
    }()
    
    private let quantityValueLabel: UILabel = {
        let label = UILabel()
        label.text = "1"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    private let plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .regular)
        button.tintColor = .label
        return button
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Changes", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.4, green: 0.7, blue: 0.5, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let warningBanner: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed.withAlphaComponent(0.1)
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupUI()
        displayResult()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Add scroll view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add close button
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add components
        contentView.addSubview(foodImageView)
        contentView.addSubview(dishNameLabel)
        contentView.addSubview(caloriesCard)
        caloriesCard.addSubview(caloriesLabel)
        caloriesCard.addSubview(caloriesValueLabel)
        contentView.addSubview(nutrientsStackView)
        contentView.addSubview(quantityLabel)
        contentView.addSubview(quantityControl)
        quantityControl.addSubview(minusButton)
        quantityControl.addSubview(quantityValueLabel)
        quantityControl.addSubview(plusButton)
        contentView.addSubview(warningBanner)
        contentView.addSubview(saveButton)
        
        foodImageView.translatesAutoresizingMaskIntoConstraints = false
        dishNameLabel.translatesAutoresizingMaskIntoConstraints = false
        caloriesCard.translatesAutoresizingMaskIntoConstraints = false
        caloriesLabel.translatesAutoresizingMaskIntoConstraints = false
        caloriesValueLabel.translatesAutoresizingMaskIntoConstraints = false
        nutrientsStackView.translatesAutoresizingMaskIntoConstraints = false
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        quantityControl.translatesAutoresizingMaskIntoConstraints = false
        minusButton.translatesAutoresizingMaskIntoConstraints = false
        quantityValueLabel.translatesAutoresizingMaskIntoConstraints = false
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        warningBanner.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Layout
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            foodImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            foodImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            foodImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            foodImageView.heightAnchor.constraint(equalToConstant: 200),
            
            dishNameLabel.topAnchor.constraint(equalTo: foodImageView.bottomAnchor, constant: 20),
            dishNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dishNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            caloriesCard.topAnchor.constraint(equalTo: dishNameLabel.bottomAnchor, constant: 16),
            caloriesCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            caloriesCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            caloriesCard.heightAnchor.constraint(equalToConstant: 80),
            
            caloriesLabel.topAnchor.constraint(equalTo: caloriesCard.topAnchor, constant: 12),
            caloriesLabel.leadingAnchor.constraint(equalTo: caloriesCard.leadingAnchor, constant: 16),
            
            caloriesValueLabel.topAnchor.constraint(equalTo: caloriesLabel.bottomAnchor, constant: 4),
            caloriesValueLabel.leadingAnchor.constraint(equalTo: caloriesCard.leadingAnchor, constant: 16),
            
            nutrientsStackView.topAnchor.constraint(equalTo: caloriesCard.bottomAnchor, constant: 20),
            nutrientsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nutrientsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            quantityLabel.topAnchor.constraint(equalTo: nutrientsStackView.bottomAnchor, constant: 24),
            quantityLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            quantityControl.topAnchor.constraint(equalTo: quantityLabel.bottomAnchor, constant: 8),
            quantityControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            quantityControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            quantityControl.heightAnchor.constraint(equalToConstant: 50),
            
            minusButton.leadingAnchor.constraint(equalTo: quantityControl.leadingAnchor, constant: 16),
            minusButton.centerYAnchor.constraint(equalTo: quantityControl.centerYAnchor),
            minusButton.widthAnchor.constraint(equalToConstant: 44),
            minusButton.heightAnchor.constraint(equalToConstant: 44),
            
            quantityValueLabel.centerXAnchor.constraint(equalTo: quantityControl.centerXAnchor),
            quantityValueLabel.centerYAnchor.constraint(equalTo: quantityControl.centerYAnchor),
            quantityValueLabel.widthAnchor.constraint(equalToConstant: 60),
            
            plusButton.trailingAnchor.constraint(equalTo: quantityControl.trailingAnchor, constant: -16),
            plusButton.centerYAnchor.constraint(equalTo: quantityControl.centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 44),
            plusButton.heightAnchor.constraint(equalToConstant: 44),
            
            warningBanner.topAnchor.constraint(equalTo: quantityControl.bottomAnchor, constant: 20),
            warningBanner.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            warningBanner.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            saveButton.topAnchor.constraint(equalTo: warningBanner.bottomAnchor, constant: 24),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
        
        // Actions
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        minusButton.addTarget(self, action: #selector(decreaseQuantity), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(increaseQuantity), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Display
    
    private func displayResult() {
        foodImageView.image = foodImage
        dishNameLabel.text = recognitionResult.prediction.displayName
        
        if let nutrients = recognitionResult.nutrients {
            updateNutrientsDisplay(nutrients: nutrients)
        } else {
            showNoNutrientsMessage()
        }
    }
    
    private func updateNutrientsDisplay(nutrients: DishNutrients) {
        // Calculate scaled nutrients (portion × quantity)
        let portion = selectedPortion
        let totalMultiplier = portion.multiplier * Double(quantity)
        scaledNutrients = ScaledNutrients(original: nutrients, multiplier: totalMultiplier)
        
        guard let scaled = scaledNutrients else { return }
        
        // Update calories
        caloriesValueLabel.text = "\(scaled.calories) kcal"
        
        // Clear and rebuild nutrients list
        nutrientsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add nutrient rows
        nutrientsStackView.addArrangedSubview(createNutrientRow(
            title: "Potassium",
            value: "\(scaled.potassium) mg",
            color: UIColor(red: 0.4, green: 0.7, blue: 0.4, alpha: 1.0),
            level: scaled.potassiumLevel
        ))
        
        nutrientsStackView.addArrangedSubview(createNutrientRow(
            title: "Sodium",
            value: "\(scaled.sodium) mg",
            color: UIColor(red: 0.9, green: 0.5, blue: 0.4, alpha: 1.0),
            level: scaled.sodiumLevel
        ))
        
        nutrientsStackView.addArrangedSubview(createNutrientRow(
            title: "Protein",
            value: String(format: "%.1f g", scaled.protein),
            color: UIColor(red: 0.95, green: 0.75, blue: 0.3, alpha: 1.0),
            level: scaled.proteinLevel
        ))
        
        // Update warning banner
        updateWarningBanner(scaled: scaled)
    }
    
    private func createNutrientRow(
        title: String,
        value: String,
        color: UIColor,
        level: SafetyLevel
    ) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        
        // Color indicator dot
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 6
        dot.translatesAutoresizingMaskIntoConstraints = false
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Value label
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(dot)
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 36),
            
            dot.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dot.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 12),
            dot.heightAnchor.constraint(equalToConstant: 12),
            
            titleLabel.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
        ])
        
        // Show warning icon for high levels
        if level == .high {
            let warningIcon = UILabel()
            warningIcon.text = "⚠️"
            warningIcon.font = .systemFont(ofSize: 14)
            warningIcon.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(warningIcon)
            
            NSLayoutConstraint.activate([
                warningIcon.trailingAnchor.constraint(equalTo: valueLabel.leadingAnchor, constant: -8),
                warningIcon.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
        }
        
        return container
    }
    
    private func updateWarningBanner(scaled: ScaledNutrients) {
        warningBanner.subviews.forEach { $0.removeFromSuperview() }
        
        let hasHighLevels = scaled.sodiumLevel == .high ||
                           scaled.potassiumLevel == .high ||
                           scaled.proteinLevel == .high
        
        warningBanner.isHidden = !hasHighLevels
        
        if hasHighLevels {
            let warningLabel = UILabel()
            warningLabel.text = "⚠️ High CKD concern - Consult your dietitian"
            warningLabel.font = .systemFont(ofSize: 15, weight: .semibold)
            warningLabel.textColor = .systemRed
            warningLabel.numberOfLines = 0
            warningLabel.textAlignment = .center
            
            warningBanner.addSubview(warningLabel)
            warningLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                warningLabel.topAnchor.constraint(equalTo: warningBanner.topAnchor, constant: 12),
                warningLabel.leadingAnchor.constraint(equalTo: warningBanner.leadingAnchor, constant: 16),
                warningLabel.trailingAnchor.constraint(equalTo: warningBanner.trailingAnchor, constant: -16),
                warningLabel.bottomAnchor.constraint(equalTo: warningBanner.bottomAnchor, constant: -12)
            ])
        }
    }
    
    private func showNoNutrientsMessage() {
        let messageLabel = UILabel()
        messageLabel.text = "⚠️ Nutritional information not available for this dish."
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textColor = .systemGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        
        nutrientsStackView.addArrangedSubview(messageLabel)
        
        saveButton.isEnabled = false
        saveButton.alpha = 0.5
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func decreaseQuantity() {
        guard quantity > 1 else { return }
        quantity -= 1
        quantityValueLabel.text = "\(quantity)"
        
        if let nutrients = recognitionResult.nutrients {
            updateNutrientsDisplay(nutrients: nutrients)
        }
    }
    
    @objc private func increaseQuantity() {
        guard quantity < 10 else { return } // Max 10 servings
        quantity += 1
        quantityValueLabel.text = "\(quantity)"
        
        if let nutrients = recognitionResult.nutrients {
            updateNutrientsDisplay(nutrients: nutrients)
        }
    }
    
    @objc private func saveButtonTapped() {
        print("\n💾 Saving meal log:")
        print("   Dish: \(recognitionResult.prediction.label)")
        print("   Portion: \(selectedPortion.rawValue)")
        print("   Quantity: \(quantity)")
        if let scaled = scaledNutrients {
            print("   Total Calories: \(scaled.calories) kcal")
            print("   Total Sodium: \(scaled.sodium) mg")
            print("   Total Potassium: \(scaled.potassium) mg")
        }
        
        let alert = UIAlertController(
            title: "Saved!",
            message: "Meal logged successfully",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}
