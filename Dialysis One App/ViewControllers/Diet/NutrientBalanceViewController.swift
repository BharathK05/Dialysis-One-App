import UIKit

final class NutrientBalanceViewController: UIViewController {

    // MARK: - Constants
    private enum Spacing {
        static let topNav: CGFloat = 12
        static let dateToGauge: CGFloat = 24
        static let gaugeToNutrients: CGFloat = 36
        static let nutrientsToSegment: CGFloat = 28
        static let segmentToCard: CGFloat = 22
        static let contentCardPadding: CGFloat = 20
    }

    // MARK: - Data
    private var selectedMealType: SavedMeal.MealType = .lunch
    private var meals: [SavedMeal] = []
    private var isEditMode: Bool = false
    
    private let metricsContainer = MetricsContainerView()

    
    // Goals - now dynamic!
    private var calorieGoal: Int {
        return LimitsManager.shared.getCalorieLimit()
    }
    private var potassiumGoal: Int {
        return LimitsManager.shared.getPotassiumLimit()
    }
    private var sodiumGoal: Int {
        return LimitsManager.shared.getSodiumLimit()
    }
    private var proteinGoal: Int {
        return LimitsManager.shared.getProteinLimit()
    }

    // MARK: - Views
    private let gradientView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let backButton: UIButton = {
        let b = UIButton(type: .system)

        let config = UIImage.SymbolConfiguration(
            pointSize: 17,
            weight: .semibold
        )

        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        b.setImage(image, for: .normal)

        b.tintColor = .black
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Nutrient Balance"
        l.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        return l
    }()
    
    private let editButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Edit", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        b.tintColor = .systemBlue
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let datePill: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        l.backgroundColor = UIColor(white: 1.0, alpha: 0.4)
        l.layer.cornerRadius = 16
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

//    private let gaugeView = HorseshoeGaugeView()
    
//    private let nutrientsStack: UIStackView = {
//        let s = UIStackView()
//        s.axis = .horizontal
//        s.distribution = .fillEqually
//        s.alignment = .center
//        s.spacing = 12
//        s.translatesAutoresizingMaskIntoConstraints = false
//        return s
//    }()

