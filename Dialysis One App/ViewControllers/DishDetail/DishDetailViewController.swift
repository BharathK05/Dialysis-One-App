//
//  DishDetailViewController.swift
//  Dialysis One App
//
//  Complete implementation with unified Quantity/Portion control
//

import UIKit

class DishDetailViewController: UIViewController {
    
    // MARK: - Portion Size Enum
    struct DisplayedNutrients {
        let calories: Int
        let protein: Double
        let potassium: Int
        let sodium: Int
        let proteinLevel: SafetyLevel
        let potassiumLevel: SafetyLevel
        let sodiumLevel: SafetyLevel
    }

    

    // MARK: - Nutrition Source
    
    private enum NutritionSource {
        case ifctDatabase      // IFCT DB / templates
        case aiEstimate        // Gemini text estimate
        case unknown
    }

    // MARK: - Public Configuration Properties

 //   var recognitionResult: FoodRecognitionResult?
    var detectedFood: DetectedFood?
    var allDetectedFoods: [DetectedFood] = []
    var foodImage: UIImage?
    private var isFromSearch: Bool = false
    // ADD AFTER LINE 31 (after var foodImage: UIImage?)
    private var classifiedFood: ClassifiedFood?
    private var baseNutrients: DishNutrients?          // Keep only ONE
    private var currentPortion: AdaptivePortionOption?
    private var portionType: PortionType = .weight

    func configureWithDetectedFood(primary: DetectedFood,
                                   allFoods: [DetectedFood],
                                   image: UIImage,
                                   presetPortion: PortionOption? = nil,
                                   fromSearch: Bool = false) {  // ✅ ADD THIS PARAMETER
        self.detectedFood = primary
        self.allDetectedFoods = allFoods
        self.foodImage = image
        self.isFromSearch = fromSearch  // ✅ NOW IT WORKS
        
        // Apply preset portion if provided
    }

    

    // MARK: - State Properties

    
    private var quantity: Double = 1.0
    
    var finalDisplayedNutrients: DisplayedNutrients?

    private var nutritionSource: NutritionSource = .unknown
    private var sideFoods: [DetectedFood] = []
    

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

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
    // MARK: - Computed Properties

    private var scaledNutrients: DisplayedNutrients? {
        return finalDisplayedNutrients
    }

