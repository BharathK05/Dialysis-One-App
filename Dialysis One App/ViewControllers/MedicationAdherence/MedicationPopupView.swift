import UIKit

protocol MedicationPopupDelegate: AnyObject {
    func medicationPopupDidToggleMedication(_ medicationId: UUID, timeOfDay: TimeOfDay)
}

class MedicationPopupView: UIView {
    
    weak var delegate: MedicationPopupDelegate?
    private let store = MedicationStore.shared
    private var currentTimeOfDay: TimeOfDay = .current()
    private var medications: [Medication] = []
    
    private let stackView = UIStackView()
    private let timeLabel = UILabel()
    private var checkboxRows: [MedicationCheckboxRow] = []
    
    var requiredHeight: Int {
        let rowCount = medications.count
        return 80 + (rowCount * 64) + 20
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        loadMedications()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = MedicationDesignTokens.Colors.popupBackground
        layer.cornerRadius = MedicationDesignTokens.Layout.popupCornerRadius
        clipsToBounds = true
        
        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = MedicationDesignTokens.Layout.shadowOffset
        layer.shadowRadius = MedicationDesignTokens.Layout.shadowRadius
        layer.shadowOpacity = MedicationDesignTokens.Layout.shadowOpacity
        
        // Time label - UPDATED STYLING
        timeLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        timeLabel.textColor = MedicationDesignTokens.Colors.textPrimary
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(timeLabel)
        
        // Stack for medication rows
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            timeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            stackView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
        
        updateTimeLabel()
    }
    
    private func updateTimeLabel() {
        // Simple text without icons
        timeLabel.text = currentTimeOfDay.rawValue
    }
    
    private func loadMedications() {
        medications = store.medicationsFor(timeOfDay: currentTimeOfDay)
        
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        checkboxRows.removeAll()
        
        for medication in medications {
            let row = MedicationCheckboxRow(medication: medication, timeOfDay: currentTimeOfDay)
            row.delegate = self
            stackView.addArrangedSubview(row)
            checkboxRows.append(row)
            
            NSLayoutConstraint.activate([
                row.heightAnchor.constraint(equalToConstant: 56)
            ])
        }
    }
}

// MARK: - MedicationCheckboxRowDelegate

extension MedicationPopupView: MedicationCheckboxRowDelegate {
    func medicationCheckboxRowDidToggle(_ row: MedicationCheckboxRow, medication: Medication) {
        // Toggle in store first
        store.toggleTaken(medicationId: medication.id, date: Date(), timeOfDay: currentTimeOfDay)
        
        // Force a small delay to ensure store is updated
        DispatchQueue.main.async {
            // Refresh the checkbox appearance
            row.refreshCheckbox()
            
            // Notify delegate
            self.delegate?.medicationPopupDidToggleMedication(medication.id, timeOfDay: self.currentTimeOfDay)
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - MedicationCheckboxRow

protocol MedicationCheckboxRowDelegate: AnyObject {
    func medicationCheckboxRowDidToggle(_ row: MedicationCheckboxRow, medication: Medication)
}

class MedicationCheckboxRow: UIView {
    
    weak var delegate: MedicationCheckboxRowDelegate?
    private var medication: Medication
    private let timeOfDay: TimeOfDay
    
    private var isChecked: Bool {
        // Always fetch fresh data from store
        let freshMedication = MedicationStore.shared.medications.first(where: { $0.id == medication.id })
        return freshMedication?.isTaken(on: Date(), timeOfDay: timeOfDay) ?? false
    }
    
    private let checkboxButton = UIButton(type: .system)
    private let nameLabel = UILabel()
    
    init(medication: Medication, timeOfDay: TimeOfDay) {
        self.medication = medication
        self.timeOfDay = timeOfDay
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.7)
        layer.cornerRadius = 12
        
        // Make the entire row tappable
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(rowTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
        
        // Checkbox button
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        checkboxButton.setImage(
            UIImage(systemName: "circle", withConfiguration: config),
            for: .normal
        )
        checkboxButton.tintColor = MedicationDesignTokens.Colors.checkmarkInactive
        checkboxButton.translatesAutoresizingMaskIntoConstraints = false
        checkboxButton.isUserInteractionEnabled = false
        addSubview(checkboxButton)
        
        // Name label
        nameLabel.text = medication.name
        nameLabel.font = MedicationDesignTokens.Typography.medicationName
        nameLabel.textColor = MedicationDesignTokens.Colors.textPrimary
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            checkboxButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            checkboxButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkboxButton.widthAnchor.constraint(equalToConstant: 28),
            checkboxButton.heightAnchor.constraint(equalToConstant: 28),
            
            nameLabel.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
        
        updateCheckboxAppearance()
        
        // Accessibility
        isAccessibilityElement = true
        accessibilityLabel = medication.name
        accessibilityTraits = .button
        updateAccessibilityHint()
    }
    
    @objc private func rowTapped() {
        // Animate first
        UIView.animate(
            withDuration: MedicationDesignTokens.Animation.checkmarkDuration,
            animations: {
                self.checkboxButton.transform = CGAffineTransform(scaleX: MedicationDesignTokens.Animation.checkmarkScale, y: MedicationDesignTokens.Animation.checkmarkScale)
            },
            completion: { _ in
                // Call delegate to update data
                self.delegate?.medicationCheckboxRowDidToggle(self, medication: self.medication)
                
                UIView.animate(withDuration: MedicationDesignTokens.Animation.checkmarkDuration) {
                    self.checkboxButton.transform = .identity
                }
            }
        )
    }
    
    func refreshCheckbox() {
        // Update local reference
        if let freshMedication = MedicationStore.shared.medications.first(where: { $0.id == medication.id }) {
            self.medication = freshMedication
        }
        updateCheckboxAppearance()
        updateAccessibilityHint()
    }
    
    private func updateCheckboxAppearance() {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let imageName = isChecked ? "checkmark.circle.fill" : "circle"
        let color = isChecked ? MedicationDesignTokens.Colors.checkmarkActive : MedicationDesignTokens.Colors.checkmarkInactive
        
        checkboxButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
        checkboxButton.tintColor = color
    }
    
    private func updateAccessibilityHint() {
        accessibilityHint = isChecked ? "Taken. Double tap to mark as not taken" : "Not taken. Double tap to mark as taken"
    }
}
