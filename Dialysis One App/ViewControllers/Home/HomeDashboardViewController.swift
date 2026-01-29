
// user 1
// main

import UIKit
import AVFoundation
import Photos

class HomeDashboardViewController: UIViewController,
                                   UIImagePickerControllerDelegate,
                                   UINavigationControllerDelegate,
                                   UIGestureRecognizerDelegate,
                                   UIPickerViewDelegate,
                                   UIPickerViewDataSource,
                                   UITextFieldDelegate {

    
    private var didRunTour = false
    
    private var appointmentHospitalLabel: UILabel?
    private var appointmentDateLabel: UILabel?
    private var appointmentTimeLabel: UILabel?

    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var dietButton: UIView!
    private var dietButtonWidthConstraint: NSLayoutConstraint!
    private var isExpanded = false
    
    // Quick Add Buttons
    private var waterButton: UIView!
    private var pillButton: UIView!
    private var cameraButton: UIButton!
    private var searchButton: UIButton!
    private var summaryTopConstraint: NSLayoutConstraint!
    private var summaryLabel: UILabel!
    
    // Medication Adherence
    private var medicationPopup: MedicationPopupView?
    private var medicationPopupWidthConstraint: NSLayoutConstraint?
    private var medicationPopupHeightConstraint: NSLayoutConstraint?
    private var isMedicationPopupExpanded = false
    private var medicationTotalLabel: UILabel?
    private let medicationStore = MedicationStore.shared
    // --- Fluid quick-add state & UI refs ---
    private var fluidTypes: [String] = ["Water", "Coffee", "Tea", "Juice"]
    private var selectedFluidTypeIndex: Int = 0
    private var selectedFluidQuantity: Int = 0   // start at 0

    private var fluidStepper: UIStepper?
    private var fluidTypeLabel: UILabel?
    private var fluidQuantityDisplayLabel: UILabel?
    private var fluidEditButton: UIButton?

    // width constraint for the fluid/water button (used during expand/collapse)
    private var waterButtonWidthConstraint: NSLayoutConstraint?
    private var isFluidExpanded: Bool = false

    // constraints to animate icon alignment
    private var fluidIconCenterConstraint: NSLayoutConstraint?
    private var fluidIconLeadingConstraint: NSLayoutConstraint?

    // fluid editor popup references
    private var fluidEditorOverlay: UIView?
    private var fluidEditorCard: UIView?

    // constraints to swap when fluid expands (so it can fill horizontally)
    private var waterButtonLeadingToDietConstraint: NSLayoutConstraint?
    private var waterButtonLeadingToContentConstraint: NSLayoutConstraint?

    // Save button on the expanded fluid card
    private var fluidQuickAddSaveButton: UIButton?

    // MARK: - Dynamic Data Properties
    
    private var uid: String {
        return FirebaseAuthManager.shared.getUserID() ?? "guest"
    }

    // Water tracking
    private var waterConsumed: Int = 150 {
        didSet { updateWaterCard() }
    }
    private var waterGoal: Int = 250
    
    // Medication tracking
    private var dosesConsumed: Int = 2 {
        didSet { updateMedicationCard() }
    }
    private var dosesGoal: Int = 3
    
    // Nutrient tracking
    // MARK: - Nutrient tracking

    // Consumed values (stored properties with didSet)
    private var potassiumConsumed: Int = 78 {
        didSet { updateNutrientCard() }
    }

    private var sodiumConsumed: Int = 45 {
        didSet { updateNutrientCard() }
    }

    private var proteinConsumed: Int = 95 {
        didSet { updateNutrientCard() }
    }

    // Goal values (computed properties - dynamically fetch from LimitsManager)
    private var potassiumGoal: Int {
        return LimitsManager.shared.getPotassiumLimit()
    }

    private var sodiumGoal: Int {
        return LimitsManager.shared.getSodiumLimit()
    }

    private var proteinGoal: Int {
        return LimitsManager.shared.getProteinLimit()
    }
    // Weight tracking
    private var currentWeight: Double = 57.0 {
        didSet { updateWeightCard() }
    }
    // MARK: - UI Element References
    private var waterValueLabel: UILabel?
    private var waterTotalLabel: UILabel?
    private var waterProgressView: SemiCircularProgressView?
    
    private var medicationValueLabel: UILabel?
    private var medicationProgressView: UIView? // Changed from SemiCircularProgressView
    
    private var potassiumValueLabel: UILabel?
    private var potassiumProgressFill: UIView?
    private var potassiumProgressBar: UIView?
    
    private var sodiumValueLabel: UILabel?
    private var sodiumProgressFill: UIView?
    private var sodiumProgressBar: UIView?
    
    private var proteinValueLabel: UILabel?
    private var proteinProgressFill: UIView?
    private var proteinProgressBar: UIView?
    
    private var weightValueLabel: UILabel?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserValues()
        addTopGradientBackground()
        setupUI()
        refreshAppointmentCard()
        updateSegmentedMedicationCard()
        loadTodayNutrients()
        
        // Listen for meal updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(mealsDidUpdate),
            name: .mealsDidUpdate,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(waterDidUpdateFromWatch),
            name: .waterDidUpdate,
            object: nil
        )

        
        // Listen for limits updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(limitsDidUpdate),
            name: .limitsDidUpdate,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSegmentedMedicationCard()
        loadTodayNutrients()
        
        // Keep it fresh every time the screen appears
       // updateSegmentedMedicationCard()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshAppointmentCard),
            name: .appointmentsChanged,
            object: nil
        )
    }
    
    
    
    // MARK: - Public Update Methods
    // MARK: - Public Update Methods
    private func loadUserValues() {
        // Default values for NEW users
        waterConsumed = UserDataManager.shared.loadInt("waterConsumed", uid: uid, defaultValue: 0)
        waterGoal = UserDataManager.shared.loadInt("waterGoal", uid: uid, defaultValue: 250)

        dosesConsumed = UserDataManager.shared.loadInt("dosesConsumed", uid: uid, defaultValue: 0)
        dosesGoal = UserDataManager.shared.loadInt("dosesGoal", uid: uid, defaultValue: 3)

        // ❌ REMOVE THESE THREE LINES - goals now come from LimitsManager
        // potassiumGoal = UserDataManager.shared.loadInt("potassiumGoal", uid: uid, defaultValue: 90)
        // sodiumGoal = UserDataManager.shared.loadInt("sodiumGoal", uid: uid, defaultValue: 70)
        // proteinGoal = UserDataManager.shared.loadInt("proteinGoal", uid: uid, defaultValue: 110)

        // Load consumed nutrients
        potassiumConsumed = UserDataManager.shared.loadInt("potassiumConsumed", uid: uid, defaultValue: 0)
        sodiumConsumed = UserDataManager.shared.loadInt("sodiumConsumed", uid: uid, defaultValue: 0)
        proteinConsumed = UserDataManager.shared.loadInt("proteinConsumed", uid: uid, defaultValue: 0)

        currentWeight = UserDataManager.shared.loadDouble("weight", uid: uid, defaultValue: 0)
    }

    func updateWater(consumed: Int, goal: Int? = nil) {
        waterConsumed = consumed
        UserDataManager.shared.save("waterConsumed", value: consumed, uid: uid)

        if let newGoal = goal {
            waterGoal = newGoal
            UserDataManager.shared.save("waterGoal", value: newGoal, uid: uid)
        }
        
        WatchConnectivityManager.shared.sendSummary(
            foodText: nil,
            waterText: "\(waterConsumed) / \(waterGoal) ml",
            medicationText: "\(dosesConsumed) / \(dosesGoal) doses"
        )

        updateWaterCard()
        
    }
    
    func updateMedication(consumed: Int, goal: Int? = nil) {
        dosesConsumed = consumed
        UserDataManager.shared.save("dosesConsumed", value: consumed, uid: uid)

        if let newGoal = goal {
            dosesGoal = newGoal
            UserDataManager.shared.save("dosesGoal", value: newGoal, uid: uid)
        }
        
        WatchConnectivityManager.shared.sendSummary(
            foodText: nil,
            waterText: "\(waterConsumed) / \(waterGoal) ml",
            medicationText: "\(dosesConsumed) / \(dosesGoal) doses"
        )

        updateMedicationCard()
    }
    
    func updateNutrients(potassium: Int? = nil, sodium: Int? = nil, protein: Int? = nil) {
        if let p = potassium {
            potassiumConsumed = p
            UserDataManager.shared.save("potassiumConsumed", value: p, uid: uid)
        }
        if let s = sodium {
            sodiumConsumed = s
            UserDataManager.shared.save("sodiumConsumed", value: s, uid: uid)
        }
        if let pr = protein {
            proteinConsumed = pr
            UserDataManager.shared.save("proteinConsumed", value: pr, uid: uid)
        }
        
        let foodSummary = "K:\(potassiumConsumed) S:\(sodiumConsumed) P:\(proteinConsumed)"
        WatchConnectivityManager.shared.sendSummary(
            foodText: foodSummary,
            waterText: "\(waterConsumed) / \(waterGoal) ml",
            medicationText: "\(dosesConsumed) / \(dosesGoal) doses"
        )


        updateNutrientCard()
    }
    
    func updateWeight(_ weight: Double) {
        currentWeight = weight
        UserDataManager.shared.save("weight", value: weight, uid: uid)
        updateWeightCard()
    }
    
    @objc private func waterDidUpdateFromWatch() {
        let consumed = UserDataManager.shared.loadInt(
            "waterConsumed",
            uid: uid,
            defaultValue: 0
        )

        updateWater(consumed: consumed)
    }

    
    // MARK: - App Tour
    private func showAppTourIfNeeded() {
        let uid = self.uid
        guard AppTourManager.shared.shouldShowTour(uid: uid) else { return }

        let steps: [AppTourManager.Step] = [
            // HOME TAB
            .init(viewID: "home.diet", tabIndex: 0,
                  message: "Scan or search foods to log meals."),

            .init(viewID: "home.water", tabIndex: 0,
                  message: "Track your hydration every day."),

            .init(viewID: "home.pill", tabIndex: 0,
                  message: "Add your medication doses."),

            .init(viewID: "home.summary", tabIndex: 0,
                  message: "Get today's nutrient breakdown."),

            .init(viewID: "home.weight", tabIndex: 0,
                  message: "Track and monitor your weight easily."),

            // HEALTH TAB
            .init(viewID: "health.watch", tabIndex: 1,
                  message: "Connect to Apple Watch for vitals monitoring."),

            .init(viewID: "health.reports", tabIndex: 1,
                  message: "Upload medical reports and keep them organized."),

            // RELIEF TAB
            .init(viewID: "relief.table", tabIndex: 2,
                  message: "Find symptoms and guided relief steps.")
        ]

        // Show tour
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            AppTourManager.shared.showTour(
                steps: steps,
                in: self.tabBarController ?? self,
                uid: uid
            )
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Register tour views once layout is ready
        AppTourManager.shared.register(view: dietButton, for: "home.diet")
        AppTourManager.shared.register(view: waterButton, for: "home.water")
        AppTourManager.shared.register(view: pillButton, for: "home.pill")
        AppTourManager.shared.register(view: summaryLabel, for: "home.summary")
        if let weightValueLabel = weightValueLabel {
            AppTourManager.shared.register(view: weightValueLabel, for: "home.weight")
        }

        if !didRunTour {
            didRunTour = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showAppTourIfNeeded()
            }
        }
    }
    
    // MARK: - Private Update Methods
    private func updateWaterCard() {
        waterValueLabel?.text = "\(waterConsumed)"
        waterTotalLabel?.text = "out of\n\(waterGoal) ml"
        let progress = CGFloat(waterConsumed) / CGFloat(waterGoal)
        waterProgressView?.progress = min(progress, 1.0)
    }
    
    
    
    private func updateMedicationCard() {
        updateSegmentedMedicationCard()
    }
    
    private func updateNutrientCard() {
        potassiumValueLabel?.text = "\(potassiumConsumed)/\(potassiumGoal)mg"
        let potassiumProgress = potassiumConsumed > 0 ? CGFloat(potassiumConsumed) / CGFloat(potassiumGoal) : 0
        if let progressBar = potassiumProgressBar, let progressFill = potassiumProgressFill {
            progressFill.constraints.forEach { constraint in
                if constraint.firstAttribute == .width {
                    progressBar.removeConstraint(constraint)
                }
            }
            NSLayoutConstraint.activate([
                progressFill.widthAnchor.constraint(equalTo: progressBar.widthAnchor, multiplier: min(potassiumProgress, 1.0))
            ])
        }
        
        sodiumValueLabel?.text = "\(sodiumConsumed)/\(sodiumGoal)mg"
        let sodiumProgress = sodiumConsumed > 0 ? CGFloat(sodiumConsumed) / CGFloat(sodiumGoal) : 0
        if let progressBar = sodiumProgressBar, let progressFill = sodiumProgressFill {
            progressFill.constraints.forEach { constraint in
                if constraint.firstAttribute == .width {
                    progressBar.removeConstraint(constraint)
                }
            }
            NSLayoutConstraint.activate([
                progressFill.widthAnchor.constraint(equalTo: progressBar.widthAnchor, multiplier: min(sodiumProgress, 1.0))
            ])
        }
        
        proteinValueLabel?.text = "\(proteinConsumed)/\(proteinGoal)mg"
        let proteinProgress = proteinConsumed > 0 ? CGFloat(proteinConsumed) / CGFloat(proteinGoal) : 0
        if let progressBar = proteinProgressBar, let progressFill = proteinProgressFill {
            progressFill.constraints.forEach { constraint in
                if constraint.firstAttribute == .width {
                    progressBar.removeConstraint(constraint)
                }
            }
            NSLayoutConstraint.activate([
                progressFill.widthAnchor.constraint(equalTo: progressBar.widthAnchor, multiplier: min(proteinProgress, 1.0))
            ])
        }
    }
    
    private func updateWeightCard() {
        weightValueLabel?.text = "\(Int(currentWeight)) Kg"
    }
    private func loadTodayNutrients() {
        let totals = MealDataManager.shared.getTodayTotals()
        
        // Update local properties
        potassiumConsumed = totals.potassium
        sodiumConsumed = totals.sodium
        proteinConsumed = totals.protein
        
        // Save to UserDefaults for persistence
        UserDataManager.shared.save("potassiumConsumed", value: totals.potassium, uid: uid)
        UserDataManager.shared.save("sodiumConsumed", value: totals.sodium, uid: uid)
        UserDataManager.shared.save("proteinConsumed", value: totals.protein, uid: uid)
        
        // Update UI
        updateNutrientCard()
    }
    @objc private func mealsDidUpdate() {
        loadTodayNutrients()
    }
    @objc private func limitsDidUpdate() {
        // Reload nutrient card with new limits
        updateNutrientCard()
    }
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.78, green: 0.93, blue: 0.82, alpha: 1.0)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupScrollView()
        setupHeader()
        setupQuickAddSection()
        setupSummarySection()
        setupWeightSection()
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
    
    private func setupHeader() {
        let titleLabel = UILabel()
        titleLabel.text = "Today"
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        let profileButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        profileButton.setImage(UIImage(systemName: "person.circle.fill", withConfiguration: config), for: .normal)
        profileButton.tintColor = .systemBlue
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileButton)
        
        profileButton.addTarget(self, action: #selector(profileButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            profileButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            profileButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            profileButton.widthAnchor.constraint(equalToConstant: 40),
            profileButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func profileButtonTapped() {
        let sheetVC = ProfileSheetViewController()
        sheetVC.modalPresentationStyle = .pageSheet

        if let sheet = sheetVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }

        present(sheetVC, animated: true)
    }
    
    private func setupQuickAddSection() {
        let label = UILabel()
        label.text = "Quick Add"
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 90),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24)
        ])

        // Diet Button (Expandable)
        dietButton = createExpandableDietButton()
        cameraButton.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        contentView.addSubview(dietButton)

        // Water Button (Fluid quick-add)
        waterButton = createFluidQuickAddButton()
        contentView.addSubview(waterButton)

        // Pill Button with tap gesture
        pillButton = createQuickAddButton(
            color: UIColor(red: 0.55, green: 0.89, blue: 0.70, alpha: 1.0),
            iconName: "pills.fill"
        )
        pillButton.isUserInteractionEnabled = true
        let pillTapGesture = UITapGestureRecognizer(target: self, action: #selector(pillButtonTapped))
        pillButton.addGestureRecognizer(pillTapGesture)
        contentView.addSubview(pillButton)

        dietButtonWidthConstraint = dietButton.widthAnchor.constraint(equalToConstant: 110)

        // initial width constraint for waterButton
        waterButtonWidthConstraint = waterButton.widthAnchor.constraint(equalToConstant: 110)
        waterButtonWidthConstraint?.isActive = true

        // keep a reference to the leading constraint so we can replace it when expanding
        waterButtonLeadingToDietConstraint =
            waterButton.leadingAnchor.constraint(equalTo: dietButton.trailingAnchor, constant: 12)
        waterButtonLeadingToDietConstraint?.isActive = true

        NSLayoutConstraint.activate([
            dietButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 16),
            dietButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            dietButton.heightAnchor.constraint(equalToConstant: 60),
            dietButtonWidthConstraint,

            waterButton.topAnchor.constraint(equalTo: dietButton.topAnchor),
            waterButton.leadingAnchor.constraint(equalTo: dietButton.trailingAnchor, constant: 12),
            waterButton.heightAnchor.constraint(equalToConstant: 60),

            pillButton.topAnchor.constraint(equalTo: dietButton.topAnchor),
            pillButton.leadingAnchor.constraint(equalTo: waterButton.trailingAnchor, constant: 12),
            pillButton.widthAnchor.constraint(equalToConstant: 110),
            pillButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    
    private func createExpandableDietButton() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(red: 0.95, green: 0.84, blue: 0.63, alpha: 1.0)
        container.layer.cornerRadius = 14
        container.translatesAutoresizingMaskIntoConstraints = false
        container.clipsToBounds = true
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: "fork.knife", withConfiguration: iconConfig))
        iconView.tintColor = .black
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tag = 101
        iconView.contentMode = .scaleAspectFit
        container.addSubview(iconView)
        
        cameraButton = UIButton(type: .system)
        let cameraConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        cameraButton.setImage(UIImage(systemName: "camera.fill", withConfiguration: cameraConfig), for: .normal)
        cameraButton.tintColor = .black
        cameraButton.backgroundColor = UIColor(red: 0.98, green: 0.91, blue: 0.76, alpha: 1.0)
        cameraButton.layer.cornerRadius = 18
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.alpha = 0
        cameraButton.tag = 102
        cameraButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        container.addSubview(cameraButton)
        
        searchButton = UIButton(type: .system)
        let searchConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        searchButton.setImage(UIImage(systemName: "magnifyingglass", withConfiguration: searchConfig), for: .normal)
        searchButton.tintColor = .black
        searchButton.backgroundColor = UIColor(red: 0.98, green: 0.91, blue: 0.76, alpha: 1.0)
        searchButton.layer.cornerRadius = 18
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        searchButton.alpha = 0
        searchButton.tag = 103
        searchButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        container.addSubview(searchButton)
        
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            cameraButton.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -10),
            cameraButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            cameraButton.widthAnchor.constraint(equalToConstant: 36),
            cameraButton.heightAnchor.constraint(equalToConstant: 36),
            
            searchButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            searchButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 36),
            searchButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dietButtonTapped))
        container.addGestureRecognizer(tapGesture)
        
        return container
    }
    
    @objc private func dietButtonTapped() {
        isExpanded.toggle()
        
        if isExpanded {
            dietButtonWidthConstraint.constant = 340
            summaryTopConstraint.constant = 40
            
            UIView.animate(withDuration: 0.15, animations: {
                self.waterButton.alpha = 0
                self.pillButton.alpha = 0
            })
            
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
                
                if let iconView = self.dietButton.viewWithTag(101) {
                    iconView.alpha = 0
                    iconView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                }
                
                if let dinnerLabel = self.dietButton.viewWithTag(100) {
                    dinnerLabel.alpha = 1
                }
                
            }, completion: { _ in
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                    self.cameraButton.alpha = 1
                    self.cameraButton.transform = .identity
                })
                
                UIView.animate(withDuration: 0.3, delay: 0.1, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                    self.searchButton.alpha = 1
                    self.searchButton.transform = .identity
                })
            })
            
        } else {
            dietButtonWidthConstraint.constant = 110
            summaryTopConstraint.constant = 16
            
            UIView.animate(withDuration: 0.15, animations: {
                self.cameraButton.alpha = 0
                self.searchButton.alpha = 0
                self.cameraButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                self.searchButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            })
            
            UIView.animate(withDuration: 0.3, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                self.view.layoutIfNeeded()
                
                if let iconView = self.dietButton.viewWithTag(101) {
                    iconView.alpha = 1
                    iconView.transform = .identity
                }
                
                if let dinnerLabel = self.dietButton.viewWithTag(100) {
                    dinnerLabel.alpha = 0
                }
                
            }, completion: { _ in
                UIView.animate(withDuration: 0.2, animations: {
                    self.waterButton.alpha = 1
                    self.pillButton.alpha = 1
                })
            })
        }
    }
    
    // MARK: - Medication Popup
    @objc private func pillButtonTapped() {
        isMedicationPopupExpanded.toggle()
        
        if isMedicationPopupExpanded {
            showMedicationPopup()
        } else {
            hideMedicationPopup()
        }
    }

    private func showMedicationPopup() {
        if medicationPopup == nil {
            let popup = MedicationPopupView()
            popup.translatesAutoresizingMaskIntoConstraints = false
            popup.alpha = 0
            popup.layer.cornerRadius = 14
            popup.clipsToBounds = true
            popup.delegate = self

            let popupTap = UITapGestureRecognizer(target: self, action: #selector(pillButtonTapped))
            popupTap.cancelsTouchesInView = false
            popupTap.numberOfTapsRequired = 1
            popupTap.delegate = self
            popup.addGestureRecognizer(popupTap)

            contentView.addSubview(popup)

            medicationPopupWidthConstraint = popup.widthAnchor.constraint(equalToConstant: 110)
            medicationPopupHeightConstraint = popup.heightAnchor.constraint(equalToConstant: 60)

            NSLayoutConstraint.activate([
                popup.topAnchor.constraint(equalTo: pillButton.topAnchor),
                popup.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
                medicationPopupWidthConstraint!,
                medicationPopupHeightConstraint!
            ])

            medicationPopup = popup
            view.layoutIfNeeded()
        }

        let targetWidth: CGFloat = min(view.bounds.width - 48, 340)
        let targetHeight = CGFloat(medicationPopup?.requiredHeight ?? 200)

        medicationPopupWidthConstraint?.constant = targetWidth
        medicationPopupHeightConstraint?.constant = targetHeight
        summaryTopConstraint.constant = targetHeight + 0

        UIView.animate(withDuration: 0.15) {
            self.dietButton.alpha = 0
            self.waterButton.alpha = 0
            self.pillButton.alpha = 0
        }

        UIView.animate(
            withDuration: MedicationDesignTokens.Animation.expansionDuration,
            delay: 0,
            usingSpringWithDamping: MedicationDesignTokens.Animation.expansionDamping,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.medicationPopup?.alpha = 1
            self.view.layoutIfNeeded()
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var touchedView = touch.view
        while let v = touchedView {
            if v is UIControl { return false }
            touchedView = v.superview
        }
        return true
    }

    private func hideMedicationPopup() {
        medicationPopupWidthConstraint?.constant = 110
        medicationPopupHeightConstraint?.constant = 60
        summaryTopConstraint.constant = 16
        
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseInOut
        ) {
            self.medicationPopup?.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.medicationPopup?.removeFromSuperview()
            self.medicationPopup = nil
            
            UIView.animate(withDuration: 0.2) {
                self.dietButton.alpha = 1
                self.waterButton.alpha = 1
                self.pillButton.alpha = 1
            }
        }
    }
    
    @objc private func medicationCardTapped() {
        let adherenceVC = MedicationAdherenceViewController()
        navigationController?.pushViewController(adherenceVC, animated: true)
    }
    
    // MARK: - Camera
    @objc func cameraButtonTapped() {
        let cameraVC = CameraCaptureViewController()
        cameraVC.delegate = self
        cameraVC.modalPresentationStyle = .fullScreen
        present(cameraVC, animated: true)
    }
    
    @objc private func weightCardTapped() {
        let weightCheckVC = WeightCheckViewController()
        navigationController?.pushViewController(weightCheckVC, animated: true)
    }

    private func requestCameraAccessAndPresentPicker() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            presentImagePicker(source: .camera)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { self.presentImagePicker(source: .camera) }
                    else { self.showPermissionAlert(.camera) }
                }
            }
        default:
            showPermissionAlert(.camera)
        }
    }

    private func requestPhotoLibraryAccessAndPresentPicker() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            presentImagePicker(source: .photoLibrary)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.presentImagePicker(source: .photoLibrary)
                    } else {
                        self.showPermissionAlert(.photoLibrary)
                    }
                }
            }
        default:
            showPermissionAlert(.photoLibrary)
        }
    }

    private enum PickerType { case camera, photoLibrary }

    private func showPermissionAlert(_ type: PickerType) {
        let title = (type == .camera) ? "Camera access required" : "Photo access required"
        let message = (type == .camera) ? "Enable Camera permission in Settings to take a photo." : "Enable Photos permission in Settings to choose a photo."
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func presentImagePicker(source: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = source
        picker.allowsEditing = true
        DispatchQueue.main.async {
            self.present(picker, animated: true)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            guard let chosen = image else { return }
            let preview = PreviewViewController(image: chosen) { acceptedImage in
                if let savedURL = self.saveImageToTemp(acceptedImage) {
                    print("Saved image to temp:", savedURL.path)
                }
            }
            let nav = UINavigationController(rootViewController: preview)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true)
        }
    }
    
    private func createQuickAddButton(color: UIColor, iconName: String) -> UIView {
        let container = UIView()
        container.backgroundColor = color
        container.layer.cornerRadius = 14
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: iconName, withConfiguration: config))
        iconView.tintColor = .black
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        container.addSubview(iconView)
        
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return container
    }
    
    private func setupSummarySection() {
        summaryLabel = UILabel()
        summaryLabel.text = "Summary"
        summaryLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(summaryLabel)

        summaryTopConstraint = summaryLabel.topAnchor.constraint(equalTo: dietButton.bottomAnchor, constant: 16)

        // Nutrient Card (with tap to open NutrientBalanceViewController)
        let nutrientCard = createNutrientBalanceCard()
        nutrientCard.translatesAutoresizingMaskIntoConstraints = false
        nutrientCard.isUserInteractionEnabled = true
        nutrientCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openNutrientBalance)))
        contentView.addSubview(nutrientCard)

        NSLayoutConstraint.activate([
            summaryTopConstraint,
            summaryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            nutrientCard.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 14),
            nutrientCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            nutrientCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            nutrientCard.heightAnchor.constraint(equalToConstant: 110)
        ])

        // Water & Medication Cards
        let cardsStack = UIStackView()
        cardsStack.axis = .horizontal
        cardsStack.spacing = 12
        cardsStack.distribution = .fillEqually
        cardsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardsStack)

        let waterProgress = CGFloat(waterConsumed) / CGFloat(waterGoal)
        let waterCard = createProgressCard(
            value: "\(waterConsumed)",
            total: "out of\n\(waterGoal) ml",
            color: UIColor.systemBlue,
            progress: waterProgress,
            type: .water
        )

        let doseCard = createSegmentedMedicationCard()
        
        // Add tap gesture to medication card
        let medicationTapGesture = UITapGestureRecognizer(target: self, action: #selector(medicationCardTapped))
        doseCard.addGestureRecognizer(medicationTapGesture)
        doseCard.isUserInteractionEnabled = true

        cardsStack.addArrangedSubview(waterCard)
        cardsStack.addArrangedSubview(doseCard)

        NSLayoutConstraint.activate([
            cardsStack.topAnchor.constraint(equalTo: nutrientCard.bottomAnchor, constant: 16),
            cardsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            cardsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            cardsStack.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    @objc private func openNutrientBalance() {
        let vc = NutrientBalanceViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func createNutrientBalanceCard() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        container.layer.cornerRadius = 20
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true
        container.insertSubview(blurView, at: 0)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: container.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        let potassiumProgress = CGFloat(potassiumConsumed) / CGFloat(potassiumGoal)
        let potassiumItem = createNutrientItem(name: "Potassium", value: "\(potassiumConsumed)/\(potassiumGoal)mg", progress: potassiumProgress, color: .systemGreen, type: .potassium)
        
        let sodiumProgress = CGFloat(sodiumConsumed) / CGFloat(sodiumGoal)
        let sodiumItem = createNutrientItem(name: "Sodium", value: "\(sodiumConsumed)/\(sodiumGoal)mg", progress: sodiumProgress, color: .systemOrange, type: .sodium)
        
        let proteinProgress = CGFloat(proteinConsumed) / CGFloat(proteinGoal)
        let proteinItem = createNutrientItem(name: "Protein", value: "\(proteinConsumed)/\(proteinGoal)mg", progress: proteinProgress, color: .systemYellow, type: .protein)
        
        stack.addArrangedSubview(potassiumItem)
        stack.addArrangedSubview(sodiumItem)
        stack.addArrangedSubview(proteinItem)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -24)
        ])
        
        return container
    }
    
    private enum NutrientType {
        case potassium, sodium, protein
    }
    
    private func createNutrientItem(name: String, value: String, progress: CGFloat, color: UIColor, type: NutrientType) -> UIView {
        let container = UIView()
        
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(nameLabel)
        
        let progressBar = UIView()
        progressBar.backgroundColor = color.withAlphaComponent(0.25)
        progressBar.layer.cornerRadius = 2.5
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(progressBar)
        
        let progressFill = UIView()
        progressFill.backgroundColor = color
        progressFill.layer.cornerRadius = 2.5
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressBar.addSubview(progressFill)
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(valueLabel)
        
        switch type {
        case .potassium:
            potassiumValueLabel = valueLabel
            potassiumProgressFill = progressFill
            potassiumProgressBar = progressBar
        case .sodium:
            sodiumValueLabel = valueLabel
            sodiumProgressFill = progressFill
            sodiumProgressBar = progressBar
        case .protein:
            proteinValueLabel = valueLabel
            proteinProgressFill = progressFill
            proteinProgressBar = progressBar
        }
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            
            progressBar.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            progressBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 5),
            
            progressFill.leadingAnchor.constraint(equalTo: progressBar.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressBar.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressBar.bottomAnchor),
            progressFill.widthAnchor.constraint(equalTo: progressBar.widthAnchor, multiplier: progress),
            
            valueLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 8),
            valueLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private enum CardType {
        case water, medication
    }
    
    private func createProgressCard(value: String, total: String, color: UIColor, progress: CGFloat, type: CardType) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        container.layer.cornerRadius = 20
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true
        container.insertSubview(blurView, at: 0)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: container.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        let circularProgress = SemiCircularProgressView(frame: CGRect(x: 0, y: 0, width: 110, height: 70))
        circularProgress.progress = progress
        circularProgress.trackColor = color.withAlphaComponent(0.2)
        circularProgress.progressColor = color
        circularProgress.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(circularProgress)
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        valueLabel.textAlignment = .center
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(valueLabel)
        
        let totalLabel = UILabel()
        totalLabel.text = total
        totalLabel.font = UIFont.systemFont(ofSize: 13)
        totalLabel.textAlignment = .center
        totalLabel.numberOfLines = 2
        totalLabel.textColor = .darkGray
        totalLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(totalLabel)
        
        switch type {
        case .water:
            waterValueLabel = valueLabel
            waterTotalLabel = totalLabel
            waterProgressView = circularProgress
        case .medication:
            break
        }
        
        NSLayoutConstraint.activate([
            circularProgress.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            circularProgress.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            circularProgress.widthAnchor.constraint(equalToConstant: 110),
            circularProgress.heightAnchor.constraint(equalToConstant: 70),
                    
            valueLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: circularProgress.bottomAnchor, constant: 0),
                    
            totalLabel.topAnchor.constraint(equalTo: circularProgress.bottomAnchor, constant: 8),
            totalLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
        
        // Add tap gesture for water card to open HydrationStatusViewController
        if type == .water {
            container.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(openHydrationStatus))
            container.addGestureRecognizer(tap)
            
            blurView.isUserInteractionEnabled = false
            circularProgress.isUserInteractionEnabled = false
            valueLabel.isUserInteractionEnabled = false
            totalLabel.isUserInteractionEnabled = false
        }

        return container
    }
    class SegmentedMedicationProgressView: UIView {
        
        private var morningProgress: CGFloat = 0
        private var afternoonProgress: CGFloat = 0
        private var nightProgress: CGFloat = 0
        
        private let lineWidth: CGFloat = 10
        private let trackColor = UIColor.lightGray.withAlphaComponent(0.2)
        
        func setProgress(morning: CGFloat, afternoon: CGFloat, night: CGFloat) {
            self.morningProgress = min(max(morning, 0), 1.0)
            self.afternoonProgress = min(max(afternoon, 0), 1.0)
            self.nightProgress = min(max(night, 0), 1.0)
            setNeedsDisplay()
        }
        
        override func draw(_ rect: CGRect) {
            UIColor.clear.setFill()
            UIRectFill(rect)
            
            let center = CGPoint(x: bounds.midX, y: bounds.maxY - 5)
            let radius = (bounds.width / 2) - (lineWidth / 2) - 3 // Extra padding
            
            let startAngle = CGFloat.pi
            let endAngle: CGFloat = 0
            
            // Draw track (background arc)
            let trackPath = UIBezierPath(arcCenter: center,
                                          radius: radius,
                                          startAngle: startAngle,
                                          endAngle: endAngle,
                                          clockwise: true)
            trackPath.lineWidth = lineWidth
            trackPath.lineCapStyle = .butt
            trackColor.setStroke()
            trackPath.stroke()
            
            // Calculate angles for 3 segments with small gaps
            let totalAngle = CGFloat.pi
            let gapAngle: CGFloat = 0.02 // Small gap between segments
            let segmentAngle = (totalAngle - (gapAngle * 2)) / 3
            
            // Morning segment (left third) - Green with LOWER OPACITY
            if morningProgress > 0 {
                let morningStart = startAngle
                let morningEnd = morningStart + (segmentAngle * morningProgress)
                let morningPath = UIBezierPath(arcCenter: center,
                                               radius: radius,
                                               startAngle: morningStart,
                                               endAngle: morningEnd,
                                               clockwise: true)
                morningPath.lineWidth = lineWidth
                morningPath.lineCapStyle = .butt
                UIColor.systemGreen.withAlphaComponent(0.6).setStroke() // 60% opacity
                morningPath.stroke()
            }
            
            // Afternoon segment (middle third) - Blue with LOWER OPACITY
            if afternoonProgress > 0 {
                let afternoonStart = startAngle + segmentAngle + gapAngle
                let afternoonEnd = afternoonStart + (segmentAngle * afternoonProgress)
                let afternoonPath = UIBezierPath(arcCenter: center,
                                                 radius: radius,
                                                 startAngle: afternoonStart,
                                                 endAngle: afternoonEnd,
                                                 clockwise: true)
                afternoonPath.lineWidth = lineWidth
                afternoonPath.lineCapStyle = .butt
                UIColor.systemBlue.withAlphaComponent(0.6).setStroke() // 60% opacity
                afternoonPath.stroke()
            }
            
            // Night segment (right third) - Indigo with LOWER OPACITY
            if nightProgress > 0 {
                let nightStart = startAngle + (segmentAngle * 2) + (gapAngle * 2)
                let nightEnd = nightStart + (segmentAngle * nightProgress)
                let nightPath = UIBezierPath(arcCenter: center,
                                             radius: radius,
                                             startAngle: nightStart,
                                             endAngle: nightEnd,
                                             clockwise: true)
                nightPath.lineWidth = lineWidth
                nightPath.lineCapStyle = .butt
                UIColor.systemIndigo.withAlphaComponent(0.6).setStroke() // 60% opacity
                nightPath.stroke()
            }
            
            // Draw separator lines between segments (very subtle)
            let separatorColor = UIColor.white.withAlphaComponent(0.5)
            let separatorWidth: CGFloat = 1.5
            
            // Separator 1 (between morning and afternoon)
            let sep1Angle = startAngle + segmentAngle + (gapAngle / 2)
            let sep1Start = CGPoint(
                x: center.x + (radius - lineWidth/2 - 1) * cos(sep1Angle),
                y: center.y + (radius - lineWidth/2 - 1) * sin(sep1Angle)
            )
            let sep1End = CGPoint(
                x: center.x + (radius + lineWidth/2 + 1) * cos(sep1Angle),
                y: center.y + (radius + lineWidth/2 + 1) * sin(sep1Angle)
            )
            let sep1Path = UIBezierPath()
            sep1Path.move(to: sep1Start)
            sep1Path.addLine(to: sep1End)
            sep1Path.lineWidth = separatorWidth
            separatorColor.setStroke()
            sep1Path.stroke()
            
            // Separator 2 (between afternoon and night)
            let sep2Angle = startAngle + (segmentAngle * 2) + gapAngle + (gapAngle / 2)
            let sep2Start = CGPoint(
                x: center.x + (radius - lineWidth/2 - 1) * cos(sep2Angle),
                y: center.y + (radius - lineWidth/2 - 1) * sin(sep2Angle)
            )
            let sep2End = CGPoint(
                x: center.x + (radius + lineWidth/2 + 1) * cos(sep2Angle),
                y: center.y + (radius + lineWidth/2 + 1) * sin(sep2Angle)
            )
            let sep2Path = UIBezierPath()
            sep2Path.move(to: sep2Start)
            sep2Path.addLine(to: sep2End)
            sep2Path.lineWidth = separatorWidth
            separatorColor.setStroke()
            sep2Path.stroke()
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            isOpaque = false
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            backgroundColor = .clear
            isOpaque = false
        }
    }
    
    private func createSegmentedMedicationCard() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        container.layer.cornerRadius = 20
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true
        container.insertSubview(blurView, at: 0)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: container.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        // Segmented progress view - SAME SIZE AS WATER CARD
        let segmentedProgress = SegmentedMedicationProgressView(frame: CGRect(x: 0, y: 0, width: 110, height: 70))
        segmentedProgress.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(segmentedProgress)
        medicationProgressView = segmentedProgress
        
        // COUNT LABEL - BOLD, centered in progress circle
        let countLabel = UILabel()
        countLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        countLabel.textAlignment = .center
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(countLabel)
        medicationValueLabel = countLabel
        
        // "out of X doses" label - below progress, regular weight
        let totalLabel = UILabel()
        totalLabel.font = UIFont.systemFont(ofSize: 13)
        totalLabel.textAlignment = .center
        totalLabel.numberOfLines = 2
        totalLabel.textColor = .darkGray
        totalLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(totalLabel)
        medicationTotalLabel = totalLabel
        
        NSLayoutConstraint.activate([
            segmentedProgress.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            segmentedProgress.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            segmentedProgress.widthAnchor.constraint(equalToConstant: 110),
            segmentedProgress.heightAnchor.constraint(equalToConstant: 70),
            
            // Count label centered in the progress arc
            countLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            countLabel.bottomAnchor.constraint(equalTo: segmentedProgress.bottomAnchor, constant: 0),
            
            // Total label below progress
            totalLabel.topAnchor.constraint(equalTo: segmentedProgress.bottomAnchor, constant: 8),
            totalLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            totalLabel.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 8),
            totalLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -8)
        ])
        
        updateSegmentedMedicationCard()
        
        // Add tap gesture
        container.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(medicationCardTapped))
        container.addGestureRecognizer(tap)
        
        blurView.isUserInteractionEnabled = false
        segmentedProgress.isUserInteractionEnabled = false
        
        return container
    }
    

    private func updateSegmentedMedicationCard() {
        let store = MedicationStore.shared
        let today = Date()
        
        // Get progress for each time of day
        let morningProgress = store.takenCount(for: .morning, date: today)
        let afternoonProgress = store.takenCount(for: .afternoon, date: today)
        let nightProgress = store.takenCount(for: .night, date: today)
        
        // Calculate segment values (0.0 to 1.0)
        let morningValue: CGFloat = morningProgress.total > 0 ? CGFloat(morningProgress.taken) / CGFloat(morningProgress.total) : 0
        let afternoonValue: CGFloat = afternoonProgress.total > 0 ? CGFloat(afternoonProgress.taken) / CGFloat(afternoonProgress.total) : 0
        let nightValue: CGFloat = nightProgress.total > 0 ? CGFloat(nightProgress.taken) / CGFloat(nightProgress.total) : 0
        
        // Update the segmented view
        if let segmentedView = medicationProgressView as? SegmentedMedicationProgressView {
            segmentedView.setProgress(morning: morningValue, afternoon: afternoonValue, night: nightValue)
        }
        
        // Update count - BOLD NUMBER like water card
        let totalTaken = morningProgress.taken + afternoonProgress.taken + nightProgress.taken
        let totalDoses = morningProgress.total + afternoonProgress.total + nightProgress.total
        medicationValueLabel?.text = "\(totalTaken)"
        
        // Update total label
        medicationTotalLabel?.text = "out of\n\(totalDoses) doses"
    }
    // MARK: - Fluid Quick-Add (button + editor)

    private func createFluidQuickAddButton() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(red: 0.67, green: 0.85, blue: 0.93, alpha: 1.0)
        container.layer.cornerRadius = 14
        container.translatesAutoresizingMaskIntoConstraints = false
        container.clipsToBounds = true

        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: "drop.fill", withConfiguration: config))
        iconView.tintColor = .black
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.tag = 201
        container.addSubview(iconView)

        // hidden content: type label
        let fluidLabel = UILabel()
        fluidLabel.text = fluidTypes[selectedFluidTypeIndex]
        fluidLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        fluidLabel.translatesAutoresizingMaskIntoConstraints = false
        fluidLabel.alpha = 0
        container.addSubview(fluidLabel)
        self.fluidTypeLabel = fluidLabel

        // hidden content: quantity label
        let qtyLabel = UILabel()
        qtyLabel.text = "\(selectedFluidQuantity) ml"
        qtyLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        qtyLabel.translatesAutoresizingMaskIntoConstraints = false
        qtyLabel.alpha = 0
        qtyLabel.isUserInteractionEnabled = true
        container.addSubview(qtyLabel)
        self.fluidQuantityDisplayLabel = qtyLabel

        // hidden: edit button
        let editBtn = UIButton(type: .system)
        let editCfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        editBtn.setImage(UIImage(systemName: "square.and.pencil", withConfiguration: editCfg), for: .normal)
        editBtn.tintColor = .black
        editBtn.translatesAutoresizingMaskIntoConstraints = false
        editBtn.alpha = 0
        container.addSubview(editBtn)
        self.fluidEditButton = editBtn
        editBtn.addTarget(self, action: #selector(fluidEditTapped), for: .touchUpInside)

        // hidden: stepper
        let stepper = UIStepper()
        stepper.minimumValue = 0
        stepper.maximumValue = 2000
        stepper.stepValue = 25
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.alpha = 0
        stepper.value = Double(selectedFluidQuantity)
        container.addSubview(stepper)
        self.fluidStepper = stepper
        stepper.addTarget(self, action: #selector(fluidStepperChanged(_:)), for: .valueChanged)

        // hidden: Save button
        let saveBtn = UIButton(type: .system)
        saveBtn.setTitle("Save", for: .normal)
        saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        saveBtn.translatesAutoresizingMaskIntoConstraints = false
        saveBtn.alpha = 0
        container.addSubview(saveBtn)
        self.fluidQuickAddSaveButton = saveBtn
        saveBtn.addTarget(self, action: #selector(fluidQuickAddSaveTapped(_:)), for: .touchUpInside)

        // icon constraints – center vs leading (for expand/collapse)
        fluidIconCenterConstraint =
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        fluidIconLeadingConstraint =
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16)

        fluidIconCenterConstraint?.isActive = true   // start centered

        NSLayoutConstraint.activate([
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            fluidLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            fluidLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            qtyLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            editBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stepper.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            saveBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            saveBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stepper.trailingAnchor.constraint(equalTo: saveBtn.leadingAnchor, constant: -8),
            editBtn.trailingAnchor.constraint(equalTo: stepper.leadingAnchor, constant: -8),
            qtyLabel.trailingAnchor.constraint(equalTo: editBtn.leadingAnchor, constant: -8)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(fluidButtonTapped))
        container.addGestureRecognizer(tap)

        let qtyTap = UITapGestureRecognizer(target: self, action: #selector(fluidEditTapped))
        qtyLabel.addGestureRecognizer(qtyTap)

        fluidQuantityDisplayLabel?.text = "\(selectedFluidQuantity) ml"

        return container
    }

    @objc private func fluidButtonTapped() {
        isFluidExpanded.toggle()

        if waterButtonWidthConstraint == nil {
            waterButtonWidthConstraint = waterButton.widthAnchor.constraint(equalToConstant: 110)
            waterButtonWidthConstraint?.isActive = true
        }

        if isFluidExpanded {
            // expand
            let targetWidth: CGFloat = max(110, view.bounds.width - 48)

            waterButtonLeadingToDietConstraint?.isActive = false
            if waterButtonLeadingToContentConstraint == nil {
                waterButtonLeadingToContentConstraint =
                    waterButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24)
            }
            waterButtonLeadingToContentConstraint?.isActive = true

            waterButtonWidthConstraint?.constant = targetWidth

            fluidIconCenterConstraint?.isActive = false
            fluidIconLeadingConstraint?.isActive = true

            UIView.animate(withDuration: 0.12) {
                self.dietButton.alpha = 0
                self.pillButton.alpha = 0
            }

            UIView.animate(withDuration: 0.45,
                           delay: 0,
                           usingSpringWithDamping: 0.68,
                           initialSpringVelocity: 0.9,
                           options: .curveEaseOut,
                           animations: {
                self.view.layoutIfNeeded()
            }, completion: { _ in
                UIView.animate(withDuration: 0.25) {
                    self.fluidTypeLabel?.alpha = 1
                    self.fluidQuantityDisplayLabel?.alpha = 1
                    self.fluidEditButton?.alpha = 1
                    self.fluidStepper?.alpha = 1
                    self.fluidQuickAddSaveButton?.alpha = 1
                }
            })
        } else {
            // collapse
            waterButtonWidthConstraint?.constant = 110

            waterButtonLeadingToContentConstraint?.isActive = false
            waterButtonLeadingToDietConstraint?.isActive = true

            fluidIconLeadingConstraint?.isActive = false
            fluidIconCenterConstraint?.isActive = true

            UIView.animate(withDuration: 0.2) {
                self.fluidTypeLabel?.alpha = 0
                self.fluidQuantityDisplayLabel?.alpha = 0
                self.fluidEditButton?.alpha = 0
                self.fluidStepper?.alpha = 0
                self.fluidQuickAddSaveButton?.alpha = 0
                self.view.layoutIfNeeded()
            } completion: { _ in
                UIView.animate(withDuration: 0.2) {
                    self.dietButton.alpha = 1
                    self.pillButton.alpha = 1
                }
            }
        }
    }

    @objc private func fluidStepperChanged(_ sender: UIStepper) {
        selectedFluidQuantity = Int(sender.value)
        fluidQuantityDisplayLabel?.text = "\(selectedFluidQuantity) ml"
    }

    @objc private func fluidQuickAddSaveTapped(_ sender: UIButton) {
        // Add quantity to total water & log entry
        let currentTotal = UserDataManager.shared.loadInt("waterConsumed", uid: uid, defaultValue: 0)
        let newTotal = currentTotal + selectedFluidQuantity
        updateWater(consumed: newTotal)

        let type = fluidTypes[selectedFluidTypeIndex]
        FluidLogStore.shared.addLog(type: type, quantity: selectedFluidQuantity)

        // collapse after save
        fluidButtonTapped()
    }

    @objc private func fluidEditTapped() {
        buildFluidEditorPopup()
    }

    // MARK: - Fluid editor popup

    private func buildFluidEditorPopup() {
        // dim overlay
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        overlay.alpha = 0
        view.addSubview(overlay)
        fluidEditorOverlay = overlay

        let tap = UITapGestureRecognizer(target: self, action: #selector(fluidEditorCancelTapped(_:)))
        overlay.addGestureRecognizer(tap)

        // card
        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 18
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)
        fluidEditorCard = card

        let title = UILabel()
        title.text = "Add Fluid"
        title.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(title)

        let typeLabel = UILabel()
        typeLabel.text = "Fluid Type"
        typeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(typeLabel)

        let typeField = UITextField()
        typeField.borderStyle = .roundedRect
        typeField.placeholder = "Water / Coffee / Tea..."
        typeField.translatesAutoresizingMaskIntoConstraints = false
        typeField.delegate = self
        card.addSubview(typeField)

        // picker for types
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        typeField.inputView = picker
        picker.selectRow(selectedFluidTypeIndex, inComponent: 0, animated: false)

        let qtyLabel = UILabel()
        qtyLabel.text = "Quantity (ml)"
        qtyLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        qtyLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(qtyLabel)

        let qtyField = UITextField()
        qtyField.borderStyle = .roundedRect
        qtyField.keyboardType = .numberPad
        qtyField.translatesAutoresizingMaskIntoConstraints = false
        qtyField.text = "\(selectedFluidQuantity)"
        card.addSubview(qtyField)
        attachDoneButtonToNumberPad(qtyField)

        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.addTarget(self, action: #selector(fluidEditorCancelTapped(_:)), for: .touchUpInside)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cancelBtn)

        let saveBtn = UIButton(type: .system)
        saveBtn.setTitle("Save", for: .normal)
        saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        saveBtn.addTarget(self, action: #selector(fluidEditorSaveTapped(_:)), for: .touchUpInside)
        saveBtn.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(saveBtn)

        NSLayoutConstraint.activate([
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            title.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            title.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            typeLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16),
            typeLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            typeField.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 8),
            typeField.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            typeField.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            qtyLabel.topAnchor.constraint(equalTo: typeField.bottomAnchor, constant: 16),
            qtyLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            qtyField.topAnchor.constraint(equalTo: qtyLabel.bottomAnchor, constant: 8),
            qtyField.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            qtyField.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            cancelBtn.topAnchor.constraint(equalTo: qtyField.bottomAnchor, constant: 18),
            cancelBtn.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            cancelBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),

            saveBtn.centerYAnchor.constraint(equalTo: cancelBtn.centerYAnchor),
            saveBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])

        UIView.animate(withDuration: 0.2) {
            overlay.alpha = 1
        }
    }

    @objc private func fluidEditorSaveTapped(_ sender: Any) {
        guard
            let card = fluidEditorCard,
            let typeField = card.subviews.compactMap({ $0 as? UITextField }).first,
            let qtyField = card.subviews.compactMap({ $0 as? UITextField }).last
        else { return }

        let typedType = (typeField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let qtyText = (qtyField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let qty = Int(qtyText) ?? selectedFluidQuantity

        if !typedType.isEmpty {
            if !fluidTypes.contains(typedType) {
                fluidTypes.append(typedType)
            }
            selectedFluidTypeIndex = fluidTypes.firstIndex(of: typedType) ?? selectedFluidTypeIndex
        }

        selectedFluidQuantity = qty

        fluidTypeLabel?.text = fluidTypes[selectedFluidTypeIndex]
        fluidQuantityDisplayLabel?.text = "\(selectedFluidQuantity) ml"
        fluidStepper?.value = Double(selectedFluidQuantity)

        // update hydration + log
        let currentTotal = UserDataManager.shared.loadInt("waterConsumed", uid: uid, defaultValue: 0)
        let newTotal = currentTotal + selectedFluidQuantity
        updateWater(consumed: newTotal)

        let finalType = fluidTypes[selectedFluidTypeIndex]
        FluidLogStore.shared.addLog(type: finalType, quantity: selectedFluidQuantity)

        view.endEditing(true)
        dismissFluidEditor()
    }

    @objc private func fluidEditorCancelTapped(_ sender: Any) {
        view.endEditing(true)
        dismissFluidEditor()
    }

    private func dismissFluidEditor() {
        UIView.animate(withDuration: 0.2, animations: {
            self.fluidEditorOverlay?.alpha = 0
        }, completion: { _ in
            self.fluidEditorCard?.removeFromSuperview()
            self.fluidEditorOverlay?.removeFromSuperview()
            self.fluidEditorCard = nil
            self.fluidEditorOverlay = nil
        })
    }

    
    @objc private func openHydrationStatus() {
        let hydrationVC = HydrationStatusViewController()
        hydrationVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(hydrationVC, animated: true)
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
    
    private func setupWeightSection() {
        let weightCard = UIView()
        weightCard.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        weightCard.layer.cornerRadius = 20
        weightCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(weightCard)
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true
        weightCard.insertSubview(blurView, at: 0)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: weightCard.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: weightCard.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: weightCard.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: weightCard.bottomAnchor)
        ])
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: "scalemass", withConfiguration: iconConfig))
        iconView.tintColor = .systemGreen
        iconView.translatesAutoresizingMaskIntoConstraints = false
        weightCard.addSubview(iconView)
        
        let titleLabel = UILabel()
        titleLabel.text = "Weight"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        weightCard.addSubview(titleLabel)
        
        let valueLabel = UILabel()
        valueLabel.text = "\(Int(currentWeight)) Kg"
        valueLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        valueLabel.textColor = .darkGray
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        weightCard.addSubview(valueLabel)
        
        weightValueLabel = valueLabel
        
        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronImageView.tintColor = .gray
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        weightCard.addSubview(chevronImageView)
        
        guard let lastView = contentView.subviews.last(where: { $0 !== weightCard }) else { return }
        
        NSLayoutConstraint.activate([
            weightCard.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 12),
            weightCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            weightCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            weightCard.heightAnchor.constraint(equalToConstant: 65),
            
            iconView.leadingAnchor.constraint(equalTo: weightCard.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: weightCard.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: weightCard.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            valueLabel.centerYAnchor.constraint(equalTo: weightCard.centerYAnchor),
            
            chevronImageView.trailingAnchor.constraint(equalTo: weightCard.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: weightCard.centerYAnchor)
        ])
        
        // Upcoming Appointments Section
        let upcomingTitle = UILabel()
        upcomingTitle.text = "Upcoming Appointments"
        upcomingTitle.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        upcomingTitle.textColor = UIColor(hex: 0x152B3C)
        upcomingTitle.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(upcomingTitle)

        let appointmentCard = UIView()
        appointmentCard.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        appointmentCard.layer.cornerRadius = 20
        appointmentCard.translatesAutoresizingMaskIntoConstraints = false
        appointmentCard.isUserInteractionEnabled = true
        contentView.addSubview(appointmentCard)

        let blurEffect2 = UIBlurEffect(style: .light)
        let blurView2 = UIVisualEffectView(effect: blurEffect2)
        blurView2.translatesAutoresizingMaskIntoConstraints = false
        blurView2.layer.cornerRadius = 20
        blurView2.clipsToBounds = true
        appointmentCard.insertSubview(blurView2, at: 0)

        let clockIcon = UIImageView(image: UIImage(systemName: "clock"))
        clockIcon.tintColor = .systemGreen
        clockIcon.translatesAutoresizingMaskIntoConstraints = false

        let hospitalLabel = UILabel()
        hospitalLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        hospitalLabel.translatesAutoresizingMaskIntoConstraints = false

        let dateLabel = UILabel()
        dateLabel.font = UIFont.systemFont(ofSize: 14)
        dateLabel.textColor = .darkGray
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        let timeLabel = UILabel()
        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.textColor = .darkGray
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Fetch next upcoming appointment from UserDefaults
        let next = AppointmentStore.shared.nextUpcoming()

        if let appointment = next {
            hospitalLabel.text = appointment.hospitalName
            dateLabel.text = appointment.date.formatted(date: .long, time: .omitted)
            timeLabel.text = appointment.date.formatted(date: .omitted, time: .shortened)
        } else {
            hospitalLabel.text = "No Appointments"
            dateLabel.text = "Tap to add your first one"
            timeLabel.text = ""
        }
        
        appointmentHospitalLabel = hospitalLabel
        appointmentDateLabel = dateLabel
        appointmentTimeLabel = timeLabel


        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .gray
        chevron.translatesAutoresizingMaskIntoConstraints = false

        appointmentCard.addSubview(clockIcon)
        appointmentCard.addSubview(hospitalLabel)
        appointmentCard.addSubview(dateLabel)
        appointmentCard.addSubview(timeLabel)
        appointmentCard.addSubview(chevron)

        NSLayoutConstraint.activate([
            upcomingTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            upcomingTitle.topAnchor.constraint(equalTo: weightCard.bottomAnchor, constant: 32),

            appointmentCard.topAnchor.constraint(equalTo: upcomingTitle.bottomAnchor, constant: 14),
            appointmentCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            appointmentCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            appointmentCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            blurView2.topAnchor.constraint(equalTo: appointmentCard.topAnchor),
            blurView2.bottomAnchor.constraint(equalTo: appointmentCard.bottomAnchor),
            blurView2.leadingAnchor.constraint(equalTo: appointmentCard.leadingAnchor),
            blurView2.trailingAnchor.constraint(equalTo: appointmentCard.trailingAnchor),

            clockIcon.leadingAnchor.constraint(equalTo: appointmentCard.leadingAnchor, constant: 16),
            clockIcon.topAnchor.constraint(equalTo: appointmentCard.topAnchor, constant: 20),
            clockIcon.widthAnchor.constraint(equalToConstant: 32),
            clockIcon.heightAnchor.constraint(equalToConstant: 32),

            hospitalLabel.leadingAnchor.constraint(equalTo: clockIcon.trailingAnchor, constant: 16),
            hospitalLabel.topAnchor.constraint(equalTo: appointmentCard.topAnchor, constant: 18),

            dateLabel.leadingAnchor.constraint(equalTo: hospitalLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: hospitalLabel.bottomAnchor, constant: 6),

            timeLabel.leadingAnchor.constraint(equalTo: hospitalLabel.leadingAnchor),
            timeLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            timeLabel.bottomAnchor.constraint(equalTo: appointmentCard.bottomAnchor, constant: -18),

            chevron.trailingAnchor.constraint(equalTo: appointmentCard.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: appointmentCard.centerYAnchor)
        ])


        let tap2 = UITapGestureRecognizer(target: self, action: #selector(openAppointmentDetails))
        appointmentCard.addGestureRecognizer(tap2)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(weightCardTapped))
        weightCard.addGestureRecognizer(tapGesture)
        weightCard.isUserInteractionEnabled = true
        
        blurView.isUserInteractionEnabled = false
        iconView.isUserInteractionEnabled = false
        titleLabel.isUserInteractionEnabled = false
        valueLabel.isUserInteractionEnabled = false
        chevronImageView.isUserInteractionEnabled = false
    }
    
    @objc func refreshAppointmentCard() {
        let next = AppointmentStore.shared.nextUpcoming()

        if let appointment = next {
            appointmentHospitalLabel?.text = appointment.hospitalName
            appointmentDateLabel?.text = appointment.date.formatted(date: .long, time: .omitted)
            appointmentTimeLabel?.text = appointment.date.formatted(date: .omitted, time: .shortened)
        } else {
            appointmentHospitalLabel?.text = "No Appointments"
            appointmentDateLabel?.text = "Tap to add"
            appointmentTimeLabel?.text = ""
        }
    }
    
    @objc private func openAppointmentDetails() {
        let vc = AppointmentDetailsViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func saveImageToTemp(_ image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return url
        } catch {
            print("Failed to write temp image:", error)
            return nil
        }
    }
    
    private func showClassificationError(_ error: Error) {
        let alert = UIAlertController(
            title: "Classification Failed",
            message: "Could not identify the food item. Please try again.\n\nError: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    // MARK: - UIPickerView DataSource & Delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return fluidTypes.count
    }

    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        return fluidTypes[row]
    }

    func pickerView(_ pickerView: UIPickerView,
                    didSelectRow row: Int,
                    inComponent component: Int) {
        selectedFluidTypeIndex = row
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func attachDoneButtonToNumberPad(_ textField: UITextField) {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done",
                                   style: .done,
                                   target: self,
                                   action: #selector(numberPadDoneTapped))
        toolbar.items = [flex, done]
        textField.inputAccessoryView = toolbar
    }

    @objc private func numberPadDoneTapped() {
        view.endEditing(true)
    }

    
    deinit {
            NotificationCenter.default.removeObserver(self)
        }
}