    private let dishNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    private let verifyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("⚠️ Report Inaccurate Data", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        button.tintColor = .systemOrange
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

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

    private let infoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "info.circle"), for: .normal)
        button.tintColor = .secondaryLabel
        button.isHidden = true
        button.accessibilityLabel = "How we calculate this"
        return button
    }()

    private let nutrientsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fillEqually
        return stack
    }()

    // Combined Quantity & Portion Control
    // Adaptive Quantity & Portion Control
    private let adaptivePortionControl: AdaptiveQuantityPortionControl = {
        let view = AdaptiveQuantityPortionControl()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()


    private let otherFoodsTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Foods on this plate"  // CHANGED FROM "Other foods on this plate"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()

    private let otherFoodsScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.isHidden = true
        return sv
    }()

    private let otherFoodsChipStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fill
        return stack
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
        setupAdaptivePortionCallback()
        
        // 🔥 NEW FLOW
        executeNewFlow()
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(foodImageView)
        contentView.addSubview(dishNameLabel)
        contentView.addSubview(otherFoodsTitleLabel)
        contentView.addSubview(otherFoodsScrollView)
        otherFoodsScrollView.addSubview(otherFoodsChipStackView)
        contentView.addSubview(caloriesCard)

        caloriesCard.addSubview(caloriesLabel)
        caloriesCard.addSubview(caloriesValueLabel)
        caloriesCard.addSubview(infoButton)

        contentView.addSubview(nutrientsStackView)
        contentView.addSubview(adaptivePortionControl)
        contentView.addSubview(warningBanner)
        contentView.addSubview(saveButton)

        foodImageView.translatesAutoresizingMaskIntoConstraints = false
        dishNameLabel.translatesAutoresizingMaskIntoConstraints = false
        caloriesCard.translatesAutoresizingMaskIntoConstraints = false
        caloriesLabel.translatesAutoresizingMaskIntoConstraints = false
        caloriesValueLabel.translatesAutoresizingMaskIntoConstraints = false
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        nutrientsStackView.translatesAutoresizingMaskIntoConstraints = false
        otherFoodsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        otherFoodsScrollView.translatesAutoresizingMaskIntoConstraints = false
        otherFoodsChipStackView.translatesAutoresizingMaskIntoConstraints = false
        warningBanner.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false

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

            otherFoodsTitleLabel.topAnchor.constraint(equalTo: dishNameLabel.bottomAnchor, constant: 16),
            otherFoodsTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            otherFoodsTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            otherFoodsScrollView.topAnchor.constraint(equalTo: otherFoodsTitleLabel.bottomAnchor, constant: 8),
            otherFoodsScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            otherFoodsScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            otherFoodsScrollView.heightAnchor.constraint(equalToConstant: 40),

            caloriesCard.topAnchor.constraint(equalTo: otherFoodsScrollView.bottomAnchor, constant: 20),
            caloriesCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            caloriesCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            caloriesCard.heightAnchor.constraint(equalToConstant: 75),

            caloriesLabel.topAnchor.constraint(equalTo: caloriesCard.topAnchor, constant: 12),
            caloriesLabel.leadingAnchor.constraint(equalTo: caloriesCard.leadingAnchor, constant: 16),

            caloriesValueLabel.topAnchor.constraint(equalTo: caloriesLabel.bottomAnchor, constant: 4),
            caloriesValueLabel.leadingAnchor.constraint(equalTo: caloriesCard.leadingAnchor, constant: 16),

            infoButton.centerYAnchor.constraint(equalTo: caloriesValueLabel.centerYAnchor),
            infoButton.trailingAnchor.constraint(equalTo: caloriesCard.trailingAnchor, constant: -16),
            infoButton.widthAnchor.constraint(equalToConstant: 22),
            infoButton.heightAnchor.constraint(equalToConstant: 22),

            nutrientsStackView.topAnchor.constraint(equalTo: caloriesCard.bottomAnchor, constant: 16),
            nutrientsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nutrientsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            adaptivePortionControl.topAnchor.constraint(equalTo: nutrientsStackView.bottomAnchor, constant: 20),
            adaptivePortionControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            adaptivePortionControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            adaptivePortionControl.heightAnchor.constraint(equalToConstant: 100),

            warningBanner.topAnchor.constraint(equalTo: adaptivePortionControl.bottomAnchor, constant: 16),
            warningBanner.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            warningBanner.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            saveButton.topAnchor.constraint(equalTo: warningBanner.bottomAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
        
        // Separate constraint block for scroll view content
        NSLayoutConstraint.activate([
            otherFoodsChipStackView.topAnchor.constraint(equalTo: otherFoodsScrollView.topAnchor),
            otherFoodsChipStackView.bottomAnchor.constraint(equalTo: otherFoodsScrollView.bottomAnchor),
            otherFoodsChipStackView.leadingAnchor.constraint(equalTo: otherFoodsScrollView.leadingAnchor),
            otherFoodsChipStackView.trailingAnchor.constraint(equalTo: otherFoodsScrollView.trailingAnchor),
            otherFoodsChipStackView.heightAnchor.constraint(equalTo: otherFoodsScrollView.heightAnchor)
        ])

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        verifyButton.addTarget(self, action: #selector(verifyTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
    }
    
    private func setupAdaptivePortionCallback() {
        adaptivePortionControl.onValueChanged = { [weak self] quantity, portion, type in
            guard let self = self, let nutrients = self.baseNutrients else { return }
            
            self.quantity = quantity
            self.currentPortion = portion
            self.portionType = type
            
            print("\n📊 Portion changed:")
            print("   Quantity: \(quantity)")
            print("   Portion: \(portion.label)")
            print("   Type: \(type.rawValue)")
            
            self.updateNutrientsDisplay(nutrients: nutrients)
        }
    }

    // MARK: - Display Result
    
    // ADD THIS ENTIRE NEW METHOD
    private func executeNewFlow() {
        print("\n🚀 ========== EXECUTING NEW FLOW ==========")
        
        guard let detected = detectedFood else {
            showError("No food detected")
            return
        }
        
        // Display basic info immediately
        if isFromSearch {
            foodImageView.isHidden = true
            foodImageView.heightAnchor.constraint(equalToConstant: 0).isActive = true  // Collapse it
        } else {
            foodImageView.image = foodImage
            foodImageView.isHidden = false
        }
        
        dishNameLabel.text = detected.name
        updateAllFoodsDisplay()
        showLoadingState()
        
        Task {
            await processFood()
        }
    }

    private func processFood() async {
        guard let detected = detectedFood else { return }
        
        // STEP 1: CLASSIFY (get canonical name + portion type)
        print("\n📍 STEP 1: Classify with Gemini")
        
        guard let classifications = await FoodPortionClassifier.shared.classifyFoods(
            from: [detected]
        ), let classified = classifications.first else {
            await MainActor.run {
                showError("Failed to classify food")
            }
            return
        }
        
        await MainActor.run {
            self.classifiedFood = classified
            self.portionType = classified.portion_type
            
            // Update UI with canonical name
            dishNameLabel.text = classified.canonical_food_name
            
            print("   ✅ Classified as: \(classified.canonical_food_name)")
            print("   ✅ Portion type: \(classified.portion_type.rawValue)")
        }
        
        // STEP 2: GET NUTRITION (DB → Calculate → Save)
        print("\n📍 STEP 2: Get Nutrition (DB → Calculate → Save)")
        
        guard let nutrients = await NutritionCacheManager.shared.getNutrition(
            for: classified
        ) else {
            await MainActor.run {
                showError("Failed to get nutrition data")
            }
            return
        }
        
        await MainActor.run {
            self.baseNutrients = nutrients
            
            print("   ✅ Nutrition obtained")
            print("   ✅ Calories: \(Int(nutrients.calories)) per 100g")
        }
        
        // STEP 3: CONFIGURE UI (portion type determines UI)
        print("\n📍 STEP 3: Configure Adaptive UI")
        
        await MainActor.run {
            // Configure adaptive portion control
            adaptivePortionControl.configure(
                for: classified.portion_type,
                defaultQuantity: classified.default_portion_value
            )
            
            self.quantity = classified.default_portion_value
            
            print("   ✅ UI configured for: \(classified.portion_type.rawValue)")
            print("   ✅ Default quantity: \(classified.default_portion_value)")
            
            // Calculate and display nutrients
            updateNutrientsDisplay(nutrients: nutrients)
            
            hideLoadingState()
            saveButton.isEnabled = true
            saveButton.alpha = 1.0
        }
        
        print("✅ ========== FLOW COMPLETE ==========\n")
    }
    

//    private func displayResult() {
//        foodImageView.image = foodImage
//
//        // Old flow (ResNet + Nutrition DB)
//        
//
//        // Gemini flow
//        guard let detected = detectedFood else {
//            dishNameLabel.text = "Unknown dish"
//            showNoNutrientsMessage()
//            return
//        }
//        
//        dishNameLabel.text = detected.name
//        updateSideFoodsFromDetectedList()
//
//        // 🔥 NEW: Check if this is a COMPOSITE MEAL
//        let isCompositeMeal = allDetectedFoods.count > 1 &&
//                             isCompositeIndianMeal(allDetectedFoods)
//        
//        if isCompositeMeal {
//            quantityPortionCard.lockToPlateOnly()
//            print("🍽️ COMPOSITE MEAL DETECTED - Calculating total nutrients for all items")
//            showEstimatingMessage()
//            
//            Task { [weak self] in
//                guard let self = self else { return }
//                
//                // Calculate nutrients for ALL items
//                if let composite = await CompositeMealNutrientCalculator.shared.calculateCompositeNutrients(
//                    mealName: detected.name,
//                    detectedFoods: self.allDetectedFoods
//                ) {
//                    await MainActor.run {
//                        print("✅ Composite nutrients calculated successfully")
//                        self.baseNutrients = composite.totalNutrients
//                        self.nutritionSource = .ifctDatabase
//                        self.updateNutrientsDisplay(nutrients: composite.totalNutrients)
//                        self.saveButton.isEnabled = true
//                        self.saveButton.alpha = 1.0
//                        
//                        // Show breakdown if needed
//                        self.showCompositeBreakdown(composite)
//                    }
//                } else {
//                    await MainActor.run {
//                        print("⚠️ Could not calculate composite nutrients")
//                        self.showNoNutrientsMessage()
//                    }
//                }
//            }
//            return
//        }
//        
//        // 🔥 SINGLE ITEM FLOW (not composite)
//        print("📍 SINGLE ITEM - Calculating nutrients for: \(detected.name)")
//        
//        // Smart portion detection from quantity hint
//        if let quantityHint = detected.quantity?.lowercased() {
//            var detectedPortion: PortionOption?
//            
//            if quantityHint.contains("katori") {
//                detectedPortion = PortionLibrary.portion(byId: "katori")
//            } else if quantityHint.contains("½") || quantityHint.contains("half") {
//                detectedPortion = PortionLibrary.portion(byId: "small_bowl")
//            } else if quantityHint.contains("1 plate") || quantityHint.contains("one plate") {
//                detectedPortion = PortionLibrary.portion(byId: "bowl")
//            } else if quantityHint.contains("2 plates") || quantityHint.contains("two plates") || quantityHint.contains("large") {
//                detectedPortion = PortionLibrary.portion(byId: "bowl")
//                quantity = 2.0
//            } else if quantityHint.contains("cup") {
//                detectedPortion = PortionLibrary.portion(byId: "cup")
//            } else if quantityHint.contains("glass") {
//                detectedPortion = PortionLibrary.portion(byId: "glass")
//            }
//            
//            // Apply detected portion
//            if let portion = detectedPortion {
//                selectedPortionOption = portion
//                quantityPortionCard.setPortion(portion)
//                if quantityHint.contains("2 plates") || quantityHint.contains("two plates") {
//                    quantityPortionCard.setQuantity(2.0)
//                }
//            }
//        }
//
//        // Try template / IFCT DB first
//        if let nutrients = DishTemplateManager.shared.nutrients(forDetectedName: detected.name) {
//            print("✅ Found nutrition for INDIVIDUAL item: \(detected.name)")
//            baseNutrients = nutrients
//            nutritionSource = .ifctDatabase
//            updateNutrientsDisplay(nutrients: nutrients)
//            saveButton.isEnabled = true
//            saveButton.alpha = 1.0
//            return
//        }
//
//        // If not in database, use LLM to estimate THIS SPECIFIC FOOD'S nutrition
//        print("⚠️ No DB nutrition for \(detected.name). Using LLM for INDIVIDUAL item...")
//        showEstimatingMessage()
//
//        Task { [weak self] in
//            guard let self = self else { return }
//            
//            // CRITICAL: Estimate nutrition for THIS SPECIFIC FOOD ITEM
//            let estimate = await LLMNutritionService.shared.estimateNutrients(
//                forDishName: detected.name,
//                categoryHint: detected.type,
//                quantityHint: nil
//            )
//            
//            await MainActor.run {
//                guard let estimate = estimate else {
//                    print("⚠️ LLM could not estimate nutrients for \(detected.name)")
//                    self.showNoNutrientsMessage()
//                    return
//                }
//                
//                print("✅ LLM estimate for INDIVIDUAL item: \(detected.name)")
//                self.baseNutrients = estimate
//                self.nutritionSource = .aiEstimate
//                self.updateNutrientsDisplay(nutrients: estimate)
//                self.saveButton.isEnabled = true
//                self.saveButton.alpha = 1.0
//            }
//        }
//    }
    private func showCompositeBreakdown(_ composite: CompositeMealNutrients) {
        print("\n📊 COMPOSITE MEAL BREAKDOWN:")
        print("   Total items: \(composite.itemBreakdown.count)")
        
        for (index, item) in composite.itemBreakdown.enumerated() {
            print("   \(index + 1). \(item.food.name): \(Int(item.nutrients.calories)) kcal")
        }
        
        if !composite.failedItems.isEmpty {
            print("   ⚠️ Failed items: \(composite.failedItems.joined(separator: ", "))")
        }
        
        print("   ➕ TOTAL: \(Int(composite.totalNutrients.calories)) kcal")
        print("============================================\n")
    }
    
    // MARK: - Nutrients Display

    private func updateNutrientsDisplay(nutrients: DishNutrients) {
        guard let portion = currentPortion else { return }
        
        // Calculate total grams based on portion type
        let totalGrams: Double
        
        switch portionType {
        case .weight:
            // For WEIGHT: quantity is in grams or oz
            totalGrams = quantity * portion.baseGrams
            
        case .count:
            // For COUNT: look up grams per piece dynamically
            Task {
                if let gramsPerPiece = await PortionWeightsDatabase.shared.getGramsPerPiece(
                    for: classifiedFood?.canonical_food_name ?? ""
                ) {
                    await MainActor.run {
                        let total = quantity * gramsPerPiece
                        self.scaleAndDisplayNutrients(nutrients: nutrients, totalGrams: total)
                    }
                } else {
                    // Fallback if lookup fails
                    await MainActor.run {
                        let total = quantity * 50.0 // Conservative estimate
                        self.scaleAndDisplayNutrients(nutrients: nutrients, totalGrams: total)
                    }
                }
            }
            return // Exit here since we're async
            
        case .bowl:
            // For BOWL: portion.baseGrams is bowl size
            totalGrams = quantity * portion.baseGrams
            
        case .meal:
            // For MEAL: estimate full plate (e.g., 400g)
            totalGrams = 400.0
        }
        
        print("   📏 Total grams: \(totalGrams)")
        
        scaleAndDisplayNutrients(nutrients: nutrients, totalGrams: totalGrams)
    }

    // NEW helper method
    private func scaleAndDisplayNutrients(nutrients: DishNutrients, totalGrams: Double) {
        // Scale nutrients from per 100g to actual serving
        let multiplier = totalGrams / 100.0
        
        let calories = Int(nutrients.calories * multiplier)
        let protein = nutrients.protein * multiplier
        let potassium = Int(nutrients.potassium * multiplier)
        let sodium = Int(nutrients.sodium * multiplier)
        
        // Update UI
        caloriesValueLabel.text = "\(calories) kcal"
        
        updateNutrientCards(
            potassium: potassium,
            sodium: sodium,
            protein: Int(protein)
        )
        
        print("   📊 Scaled calories: \(calories) kcal")
    }


    private func updateNutrientCards(
        potassium: Int,
        sodium: Int,
        protein: Int
    ) {
        nutrientsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let proteinLimit = LimitsDiet.shared.getProteinLimit()
        let potassiumLimit = LimitsDiet.shared.getPotassiumLimit()
        let sodiumLimit = LimitsDiet.shared.getSodiumLimit()

        let proteinLevel: SafetyLevel = protein > proteinLimit ? .high : .low
        let potassiumLevel: SafetyLevel = potassium > potassiumLimit ? .high : .low
        let sodiumLevel: SafetyLevel = sodium > sodiumLimit ? .high : .low

        nutrientsStackView.addArrangedSubview(
            createNutrientRow(
                title: "Protein",
                value: "\(protein) g",
                color: .systemYellow,
                level: proteinLevel
            )
        )

        nutrientsStackView.addArrangedSubview(
            createNutrientRow(
                title: "Potassium",
                value: "\(potassium) mg",
                color: .systemGreen,
                level: potassiumLevel
            )
        )

        nutrientsStackView.addArrangedSubview(
            createNutrientRow(
                title: "Sodium",
                value: "\(sodium) mg",
                color: .systemOrange,
                level: sodiumLevel
            )
        )

        // ✅ FIXED: Get calories from the already-updated label
        let caloriesText = caloriesValueLabel.text?.replacingOccurrences(of: " kcal", with: "") ?? "0"
        let calories = Int(caloriesText) ?? 0

        // Store final nutrients
        finalDisplayedNutrients = DisplayedNutrients(
            calories: calories,
            protein: Double(protein),
            potassium: potassium,
            sodium: sodium,
            proteinLevel: proteinLevel,
            potassiumLevel: potassiumLevel,
            sodiumLevel: sodiumLevel
        )

        updateWarningBanner(
            calories: calories,
            protein: protein,
            potassium: potassium,
            sodium: sodium
        )
    }




    private func createNutrientRow(
        title: String,
        value: String,
        color: UIColor,
        level: SafetyLevel
    ) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 6
        dot.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

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

    private func updateWarningBanner(calories: Int, protein: Int, potassium: Int, sodium: Int) {
        warningBanner.subviews.forEach { $0.removeFromSuperview() }

        let proteinLimit = LimitsDiet.shared.getProteinLimit()
        let potassiumLimit = LimitsDiet.shared.getPotassiumLimit()
        let sodiumLimit = LimitsDiet.shared.getSodiumLimit()
        
        let hasHighProtein = protein > proteinLimit
        let hasHighPotassium = potassium > potassiumLimit
        let hasHighSodium = sodium > sodiumLimit
        
        let hasHighLevels = hasHighProtein || hasHighPotassium || hasHighSodium

        warningBanner.isHidden = !hasHighLevels

        guard hasHighLevels else { return }

        let warningLabel = UILabel()
        warningLabel.text = "⚠️ High CKD concern – please discuss with your dietitian."
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
    
    // MARK: - Composite Meal Detection

    private func isCompositeIndianMeal(_ foods: [DetectedFood]) -> Bool {
        // Check if we have multiple items that form a typical Indian meal
        let foodNames = foods.map { $0.name.lowercased() }
        
        // Common combinations that indicate a composite meal
        let hasRiceOrRoti = foodNames.contains(where: { $0.contains("rice") || $0.contains("roti") || $0.contains("chapati") })
        let hasCurryOrDal = foodNames.contains(where: { $0.contains("dal") || $0.contains("curry") || $0.contains("sabzi") })
        
        return hasRiceOrRoti && hasCurryOrDal
    }
    
    // ADD THESE NEW METHODS
    private func showLoadingState() {
        caloriesValueLabel.text = "..."
        saveButton.isEnabled = false
        saveButton.alpha = 0.5
    }

    private func hideLoadingState() {
        // Loading complete - UI will be updated by updateNutrientsDisplay
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Side Foods
    


    
    private func updateAllFoodsDisplay() {
        guard !allDetectedFoods.isEmpty else {
            otherFoodsTitleLabel.isHidden = true
            otherFoodsScrollView.isHidden = true
            return
        }

        // Clear existing chips
        otherFoodsChipStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Show ALL detected foods (including main dish)
        otherFoodsTitleLabel.isHidden = false
        otherFoodsScrollView.isHidden = false

        for (index, food) in allDetectedFoods.enumerated() {
            let chip = makeFoodChip(
                for: food,
                isMainDish: food.name == detectedFood?.name
            )
            chip.tag = index
            let tap = UITapGestureRecognizer(target: self, action: #selector(foodChipTapped(_:)))
            chip.addGestureRecognizer(tap)
            otherFoodsChipStackView.addArrangedSubview(chip)
        }
    }


    private func makeFoodChip(for food: DetectedFood, isMainDish: Bool) -> UIView {
        let container = UIView()
        container.backgroundColor = isMainDish ? UIColor.systemGreen.withAlphaComponent(0.15) : UIColor.systemGray6
        container.layer.cornerRadius = 18
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isUserInteractionEnabled = true
        
        // Add subtle border for main dish
        if isMainDish {
            container.layer.borderWidth = 1.5
            container.layer.borderColor = UIColor.systemGreen.cgColor
        }
        
        let dot = UIView()
        dot.backgroundColor = isMainDish ? .systemGreen : .systemGray
        dot.layer.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 14, weight: isMainDish ? .semibold : .medium)
        nameLabel.textColor = .label
        nameLabel.text = food.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.setContentHuggingPriority(.required, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // Show serving info (like "1 serving")
        let servingLabel = UILabel()
        servingLabel.font = .systemFont(ofSize: 12, weight: .regular)
        servingLabel.textColor = .secondaryLabel
        servingLabel.text = "1 serving" // You can make this dynamic based on quantity
        servingLabel.translatesAutoresizingMaskIntoConstraints = false
        servingLabel.setContentHuggingPriority(.required, for: .horizontal)
        servingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let hStack = UIStackView(arrangedSubviews: [dot, nameLabel, servingLabel])
        hStack.axis = .horizontal
        hStack.spacing = 6
        hStack.alignment = .center
        hStack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(hStack)
        
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            
            dot.widthAnchor.constraint(equalToConstant: 8),
            dot.heightAnchor.constraint(equalToConstant: 8),
            
            container.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        return container
    }

    @objc private func foodChipTapped(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else { return }
        let selectedFood = allDetectedFoods[index]
        
        // If tapping the current main dish, don't navigate
        if selectedFood.name == detectedFood?.name {
            print("👆 Already viewing this dish")
            return
        }

        let vc = DishDetailViewController()
        vc.configureWithDetectedFood(
            primary: selectedFood,
            allFoods: allDetectedFoods,
            image: foodImage ?? UIImage()
        )

        navigationController?.pushViewController(vc, animated: true)
    }
    // MARK: - Empty States

    private func showEstimatingMessage() {
        nutrientsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let messageLabel = UILabel()
        messageLabel.text = "Estimating nutrition using AI…"
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textColor = .systemGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        nutrientsStackView.addArrangedSubview(messageLabel)

        caloriesValueLabel.text = "–"
        nutritionSource = .unknown
        infoButton.isHidden = true
        saveButton.isEnabled = false
        saveButton.alpha = 0.5
    }

    private func showNoNutrientsMessage() {
        nutrientsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let messageLabel = UILabel()
        messageLabel.text = "⚠️ Nutritional information not available for this dish."
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textColor = .systemGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        nutrientsStackView.addArrangedSubview(messageLabel)

        caloriesValueLabel.text = "–"
        nutritionSource = .unknown
        infoButton.isHidden = true
        saveButton.isEnabled = false
        saveButton.alpha = 0.5
    }

    // MARK: - Actions

    @objc private func sideFoodChipTapped(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else { return }
        let selectedFood = sideFoods[index]

        let vc = DishDetailViewController()
        vc.configureWithDetectedFood(
            primary: selectedFood,
            allFoods: allDetectedFoods,
            image: foodImage ?? UIImage()
        )

        navigationController?.pushViewController(vc, animated: true)
    }

    
    @objc private func verifyTapped() {
        let alert = UIAlertController(
            title: "Report Issue",
            message: "Help us improve! What's wrong with this data?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Calories seem wrong", style: .default) { _ in
            self.reportIssue(type: "calories")
        })
        
        alert.addAction(UIAlertAction(title: "Nutrients seem wrong", style: .default) { _ in
            self.reportIssue(type: "nutrients")
        })
        
        alert.addAction(UIAlertAction(title: "Wrong dish detected", style: .default) { _ in
            self.reportIssue(type: "dish_name")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }

    @objc private func closeTapped() {
        print("🔙 Close button tapped from Detail View")
        view.endEditing(true)
        
        // IMPORTANT: Dismiss ALL the way back to home
        if let nav = navigationController {
            // Check if we're in a modal presentation
            if let presentingVC = nav.presentingViewController {
                print("   Dismissing modal navigation completely")
                presentingVC.dismiss(animated: true, completion: nil)
            } else if let tabBar = nav.tabBarController {
                print("   Found tab bar - selecting home and popping")
                tabBar.selectedIndex = 0
                if let homeNav = tabBar.selectedViewController as? UINavigationController {
                    homeNav.popToRootViewController(animated: false)
                }
            } else {
                print("   Popping to root")
                nav.popToRootViewController(animated: true)
            }
        } else {
            print("   Direct dismiss")
            dismiss(animated: true, completion: nil)
        }
    }

    @objc private func infoButtonTapped() {
        let title = "How we calculate this"

        let message: String
        switch nutritionSource {
        case .ifctDatabase:
            message = """
            • Food composition from Indian Food Composition Tables (IFCT 2017) and similar renal-nutrition data.
            
            • Values are per 100 g of edible portion and then scaled to your selected quantity.
            
            • CKD safety levels are aligned with standard nephrology guidelines (e.g. KDIGO) and reviewed with renal-dietitian input.
            
            • Your daily limits in the app are personalised using your saved health details (stage, weight, etc.), but this is not a substitute for your own doctor's advice.
            """
        case .aiEstimate:
            message = """
            • This dish was not available in our IFCT database, so values are an AI-assisted estimate using Gemini.
            
            • Gemini is instructed to use IFCT-style Indian food tables and to be conservative for CKD – we prefer to slightly over-estimate potassium/sodium instead of under-estimating.
            
            • Safety tags (low / moderate / high) are only guidance. Please confirm with your nephrologist or dietitian before making changes to your diet.
            """
        case .unknown:
            message = """
            We couldn't link this dish to a trusted nutrition source yet.
            
            You can still log it for your diary, but the CKD safety view will be limited. Please check with your dietitian for exact limits.
            """
        }

        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = alert.popoverPresentationController {
            pop.sourceView = infoButton
            pop.sourceRect = infoButton.bounds
        }

        present(alert, animated: true)
    }

    @objc private func saveButtonTapped() {
        guard let scaled = scaledNutrients else {
            print("⚠️ No nutrients to save")
            return
        }

        let alert = UIAlertController(
            title: "Select Meal Type",
            message: "When did you have this meal?",
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "Breakfast", style: .default) { [weak self] _ in
            self?.saveMealAndReturn(mealType: .breakfast)
        })

        alert.addAction(UIAlertAction(title: "Lunch", style: .default) { [weak self] _ in
            self?.saveMealAndReturn(mealType: .lunch)
        })

        alert.addAction(UIAlertAction(title: "Dinner", style: .default) { [weak self] _ in
            self?.saveMealAndReturn(mealType: .dinner)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = alert.popoverPresentationController {
            pop.sourceView = saveButton
            pop.sourceRect = saveButton.bounds
        }

        present(alert, animated: true)
    }

    // MARK: - Save Flow

    private func saveMealAndReturn(mealType: SavedMeal.MealType) {
        guard let classified = classifiedFood,
              let nutrients = baseNutrients,
              let portion = currentPortion else {
            showError("Cannot save - missing nutrition data")
            return
        }
        
        // Calculate final nutrients with current portion
        let totalGrams: Double
        switch portionType {
        case .weight:
            totalGrams = quantity * portion.baseGrams
        case .count:
            // Use cached value if available, else conservative estimate
            totalGrams = quantity * 50.0 // Will be replaced by proper lookup
        case .bowl:
            totalGrams = quantity * portion.baseGrams
        case .meal:
            totalGrams = 400.0
        }
        
        let multiplier = totalGrams / 100.0
        
        let finalCalories = Int(nutrients.calories * multiplier)
        let finalProtein = nutrients.protein * multiplier
        let finalPotassium = Int(nutrients.potassium * multiplier)
        let finalSodium = Int(nutrients.sodium * multiplier)
        
        print("\n💾 Saving meal:")
        print("   Dish: \(classified.canonical_food_name)")
        print("   Portion: \(quantity) \(portion.label)")
        print("   Calories: \(finalCalories)")
        
        // Save to local storage
        MealDataManager.shared.saveMeal(
            dishName: classified.canonical_food_name,
            calories: finalCalories,
            potassium: finalPotassium,
            sodium: finalSodium,
            protein: finalProtein,
            quantity: Int(quantity),
            mealType: mealType,
            image: foodImage
        )
        
        // Sync to Supabase
        let source = NutritionCacheManager.shared.getSource(
            for: classified.canonical_food_name
        ) ?? "unknown"
        
        syncToSupabase(
            dishName: classified.canonical_food_name,
            calories: finalCalories,
            potassium: finalPotassium,
            sodium: finalSodium,
            protein: finalProtein,
            quantity: Int(quantity),
            mealType: mealType,
            source: source
        )
        
        showSuccessBannerAndReturn(mealType: mealType)
    }

    // NEW helper method for Supabase sync
    private func syncToSupabase(
        dishName: String,
        calories: Int,
        potassium: Int,
        sodium: Int,
        protein: Double,
        quantity: Int,
        mealType: SavedMeal.MealType,
        source: String
    ) {
        guard let userId = FirebaseAuthManager.shared.getUserID() else { return }
        
        let meal = SavedMeal(
            id: UUID(),
            dishName: dishName,
            calories: calories,
            potassium: potassium,
            sodium: sodium,
            protein: protein,
            quantity: quantity,
            mealType: mealType,
            timestamp: Date(),
            imageData: foodImage?.jpegData(compressionQuality: 0.7)
        )
        
        let ckdStage = UserDefaults.standard
            .dictionary(forKey: "EditHealthDetailsLocal_v1")?["ckdStage"] as? String
        
        let record = MealRecord(
            from: meal,
            userId: userId,
            source: source,
            ckdStage: ckdStage
        )
        
        SupabaseService.shared.logMealInBackground(record)
    }

    private func showSuccessBannerAndReturn(mealType: SavedMeal.MealType) {
        let banner = UIView()
        banner.backgroundColor = UIColor.systemGreen
        banner.layer.cornerRadius = 12
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.alpha = 0
        
        let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmark.tintColor = .white
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Meal saved successfully!"
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        banner.addSubview(checkmark)
        banner.addSubview(label)
        view.addSubview(banner)
        
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            banner.heightAnchor.constraint(equalToConstant: 60),
            
            checkmark.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 16),
            checkmark.centerYAnchor.constraint(equalTo: banner.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 28),
            checkmark.heightAnchor.constraint(equalToConstant: 28),
            
            label.leadingAnchor.constraint(equalTo: checkmark.trailingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: banner.centerYAnchor),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -16)
        ])
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            banner.alpha = 1
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        print("✅ Meal saved - navigating back to home in 1.2s")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.3) {
                banner.alpha = 0
            } completion: { _ in
                banner.removeFromSuperview()
            }
            
            self.navigateToHome()
        }
    }
    
    

    // MARK: - Supabase Sync
    
    private func syncMealToSupabase(_ savedMeal: SavedMeal) {
        guard let userId = FirebaseAuthManager.shared.getUserID() else {
            print("⚠️ No user ID - skipping Supabase sync")
            return
        }
        
        let source: String
        switch nutritionSource {
        case .ifctDatabase:
            source = "ifct_db"
        case .aiEstimate:
            source = "ai_estimate"
        case .unknown:
            source = "unknown"
        }
        
        let ckdStage = UserDefaults.standard
            .dictionary(forKey: "EditHealthDetailsLocal_v1")?["ckdStage"] as? String
        
        let record = MealRecord(
            from: savedMeal,
            userId: userId,
            source: source,
            ckdStage: ckdStage
        )
        
        SupabaseService.shared.logMealInBackground(record)
        
        trackDishFrequency(dishName: savedMeal.dishName, userId: userId)
    }
    
    private func trackDishFrequency(dishName: String, userId: String) {
        Task {
            do {
                try await FoodSearchService.shared.incrementDishFrequency(
                    dishName: dishName,
                    userId: userId
                )
                print("✅ Tracked frequency for: \(dishName)")
            } catch {
                print("⚠️ Failed to track dish frequency: \(error.localizedDescription)")
                // Don't block the save flow if tracking fails
            }
        }
    }

    
    private func reportIssue(type: String) {
        Task {
            let report: [String: Any] = [
                "user_id": FirebaseAuthManager.shared.getUserID() ?? "guest",
                "dish_name": detectedFood?.name ?? "unknown",
                "issue_type": type,
                "source": nutritionSource == .aiEstimate ? "ai_estimate" : "database",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            
            print("📝 Issue reported: \(report)")
        }
        
        let thankYou = UIAlertController(
            title: "Thank you!",
            message: "Your feedback helps us improve accuracy.",
            preferredStyle: .alert
        )
        thankYou.addAction(UIAlertAction(title: "OK", style: .default))
        present(thankYou, animated: true)
    }
    private func navigateToHome() {
        print("🏠 Navigating to home dashboard")
        
        if let nav = navigationController {
            print("   Has navigation controller")
            
            // Check if we're in a tab bar
            if let tabBar = nav.tabBarController {
                print("   Found tab bar - dismissing and selecting home")
                nav.dismiss(animated: true) {
                    tabBar.selectedIndex = 0
                    if let homeNav = tabBar.selectedViewController as? UINavigationController {
                        homeNav.popToRootViewController(animated: false)
                    }
                }
            } else if let presentingNav = nav.presentingViewController as? UINavigationController {
                print("   Inside presented modal nav - dismissing to presenting nav")
                nav.dismiss(animated: true) {
                    presentingNav.popToRootViewController(animated: false)
                }
            } else if nav.presentingViewController != nil {
                print("   Modal nav - dismissing")
                nav.dismiss(animated: true)
            } else {
                print("   Regular nav - popping to root")
                nav.popToRootViewController(animated: true)
            }
        } else if let presentingVC = presentingViewController {
            print("   Directly presented - dismissing")
            presentingVC.dismiss(animated: true)
        } else {
            print("   ⚠️ No navigation context - trying window root")
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                
                if let tabBar = rootVC as? UITabBarController {
                    print("   Found tab bar - selecting home tab")
                    tabBar.selectedIndex = 0
                    if let homeNav = tabBar.selectedViewController as? UINavigationController {
                        homeNav.popToRootViewController(animated: true)
                    }
                } else if let nav = rootVC as? UINavigationController {
                    print("   Found nav - popping to root")
                    nav.popToRootViewController(animated: true)
                }
            }
        }
    }

}
