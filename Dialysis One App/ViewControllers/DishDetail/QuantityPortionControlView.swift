//
//  QuantityPortionControlView.swift
//  Dialysis One App
//
//  Unified Quantity & Portion Control with Indian Measures
//

import UIKit

class QuantityPortionControlView: UIView {
    
    // MARK: - Properties
    
    var onValueChanged: ((Double, PortionOption) -> Void)?
    
    private var currentQuantity: Double = 1.0 {
        didSet {
            quantityValueLabel.text = QuantityScale.formatValue(currentQuantity)
            updateNutrients()
        }
    }
    
    private var currentPortion: PortionOption = PortionLibrary.portion(byId: "katori") ?? PortionLibrary.standard[0] {
        didSet {
            portionButton.setTitle(currentPortion.label, for: .normal)
            updateNutrients()
        }
    }
    
    // MARK: - Smart Quantity System
    
    private struct QuantityScale {
        static func getNextValue(from current: Double) -> Double {
            switch current {
            case 0..<1.0:
                return min(current + 0.25, 1.0)
            case 1.0..<5.0:
                return min(current + 0.5, 5.0)
            case 5.0..<10.0:
                return min(current + 1.0, 10.0)
            case 10.0..<50.0:
                return min(current + 5.0, 50.0)
            case 50.0..<100.0:
                return min(current + 10.0, 100.0)
            case 100.0..<2000.0:
                return min(current + 50.0, 2000.0)
            default:
                return 2000.0
            }
        }
        
        static func getPreviousValue(from current: Double) -> Double {
            switch current {
            case 0.25...1.0:
                return max(current - 0.25, 0.25)
            case 1.0...5.0:
                if current == 1.0 { return 0.75 }
                return max(current - 0.5, 1.0)
            case 5.0...10.0:
                if current == 5.0 { return 4.5 }
                return max(current - 1.0, 5.0)
            case 10.0...50.0:
                if current == 10.0 { return 9.0 }
                return max(current - 5.0, 10.0)
            case 50.0...100.0:
                if current == 50.0 { return 45.0 }
                return max(current - 10.0, 50.0)
            case 100.0...2000.0:
                if current == 100.0 { return 90.0 }
                return max(current - 50.0, 100.0)
            default:
                return 0.25
            }
        }
        
        static func formatValue(_ value: Double) -> String {
            if value < 1.0 {
                return String(format: "%.2f", value)
                    .replacingOccurrences(of: ".00", with: "")
                    .replacingOccurrences(of: "0.50", with: "0.5")
            } else if value < 10.0 && value.truncatingRemainder(dividingBy: 1.0) != 0 {
                return String(format: "%.1f", value)
            } else {
                return String(format: "%.0f", value)
            }
        }
    }
    
    // MARK: - UI Components
    
    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Quantity Section
    private let quantityCard: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
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
    
    private let quantityControlStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let decrementButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let quantityValueLabel: UILabel = {
        let label = UILabel()
        label.text = "1"
        label.font = .systemFont(ofSize: 26, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()
    
    private let incrementButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Portion Section
    private let portionCard: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let portionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Measure"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let portionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Katori", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.label, for: .normal)
        button.contentHorizontalAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let chevron = UIImage(systemName: "chevron.down", withConfiguration: config)
        button.setImage(chevron, for: .normal)
        button.tintColor = .secondaryLabel
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        
        return button
    }()
    