    private let mealsSegmented: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Breakfast","Lunch","Dinner"])
        sc.selectedSegmentIndex = 1
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.backgroundColor = UIColor(white: 1.0, alpha: 0.3)
        sc.selectedSegmentTintColor = .white
        sc.setTitleTextAttributes([.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)], for: .selected)
        sc.setTitleTextAttributes([.foregroundColor: UIColor.black.withAlphaComponent(0.7), .font: UIFont.systemFont(ofSize: 14, weight: .regular)], for: .normal)
        sc.layer.cornerRadius = 18
        sc.clipsToBounds = true
        return sc
    }()

    private let contentCard: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        v.layer.cornerRadius = 18
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.06
        v.layer.shadowOffset = CGSize(width: 0, height: 6)
        v.layer.shadowRadius = 12
        return v
    }()

    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 14
        s.alignment = .fill
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    private let emptyStateLabel: UILabel = {
        let l = UILabel()
        l.text = "No meals logged yet.\nStart by scanning your food!"
        l.textAlignment = .center
        l.numberOfLines = 0
        l.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        l.textColor = .darkGray
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isHidden = true
        return l
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureNavigationBar()
        setupLayout()
        
        // Set today's date
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        datePill.text = formatter.string(from: Date())
        
        loadMealData()
        
        // Listen for meal updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loadMealData),
            name: .mealsDidUpdate,
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func editButtonTapped() {
        isEditMode.toggle()
        
        // Update button title with animation
        UIView.transition(with: editButton, duration: 0.2, options: .transitionCrossDissolve) {
            self.editButton.setTitle(self.isEditMode ? "Done" : "Edit", for: .normal)
        }
        
        // Reload the meal rows with delete buttons
        populateContentRows()
        
        print("✏️ Edit mode: \(isEditMode)")
    }
    
    @objc private func segmentChanged() {
        // Exit edit mode when switching segments
        if isEditMode {
            isEditMode = false
            editButton.setTitle("Edit", for: .normal)
        }
        
        switch mealsSegmented.selectedSegmentIndex {
        case 0: selectedMealType = .breakfast
        case 1: selectedMealType = .lunch
        case 2: selectedMealType = .dinner
        default: selectedMealType = .lunch
        }
        loadMealData()
    }
    
    @objc private func loadMealData() {
        // Get today's totals for gauge and nutrient cards
        let totals = MealDataManager.shared.getTodayTotals()
        
        metricsContainer.update(
            calories: totals.calories,
            calorieGoal: calorieGoal,
            potassium: totals.potassium,
            sodium: totals.sodium,
            protein: totals.protein
        )

        
        // Update gauge
//        gaugeView.maxValue = CGFloat(calorieGoal)
//        gaugeView.currentValue = CGFloat(totals.calories)
        
        // Update nutrient cards
//        updateNutrientCards(
//            potassium: totals.potassium,
//            sodium: totals.sodium,
//            protein: totals.protein
//        )
        
        // Get meals for selected meal type
        meals = MealDataManager.shared.getMeals(for: selectedMealType)
        
        // Update content card
        populateContentRows()
    }
    
    @objc private func limitsDidUpdate() {
        // Reload everything with new limits
        loadMealData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setGradient()
    }

    // MARK: - Setup
    private func configureNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupLayout() {
        view.addSubview(gradientView)
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Add all nav bar elements
        gradientView.addSubview(backButton)
        gradientView.addSubview(titleLabel)
        gradientView.addSubview(editButton)
        
        // Setup targets
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        mealsSegmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: gradientView.safeAreaLayoutGuide.topAnchor, constant: Spacing.topNav),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            
            editButton.trailingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: -16),
            editButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            editButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        gradientView.addSubview(datePill)
        NSLayoutConstraint.activate([
            datePill.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            datePill.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            datePill.heightAnchor.constraint(equalToConstant: 34),
            datePill.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
        
        gradientView.addSubview(metricsContainer)
        metricsContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            metricsContainer.topAnchor.constraint(equalTo: datePill.bottomAnchor, constant: Spacing.dateToGauge),
            metricsContainer.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor),
            metricsContainer.trailingAnchor.constraint(equalTo: gradientView.trailingAnchor),
            metricsContainer.heightAnchor.constraint(equalToConstant: 340)
        ])


//        gradientView.addSubview(gaugeView)
//        gaugeView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            gaugeView.topAnchor.constraint(equalTo: datePill.bottomAnchor, constant: Spacing.dateToGauge),
//            gaugeView.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
//            gaugeView.widthAnchor.constraint(equalToConstant: 300),
//            gaugeView.heightAnchor.constraint(equalToConstant: 160)
//        ])

//        gradientView.addSubview(nutrientsStack)
//        NSLayoutConstraint.activate([
//            nutrientsStack.topAnchor.constraint(equalTo: gaugeView.bottomAnchor, constant: Spacing.gaugeToNutrients),
//            nutrientsStack.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 18),
//            nutrientsStack.trailingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: -18),
//            nutrientsStack.heightAnchor.constraint(equalToConstant: 72)
//        ])

        gradientView.addSubview(mealsSegmented)
        NSLayoutConstraint.activate([
//            mealsSegmented.topAnchor.constraint(equalTo: nutrientsStack.bottomAnchor, constant: Spacing.nutrientsToSegment),
            mealsSegmented.topAnchor.constraint(equalTo: metricsContainer.bottomAnchor, constant: Spacing.nutrientsToSegment),
            mealsSegmented.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            mealsSegmented.widthAnchor.constraint(equalTo: gradientView.widthAnchor, multiplier: 0.86),
            mealsSegmented.heightAnchor.constraint(equalToConstant: 40)
        ])

        gradientView.addSubview(contentCard)
        NSLayoutConstraint.activate([
            contentCard.topAnchor.constraint(equalTo: mealsSegmented.bottomAnchor, constant: Spacing.segmentToCard),
            contentCard.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 18),
            contentCard.trailingAnchor.constraint(equalTo: gradientView.trailingAnchor, constant: -18),
            contentCard.bottomAnchor.constraint(equalTo: gradientView.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])

        contentCard.addSubview(contentStack)
        contentCard.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: contentCard.topAnchor, constant: Spacing.contentCardPadding),
            contentStack.leadingAnchor.constraint(equalTo: contentCard.leadingAnchor, constant: Spacing.contentCardPadding),
            contentStack.trailingAnchor.constraint(equalTo: contentCard.trailingAnchor, constant: -Spacing.contentCardPadding),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: contentCard.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: contentCard.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: contentCard.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: contentCard.trailingAnchor, constant: -40)
        ])
        