final class PreviewViewController: UIViewController {
    private let imageView = UIImageView()
    private let acceptedHandler: (UIImage) -> Void
    private let image: UIImage

    init(image: UIImage, accepted: @escaping (UIImage) -> Void) {
        self.image = image
        self.acceptedHandler = accepted
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        view.addSubview(imageView)

        let retake = UIBarButtonItem(title: "Retake", style: .plain, target: self, action: #selector(retakeTapped))
        let accept = UIBarButtonItem(title: "Accept", style: .done, target: self, action: #selector(acceptTapped))
        navigationItem.leftBarButtonItem = retake
        navigationItem.rightBarButtonItem = accept
        navigationItem.title = "Preview"

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12)
        ])
    }

    @objc private func retakeTapped() {
        dismiss(animated: true)
    }

    @objc private func acceptTapped() {
        acceptedHandler(image)
        dismiss(animated: true)
    }
}

class SemiCircularProgressView: UIView {
    
    var progress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var trackColor: UIColor = UIColor.lightGray.withAlphaComponent(0.3)
    var progressColor: UIColor = .systemBlue
    var lineWidth: CGFloat = 10
    
    override func draw(_ rect: CGRect) {
        UIColor.clear.setFill()
        UIRectFill(rect)
        
        let center = CGPoint(x: bounds.midX, y: bounds.maxY - 5)
        let radius = (bounds.width / 2) - (lineWidth / 2)
        
        let startAngle = CGFloat.pi
        let endAngle: CGFloat = 0
        
        let trackPath = UIBezierPath(arcCenter: center,
                                      radius: radius,
                                      startAngle: startAngle,
                                      endAngle: endAngle,
                                      clockwise: true)
        trackPath.lineWidth = lineWidth
        trackPath.lineCapStyle = .round
        trackColor.setStroke()
        trackPath.stroke()
        
        let progressEndAngle = startAngle + (CGFloat.pi * progress)
        let progressPath = UIBezierPath(arcCenter: center,
                                         radius: radius,
                                         startAngle: startAngle,
                                         endAngle: progressEndAngle,
                                         clockwise: true)
        progressPath.lineWidth = lineWidth
        progressPath.lineCapStyle = .round
        progressColor.setStroke()
        progressPath.stroke()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isOpaque = false
    }
}

extension Notification.Name {
    static let waterDidUpdate = Notification.Name("waterDidUpdate")
}

extension Notification.Name {
    static let medicationDidUpdate = Notification.Name("medicationDidUpdate")
}


extension HomeDashboardViewController: CameraCaptureDelegate {
    
    func cameraCaptureDidCaptureFood(image: UIImage, result: FoodRecognitionResult) {
        let detailVC = DishDetailViewController()
        detailVC.recognitionResult = result
        detailVC.foodImage = image
        
        if let navController = navigationController {
            navController.pushViewController(detailVC, animated: true)
        } else {
            detailVC.modalPresentationStyle = .fullScreen
            present(detailVC, animated: true)
        }
    }
    
    func cameraCaptureDidCancel() {
        // Camera dismissed
    }
}

extension HomeDashboardViewController: MedicationPopupDelegate {
    func medicationPopupDidToggleMedication(_ medicationId: UUID, timeOfDay: TimeOfDay) {
        updateMedicationCard()
    }
}

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
