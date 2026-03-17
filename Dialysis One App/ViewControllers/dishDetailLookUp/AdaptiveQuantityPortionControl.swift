//
//  AdaptiveQuantityPortionControl.swift
//  Dialysis One App
//
//  Created by user@1 on 22/01/26.
//


//
//  AdaptiveQuantityPortionControl.swift
//  Dialysis One App
//
//  Portion control that adapts UI based on food type
//

import UIKit

class AdaptiveQuantityPortionControl: UIView {
    
    // MARK: - Properties
    
    var onValueChanged: ((Double, AdaptivePortionOption, PortionType) -> Void)?
    
    private var portionType: PortionType = .weight {
        didSet {
            updateForPortionType()
        }
    }
    
    private var currentQuantity: Double = 1.0 {
        didSet {
            updateDisplay()
            notifyChange()
        }
    }
    
    private var currentPortion: AdaptivePortionOption = AdaptivePortionLibrary.defaultPortion(for: .weight) {
        didSet {
            updateDisplay()
            notifyChange()
        }
    }
    
    private var quantityOptions: [Double] = []
    private var portionOptions: [AdaptivePortionOption] = []
    
    // MARK: - UI Components
    
    private let containerCard: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let quantitySection: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let measureSection: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let quantityTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Quantity"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let quantityValueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("1", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.label, for: .normal)
        button.contentHorizontalAlignment = .center
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let chevron = UIImage(systemName: "chevron.down", withConfiguration: config)
        button.setImage(chevron, for: .normal)
        button.tintColor = .secondaryLabel
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        
        return button
    }()
    
    private let measureTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Measure"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let measureValueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Grams", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.label, for: .normal)
        button.contentHorizontalAlignment = .center
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let chevron = UIImage(systemName: "chevron.down", withConfiguration: config)
        button.setImage(chevron, for: .normal)
        button.tintColor = .secondaryLabel
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        
        return button
    }()
    
    private let infoButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "questionmark.circle", withConfiguration: config), for: .normal)
        button.tintColor = .secondaryLabel
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
        updateForPortionType()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupActions()
        updateForPortionType()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(containerCard)
        addSubview(infoButton)
        
        containerCard.addSubview(headerStack)
        
        headerStack.addArrangedSubview(quantitySection)
        headerStack.addArrangedSubview(measureSection)
        
        quantitySection.addSubview(quantityTitleLabel)
        quantitySection.addSubview(quantityValueButton)
        
        measureSection.addSubview(measureTitleLabel)
        measureSection.addSubview(measureValueButton)
        
        NSLayoutConstraint.activate([
            infoButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            infoButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            infoButton.widthAnchor.constraint(equalToConstant: 32),
            infoButton.heightAnchor.constraint(equalToConstant: 32),
            
            containerCard.topAnchor.constraint(equalTo: topAnchor),
            containerCard.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerCard.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerCard.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            headerStack.topAnchor.constraint(equalTo: containerCard.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: containerCard.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: containerCard.trailingAnchor, constant: -16),
            headerStack.bottomAnchor.constraint(equalTo: containerCard.bottomAnchor, constant: -12),
            
            quantityTitleLabel.topAnchor.constraint(equalTo: quantitySection.topAnchor),
            quantityTitleLabel.leadingAnchor.constraint(equalTo: quantitySection.leadingAnchor),
            quantityTitleLabel.trailingAnchor.constraint(equalTo: quantitySection.trailingAnchor),
            
            quantityValueButton.topAnchor.constraint(equalTo: quantityTitleLabel.bottomAnchor, constant: 8),
            quantityValueButton.leadingAnchor.constraint(equalTo: quantitySection.leadingAnchor),
            quantityValueButton.trailingAnchor.constraint(equalTo: quantitySection.trailingAnchor),
            quantityValueButton.heightAnchor.constraint(equalToConstant: 44),
            quantityValueButton.bottomAnchor.constraint(equalTo: quantitySection.bottomAnchor),
            
            measureTitleLabel.topAnchor.constraint(equalTo: measureSection.topAnchor),
            measureTitleLabel.leadingAnchor.constraint(equalTo: measureSection.leadingAnchor),
            measureTitleLabel.trailingAnchor.constraint(equalTo: measureSection.trailingAnchor),
            
            measureValueButton.topAnchor.constraint(equalTo: measureTitleLabel.bottomAnchor, constant: 8),
            measureValueButton.leadingAnchor.constraint(equalTo: measureSection.leadingAnchor),
            measureValueButton.trailingAnchor.constraint(equalTo: measureSection.trailingAnchor),
            measureValueButton.heightAnchor.constraint(equalToConstant: 44),
            measureValueButton.bottomAnchor.constraint(equalTo: measureSection.bottomAnchor)
        ])
    }
    
    private func setupActions() {
        quantityValueButton.addTarget(self, action: #selector(showQuantityPicker), for: .touchUpInside)
        measureValueButton.addTarget(self, action: #selector(showMeasurePicker), for: .touchUpInside)
        infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)
    }
    
    // MARK: - Adaptive UI Updates
    
    private func updateForPortionType() {
        // Update available options
        quantityOptions = AdaptivePortionLibrary.quantityOptions(for: portionType)
        portionOptions = AdaptivePortionLibrary.portions(for: portionType)
        
        // Set default portion for this type
        currentPortion = AdaptivePortionLibrary.defaultPortion(for: portionType)
        
        // Set default quantity
        currentQuantity = quantityOptions.first ?? 1.0
        
        // Update UI visibility based on type
        switch portionType {
        case .meal:
            // MEAL: Hide both controls, show fixed "1 meal"
            quantityValueButton.isEnabled = false
            measureValueButton.isEnabled = false
            quantityValueButton.setTitle("1", for: .normal)
            measureValueButton.setTitle("1 Meal", for: .normal)
            
        case .count:
            // COUNT: Show quantity, hide measure (always "pieces")
            quantityValueButton.isEnabled = true
            measureValueButton.isEnabled = false
            measureValueButton.setTitle("Pieces", for: .normal)
            
        case .weight, .bowl:
            // WEIGHT/BOWL: Show both controls
            quantityValueButton.isEnabled = true
            measureValueButton.isEnabled = true
        }
        
        updateDisplay()
    }
    
    private func updateDisplay() {
        quantityValueButton.setTitle(formatQuantity(currentQuantity), for: .normal)
        measureValueButton.setTitle(currentPortion.label, for: .normal)
    }
    
    // MARK: - Show Pickers
    
    @objc private func showQuantityPicker() {
        guard portionType != .meal else { return }
        guard let viewController = findViewController() else { return }
        
        let pickerVC = QuantityPickerViewController()
        pickerVC.options = quantityOptions
        pickerVC.selectedValue = currentQuantity
        pickerVC.portionType = portionType.rawValue
        pickerVC.onSelect = { [weak self] value in
            self?.currentQuantity = value
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
        
        pickerVC.modalPresentationStyle = .pageSheet
        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        viewController.present(pickerVC, animated: true)
    }
    
    @objc private func showMeasurePicker() {
        guard portionType != .meal && portionType != .count else { return }
        guard let viewController = findViewController() else { return }
        
        let alert = UIAlertController(
            title: "Select Measure",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        for portion in portionOptions {
            let action = UIAlertAction(title: portion.label, style: .default) { [weak self] _ in
                self?.currentPortion = portion
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
            }
            
            if portion.id == currentPortion.id {
                action.setValue(true, forKey: "checked")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = measureValueButton
            popover.sourceRect = measureValueButton.bounds
        }
        
        viewController.present(alert, animated: true)
    }
    
    @objc private func infoTapped() {
        guard let viewController = findViewController() else { return }
        
        let helpVC = QuantityHelpViewController()
        helpVC.modalPresentationStyle = .pageSheet
        
        if let sheet = helpVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        viewController.present(helpVC, animated: true)
    }
    
    // MARK: - Public Methods
    
    func configure(for portionType: PortionType, defaultQuantity: Double) {
        self.portionType = portionType
        self.currentQuantity = defaultQuantity
    }
    
    func getCurrentValues() -> (quantity: Double, portion: AdaptivePortionOption, type: PortionType) {
        return (currentQuantity, currentPortion, portionType)
    }
    
    // MARK: - Private Methods
    
    private func formatQuantity(_ value: Double) -> String {
        switch portionType {
        case .weight:
            return String(format: "%.0f", value)
        case .count:
            return String(format: "%.0f", value)
        case .bowl:
            return value == floor(value) ? String(format: "%.0f", value) : String(format: "%.1f", value)
        case .meal:
            return "1"
        }
    }
    
    private func notifyChange() {
        onValueChanged?(currentQuantity, currentPortion, portionType)
    }
    
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
}