//
//  CreateFoodViewController.swift
//  Dialysis One App
//
//  Screen for creating custom food by adding ingredients.
//  Uses FoodBuilderManager for centralized state management.
//

import UIKit

final class CreateFoodViewController: UIViewController {
    
    // MARK: - Properties
    
    private let builder = FoodBuilderManager.shared
    private let addHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let successHaptic = UINotificationFeedbackGenerator()
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        return sv
    }()
    
    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    // Header illustration
    private let headerImageView: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)
        iv.image = UIImage(systemName: "fork.knife.circle.fill", withConfiguration: config)
        iv.tintColor = .systemOrange
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Add ingredients to create your\nfood and track it"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Food name section
    private let foodNameSectionView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let foodNameHintLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter the food name"
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let foodEmojiLabel: UILabel = {
        let label = UILabel()
        label.text = "🍛"
        label.font = .systemFont(ofSize: 24)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let foodNameTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 20, weight: .medium)
        tf.placeholder = "e.g. Dosa, Custom Salad"
        tf.borderStyle = .none
        tf.autocapitalizationType = .words
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let foodNameUnderline: UIView = {
        let v = UIView()
        v.backgroundColor = .systemOrange
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let foodNameSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    // Ingredients section
    private let ingredientsSectionLabel: UILabel = {
        let label = UILabel()
        label.text = "Add food & ingredients"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let addIngredientButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        button.setImage(UIImage(systemName: "plus.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .systemOrange
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Ingredients table
    private let ingredientsTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.separatorStyle = .singleLine
        table.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        table.isScrollEnabled = false
        table.backgroundColor = .clear
        return table
    }()
    
    private var ingredientsTableHeightConstraint: NSLayoutConstraint!
    
    // Empty state
    private let emptyIngredientLabel: UILabel = {
        let label = UILabel()
        label.text = "Click the '+' button to add food/ingredients"
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Totals card
    private let totalsCard: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 12
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let totalsTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Total Nutrition"
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let totalsCaloriesLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let totalsProteinLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let totalsPotassiumLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let totalsSodiumLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Save button
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("SAVE FOOD", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.backgroundColor = .systemGray4
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 0
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Sticky total calories bar (shown above save button)
    private let stickyCaloriesBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.0, green: 0.5, blue: 0.45, alpha: 1.0)
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let stickyCaloriesLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .left
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let stickyCaloriesValueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .bold)
        l.textColor = .white
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        builder.delegate = self
        addHaptic.prepare()
        successHaptic.prepare()
        
        setupNavigation()
        setupUI()
        setupActions()
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh ingredients in case we returned from DishDetail
        updateUI()
    }
    
    // MARK: - Navigation Setup
    
    private func setupNavigation() {
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backButton.tintColor = .label
        navigationItem.leftBarButtonItem = backButton
        navigationItem.title = ""
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerImageView)
        contentView.addSubview(headerLabel)
        
        // Food name section
        contentView.addSubview(foodNameSectionView)
        foodNameSectionView.addSubview(foodNameHintLabel)
        foodNameSectionView.addSubview(foodEmojiLabel)
        foodNameSectionView.addSubview(foodNameTextField)
        foodNameSectionView.addSubview(foodNameUnderline)
        contentView.addSubview(foodNameSeparator)
        
        // Ingredients section
        contentView.addSubview(ingredientsSectionLabel)
        contentView.addSubview(addIngredientButton)
        contentView.addSubview(ingredientsTableView)
        contentView.addSubview(emptyIngredientLabel)
        
        // Totals card
        contentView.addSubview(totalsCard)
        totalsCard.addSubview(totalsTitleLabel)
        totalsCard.addSubview(totalsCaloriesLabel)
        totalsCard.addSubview(totalsProteinLabel)
        totalsCard.addSubview(totalsPotassiumLabel)
        totalsCard.addSubview(totalsSodiumLabel)
        
        // Sticky calories bar
        stickyCaloriesBar.addSubview(stickyCaloriesLabel)
        stickyCaloriesBar.addSubview(stickyCaloriesValueLabel)
        view.addSubview(stickyCaloriesBar)
        
        // Save button (fixed at bottom)
        view.addSubview(saveButton)
        
        // Table view setup
        ingredientsTableView.delegate = self
        ingredientsTableView.dataSource = self
        ingredientsTableView.register(IngredientCell.self, forCellReuseIdentifier: "IngredientCell")
        
        foodNameTextField.delegate = self
        
        ingredientsTableHeightConstraint = ingredientsTableView.heightAnchor.constraint(equalToConstant: 0)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Save button at bottom
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            saveButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            saveButton.heightAnchor.constraint(equalToConstant: 56 + view.safeAreaInsets.bottom),
            
            // Sticky calories bar just above save button
            stickyCaloriesBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stickyCaloriesBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stickyCaloriesBar.bottomAnchor.constraint(equalTo: saveButton.topAnchor),
            stickyCaloriesBar.heightAnchor.constraint(equalToConstant: 44),
            
            stickyCaloriesLabel.leadingAnchor.constraint(equalTo: stickyCaloriesBar.leadingAnchor, constant: 20),
            stickyCaloriesLabel.centerYAnchor.constraint(equalTo: stickyCaloriesBar.centerYAnchor),
            
            stickyCaloriesValueLabel.trailingAnchor.constraint(equalTo: stickyCaloriesBar.trailingAnchor, constant: -20),
            stickyCaloriesValueLabel.centerYAnchor.constraint(equalTo: stickyCaloriesBar.centerYAnchor),
            
            // Scroll view (above sticky calories bar)
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: stickyCaloriesBar.topAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            headerImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            headerImageView.widthAnchor.constraint(equalToConstant: 60),
            headerImageView.heightAnchor.constraint(equalToConstant: 60),
            
            headerLabel.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: 12),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            // Food name section
            foodNameSectionView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 28),
            foodNameSectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            foodNameSectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            foodNameHintLabel.topAnchor.constraint(equalTo: foodNameSectionView.topAnchor),
            foodNameHintLabel.leadingAnchor.constraint(equalTo: foodEmojiLabel.trailingAnchor, constant: 8),
            foodNameHintLabel.trailingAnchor.constraint(equalTo: foodNameSectionView.trailingAnchor),
            
            foodEmojiLabel.topAnchor.constraint(equalTo: foodNameHintLabel.bottomAnchor, constant: 6),
            foodEmojiLabel.leadingAnchor.constraint(equalTo: foodNameSectionView.leadingAnchor),
            foodEmojiLabel.widthAnchor.constraint(equalToConstant: 30),
            
            foodNameTextField.leadingAnchor.constraint(equalTo: foodEmojiLabel.trailingAnchor, constant: 8),
            foodNameTextField.trailingAnchor.constraint(equalTo: foodNameSectionView.trailingAnchor),
            foodNameTextField.centerYAnchor.constraint(equalTo: foodEmojiLabel.centerYAnchor),
            
            foodNameUnderline.topAnchor.constraint(equalTo: foodNameTextField.bottomAnchor, constant: 4),
            foodNameUnderline.leadingAnchor.constraint(equalTo: foodNameTextField.leadingAnchor),
            foodNameUnderline.trailingAnchor.constraint(equalTo: foodNameTextField.trailingAnchor),
            foodNameUnderline.heightAnchor.constraint(equalToConstant: 2),
            foodNameUnderline.bottomAnchor.constraint(equalTo: foodNameSectionView.bottomAnchor),
            
            foodNameSeparator.topAnchor.constraint(equalTo: foodNameSectionView.bottomAnchor, constant: 16),
            foodNameSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            foodNameSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            foodNameSeparator.heightAnchor.constraint(equalToConstant: 0.5),
            
            // Ingredients section
            ingredientsSectionLabel.topAnchor.constraint(equalTo: foodNameSeparator.bottomAnchor, constant: 20),
            ingredientsSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            addIngredientButton.centerYAnchor.constraint(equalTo: ingredientsSectionLabel.centerYAnchor),
            addIngredientButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            addIngredientButton.widthAnchor.constraint(equalToConstant: 36),
            addIngredientButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Empty state
            emptyIngredientLabel.topAnchor.constraint(equalTo: ingredientsSectionLabel.bottomAnchor, constant: 40),
            emptyIngredientLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            emptyIngredientLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            // Ingredients table
            ingredientsTableView.topAnchor.constraint(equalTo: ingredientsSectionLabel.bottomAnchor, constant: 12),
            ingredientsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            ingredientsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            ingredientsTableHeightConstraint,
            
            // Totals card
            totalsCard.topAnchor.constraint(equalTo: ingredientsTableView.bottomAnchor, constant: 20),
            totalsCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            totalsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            totalsCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            totalsTitleLabel.topAnchor.constraint(equalTo: totalsCard.topAnchor, constant: 16),
            totalsTitleLabel.leadingAnchor.constraint(equalTo: totalsCard.leadingAnchor, constant: 16),
            
            totalsCaloriesLabel.topAnchor.constraint(equalTo: totalsTitleLabel.bottomAnchor, constant: 6),
            totalsCaloriesLabel.leadingAnchor.constraint(equalTo: totalsCard.leadingAnchor, constant: 16),
            
            totalsProteinLabel.topAnchor.constraint(equalTo: totalsCaloriesLabel.bottomAnchor, constant: 8),
            totalsProteinLabel.leadingAnchor.constraint(equalTo: totalsCard.leadingAnchor, constant: 16),
            
            totalsPotassiumLabel.topAnchor.constraint(equalTo: totalsProteinLabel.bottomAnchor, constant: 4),
            totalsPotassiumLabel.leadingAnchor.constraint(equalTo: totalsCard.leadingAnchor, constant: 16),
            
            totalsSodiumLabel.topAnchor.constraint(equalTo: totalsPotassiumLabel.bottomAnchor, constant: 4),
            totalsSodiumLabel.leadingAnchor.constraint(equalTo: totalsCard.leadingAnchor, constant: 16),
            totalsSodiumLabel.bottomAnchor.constraint(equalTo: totalsCard.bottomAnchor, constant: -16),
        ])
    }
    
    // MARK: - Actions
    
    private func setupActions() {
        addIngredientButton.addTarget(self, action: #selector(addIngredientTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveFoodTapped), for: .touchUpInside)
        foodNameTextField.addTarget(self, action: #selector(foodNameChanged), for: .editingChanged)
    }
    
    @objc private func addIngredientTapped() {
        // Save the current food name
        builder.setFoodName(foodNameTextField.text ?? "")
        
        // Push search in ingredient mode
        let searchVC = EnhancedFoodSearchViewController()
        searchVC.isIngredientMode = true
        searchVC.ingredientSearchDelegate = self
        navigationController?.pushViewController(searchVC, animated: true)
    }
    
    @objc private func foodNameChanged() {
        builder.setFoodName(foodNameTextField.text ?? "")
        updateSaveButtonState()
    }
    
    @objc private func saveFoodTapped() {
        builder.setFoodName(foodNameTextField.text ?? "")
        
        guard let meal = builder.buildCompositeMeal() else {
            showAlert("Missing Info", "Please enter a food name and add at least one ingredient.")
            return
        }
        
        // Show meal type picker
        let alert = UIAlertController(
            title: "Select Meal Type",
            message: "When did you have this meal?",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Breakfast", style: .default) { [weak self] _ in
            self?.saveAndReturn(mealType: .breakfast, meal: meal)
        })
        
        alert.addAction(UIAlertAction(title: "Lunch", style: .default) { [weak self] _ in
            self?.saveAndReturn(mealType: .lunch, meal: meal)
        })
        
        alert.addAction(UIAlertAction(title: "Dinner", style: .default) { [weak self] _ in
            self?.saveAndReturn(mealType: .dinner, meal: meal)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let pop = alert.popoverPresentationController {
            pop.sourceView = saveButton
            pop.sourceRect = saveButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func saveAndReturn(mealType: SavedMeal.MealType, meal: (dishName: String, calories: Int, protein: Double, potassium: Int, sodium: Int)) {
        
        MealDataManager.shared.saveMeal(
            dishName: meal.dishName,
            calories: meal.calories,
            potassium: meal.potassium,
            sodium: meal.sodium,
            protein: meal.protein,
            quantity: 1,
            mealType: mealType,
            image: nil
        )
        
        successHaptic.notificationOccurred(.success)
        print("✅ Custom food saved: \(meal.dishName) with \(builder.ingredientCount) ingredients, \(meal.calories) kcal")
        
        builder.reset()
        showSuccessBanner(dishName: meal.dishName)
    }
    
    private func showSuccessBanner(dishName: String) {
        let banner = UIView()
        banner.backgroundColor = UIColor.systemGreen
        banner.layer.cornerRadius = 12
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.alpha = 0
        
        let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmark.tintColor = .white
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "'\(dishName)' saved successfully!"
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            UIView.animate(withDuration: 0.3) {
                banner.alpha = 0
            } completion: { _ in
                banner.removeFromSuperview()
            }
            self?.navigateToHome()
        }
    }
    
    @objc private func backTapped() {
        // Warn if there are ingredients
        if !builder.isEmpty {
            let alert = UIAlertController(
                title: "Discard Changes?",
                message: "You have unsaved ingredients. Are you sure you want to go back?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
                self?.builder.reset()
                self?.navigationController?.popViewController(animated: true)
            })
            alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
            present(alert, animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Update UI
    
    private func updateUI() {
        let ingredients = builder.ingredients
        let prevCount = ingredientsTableView.numberOfRows(inSection: 0)
        
        ingredientsTableView.reloadData()
        
        // Update table height
        let rowHeight: CGFloat = 64
        ingredientsTableHeightConstraint.constant = CGFloat(ingredients.count) * rowHeight
        
        // Empty state
        emptyIngredientLabel.isHidden = !ingredients.isEmpty
        ingredientsTableView.isHidden = ingredients.isEmpty
        
        // Totals card
        if !ingredients.isEmpty {
            totalsCard.isHidden = false
            totalsCaloriesLabel.text = "\(Int(builder.totalCalories)) kcal"
            totalsProteinLabel.text = "Protein: \(String(format: "%.1f", builder.totalProtein)) g"
            totalsPotassiumLabel.text = "Potassium: \(Int(builder.totalPotassium)) mg"
            totalsSodiumLabel.text = "Sodium: \(Int(builder.totalSodium)) mg"
            
            // Sticky calories bar
            stickyCaloriesBar.isHidden = false
            stickyCaloriesLabel.text = "Total Calories"
            stickyCaloriesValueLabel.text = "\(Int(builder.totalCalories)) kcal"
            
            // Scroll to newly added ingredient if count increased
            if ingredients.count > prevCount && ingredients.count > 0 {
                let lastIndex = IndexPath(row: ingredients.count - 1, section: 0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                    self?.ingredientsTableView.scrollToRow(at: lastIndex, at: .bottom, animated: true)
                    // Also scroll the outer scrollView to bottom
                    if let sv = self?.scrollView {
                        let bottom = sv.contentSize.height - sv.bounds.height
                        if bottom > 0 {
                            sv.setContentOffset(CGPoint(x: 0, y: bottom), animated: true)
                        }
                    }
                }
            }
        } else {
            totalsCard.isHidden = true
            stickyCaloriesBar.isHidden = true
        }
        
        // Restore food name from builder
        if foodNameTextField.text?.isEmpty == true && !builder.foodName.isEmpty {
            foodNameTextField.text = builder.foodName
        }
        
        updateSaveButtonState()
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
    }
    
    private func updateSaveButtonState() {
        let hasName = !(foodNameTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        let hasIngredients = !builder.isEmpty
        let enabled = hasName && hasIngredients
        
        saveButton.isEnabled = enabled
        saveButton.backgroundColor = enabled
            ? UIColor(red: 0.0, green: 0.5, blue: 0.45, alpha: 1.0)
            : .systemGray4
    }
    
    // MARK: - Edit Ingredient
    
    private func editIngredient(at index: Int) {
        let ingredient = builder.ingredients[index]
        
        // Open DishDetailViewController in ingredient mode with prefilled values
        let detectedFood = DetectedFood(
            name: ingredient.name,
            type: nil,
            quantity: "\(ingredient.quantity) \(ingredient.unit)",
            confidence: "1.0"
        )
        
        let detailVC = DishDetailViewController()
        let placeholderImage = UIImage(systemName: "photo")?.withTintColor(.systemGray4, renderingMode: .alwaysOriginal)
        
        detailVC.isIngredientMode = true
        detailVC.ingredientDelegate = self
        detailVC.editingIngredientIndex = index
        
        detailVC.configureWithDetectedFood(
            primary: detectedFood,
            allFoods: [detectedFood],
            image: placeholderImage ?? UIImage(),
            fromSearch: true
        )
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - Helpers
    
    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func navigateToHome() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let root = window.rootViewController else { return }
        
        if let tabBar = root as? UITabBarController {
            tabBar.selectedIndex = 0
            if let homeNav = tabBar.selectedViewController as? UINavigationController {
                homeNav.popToRootViewController(animated: false)
            }
            root.dismiss(animated: true)
            return
        }
        
        if let nav = root as? UINavigationController {
            nav.popToRootViewController(animated: false)
            root.dismiss(animated: true)
            return
        }
        
        root.dismiss(animated: true)
    }
}

// MARK: - UITableView DataSource & Delegate

extension CreateFoodViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return builder.ingredientCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath) as! IngredientCell
        let ingredient = builder.ingredients[indexPath.row]
        cell.configure(with: ingredient)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        editIngredient(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Fade + slide-in animation for each ingredient cell
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 16)
        UIView.animate(withDuration: 0.25, delay: Double(indexPath.row) * 0.04,
                       options: [.curveEaseOut], animations: {
            cell.alpha = 1
            cell.transform = .identity
        })
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.builder.removeIngredient(at: indexPath.row)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            self?.editIngredient(at: indexPath.row)
            completion(true)
        }
        editAction.backgroundColor = .systemBlue
        editAction.image = UIImage(systemName: "pencil")
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
}

// MARK: - UITextField Delegate

extension CreateFoodViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - FoodBuilderManagerDelegate

extension CreateFoodViewController: FoodBuilderManagerDelegate {
    func foodBuilderDidUpdateIngredients() {
        updateUI()
    }
}

// MARK: - IngredientSearchDelegate

extension CreateFoodViewController: IngredientSearchDelegate {
    func didSelectIngredient(_ ingredient: IngredientItem) {
        addHaptic.impactOccurred()
        updateUI()
    }
}

// MARK: - IngredientSelectionDelegate

extension CreateFoodViewController: IngredientSelectionDelegate {
    func didConfirmIngredient(_ ingredient: IngredientItem) {
        addHaptic.impactOccurred()
        updateUI()
    }
}

// MARK: - Ingredient Cell

final class IngredientCell: UITableViewCell {
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let caloriesLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let disclosureIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .default
        backgroundColor = .clear
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(quantityLabel)
        contentView.addSubview(caloriesLabel)
        contentView.addSubview(disclosureIcon)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: caloriesLabel.leadingAnchor, constant: -12),
            
            quantityLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            quantityLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            quantityLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            
            caloriesLabel.trailingAnchor.constraint(equalTo: disclosureIcon.leadingAnchor, constant: -8),
            caloriesLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            disclosureIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            disclosureIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            disclosureIcon.widthAnchor.constraint(equalToConstant: 12),
            disclosureIcon.heightAnchor.constraint(equalToConstant: 12),
        ])
    }
    
    func configure(with ingredient: IngredientItem) {
        nameLabel.text = ingredient.name
        quantityLabel.text = "\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit)"
        caloriesLabel.text = "\(Int(ingredient.calories)) Cal"
    }
}
