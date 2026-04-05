
// user 1
// main

import UIKit
import SwiftUI
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
    
   

    
    // MARK: - Properties
    let scrollView = UIScrollView()
    let contentView = UIView()
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
    
    // Add to MARK: - Properties section
    var highlightsLabel: UILabel?
    var highlightsContainer: HighlightsContainerView?
    var summaryCardsStackView: UIView? // Reference to summary section bottom
    
//    private var appointmentHospitalLabel: UILabel?
//    private var appointmentDateLabel: UILabel?
//    private var appointmentTimeLabel: UILabel?


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
    private let dietCardState = DietCardState()
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
    private var potassiumConsumed: Int = 0 {
        didSet { updateNutrientCard() }
    }

    private var sodiumConsumed: Int = 0 {
        didSet { updateNutrientCard() }
    }

    private var proteinConsumed: Int = 0 {
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
    private var waterRingView: FullCircularProgressView?   // new full-ring for hydration card

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

   
    


    // -------------------------------------------------------------------------

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserValues()
        addTopGradientBackground()
        setupUI()
       // refreshAppointmentCard()
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
        refreshHighlights()
        // Keep it fresh every time the screen appears
       // updateSegmentedMedicationCard()
        
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
        refreshHighlights()
        
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
        NotificationCenter.default.post(name: .mealsDidUpdate, object: nil)


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
        // Update full-ring hydration card
        let progress = waterGoal > 0 ? CGFloat(waterConsumed) / CGFloat(waterGoal) : 0
        waterRingView?.progress = min(progress, 1.0)
        let liters = String(format: "%.1f", Double(waterConsumed) / 1000.0)
        waterValueLabel?.text = liters
        let pct = waterGoal > 0 ? Int(progress * 100) : 0
        waterTotalLabel?.text = "\(pct)% of daily goal"
        // Legacy semi-circular (unused in new layout, safe to update)
        waterProgressView?.progress = min(progress, 1.0)
    }

    private func updateMedicationCard() {
        updateSegmentedMedicationCard()
    }

    private func updateNutrientCard() {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal

        let kVal = fmt.string(from: NSNumber(value: potassiumConsumed)) ?? "\(potassiumConsumed)"
        potassiumValueLabel?.text = kVal
        let kProg = potassiumGoal > 0 ? CGFloat(potassiumConsumed) / CGFloat(potassiumGoal) : 0
        updateProgressBar(fill: potassiumProgressFill, bar: potassiumProgressBar, progress: kProg)

        let sVal = fmt.string(from: NSNumber(value: sodiumConsumed)) ?? "\(sodiumConsumed)"
        sodiumValueLabel?.text = sVal
        let sProg = sodiumGoal > 0 ? CGFloat(sodiumConsumed) / CGFloat(sodiumGoal) : 0
        updateProgressBar(fill: sodiumProgressFill, bar: sodiumProgressBar, progress: sProg)

        let pVal = fmt.string(from: NSNumber(value: proteinConsumed)) ?? "\(proteinConsumed)"
        proteinValueLabel?.text = pVal
        let pProg = proteinGoal > 0 ? CGFloat(proteinConsumed) / CGFloat(proteinGoal) : 0
        updateProgressBar(fill: proteinProgressFill, bar: proteinProgressBar, progress: pProg)
    }

    private func updateProgressBar(fill: UIView?, bar: UIView?, progress: CGFloat) {
        guard let fill = fill, let bar = bar else { return }
        fill.constraints.forEach { c in
            if c.firstAttribute == .width { bar.removeConstraint(c) }
        }
        NSLayoutConstraint.activate([
            fill.widthAnchor.constraint(equalTo: bar.widthAnchor, multiplier: min(max(progress, 0), 1.0))
        ])
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
        refreshHighlights()
    }
    @objc private func limitsDidUpdate() {
        // Reload nutrient card with new limits
        updateNutrientCard()
    }
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppTheme.background
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupScrollView()
        setupHeader()
        setupQuickAddSection()
        setupSummarySection()
       
        setupHighlightsSection()
        setupHighlightsObservers()
        
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
    private func findSummaryBottomView() -> UIView {
        return summaryCardsStackView ?? contentView
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
            color: AppTheme.pillCardBase,
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
        container.backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        
        // Dummy buttons to prevent crashes in other animations
        cameraButton = UIButton()
        searchButton = UIButton()
        
        let dietView = DietCardSwiftUIView(
            state: dietCardState,
            onCameraTap: { [weak self] in self?.cameraButtonTapped() },
            onSearchTap: { [weak self] in self?.searchButtonTapped() }
        )
        
        let hostingController = UIHostingController(rootView: dietView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: container.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        
        self.addChild(hostingController)
        hostingController.didMove(toParent: self)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dietButtonTapped))
        container.addGestureRecognizer(tapGesture)
        
        return container
    }
    
    @objc private func dietButtonTapped() {
        if isFluidExpanded { return }
        isExpanded.toggle()
        dietCardState.isExpanded = isExpanded
        
        if isExpanded {
            dietButtonWidthConstraint.constant = 340
            summaryTopConstraint.constant = 40
            
            UIView.animate(withDuration: 0.15, animations: {
                self.waterButton.alpha = 0
                self.pillButton.alpha = 0
            })
            
            UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.68, initialSpringVelocity: 0.8, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
            
        } else {
            dietButtonWidthConstraint.constant = 110
            summaryTopConstraint.constant = 16
            
            UIView.animate(withDuration: 0.4, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                self.view.layoutIfNeeded()
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
    @objc private func searchButtonTapped() {
        print("🔍 Search button tapped - opening FoodSearchViewController")
        
        let searchVC = EnhancedFoodSearchViewController()
        searchVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(searchVC, animated: true)
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

        // 1. Nutrient Card
        let nutrientCard = createNutrientBalanceCard()
        nutrientCard.translatesAutoresizingMaskIntoConstraints = false
        nutrientCard.isUserInteractionEnabled = true
        nutrientCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openNutrientBalance)))
        contentView.addSubview(nutrientCard)

        // 2. Hydration Card
        let waterCard = createHydrationSummaryCard()
        waterCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(waterCard)

        // 3. Medication Card
        let doseCard = createMedicationSummaryCard()
        doseCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(doseCard)

        self.summaryCardsStackView = doseCard

        NSLayoutConstraint.activate([
            summaryTopConstraint,
            summaryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),

            nutrientCard.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 14),
            nutrientCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            nutrientCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            waterCard.topAnchor.constraint(equalTo: nutrientCard.bottomAnchor, constant: 14),
            waterCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            waterCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            waterCard.heightAnchor.constraint(equalToConstant: 110),

            doseCard.topAnchor.constraint(equalTo: waterCard.bottomAnchor, constant: 14),
            doseCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            doseCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            doseCard.heightAnchor.constraint(equalToConstant: 110)
        ])
    }
    // MARK: - Highlights Section Setup

    

    @objc private func handleDataUpdate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshHighlights()
        }
    }

    

    private func navigateToHighlightScreen(_ destination: HealthInsight.DestinationScreen) {
        let viewController: UIViewController
        
        switch destination {
        case .nutrientBalance:
            viewController = NutrientBalanceViewController()
        case .hydrationStatus:
            viewController = HydrationStatusViewController()
        case .medicationAdherence:
            viewController = MedicationAdherenceViewController()
        case .healthAndVitals:
            viewController = HealthAndVitalsViewController()
        }
        
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc private func openNutrientBalance() {
        let vc = NutrientBalanceViewController()
       
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func createNutrientBalanceCard() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemBackground
        container.layer.cornerRadius = 20
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.06
        container.layer.shadowRadius = 8
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        // Brand colors matching the reference design
        let potassiumColor = UIColor(red: 0.0,  green: 0.47, blue: 0.35, alpha: 1) // teal-green
        let sodiumColor    = UIColor(red: 0.12, green: 0.31, blue: 0.55, alpha: 1) // dark blue
        let proteinColor   = UIColor(red: 0.42, green: 0.30, blue: 0.05, alpha: 1) // warm brown

        let potassiumProgress = potassiumGoal > 0 ? CGFloat(potassiumConsumed) / CGFloat(potassiumGoal) : 0
        let potassiumRow = createNutrientRow(
            name: "Potassium", value: "\(potassiumConsumed)", unit: "mg",
            progress: potassiumProgress, color: potassiumColor, type: .potassium
        )

        let sodiumProgress = sodiumGoal > 0 ? CGFloat(sodiumConsumed) / CGFloat(sodiumGoal) : 0
        let sodiumRow = createNutrientRow(
            name: "Sodium", value: "\(sodiumConsumed)", unit: "mg",
            progress: sodiumProgress, color: sodiumColor, type: .sodium
        )

        let proteinProgress = proteinGoal > 0 ? CGFloat(proteinConsumed) / CGFloat(proteinGoal) : 0
        let proteinRow = createNutrientRow(
            name: "Protein", value: "\(proteinConsumed)", unit: "g",
            progress: proteinProgress, color: proteinColor, type: .protein
        )

        stack.addArrangedSubview(potassiumRow)
        stack.addArrangedSubview(sodiumRow)
        stack.addArrangedSubview(proteinRow)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18)
        ])

        return container
    }

    private enum NutrientType {
        case potassium, sodium, protein
    }

    /// Creates a single nutrient row: name(left) + bold-value + unit(right), bar below
    private func createNutrientRow(name: String, value: String, unit: String,
                                   progress: CGFloat, color: UIColor,
                                   type: NutrientType) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        // Name label (left)
        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(nameLabel)

        // Value label (right, bold)
        let valueLabel = UILabel()
        valueLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        valueLabel.textColor = .label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(valueLabel)

        // Unit label (right of value, smaller)
        let unitLabel = UILabel()
        unitLabel.text = unit
        unitLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        unitLabel.textColor = .secondaryLabel
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(unitLabel)

        // Progress track
        let progressBar = UIView()
        progressBar.backgroundColor = color.withAlphaComponent(0.18)
        progressBar.layer.cornerRadius = 3
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(progressBar)

        // Progress fill
        let progressFill = UIView()
        progressFill.backgroundColor = color
        progressFill.layer.cornerRadius = 3
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressBar.addSubview(progressFill)

        // Wire up references for later updates
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

        // Initial text - format like "3,200"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        valueLabel.text = formatter.string(from: NSNumber(value: Int(value) ?? 0)) ?? value

        let clampedProgress = min(max(progress, 0), 1.0)

        NSLayoutConstraint.activate([
            // Name row
            nameLabel.topAnchor.constraint(equalTo: row.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor),

            unitLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            unitLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),

            valueLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: unitLabel.leadingAnchor, constant: -3),

            // Progress bar
            progressBar.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            progressBar.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 5),
            progressBar.bottomAnchor.constraint(equalTo: row.bottomAnchor),

            // Fill
            progressFill.leadingAnchor.constraint(equalTo: progressBar.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressBar.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressBar.bottomAnchor),
            progressFill.widthAnchor.constraint(equalTo: progressBar.widthAnchor, multiplier: clampedProgress)
        ])

        return row
    }
    
    // MARK: - Full-ring progress view used by Hydration & Medication summary cards
    class FullCircularProgressView: UIView {
        var progress: CGFloat = 0 { didSet { setNeedsDisplay() } }
        var trackColor: UIColor = UIColor.systemGray4
        var progressColor: UIColor = UIColor.systemBlue
        private let lineWidth: CGFloat = 7

        override func draw(_ rect: CGRect) {
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = (min(bounds.width, bounds.height) / 2) - lineWidth / 2
            let start = -CGFloat.pi / 2
            let end   = start + 2 * CGFloat.pi

            // Track
            let track = UIBezierPath(arcCenter: center, radius: radius,
                                     startAngle: start, endAngle: end, clockwise: true)
            track.lineWidth = lineWidth
            trackColor.setStroke()
            track.stroke()

            // Fill
            let fillEnd = start + 2 * CGFloat.pi * min(max(progress, 0), 1.0)
            let fill = UIBezierPath(arcCenter: center, radius: radius,
                                    startAngle: start, endAngle: fillEnd, clockwise: true)
            fill.lineWidth = lineWidth
            fill.lineCapStyle = .round
            progressColor.setStroke()
            fill.stroke()
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear; isOpaque = false
        }
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            backgroundColor = .clear; isOpaque = false
        }
    }

    /// Hydration card: full-circle ring left, title + subtitle right
    private func createHydrationSummaryCard() -> UIView {
        let container = makeCardContainer()

        let ringSize: CGFloat = 72
        let ring = FullCircularProgressView()
        ring.translatesAutoresizingMaskIntoConstraints = false
        ring.trackColor = UIColor(red: 0.12, green: 0.31, blue: 0.55, alpha: 0.18)
        ring.progressColor = UIColor(red: 0.12, green: 0.31, blue: 0.55, alpha: 1)
        ring.progress = waterGoal > 0 ? CGFloat(waterConsumed) / CGFloat(waterGoal) : 0
        container.addSubview(ring)
        waterRingView = ring   // stored for updateWaterCard()

        // Center value label (liters)
        let liters = String(format: "%.1f", Double(waterConsumed) / 1000.0)
        let valLabel = UILabel()
        valLabel.text = liters
        valLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        valLabel.textAlignment = .center
        valLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(valLabel)
        waterValueLabel = valLabel

        let unitLabel = UILabel()
        unitLabel.text = "Liters"
        unitLabel.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        unitLabel.textColor = .secondaryLabel
        unitLabel.textAlignment = .center
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(unitLabel)

        // Right side text
        let titleLabel = UILabel()
        titleLabel.text = "Hydration"
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        let pct = waterGoal > 0 ? Int(CGFloat(waterConsumed) / CGFloat(waterGoal) * 100) : 0
        let subtitleLabel = UILabel()
        subtitleLabel.text = "\(pct)% of daily goal"
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(subtitleLabel)
        waterTotalLabel = subtitleLabel

        NSLayoutConstraint.activate([
            ring.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            ring.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            ring.widthAnchor.constraint(equalToConstant: ringSize),
            ring.heightAnchor.constraint(equalToConstant: ringSize),

            valLabel.centerXAnchor.constraint(equalTo: ring.centerXAnchor),
            valLabel.centerYAnchor.constraint(equalTo: ring.centerYAnchor, constant: -6),

            unitLabel.centerXAnchor.constraint(equalTo: ring.centerXAnchor),
            unitLabel.topAnchor.constraint(equalTo: valLabel.bottomAnchor, constant: 1),

            titleLabel.leadingAnchor.constraint(equalTo: ring.trailingAnchor, constant: 18),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -10),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3)
        ])

        container.isUserInteractionEnabled = true
        container.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openHydrationStatus)))
        return container
    }

    private enum CardType {
        case water, medication
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
    
    private func createMedicationSummaryCard() -> UIView {
        let container = makeCardContainer()

        let ringSize: CGFloat = 72
        let medBrown = UIColor(red: 0.42, green: 0.30, blue: 0.05, alpha: 1)

        // Use a plain FullCircularProgressView for the ring
        let ring = FullCircularProgressView()
        ring.translatesAutoresizingMaskIntoConstraints = false
        ring.trackColor = medBrown.withAlphaComponent(0.18)
        ring.progressColor = medBrown
        container.addSubview(ring)
        medicationProgressView = ring  // reuse existing optional ref

        // Center fraction label e.g. "2/8"
        let store = MedicationStore.shared
        let today = Date()
        let mp = store.takenCount(for: .morning, date: today)
        let ap = store.takenCount(for: .afternoon, date: today)
        let np = store.takenCount(for: .night, date: today)
        let totalTaken = mp.taken + ap.taken + np.taken
        let totalDoses = mp.total + ap.total + np.total

        let fracLabel = UILabel()
        fracLabel.text = "\(totalTaken)/\(totalDoses)"
        fracLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        fracLabel.textAlignment = .center
        fracLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(fracLabel)
        medicationValueLabel = fracLabel

        let unitLabel = UILabel()
        unitLabel.text = "Doses"
        unitLabel.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        unitLabel.textColor = .secondaryLabel
        unitLabel.textAlignment = .center
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(unitLabel)

        // Progress
        ring.progress = totalDoses > 0 ? CGFloat(totalTaken) / CGFloat(totalDoses) : 0

        // Right side text
        let titleLabel = UILabel()
        titleLabel.text = "Medication"
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Critical tracking"
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(subtitleLabel)
        medicationTotalLabel = subtitleLabel

        NSLayoutConstraint.activate([
            ring.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            ring.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            ring.widthAnchor.constraint(equalToConstant: ringSize),
            ring.heightAnchor.constraint(equalToConstant: ringSize),

            fracLabel.centerXAnchor.constraint(equalTo: ring.centerXAnchor),
            fracLabel.centerYAnchor.constraint(equalTo: ring.centerYAnchor, constant: -6),

            unitLabel.centerXAnchor.constraint(equalTo: ring.centerXAnchor),
            unitLabel.topAnchor.constraint(equalTo: fracLabel.bottomAnchor, constant: 1),

            titleLabel.leadingAnchor.constraint(equalTo: ring.trailingAnchor, constant: 18),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -10),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3)
        ])

        container.isUserInteractionEnabled = true
        container.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(medicationCardTapped)))
        return container
    }

    /// Shared card container style (white bg, rounded, subtle shadow)
    private func makeCardContainer() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor.systemBackground
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowRadius = 8
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    private func createSegmentedMedicationCard() -> UIView {
        // Kept for backward-compat; not used in new layout
        return makeCardContainer()
    }
    

    private func updateSegmentedMedicationCard() {
        let store = MedicationStore.shared
        let today = Date()

        let mp = store.takenCount(for: .morning, date: today)
        let ap = store.takenCount(for: .afternoon, date: today)
        let np = store.takenCount(for: .night, date: today)

        let totalTaken = mp.taken + ap.taken + np.taken
        let totalDoses = mp.total + ap.total + np.total

        // Update the full-ring progress view
        if let ring = medicationProgressView as? FullCircularProgressView {
            ring.progress = totalDoses > 0 ? CGFloat(totalTaken) / CGFloat(totalDoses) : 0
        }

        // Fraction label e.g. "2/8"
        medicationValueLabel?.text = "\(totalTaken)/\(totalDoses)"

        // Subtitle (static in this design, but keep it live)
        medicationTotalLabel?.text = "Critical tracking"
    }
    // MARK: - Fluid Quick-Add (button + editor)

    private func createFluidQuickAddButton() -> UIView {
        let container = UIView()
        container.backgroundColor = AppTheme.waterCardBase
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
        NotificationCenter.default.post(name: NSNotification.Name("fluidDidUpdate"), object: nil)
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
       
        navigationController?.pushViewController(hydrationVC, animated: true)
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
    
    // Automatically called when Dark Mode toggles
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateGradientColors()
        }
    }
    
    private func updateGradientColors() {
        let topColor = AppTheme.background
        let bottomColor = UIColor { trait in trait.userInterfaceStyle == .dark ? UIColor(white: 0.05, alpha: 1.0) : UIColor(red: 200/255, green: 235/255, blue: 225/255, alpha: 1) }
        
        // CAGradientLayer needs to have its CGColors manually updated specifically for the current trait collection
        backgroundGradientLayer?.colors = [
            topColor.resolvedColor(with: traitCollection).cgColor, 
            bottomColor.resolvedColor(with: traitCollection).cgColor
        ]
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
    
    /// Pick the "main" dish from Gemini results.
    /// For now we just avoid obvious garnish / herb / spice types.
    private func pickPrimaryDish(from foods: [DetectedFood]) -> DetectedFood? {
        let ignoreTypeKeywords = ["garnish", "herb", "spice"]
        
        // Prefer items whose `type` is NOT just garnish/herb/spice
        if let main = foods.first(where: { food in
            guard let type = food.type?.lowercased() else { return true }
            return !ignoreTypeKeywords.contains(where: { type.contains($0) })
        }) {
            return main
        }
        
        // Fallback: just use the first one
        return foods.first
    }
    
    func cameraCaptureDidCaptureFood(image: UIImage, foods: [DetectedFood]) {
        print("\n📱 ========== HOME RECEIVED RESULTS ==========")
        print("✅ Received \(foods.count) food items:")
        for (index, food) in foods.enumerated() {
            print("   \(index + 1). \(food.name)")
            if let type = food.type {
                print("      Type: \(type)")
            }
            if let quantity = food.quantity {
                print("      Quantity: \(quantity)")
            }
        }
        
        guard let primary = pickPrimaryDish(from: foods) else {
            print("⚠️ No primary dish could be chosen")
            return
        }
        
        print("🍛 Primary dish chosen for details: \(primary.name)")
        print("============================================\n")
        
        let detailVC = DishDetailViewController()
        detailVC.configureWithDetectedFood(primary: primary,
                                           allFoods: foods,
                                           image: image)
        
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
    func cameraCaptureDidRequestRescan() {
        // Camera will handle the rescan internally via notification
        print("📷 Rescan requested")
    }
}


extension HomeDashboardViewController: MedicationPopupDelegate {
    func medicationPopupDidToggleMedication(_ medicationId: UUID, timeOfDay: TimeOfDay) {
        updateMedicationCard()
        NotificationCenter.default.post(name: NSNotification.Name("medicationsDidUpdate"), object: nil)
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