    private let infoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "questionmark.circle"), for: .normal)
        button.tintColor = .secondaryLabel
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupActions()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(containerStack)
        
        quantityCard.addSubview(quantityTitleLabel)
        quantityCard.addSubview(quantityControlStack)
        
        quantityControlStack.addArrangedSubview(decrementButton)
        quantityControlStack.addArrangedSubview(quantityValueLabel)
        quantityControlStack.addArrangedSubview(incrementButton)
        
        portionCard.addSubview(portionTitleLabel)
        portionCard.addSubview(portionButton)
        
        containerStack.addArrangedSubview(quantityCard)
        containerStack.addArrangedSubview(portionCard)
        
        addSubview(infoButton)
        
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: topAnchor),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            quantityTitleLabel.topAnchor.constraint(equalTo: quantityCard.topAnchor, constant: 12),
            quantityTitleLabel.leadingAnchor.constraint(equalTo: quantityCard.leadingAnchor, constant: 16),
            quantityTitleLabel.trailingAnchor.constraint(equalTo: quantityCard.trailingAnchor, constant: -16),
            
            quantityControlStack.topAnchor.constraint(equalTo: quantityTitleLabel.bottomAnchor, constant: 16),
            quantityControlStack.leadingAnchor.constraint(equalTo: quantityCard.leadingAnchor, constant: 16),
            quantityControlStack.trailingAnchor.constraint(equalTo: quantityCard.trailingAnchor, constant: -16),
            quantityControlStack.bottomAnchor.constraint(lessThanOrEqualTo: quantityCard.bottomAnchor, constant: -12),
            
            decrementButton.widthAnchor.constraint(equalToConstant: 36),
            decrementButton.heightAnchor.constraint(equalToConstant: 36),
            
            quantityValueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            quantityValueLabel.heightAnchor.constraint(equalToConstant: 40),
            
            incrementButton.widthAnchor.constraint(equalToConstant: 36),
            incrementButton.heightAnchor.constraint(equalToConstant: 36),
            
            portionTitleLabel.topAnchor.constraint(equalTo: portionCard.topAnchor, constant: 12),
            portionTitleLabel.leadingAnchor.constraint(equalTo: portionCard.leadingAnchor, constant: 16),
            portionTitleLabel.trailingAnchor.constraint(equalTo: portionCard.trailingAnchor, constant: -16),
            
            portionButton.topAnchor.constraint(equalTo: portionTitleLabel.bottomAnchor, constant: 12),
            portionButton.leadingAnchor.constraint(equalTo: portionCard.leadingAnchor, constant: 12),
            portionButton.trailingAnchor.constraint(equalTo: portionCard.trailingAnchor, constant: -12),
            portionButton.bottomAnchor.constraint(lessThanOrEqualTo: portionCard.bottomAnchor, constant: -12),
            portionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            
            infoButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            infoButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            infoButton.widthAnchor.constraint(equalToConstant: 24),
            infoButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func setupActions() {
        decrementButton.addTarget(self, action: #selector(decrementTapped), for: .touchUpInside)
        incrementButton.addTarget(self, action: #selector(incrementTapped), for: .touchUpInside)
        portionButton.addTarget(self, action: #selector(portionTapped), for: .touchUpInside)
        infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func decrementTapped() {
        let newValue = QuantityScale.getPreviousValue(from: currentQuantity)
        if newValue != currentQuantity {
            currentQuantity = newValue
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    @objc private func incrementTapped() {
        let newValue = QuantityScale.getNextValue(from: currentQuantity)
        if newValue != currentQuantity {
            currentQuantity = newValue
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    @objc private func portionTapped() {
        showPortionPicker()
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
    
    private func showPortionPicker() {
        guard let viewController = findViewController() else { return }
        
        let alert = UIAlertController(
            title: "Select Portion Size",
            message: "Choose the size that matches your serving",
            preferredStyle: .actionSheet
        )
        
        // Add all standard portions from PortionLibrary
        for portion in PortionLibrary.standard {
            let volumeInfo = portion.ml != nil ? " (\(portion.ml!)ml)" : ""
            let displayTitle = "\(portion.label)\(volumeInfo)"
            
            let action = UIAlertAction(title: displayTitle, style: .default) { [weak self] _ in
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
            popover.sourceView = portionButton
            popover.sourceRect = portionButton.bounds
        }
        
        viewController.present(alert, animated: true)
    }
    
    private func updateNutrients() {
        onValueChanged?(currentQuantity, currentPortion)
    }
    
    // MARK: - Public Methods
    
    func setPortion(_ portion: PortionOption) {
        currentPortion = portion
    }
    
    func setQuantity(_ quantity: Double) {
        currentQuantity = max(0.25, min(2000.0, quantity))
    }
    
    func getCurrentValues() -> (quantity: Double, portion: PortionOption) {
        return (currentQuantity, currentPortion)
    }
    
    // MARK: - Helper
    
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