//        populateNutrientCards()
    }

    private func setGradient() {
        guard gradientView.layer.sublayers?.first(where: { $0.name == "bgGradient" }) == nil else { return }
        let g = CAGradientLayer()
        g.name = "bgGradient"
        g.frame = gradientView.bounds
        g.colors = [
            UIColor(red: 200/255, green: 240/255, blue: 210/255, alpha: 1).cgColor,
            UIColor(red: 235/255, green: 250/255, blue: 245/255, alpha: 1).cgColor
        ]
        g.startPoint = CGPoint(x: 0.5, y: 0)
        g.endPoint = CGPoint(x: 0.5, y: 1)
        gradientView.layer.insertSublayer(g, at: 0)
    }

    // MARK: - Populate Components
//    private func populateNutrientCards() {
//        let potassium = nutrientCard(title: "Potassium", value: "0/\(potassiumGoal)mg", color: UIColor.systemGreen)
//        let sodium = nutrientCard(title: "Sodium", value: "0/\(sodiumGoal)mg", color: UIColor.systemOrange)
//        let protein = nutrientCard(title: "Protein", value: "0/\(proteinGoal)mg", color: UIColor.systemYellow)
//
//        nutrientsStack.addArrangedSubview(potassium)
//        nutrientsStack.addArrangedSubview(sodium)
//        nutrientsStack.addArrangedSubview(protein)
//    }
    
//    private func updateNutrientCards(potassium: Int, sodium: Int, protein: Int) {
//        if let potassiumCard = nutrientsStack.arrangedSubviews[0] as? UIView,
//           let valueLabel = potassiumCard.subviews.first(where: { ($0 as? UILabel)?.text?.contains("/") == true }) as? UILabel {
//            valueLabel.text = "\(potassium)/\(potassiumGoal)mg"
//        }
        
//        if let sodiumCard = nutrientsStack.arrangedSubviews[1] as? UIView,
//           let valueLabel = sodiumCard.subviews.first(where: { ($0 as? UILabel)?.text?.contains("/") == true }) as? UILabel {
//            valueLabel.text = "\(sodium)/\(sodiumGoal)mg"
//        }
//        
//        if let proteinCard = nutrientsStack.arrangedSubviews[2] as? UIView,
//           let valueLabel = proteinCard.subviews.first(where: { ($0 as? UILabel)?.text?.contains("/") == true }) as? UILabel {
//            valueLabel.text = "\(protein)/\(proteinGoal)mg"
//        }
    

