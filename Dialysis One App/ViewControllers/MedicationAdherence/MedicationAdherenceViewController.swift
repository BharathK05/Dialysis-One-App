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
    private var yourMedicationsCard: UIView?
    private var medsInfoCardConstraints: [NSLayoutConstraint] = []
    private var isEditMode = false
    private let editButton = UIButton(type: .system)
    private let yourMedsLabel = UILabel()
    private let dateEditContainer = UIView()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateStatus()
        loadMedications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateStatus()
        loadMedications()
        
        // 📤 Send medication list to Watch (default: current time)
            let time = TimeOfDay.current()

            WatchConnectivityManager.shared.sendMedicationList(
                MedicationStore.shared.medicationsFor(
                    timeOfDay: time,
                    date: Date()
                ),
                timeOfDay: time
            )
    }
    
    private func setupUI() {
        addTopGradientBackground()
        
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
        
        // Container for date and edit button
        dateEditContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dateEditContainer)
        
        // Date label
        dateLabel.font = MedicationDesignTokens.Typography.dateLabel
        dateLabel.textColor = MedicationDesignTokens.Colors.textSecondary
        dateLabel.textAlignment = .left
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateEditContainer.addSubview(dateLabel)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        dateLabel.text = dateFormatter.string(from: currentDate)
        
        // Edit button with smaller icon
        let editConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        editButton.setImage(UIImage(systemName: "pencil.circle", withConfiguration: editConfig), for: .normal)
        editButton.setImage(UIImage(systemName: "checkmark.circle.fill", withConfiguration: editConfig), for: .selected)
        editButton.tintColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        dateEditContainer.addSubview(editButton)
        
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
        medicationListContainer.layer.cornerRadius = 16
        medicationListContainer.layer.shadowColor = UIColor.black.cgColor
        medicationListContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        medicationListContainer.layer.shadowRadius = 8
        medicationListContainer.layer.shadowOpacity = 0.08
        medicationListContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(medicationListContainer)
        
        // Blur effect
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 16
        blurView.clipsToBounds = true
        medicationListContainer.insertSubview(blurView, at: 0)
        
        // Medication stack
        medicationStackView.axis = .vertical
        medicationStackView.spacing = 12
        medicationStackView.translatesAutoresizingMaskIntoConstraints = false
        medicationListContainer.addSubview(medicationStackView)
        
        // "Your Medications" section label
        yourMedsLabel.text = "Your Medications"
        yourMedsLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        yourMedsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(yourMedsLabel)
        
        // Medications info card
        yourMedicationsCard = createYourMedicationsCard()
        contentView.addSubview(yourMedicationsCard!)
        
        // Add medication button
        addMedicationButton.setTitle("Add Medication", for: .normal)
        addMedicationButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        addMedicationButton.setTitleColor(.white, for: .normal)
        addMedicationButton.backgroundColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        addMedicationButton.layer.cornerRadius = 12
        addMedicationButton.layer.shadowColor = UIColor.black.cgColor
        addMedicationButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        addMedicationButton.layer.shadowRadius = 12
        addMedicationButton.layer.shadowOpacity = 0.15
        addMedicationButton.translatesAutoresizingMaskIntoConstraints = false
        addMedicationButton.addTarget(self, action: #selector(addMedicationTapped), for: .touchUpInside)
        contentView.addSubview(addMedicationButton)
        
        medsInfoCardConstraints = [
            yourMedicationsCard!.topAnchor.constraint(equalTo: yourMedsLabel.bottomAnchor, constant: 16),
            yourMedicationsCard!.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            yourMedicationsCard!.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
        ]

        // Replace the NSLayoutConstraint.activate section in setupUI() with this:

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
            
            dateEditContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            dateEditContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            dateEditContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            dateEditContainer.heightAnchor.constraint(equalToConstant: 30),
            
            // DATE LABEL CONSTRAINTS - FIXED WITH TRAILING CONSTRAINT
            dateLabel.leadingAnchor.constraint(equalTo: dateEditContainer.leadingAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: dateEditContainer.centerYAnchor),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: editButton.leadingAnchor, constant: -8),
            
            // EDIT BUTTON CONSTRAINTS
            editButton.trailingAnchor.constraint(equalTo: dateEditContainer.trailingAnchor),
            editButton.centerYAnchor.constraint(equalTo: dateEditContainer.centerYAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 32),
            editButton.heightAnchor.constraint(equalToConstant: 32),
            
            statusLabel.topAnchor.constraint(equalTo: dateEditContainer.bottomAnchor, constant: 16),
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
            
            addMedicationButton.topAnchor.constraint(equalTo: yourMedicationsCard!.bottomAnchor, constant: 20),
            addMedicationButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            addMedicationButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            addMedicationButton.heightAnchor.constraint(equalToConstant: 54),
            addMedicationButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ] + medsInfoCardConstraints)
        
        updateStatus()
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
    
    private func createYourMedicationsCard() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        container.layer.cornerRadius = 16
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowRadius = 8
        container.layer.shadowOpacity = 0.08
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon (smaller)
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: "pills.circle.fill", withConfiguration: iconConfig))
        iconView.tintColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        container.addSubview(iconView)
        
        // Stack for medication list
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        // Add all medications with REAL names and dosages
        let allMeds = MedicationStore.shared.medications
        
        if allMeds.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No medications added yet"
            emptyLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.textAlignment = .center
            stack.addArrangedSubview(emptyLabel)
        } else {
            for med in allMeds {
                let medRow = createMedicationInfoRow(medication: med)
                stack.addArrangedSubview(medRow)
            }
        }
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),
            
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
        
        return container
    }
    
    private func refreshYourMedicationsCard() {
        // Remove old card
        yourMedicationsCard?.removeFromSuperview()
        
        // Deactivate old constraints
        NSLayoutConstraint.deactivate(medsInfoCardConstraints)
        medsInfoCardConstraints.removeAll()
        
        // Create new card
        yourMedicationsCard = createYourMedicationsCard()
        contentView.addSubview(yourMedicationsCard!)
        
        // Re-apply constraints
        medsInfoCardConstraints = [
            yourMedicationsCard!.topAnchor.constraint(equalTo: yourMedsLabel.bottomAnchor, constant: 16),
            yourMedicationsCard!.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            yourMedicationsCard!.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
        ]
        
        NSLayoutConstraint.activate(medsInfoCardConstraints)
        
        // Update button constraint
        addMedicationButton.topAnchor.constraint(equalTo: yourMedicationsCard!.bottomAnchor, constant: 20).isActive = true
    }

    
    private func createMedicationInfoRow(medication: Medication) -> UIView {
        let row = UIView()
        
        // Name + Dosage stack
        let nameStack = UIStackView()
        nameStack.axis = .horizontal
        nameStack.spacing = 6
        nameStack.alignment = .center
        nameStack.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(nameStack)
        
        // REAL medication name
        let nameLabel = UILabel()
        nameLabel.text = medication.name
        nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        nameStack.addArrangedSubview(nameLabel)
        
        // REAL dosage
        let dosageLabel = UILabel()
        dosageLabel.text = medication.dosage
        dosageLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        dosageLabel.textColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        dosageLabel.setContentHuggingPriority(.required, for: .horizontal)
        nameStack.addArrangedSubview(dosageLabel)
        
        // REAL description
        let descLabel = UILabel()
        descLabel.text = medication.description
        descLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 2
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(descLabel)
        
        NSLayoutConstraint.activate([
            nameStack.topAnchor.constraint(equalTo: row.topAnchor),
            nameStack.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            nameStack.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            
            descLabel.topAnchor.constraint(equalTo: nameStack.bottomAnchor, constant: 2),
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
                let row = MedicationDetailRow(
                    medication: medication,
                    timeOfDay: selectedTimeOfDay,
                    date: currentDate,
                    isEditMode: isEditMode
                )
                row.delegate = self
                medicationStackView.addArrangedSubview(row)
                
                NSLayoutConstraint.activate([
                    row.heightAnchor.constraint(equalToConstant: MedicationDesignTokens.Layout.rowHeight)
                ])
            }
        }
    }
    
    @objc private func editTapped() {
        isEditMode.toggle()
        editButton.isSelected = isEditMode
        
        // Reload medications with edit UI
        loadMedications()
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    
    private func updateStatus() {
        let progress = store.takenCount(for: selectedTimeOfDay, date: currentDate)
        statusLabel.text = "\(progress.taken) out of \(progress.total) Dose taken"
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func addMedicationTapped() {
        let flowVC = AddMedicationFlowViewController()
        flowVC.flowDelegate = self
        flowVC.modalPresentationStyle = .pageSheet
        
        if let sheet = flowVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }
        
        present(flowVC, animated: true)
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

extension MedicationAdherenceViewController: AddMedicationFlowDelegate {
    func medicationFlowDidComplete(_ data: MedicationFlowData) {
        // Create medication from flow data
        let medication = Medication(
            name: data.name,
            description: data.description,
            times: Array(data.selectedTimes),
            dosage: "\(data.dosage)\(data.unit)"
        )
        
        store.addMedication(medication)
        loadMedications()
        updateStatus()
        refreshYourMedicationsCard()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func medicationFlowDidCancel() {
        // User cancelled
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
    
    func medicationDetailRowDidRequestDelete(_ row: MedicationDetailRow, medication: Medication) {
        let alert = UIAlertController(
            title: "Delete Medication",
            message: "Are you sure you want to delete \(medication.name)?",
            preferredStyle: .alert
        )
            
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.store.deleteMedication(id: medication.id)
            self.loadMedications()
            self.updateStatus()
            self.refreshYourMedicationsCard()
                
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        })
            
        present(alert, animated: true)
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
    func medicationDetailRowDidRequestDelete(_ row: MedicationDetailRow, medication: Medication)
}

class MedicationDetailRow: UIView {
    
    weak var delegate: MedicationDetailRowDelegate?
    private var medication: Medication
    private let timeOfDay: TimeOfDay
    private let date: Date
    private let isEditMode: Bool
    private let deleteButton = UIButton(type: .system)
    
    private var isChecked: Bool {
        // Always fetch fresh data from store
        let freshMedication = MedicationStore.shared.medications.first(where: { $0.id == medication.id })
        return freshMedication?.isTaken(on: date, timeOfDay: timeOfDay) ?? false
    }
    
    private let checkboxButton = UIButton(type: .system)
    private let nameLabel = UILabel()
    private let dosageLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let stackView = UIStackView()
    
    init(medication: Medication, timeOfDay: TimeOfDay, date: Date, isEditMode: Bool = false) {
        self.medication = medication
        self.timeOfDay = timeOfDay
        self.date = date
        self.isEditMode = isEditMode
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.7)
        layer.cornerRadius = 16
        
        // Checkbox button (smaller)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
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
        stackView.spacing = 2
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        // Name + Dosage in horizontal stack
        let nameRow = UIStackView()
        nameRow.axis = .horizontal
        nameRow.spacing = 8
        nameRow.alignment = .center
        
        // Name label - Shows REAL medication name
        nameLabel.text = medication.name
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = MedicationDesignTokens.Colors.textPrimary
        nameRow.addArrangedSubview(nameLabel)
        
        // Dosage label - Shows REAL dosage
        dosageLabel.text = medication.dosage
        dosageLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        dosageLabel.textColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        dosageLabel.setContentHuggingPriority(.required, for: .horizontal)
        nameRow.addArrangedSubview(dosageLabel)
        
        if isEditMode {
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
            deleteButton.setImage(UIImage(systemName: "trash.circle.fill", withConfiguration: config), for: .normal)
            deleteButton.tintColor = .systemRed
            deleteButton.translatesAutoresizingMaskIntoConstraints = false
            deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
            addSubview(deleteButton)
                    
            NSLayoutConstraint.activate([
                deleteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                deleteButton.centerYAnchor.constraint(equalTo: centerYAnchor),
                deleteButton.widthAnchor.constraint(equalToConstant: 44),
                deleteButton.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
        
        stackView.addArrangedSubview(nameRow)
        
        // Description label - Shows REAL description
        descriptionLabel.text = medication.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.textColor = MedicationDesignTokens.Colors.textSecondary
        descriptionLabel.numberOfLines = 2
        stackView.addArrangedSubview(descriptionLabel)
        
        let stackTrailing = isEditMode ?
            stackView.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -8) :
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            checkboxButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: MedicationDesignTokens.Layout.rowPadding),
            checkboxButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkboxButton.widthAnchor.constraint(equalToConstant: MedicationDesignTokens.Layout.minimumTapTarget),
            checkboxButton.heightAnchor.constraint(equalToConstant: MedicationDesignTokens.Layout.minimumTapTarget),
            
            stackView.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 12),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackTrailing
        ])
        
        updateCheckboxAppearance()
        
        // Accessibility
        isAccessibilityElement = true
        accessibilityLabel = "\(medication.name) \(medication.dosage), \(medication.description)"
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
   
    
    @objc private func deleteTapped() {
        // Notify delegate
        delegate?.medicationDetailRowDidRequestDelete(self, medication: medication)
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
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        let imageName = isChecked ? "checkmark.circle.fill" : "circle"
        let color = isChecked ? MedicationDesignTokens.Colors.checkmarkActive : MedicationDesignTokens.Colors.checkmarkInactive
        
        checkboxButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
        checkboxButton.tintColor = color
    }
    
    private func updateAccessibilityHint() {
        accessibilityHint = isChecked ? "Taken. Double tap to mark as not taken" : "Not taken. Double tap to mark as taken"
    }
}
