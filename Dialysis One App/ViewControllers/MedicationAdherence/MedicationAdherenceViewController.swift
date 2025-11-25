import UIKit

class MedicationAdherenceViewController: UIViewController {
    
    private let store = MedicationStore.shared
    private var selectedTimeOfDay: TimeOfDay = .current()
    private let currentDate = Date()
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let dateLabel = UILabel()
    private let statusLabel = UILabel()
    private let timeSegmentedControl = TimeSegmentedControl()
    private let medicationListContainer = UIView()
    private let medicationStackView = UIStackView()
    private let addMedicationButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMedications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStatus()
        // Reload to ensure fresh state
        loadMedications()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.78, green: 0.93, blue: 0.82, alpha: 1.0)
        
        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = "Medication Adherence"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Back button
        let backButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        backButton.tintColor = .black
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Date label
        dateLabel.font = MedicationDesignTokens.Typography.dateLabel
        dateLabel.textColor = MedicationDesignTokens.Colors.textSecondary
        dateLabel.textAlignment = .center
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateLabel)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        dateLabel.text = dateFormatter.string(from: currentDate)
        
        // Status label
        statusLabel.font = MedicationDesignTokens.Typography.statusBadge
        statusLabel.textColor = MedicationDesignTokens.Colors.textPrimary
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusLabel)
        
        // Time segmented control
        timeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        timeSegmentedControl.delegate = self
        contentView.addSubview(timeSegmentedControl)
        
        // Medication list container
        medicationListContainer.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        medicationListContainer.layer.cornerRadius = MedicationDesignTokens.Layout.cardCornerRadius
        medicationListContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(medicationListContainer)
        
        // Blur effect
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = MedicationDesignTokens.Layout.cardCornerRadius
        blurView.clipsToBounds = true
        medicationListContainer.insertSubview(blurView, at: 0)
        
        // Medication stack
        medicationStackView.axis = .vertical
        medicationStackView.spacing = 12
        medicationStackView.translatesAutoresizingMaskIntoConstraints = false
        medicationListContainer.addSubview(medicationStackView)
        
        // "Your Medications" section label
        let yourMedsLabel = UILabel()
        yourMedsLabel.text = "Your Medications"
        yourMedsLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        yourMedsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(yourMedsLabel)
        
        // Medications info card
        let medsInfoCard = createYourMedicationsCard()
        contentView.addSubview(medsInfoCard)
        
        // Add medication button
        addMedicationButton.setTitle("Add Medication", for: .normal)
        addMedicationButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        addMedicationButton.setTitleColor(.systemBlue, for: .normal)
        addMedicationButton.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        addMedicationButton.layer.cornerRadius = 16
        addMedicationButton.translatesAutoresizingMaskIntoConstraints = false
        addMedicationButton.addTarget(self, action: #selector(addMedicationTapped), for: .touchUpInside)
        contentView.addSubview(addMedicationButton)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            dateLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 16),
            statusLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            timeSegmentedControl.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 24),
            timeSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            timeSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            timeSegmentedControl.heightAnchor.constraint(equalToConstant: 50),
            
            medicationListContainer.topAnchor.constraint(equalTo: timeSegmentedControl.bottomAnchor, constant: 20),
            medicationListContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            medicationListContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            blurView.topAnchor.constraint(equalTo: medicationListContainer.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: medicationListContainer.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: medicationListContainer.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: medicationListContainer.bottomAnchor),
            
            medicationStackView.topAnchor.constraint(equalTo: medicationListContainer.topAnchor, constant: 20),
            medicationStackView.leadingAnchor.constraint(equalTo: medicationListContainer.leadingAnchor, constant: 20),
            medicationStackView.trailingAnchor.constraint(equalTo: medicationListContainer.trailingAnchor, constant: -20),
            medicationStackView.bottomAnchor.constraint(equalTo: medicationListContainer.bottomAnchor, constant: -20),
            
            yourMedsLabel.topAnchor.constraint(equalTo: medicationListContainer.bottomAnchor, constant: 32),
            yourMedsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            medsInfoCard.topAnchor.constraint(equalTo: yourMedsLabel.bottomAnchor, constant: 16),
            medsInfoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            medsInfoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            addMedicationButton.topAnchor.constraint(equalTo: medsInfoCard.bottomAnchor, constant: 20),
            addMedicationButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            addMedicationButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            addMedicationButton.heightAnchor.constraint(equalToConstant: 56),
            addMedicationButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
        
        updateStatus()
    }
    
    private func createYourMedicationsCard() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        container.layer.cornerRadius = 20
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon
        let iconView = UIImageView(image: UIImage(systemName: "pills.circle.fill"))
        iconView.tintColor = .systemGreen
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        container.addSubview(iconView)
        
        // Stack for medication list
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        // Add all medications
        let allMeds = store.medications
        for med in allMeds {
            let medRow = createMedicationInfoRow(medication: med)
            stack.addArrangedSubview(medRow)
        }
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            iconView.widthAnchor.constraint(equalToConstant: 60),
            iconView.heightAnchor.constraint(equalToConstant: 60),
            
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
        
        return container
    }
    
    private func createMedicationInfoRow(medication: Medication) -> UIView {
        let row = UIView()
        
        let nameLabel = UILabel()
        nameLabel.text = medication.name
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(nameLabel)
        
        let descLabel = UILabel()
        descLabel.text = medication.description
        descLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        descLabel.textColor = .secondaryLabel
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(descLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: row.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            
            descLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            descLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            descLabel.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])
        
        return row
    }
    
    private func loadMedications() {
        medicationStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let medications = store.medicationsFor(timeOfDay: selectedTimeOfDay, date: currentDate)
        
        if medications.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No medications for this time"
            emptyLabel.font = MedicationDesignTokens.Typography.medicationDescription
            emptyLabel.textColor = MedicationDesignTokens.Colors.textSecondary
            emptyLabel.textAlignment = .center
            medicationStackView.addArrangedSubview(emptyLabel)
        } else {
            for medication in medications {
                let row = MedicationDetailRow(medication: medication, timeOfDay: selectedTimeOfDay, date: currentDate)
                row.delegate = self
                medicationStackView.addArrangedSubview(row)
                
                NSLayoutConstraint.activate([
                    row.heightAnchor.constraint(equalToConstant: MedicationDesignTokens.Layout.rowHeight)
                ])
            }
        }
    }
    
    private func updateStatus() {
        let progress = store.takenCount(for: selectedTimeOfDay, date: currentDate)
        statusLabel.text = "\(progress.taken) out of \(progress.total) Dose taken"
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func addMedicationTapped() {
        let alert = UIAlertController(title: "Add Medication", message: "This feature will allow you to add new medications", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TimeSegmentedControlDelegate

extension MedicationAdherenceViewController: TimeSegmentedControlDelegate {
    func timeSegmentedControlDidSelectTime(_ control: TimeSegmentedControl, timeOfDay: TimeOfDay) {
        selectedTimeOfDay = timeOfDay
        
        UIView.animate(withDuration: 0.3) {
            self.medicationStackView.alpha = 0
        } completion: { _ in
            self.loadMedications()
            self.updateStatus()
            UIView.animate(withDuration: 0.3) {
                self.medicationStackView.alpha = 1
            }
        }
    }
}

// MARK: - MedicationDetailRowDelegate

extension MedicationAdherenceViewController: MedicationDetailRowDelegate {
    func medicationDetailRowDidToggle(_ row: MedicationDetailRow, medication: Medication) {
        store.toggleTaken(medicationId: medication.id, date: currentDate, timeOfDay: selectedTimeOfDay)
        
        // Force refresh after toggle
        DispatchQueue.main.async {
            row.refreshCheckbox()
            self.updateStatus()
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - TimeSegmentedControl

protocol TimeSegmentedControlDelegate: AnyObject {
    func timeSegmentedControlDidSelectTime(_ control: TimeSegmentedControl, timeOfDay: TimeOfDay)
}

class TimeSegmentedControl: UIView {
    
    weak var delegate: TimeSegmentedControlDelegate?
    private var selectedTimeOfDay: TimeOfDay = .current()
    
    private let stackView = UIStackView()
    private var buttons: [TimeOfDay: UIButton] = [:]
    private let selectionIndicator = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.4)
        layer.cornerRadius = 14
        
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        // Selection indicator
        selectionIndicator.backgroundColor = MedicationDesignTokens.Colors.selectedTabBackground
        selectionIndicator.layer.cornerRadius = 12
        selectionIndicator.layer.shadowColor = UIColor.black.cgColor
        selectionIndicator.layer.shadowOffset = CGSize(width: 0, height: 2)
        selectionIndicator.layer.shadowRadius = 4
        selectionIndicator.layer.shadowOpacity = 0.1
        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(selectionIndicator, at: 0)
        
        // Create buttons for each time of day
        for timeOfDay in TimeOfDay.allCases {
            let button = UIButton(type: .system)
            button.setTitle(timeOfDay.rawValue, for: .normal)
            button.titleLabel?.font = MedicationDesignTokens.Typography.timeSlotLabel
            button.setTitleColor(MedicationDesignTokens.Colors.textPrimary, for: .normal)
            button.tag = timeOfDay.hashValue
            button.addTarget(self, action: #selector(timeTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            buttons[timeOfDay] = button
        }
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
        
        layoutIfNeeded()
        updateSelectionIndicator(animated: false)
    }
    
    @objc private func timeTapped(_ sender: UIButton) {
        guard let timeOfDay = TimeOfDay.allCases.first(where: { $0.hashValue == sender.tag }) else { return }
        selectedTimeOfDay = timeOfDay
        updateSelectionIndicator(animated: true)
        delegate?.timeSegmentedControlDidSelectTime(self, timeOfDay: timeOfDay)
        
        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    private func updateSelectionIndicator(animated: Bool) {
        guard let selectedButton = buttons[selectedTimeOfDay] else { return }
        
        let update = {
            self.selectionIndicator.frame = selectedButton.frame
        }
        
        if animated {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.5,
                options: .curveEaseInOut,
                animations: update
            )
        } else {
            update()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateSelectionIndicator(animated: false)
    }
}

// MARK: - MedicationDetailRow

protocol MedicationDetailRowDelegate: AnyObject {
    func medicationDetailRowDidToggle(_ row: MedicationDetailRow, medication: Medication)
}

class MedicationDetailRow: UIView {
    
    weak var delegate: MedicationDetailRowDelegate?
    private var medication: Medication
    private let timeOfDay: TimeOfDay
    private let date: Date
    
    private var isChecked: Bool {
        // Always fetch fresh data from store
        let freshMedication = MedicationStore.shared.medications.first(where: { $0.id == medication.id })
        return freshMedication?.isTaken(on: date, timeOfDay: timeOfDay) ?? false
    }
    
    private let checkboxButton = UIButton(type: .system)
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let stackView = UIStackView()
    
    init(medication: Medication, timeOfDay: TimeOfDay, date: Date) {
        self.medication = medication
        self.timeOfDay = timeOfDay
        self.date = date
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.7)
        layer.cornerRadius = 16
        
        // Checkbox button
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        checkboxButton.setImage(
            UIImage(systemName: "circle", withConfiguration: config),
            for: .normal
        )
        checkboxButton.tintColor = MedicationDesignTokens.Colors.checkmarkInactive
        checkboxButton.translatesAutoresizingMaskIntoConstraints = false
        checkboxButton.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        addSubview(checkboxButton)
        
        // Stack for labels
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        // Name label
        nameLabel.text = medication.name
        nameLabel.font = MedicationDesignTokens.Typography.medicationName
        nameLabel.textColor = MedicationDesignTokens.Colors.textPrimary
        stackView.addArrangedSubview(nameLabel)
        
        // Description label
        descriptionLabel.text = medication.description
        descriptionLabel.font = MedicationDesignTokens.Typography.medicationDescription
        descriptionLabel.textColor = MedicationDesignTokens.Colors.textSecondary
        descriptionLabel.numberOfLines = 2
        stackView.addArrangedSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            checkboxButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: MedicationDesignTokens.Layout.rowPadding),
            checkboxButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkboxButton.widthAnchor.constraint(equalToConstant: MedicationDesignTokens.Layout.minimumTapTarget),
            checkboxButton.heightAnchor.constraint(equalToConstant: MedicationDesignTokens.Layout.minimumTapTarget),
            
            stackView.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 12),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -MedicationDesignTokens.Layout.rowPadding)
        ])
        
        updateCheckboxAppearance()
        
        // Accessibility
        isAccessibilityElement = true
        accessibilityLabel = "\(medication.name), \(medication.description)"
        accessibilityTraits = .button
        updateAccessibilityHint()
    }
    
    @objc private func checkboxTapped() {
        // Animate first
        UIView.animate(
            withDuration: MedicationDesignTokens.Animation.checkmarkDuration,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.8,
            options: .curveEaseOut,
            animations: {
                self.checkboxButton.transform = CGAffineTransform(scaleX: MedicationDesignTokens.Animation.checkmarkScale, y: MedicationDesignTokens.Animation.checkmarkScale)
            },
            completion: { _ in
                // Call delegate to update data
                self.delegate?.medicationDetailRowDidToggle(self, medication: self.medication)
                
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
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        let imageName = isChecked ? "checkmark.circle.fill" : "circle"
        let color = isChecked ? MedicationDesignTokens.Colors.checkmarkActive : MedicationDesignTokens.Colors.checkmarkInactive
        
        checkboxButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
        checkboxButton.tintColor = color
    }
    
    private func updateAccessibilityHint() {
        accessibilityHint = isChecked ? "Taken. Double tap to mark as not taken" : "Not taken. Double tap to mark as taken"
    }
}