//    private func nutrientCard(title: String, value: String, color: UIColor) -> UIView {
//        let container = UIView()
//        container.translatesAutoresizingMaskIntoConstraints = false
//        container.backgroundColor = .white
//        container.layer.cornerRadius = 12
//        container.layer.shadowColor = UIColor.black.cgColor
//        container.layer.shadowOpacity = 0.04
//        container.layer.shadowOffset = CGSize(width: 0, height: 4)
//        container.layer.shadowRadius = 8
//
//        let titleLabel = UILabel()
//        titleLabel.text = title
//        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
//        titleLabel.translatesAutoresizingMaskIntoConstraints = false
//
//        let valueLabel = UILabel()
//        valueLabel.text = value
//        valueLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
//        valueLabel.translatesAutoresizingMaskIntoConstraints = false
//        valueLabel.textAlignment = .center
//
//        let underline = UIView()
//        underline.translatesAutoresizingMaskIntoConstraints = false
//        underline.backgroundColor = color
//        underline.layer.cornerRadius = 1.5
//
//        container.addSubview(titleLabel)
//        container.addSubview(underline)
//        container.addSubview(valueLabel)
//
//        NSLayoutConstraint.activate([
//            container.heightAnchor.constraint(equalToConstant: 72),
//            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
//            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
//            underline.centerXAnchor.constraint(equalTo: container.centerXAnchor),
//            underline.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
//            underline.widthAnchor.constraint(equalToConstant: 40),
//            underline.heightAnchor.constraint(equalToConstant: 3),
//            valueLabel.topAnchor.constraint(equalTo: underline.bottomAnchor, constant: 8),
//            valueLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
//            valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
//        ])
//
//        return container
//    }

    private func populateContentRows() {
        // Clear existing rows
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if meals.isEmpty {
            emptyStateLabel.isHidden = false
            contentStack.isHidden = true
        } else {
            emptyStateLabel.isHidden = true
            contentStack.isHidden = false
            
            for meal in meals {
                let row = makeRow(
                    left: meal.dishName,
                    center: "x\(meal.quantity)",
                    right: "\(meal.calories) kcal",
                    meal: meal
                )
                contentStack.addArrangedSubview(row)
            }
        }
    }

    private func makeRow(left: String, center: String, right: String, meal: SavedMeal? = nil) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor(red: 210/255, green: 238/255, blue: 220/255, alpha: 1)
        container.layer.cornerRadius = 22
        container.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let leftLabel = UILabel()
        leftLabel.text = left
        leftLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        leftLabel.translatesAutoresizingMaskIntoConstraints = false

        let centerLabel = UILabel()
        centerLabel.text = center
        centerLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        centerLabel.translatesAutoresizingMaskIntoConstraints = false
        centerLabel.textAlignment = .center

        let rightLabel = UILabel()
        rightLabel.text = right
        rightLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        rightLabel.translatesAutoresizingMaskIntoConstraints = false
        rightLabel.textAlignment = .right

        container.addSubview(leftLabel)
        container.addSubview(centerLabel)
        container.addSubview(rightLabel)
        
        // Add delete button if in edit mode
        if isEditMode, let meal = meal {
        let deleteButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        deleteButton.setImage(UIImage(systemName: "trash", withConfiguration: config), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        deleteButton.layer.cornerRadius = 14
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addAction(UIAction { [weak self] _ in
                        // Haptic feedback on tap
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
                        
            self?.deleteMeal(meal)
        }, for: .touchUpInside)
        container.addSubview(deleteButton)
                    
        NSLayoutConstraint.activate([
            deleteButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            deleteButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 28),
            deleteButton.heightAnchor.constraint(equalToConstant: 28),
                
            leftLabel.leadingAnchor.constraint(equalTo: deleteButton.trailingAnchor, constant: 10),
            leftLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            leftLabel.trailingAnchor.constraint(lessThanOrEqualTo: centerLabel.leadingAnchor, constant: -8)
        ])
        } else {
            NSLayoutConstraint.activate([
                leftLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
                leftLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            centerLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            centerLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            rightLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),
            rightLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }
    
    private func deleteMeal(_ meal: SavedMeal) {
        print("🗑️ Delete tapped for: \(meal.dishName)")
        
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Delete Meal",
            message: "Are you sure you want to delete \(meal.dishName)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            print("🗑️ Deleting meal: \(meal.dishName)")
            
            // Delete the meal
            MealDataManager.shared.deleteMeal(id: meal.id)
            
            // Exit edit mode
            self?.isEditMode = false
            self?.editButton.setTitle("Edit", for: .normal)
            
            // Reload data (this will also trigger notification to update home screen)
            self?.loadMealData()
            
            // Show success feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            print("✅ Meal deleted successfully")
        })
        
        present(alert, animated: true)
    }
}

final class MetricsContainerView: UIView {

    enum Mode {
        case list, cards
    }

    private var mode: Mode = .cards

    private let toggle: UISegmentedControl = {
        let listIcon = UIImage(systemName: "list.bullet")
        let cardIcon = UIImage(systemName: "rectangle.stack")

        let sc = UISegmentedControl(items: [listIcon, cardIcon])
        sc.selectedSegmentIndex = 1
        sc.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        sc.selectedSegmentTintColor = .white
        sc.layer.cornerRadius = 18
        sc.clipsToBounds = true
        return sc
    }()

