//
//  DishConfirmationViewController.swift
//  Dialysis One App
//

import UIKit

final class DishConfirmationViewController: UIViewController {
    
    // MARK: - Properties
    var capturedImage: UIImage?
    var detectedFoods: [DetectedFood] = []
    var selectedDish: DetectedFood?
    private var recentDishes: [String] = []
    
    // MARK: - UI COMPONENTS
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    private let contentView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
        btn.tintColor = .label
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Is this correct?"
        lbl.font = .systemFont(ofSize: 26, weight: .bold)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    private let foodImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let detectedDishCard: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = true
        return v
    }()
    
    private let dishNameTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 20, weight: .semibold)
        tf.placeholder = "Dish name"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.isUserInteractionEnabled = false
        return tf
    }()
    
    private let editIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "pencil"))
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemGray
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let alternatesLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Detected items"
        lbl.font = .systemFont(ofSize: 16, weight: .semibold)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.isHidden = true
        return lbl
    }()
    private let helperTextLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Long press an item to modify or remove"
        lbl.font = .systemFont(ofSize: 13, weight: .regular)
        lbl.textColor = .tertiaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.isHidden = true
        return lbl
    }()
    
    
    
    private let addItemButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "plus.circle.fill")
        config.baseForegroundColor = .systemBlue
        config.imagePadding = 4
        config.buttonSize = .small
        
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isHidden = true
        return btn
    }()

    private let alternatesChipContainer: UIView = {
        let view = UIView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    

    
    private let actionButtonsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 12
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let searchButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Search Manually", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.backgroundColor = .systemGray6
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = UIImage(systemName: "magnifyingglass", withConfiguration: config)
        btn.setImage(image, for: .normal)
        btn.tintColor = .systemBlue
        
        return btn
    }()
    
    private let rescanButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Re-scan Food", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.backgroundColor = .systemGray6
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = UIImage(systemName: "camera", withConfiguration: config)
        btn.setImage(image, for: .normal)
        btn.tintColor = .systemBlue
        
        return btn
    }()
    
    private let confirmButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Confirm Dish", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = UIColor(red: 0.3, green: 0.6, blue: 0.45, alpha: 1)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let image = UIImage(systemName: "checkmark", withConfiguration: config)
        btn.setImage(image, for: .normal)
        btn.tintColor = .white
        
        return btn
    }()
    
    
    // MARK: - VIEW DID LOAD
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        dishNameTextField.delegate = self
        
        setupUI()
        setupActions()
        populateData()
    }
    
    
    // MARK: - SETUP UI
    
    private func setupUI() {
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(foodImageView)
        contentView.addSubview(detectedDishCard)
        detectedDishCard.addSubview(dishNameTextField)
        detectedDishCard.addSubview(editIcon)
        
        contentView.addSubview(alternatesLabel)
        contentView.addSubview(helperTextLabel)
        contentView.addSubview(addItemButton)
        contentView.addSubview(alternatesChipContainer)
        
        // Add buttons to horizontal stack
        actionButtonsStack.addArrangedSubview(rescanButton)
        actionButtonsStack.addArrangedSubview(searchButton)
        
        view.addSubview(actionButtonsStack)
        view.addSubview(confirmButton)
        
        // Add close button LAST so it's on top
        view.addSubview(closeButton)
        
        setupConstraints()
    }
    
    
    // MARK: - CONSTRAINTS
    
    private func setupConstraints() {
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -20),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            foodImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            foodImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            foodImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            foodImageView.heightAnchor.constraint(equalToConstant: 200),
            
            detectedDishCard.topAnchor.constraint(equalTo: foodImageView.bottomAnchor, constant: 20),
            detectedDishCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            detectedDishCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            detectedDishCard.heightAnchor.constraint(equalToConstant: 60),
            
            dishNameTextField.leadingAnchor.constraint(equalTo: detectedDishCard.leadingAnchor, constant: 16),
            dishNameTextField.trailingAnchor.constraint(equalTo: editIcon.leadingAnchor, constant: -8),
            dishNameTextField.centerYAnchor.constraint(equalTo: detectedDishCard.centerYAnchor),
            
            editIcon.trailingAnchor.constraint(equalTo: detectedDishCard.trailingAnchor, constant: -16),
            editIcon.centerYAnchor.constraint(equalTo: detectedDishCard.centerYAnchor),
            editIcon.widthAnchor.constraint(equalToConstant: 22),
            editIcon.heightAnchor.constraint(equalToConstant: 22),
            
            alternatesLabel.topAnchor.constraint(equalTo: detectedDishCard.bottomAnchor, constant: 24),
            alternatesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            helperTextLabel.topAnchor.constraint(equalTo: alternatesLabel.bottomAnchor, constant: 4),
            helperTextLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            addItemButton.topAnchor.constraint(equalTo: alternatesLabel.topAnchor),
            addItemButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            alternatesChipContainer.topAnchor.constraint(equalTo: helperTextLabel.bottomAnchor, constant: 12),
            alternatesChipContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            alternatesChipContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            alternatesChipContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),

            
        ])
        
        // Bottom buttons - side by side action buttons
        NSLayoutConstraint.activate([
            actionButtonsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionButtonsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionButtonsStack.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -12),
            actionButtonsStack.heightAnchor.constraint(equalToConstant: 48),
            
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            confirmButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }
    
    
    // MARK: - ACTIONS
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        rescanButton.addTarget(self, action: #selector(rescanTapped), for: .touchUpInside)
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        addItemButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
        
        // Add tap gesture to the CARD to enable editing
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(enableEditing))
        detectedDishCard.addGestureRecognizer(tapGesture)
        
        // Add long press gesture to the CARD for editing popup
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressOnMainDish(_:)))
        longPressGesture.minimumPressDuration = 0.5
        detectedDishCard.addGestureRecognizer(longPressGesture)
        
        print("✅ Long press gesture added to detectedDishCard")
    }
    
    @objc private func handleLongPressOnMainDish(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        print("🔵 Long press detected!")
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Show popup to edit the main dish name
        showEditMainDishPopup()
    }
    
    private func showEditMainDishPopup() {
        print("📝 Showing edit dish popup")
        
        let alert = UIAlertController(
            title: "Edit Dish Name",
            message: "Change the name of the main dish",
            preferredStyle: .alert
        )
        
        alert.addTextField { [weak self] textField in
            textField.text = self?.dishNameTextField.text
            textField.placeholder = "Dish name"
            textField.autocapitalizationType = .words
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let newName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces),
                  !newName.isEmpty else { return }
            
            // Update the text field with new name
            self.dishNameTextField.text = newName
            
            // Update selectedDish with new name
            if let currentDish = self.selectedDish {
                self.selectedDish = DetectedFood(
                    name: newName,
                    type: currentDish.type,
                    quantity: currentDish.quantity,
                    confidence: currentDish.confidence
                )
            }
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func enableEditing() {
        dishNameTextField.isUserInteractionEnabled = true
        dishNameTextField.becomeFirstResponder()
    }
    
    @objc private func closeTapped() {
        view.endEditing(true)
        navigateToHome()
    }
    
    private func navigateToHome() {
        print("🏠 Navigating to home from confirmation screen")
        
        if let nav = navigationController {
            if let tabBar = nav.tabBarController {
                // If inside a tab bar, dismiss the modal and select home tab
                nav.dismiss(animated: true) {
                    tabBar.selectedIndex = 0
                }
            } else if nav.presentingViewController != nil {
                // Modal navigation - dismiss it
                nav.dismiss(animated: true)
            } else {
                // Regular navigation - pop to root
                nav.popToRootViewController(animated: true)
            }
        } else {
            // Direct presentation
            dismiss(animated: true)
        }
    }
    
    @objc private func rescanTapped() {
        dismiss(animated: true) {
            NotificationCenter.default.post(name: .reopenCamera, object: nil)
        }
    }
    
    @objc private func searchTapped() {
        let searchVC = EnhancedFoodSearchViewController()
        let nav = UINavigationController(rootViewController: searchVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    
    // MARK: - POPULATE UI
    
    private func populateData() {
        foodImageView.image = capturedImage
        
        guard !detectedFoods.isEmpty else { return }
        guard let primary = selectedDish else { return }
        
        dishNameTextField.text = primary.name
        
        if detectedFoods.count > 1 {
            let alternates = detectedFoods.filter {
                $0.name != selectedDish?.name
            }

            if !alternates.isEmpty {
                alternatesLabel.isHidden = false
                helperTextLabel.isHidden = false
                alternatesChipContainer.isHidden = false
                addItemButton.isHidden = false
                
                layoutChipsWithWrapping(alternates)
            }
        }
        // Show add button when there are detected items
        
    }
    private func layoutChipsWithWrapping(_ foods: [DetectedFood]) {
        // Clear existing chips
        alternatesChipContainer.subviews.forEach { $0.removeFromSuperview() }
        
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        let spacing: CGFloat = 8
        let containerWidth = view.bounds.width - 40 // Account for 20pt padding on each side
        
        for (index, food) in foods.enumerated() {
            let chip = createChip(for: food, index: index)
            alternatesChipContainer.addSubview(chip)
            
            // Measure chip size
            let chipSize = chip.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            let chipWidth = chipSize.width
            let chipHeight: CGFloat = 36
            
            // Check if chip fits on current line
            if currentX + chipWidth > containerWidth && currentX > 0 {
                // Move to next line
                currentX = 0
                currentY += chipHeight + spacing
            }
            
            // Position chip
            chip.frame = CGRect(x: currentX, y: currentY, width: chipWidth, height: chipHeight)
            
            // Update X position for next chip
            currentX += chipWidth + spacing
        }
        
        // Update container height
        let totalHeight = currentY + 36
        alternatesChipContainer.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                constraint.isActive = false
            }
        }
        alternatesChipContainer.heightAnchor.constraint(equalToConstant: totalHeight).isActive = true
    }
    
    private func createChip(for food: DetectedFood, index: Int) -> UIView {
        let v = UIView()
        v.backgroundColor = .systemGray5
        v.layer.cornerRadius = 16
        v.tag = index
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isUserInteractionEnabled = true  // IMPORTANT!
        
        let lbl = UILabel()
        lbl.text = food.name
        lbl.font = .systemFont(ofSize: 14, weight: .medium)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        
        v.addSubview(lbl)
        
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 12),
            lbl.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -12),
            lbl.topAnchor.constraint(equalTo: v.topAnchor, constant: 8),
            lbl.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -8)
        ])
        
        // Tap gesture - navigate to detail
        let tap = UITapGestureRecognizer(target: self, action: #selector(chipTapped(_:)))
        v.addGestureRecognizer(tap)
        
        // Long press gesture - edit or delete
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(chipLongPressed(_:)))
        longPress.minimumPressDuration = 0.5
        v.addGestureRecognizer(longPress)
        
        return v
    }

    @objc private func chipTapped(_ sender: UITapGestureRecognizer) {
        guard let tag = sender.view?.tag else { return }
        
        let alternates = detectedFoods.filter { $0.name != selectedDish?.name }
        let selected = alternates[tag]
        
        // Navigate to detail view for this INDIVIDUAL item
        let vc = DishDetailViewController()
        vc.configureWithDetectedFood(
            primary: selected,
            allFoods: detectedFoods,
            image: capturedImage ?? UIImage()
        )
        
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func chipLongPressed(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        guard let tag = sender.view?.tag else { return }
        
        print("🔵 Long press detected on chip!")
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let alternates = detectedFoods.filter { $0.name != selectedDish?.name }
        let selected = alternates[tag]
        
        showChipActionSheet(for: selected, at: tag)
    }
    
    
    // MARK: - CONFIRM
    
    @objc private func confirmTapped() {
        print("📘 Confirm button tapped")
        
        guard let selected = selectedDish else {
            print("⚠️ No selected dish")
            showAlert("Missing name", "Please confirm dish name")
            return
        }
        
        view.endEditing(true)
        
        // Use the edited name if user changed it
        let finalName = dishNameTextField.text?.trimmingCharacters(in: .whitespaces) ?? selected.name
        
        let confirmed = DetectedFood(
            name: finalName.isEmpty ? selected.name : finalName,
            type: selected.type,
            quantity: selected.quantity,
            confidence: selected.confidence
        )
        
        print("✅ Creating detail view for: \(confirmed.name)")
        print("   All foods count: \(detectedFoods.count)")
        
        let vc = DishDetailViewController()
        vc.configureWithDetectedFood(
            primary: confirmed,
            allFoods: detectedFoods,
            image: capturedImage ?? UIImage()
        )
        
        if let nav = navigationController {
            print("📱 Pushing to existing nav controller")
            nav.pushViewController(vc, animated: true)
        } else {
            print("📱 Creating new nav controller")
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
    
    private func showAlert(_ title: String, _ msg: String) {
        let a = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
    
    private func showChipActionSheet(for food: DetectedFood, at index: Int) {
        let alert = UIAlertController(
            title: food.name,
            message: "Choose an action",
            preferredStyle: .actionSheet
        )
        
        // Edit name action
        alert.addAction(UIAlertAction(title: "Edit Name", style: .default) { [weak self] _ in
            self?.showEditChipNamePopup(for: food, at: index)
        })
        
        // Delete action
        alert.addAction(UIAlertAction(title: "Delete Item", style: .destructive) { [weak self] _ in
            self?.deleteChipItem(at: index)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showEditChipNamePopup(for food: DetectedFood, at index: Int) {
        let alert = UIAlertController(
            title: "Edit Item Name",
            message: "Change the name of this detected item",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.text = food.name
            textField.placeholder = "Item name"
            textField.autocapitalizationType = .words
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let newName = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces),
                  !newName.isEmpty else { return }
            
            // Update the food item in the array
            var alternates = self.detectedFoods.filter { $0.name != self.selectedDish?.name }
            let updatedFood = DetectedFood(
                name: newName,
                type: alternates[index].type,
                quantity: alternates[index].quantity,
                confidence: alternates[index].confidence
            )
            
            // Find original index in detectedFoods
            if let originalIndex = self.detectedFoods.firstIndex(where: { $0.name == food.name && $0.type == food.type }) {
                self.detectedFoods[originalIndex] = updatedFood
            }
            
            // Rebuild the chips UI
            self.rebuildChips()
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        })
        
        present(alert, animated: true)
    }
    
    private func deleteChipItem(at index: Int) {
        let alternates = detectedFoods.filter { $0.name != selectedDish?.name }
        let foodToDelete = alternates[index]
        
        // Remove from main array
        detectedFoods.removeAll { $0.name == foodToDelete.name && $0.type == foodToDelete.type }
        
        // Rebuild the chips UI
        rebuildChips()
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Show toast
        showToast("Item removed")
    }
    private func rebuildChips() {
        // Get updated alternates
        let alternates = detectedFoods.filter { $0.name != selectedDish?.name }
        
        // Hide section if no alternates
        if alternates.isEmpty {
            alternatesLabel.isHidden = true
            addItemButton.isHidden = true
            alternatesChipContainer.isHidden = true
            return
        }
        
        // Show section and rebuild chips with wrapping
        alternatesLabel.isHidden = false
        addItemButton.isHidden = false
        alternatesChipContainer.isHidden = false
        
        layoutChipsWithWrapping(alternates)
    }

    // MARK: - Toast helper

    private func showToast(_ message: String) {
        let toast = UILabel()
        toast.text = message
        toast.font = .systemFont(ofSize: 14, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = .systemGray
        toast.textAlignment = .center
        toast.layer.cornerRadius = 8
        toast.clipsToBounds = true
        toast.alpha = 0
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            toast.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, animations: {
                toast.alpha = 0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }


}


// MARK: - TEXT FIELD DELEGATE

extension DishConfirmationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


// MARK: - NOTIFICATION FOR CAMERA

extension Notification.Name {
    static let reopenCamera = Notification.Name("reopenCamera")
}