    private let listView = MetricsListView()
    private let cardsView = MetricsCardsView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        toggle.selectedSegmentIndex = 1
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)

        addSubview(toggle)
        addSubview(listView)
        addSubview(cardsView)

        toggle.translatesAutoresizingMaskIntoConstraints = false
        listView.translatesAutoresizingMaskIntoConstraints = false
        cardsView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            toggle.topAnchor.constraint(equalTo: topAnchor),
            toggle.centerXAnchor.constraint(equalTo: centerXAnchor),
            toggle.heightAnchor.constraint(equalToConstant: 36),

            listView.topAnchor.constraint(equalTo: toggle.bottomAnchor, constant: 16),
            listView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            listView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            listView.bottomAnchor.constraint(equalTo: bottomAnchor),

            cardsView.topAnchor.constraint(equalTo: toggle.bottomAnchor, constant: 16),
            cardsView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardsView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardsView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        listView.isHidden = true
    }

    @objc private func toggleChanged() {
        mode = toggle.selectedSegmentIndex == 0 ? .list : .cards
        listView.isHidden = mode != .list
        cardsView.isHidden = mode != .cards
    }

    func update(calories: Int, calorieGoal: Int, potassium: Int, sodium: Int, protein: Int) {
        listView.update(calories: calories, potassium: potassium, sodium: sodium, protein: protein)
        cardsView.update(calories: calories, goal: calorieGoal, potassium: potassium, sodium: sodium, protein: protein)
    }
}

final class MetricsListView: UIView {

    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .vertical
        stack.spacing = 12
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(calories: Int, potassium: Int, sodium: Int, protein: Int) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        stack.addArrangedSubview(makeRow("Calories", "\(calories) kcal"))
        stack.addArrangedSubview(makeRow("Potassium", "\(potassium) mg"))
        stack.addArrangedSubview(makeRow("Sodium", "\(sodium) mg"))
        stack.addArrangedSubview(makeRow("Protein", "\(protein) g"))
    }

    private func makeRow(_ title: String, _ value: String) -> UIView {
        let container = UIView()
        container.applyGlassCardStyle(cornerRadius: 18)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16, weight: .regular)
        valueLabel.textAlignment = .right

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.distribution = .fillEqually

        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 52),

            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

}

final class MetricsCardsView: UIView,
                              UICollectionViewDataSource,
                              UICollectionViewDelegate {

    private var data: [(String, Int, Int)] = []

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(
            width: UIScreen.main.bounds.width * 0.78,
            height: 260
        )
        layout.minimumLineSpacing = 16

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.contentInset = UIEdgeInsets(
            top: 0,
            left: 30,
            bottom: 0,
            right: 30
        )
        cv.decelerationRate = .fast
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.dataSource = self
        cv.register(MetricCardCell.self, forCellWithReuseIdentifier: "cell")
        cv.delegate = self
        return cv
    }()


    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(calories: Int, goal: Int, potassium: Int, sodium: Int, protein: Int) {
        data = [
            ("Calories", calories, goal),
            ("Potassium", potassium, 2000),
            ("Sodium", sodium, 2000),
            ("Protein", protein, 84)
        ]
        collectionView.reloadData()
    }

    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        data.count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MetricCardCell
        let item = data[indexPath.item]
        cell.configure(title: item.0, value: item.1, goal: item.2)
        return cell
    }
    
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        let itemWidth = layout.itemSize.width + layout.minimumLineSpacing
        let offsetX = targetContentOffset.pointee.x + scrollView.contentInset.left

        let index = round(offsetX / itemWidth)
        let newOffsetX = index * itemWidth - scrollView.contentInset.left

        targetContentOffset.pointee.x = newOffsetX
    }

}

final class MetricCardCell: UICollectionViewCell {

    private let titleLabel = UILabel()
    private let gaugeView = HorseshoeGaugeView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(titleLabel)
        contentView.addSubview(gaugeView)
        layer.masksToBounds = false
        contentView.layer.masksToBounds = false
        backgroundColor = .clear
        contentView.applyGlassCardStyle()
        contentView.backgroundColor = UIColor.white.withAlphaComponent(0.55)


        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        gaugeView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            gaugeView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            gaugeView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            gaugeView.widthAnchor.constraint(equalToConstant: 260),
            gaugeView.heightAnchor.constraint(equalToConstant: 150)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, value: Int, goal: Int) {
        titleLabel.text = title
        gaugeView.maxValue = CGFloat(goal)
        gaugeView.currentValue = CGFloat(value)
    }
}




// MARK: - HorseshoeGaugeView

final class HorseshoeGaugeView: UIView {

    private let centerLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.textAlignment = .center
        return l
    }()

    private let subLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        l.textColor = UIColor(white: 0.4, alpha: 1)
        l.textAlignment = .center
        return l
    }()

    var maxValue: CGFloat = 2000 {
        didSet { setNeedsDisplay() }
    }
    var currentValue: CGFloat = 1450 {
        didSet { setNeedsLayout(); setNeedsDisplay() }
    }

    private let trackWidth: CGFloat = 20

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupLabels()
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLabels() {
        addSubview(centerLabel)
        addSubview(subLabel)
        centerLabel.font = UIFont.systemFont(ofSize: 28, weight: .regular)
        centerLabel.text = "\(Int(currentValue)) Kcal"
        subLabel.text = "of \(Int(maxValue)) kcal"

        NSLayoutConstraint.activate([
            centerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 5),

            subLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subLabel.topAnchor.constraint(equalTo: centerLabel.bottomAnchor, constant: 2)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        centerLabel.text = "\(Int(currentValue)) Kcal"
        subLabel.text = "of \(Int(maxValue)) kcal"
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawHorseshoe(in: rect)
    }

    private func drawHorseshoe(in rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()

        let centerPoint = CGPoint(x: rect.midX, y: rect.maxY - 10)
        let radius: CGFloat = 115

        let startAngle = CGFloat(200) * .pi / 180
        let endAngle = CGFloat(340) * .pi / 180

        // Background track
        let bgPath = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        UIColor(red: 210/255, green: 230/255, blue: 215/255, alpha: 1).setStroke()
        bgPath.lineWidth = trackWidth
        bgPath.lineCapStyle = .round
        bgPath.stroke()

        // Progress arc
        let fraction = min(max(currentValue / maxValue, 0), 1)
        let progEndAngle = startAngle + (endAngle - startAngle) * fraction

        let progPath = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: startAngle, endAngle: progEndAngle, clockwise: true)

        ctx.saveGState()
        ctx.addPath(progPath.cgPath)
        ctx.setLineWidth(trackWidth)
        ctx.setLineCap(.round)
        ctx.replacePathWithStrokedPath()
        ctx.clip()

        let colors = [
            UIColor(red: 140/255, green: 190/255, blue: 145/255, alpha: 1).cgColor,
            UIColor(red: 180/255, green: 225/255, blue: 175/255, alpha: 1).cgColor
        ]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 1]) {
            let startPoint = CGPoint(x: rect.minX, y: centerPoint.y)
            let endPoint = CGPoint(x: rect.maxX, y: centerPoint.y)
            ctx.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
        }
        ctx.restoreGState()

        // White knob
        let knobAngle = progEndAngle
        let knobCenter = CGPoint(x: centerPoint.x + radius * cos(knobAngle), y: centerPoint.y + radius * sin(knobAngle))
        let knobPath = UIBezierPath(arcCenter: knobCenter, radius: 8, startAngle: 0, endAngle: 2 * .pi, clockwise: true)

        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: 3), blur: 6, color: UIColor(white: 0.0, alpha: 0.15).cgColor)
        UIColor.white.setFill()
        knobPath.fill()
        ctx.restoreGState()

        ctx.restoreGState()
    }
}

extension UIView {
    func applyGlassCardStyle(cornerRadius: CGFloat = 22) {
        backgroundColor = UIColor.white.withAlphaComponent(0.55)
        layer.cornerRadius = cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 12
    }
}

