import UIKit

class HomeDashboardViewController: UIViewController {
    
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
        
        // Profile button with SF Symbol
        let profileButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        profileButton.setImage(UIImage(systemName: "person.circle.fill", withConfiguration: config), for: .normal)
        profileButton.tintColor = .systemBlue
        profileButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            profileButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            profileButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            profileButton.widthAnchor.constraint(equalToConstant: 40),
            profileButton.heightAnchor.constraint(equalToConstant: 40)
        ])
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
        contentView.addSubview(dietButton)
        
        // Water Button
        waterButton = createQuickAddButton(color: UIColor(red: 0.67, green: 0.85, blue: 0.93, alpha: 1.0), iconName: "drop.fill")
        contentView.addSubview(waterButton)
        
        // Pill Button
        pillButton = createQuickAddButton(color: UIColor(red: 0.55, green: 0.89, blue: 0.70, alpha: 1.0), iconName: "pills.fill")
        contentView.addSubview(pillButton)
        
        dietButtonWidthConstraint = dietButton.widthAnchor.constraint(equalToConstant: 110)
        
        NSLayoutConstraint.activate([
            dietButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 16),
            dietButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            dietButton.heightAnchor.constraint(equalToConstant: 60),
            dietButtonWidthConstraint,
            
            waterButton.topAnchor.constraint(equalTo: dietButton.topAnchor),
            waterButton.leadingAnchor.constraint(equalTo: dietButton.trailingAnchor, constant: 12),
            waterButton.widthAnchor.constraint(equalToConstant: 110),
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
        
        // Fork and knife icon
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: "fork.knife", withConfiguration: iconConfig))
        iconView.tintColor = .black
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tag = 101
        iconView.contentMode = .scaleAspectFit
        container.addSubview(iconView)
        
        // Camera Button (Hidden initially)
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
        
        // Search Button (Hidden initially)
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
            // Expand animation
            dietButtonWidthConstraint.constant = 340
            summaryTopConstraint.constant = 40
            
            // Hide other buttons
            UIView.animate(withDuration: 0.15, animations: {
                self.waterButton.alpha = 0
                self.pillButton.alpha = 0
            })
            
            // Main expansion with bounce
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
                // Pop in the buttons with stagger
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
            // Collapse animation
            dietButtonWidthConstraint.constant = 110
            summaryTopConstraint.constant = 16
            
            // Hide buttons first
            UIView.animate(withDuration: 0.15, animations: {
                self.cameraButton.alpha = 0
                self.searchButton.alpha = 0
                self.cameraButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                self.searchButton.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            })
            
            // Main collapse
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
                // Show other buttons
                UIView.animate(withDuration: 0.2, animations: {
                    self.waterButton.alpha = 1
                    self.pillButton.alpha = 1
                })
            })
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
        
        // Nutrient Balance Card
        let nutrientCard = createNutrientBalanceCard()
        contentView.addSubview(nutrientCard)
        
        // Water and Dose Cards Container
        let cardsStack = UIStackView()
        cardsStack.axis = .horizontal
        cardsStack.spacing = 12
        cardsStack.distribution = .fillEqually
        cardsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardsStack)
        
        let waterCard = createProgressCard(value: "150", total: "out of\n250 ml", color: UIColor.systemBlue, progress: 0.6)
        let doseCard = createProgressCard(value: "2", total: "out of\n3 doses", color: UIColor.systemGreen, progress: 0.67)
        
        cardsStack.addArrangedSubview(waterCard)
        cardsStack.addArrangedSubview(doseCard)
        
        NSLayoutConstraint.activate([
            summaryTopConstraint,
            summaryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            
            nutrientCard.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 16),
            nutrientCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            nutrientCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            nutrientCard.heightAnchor.constraint(equalToConstant: 140),
            
            cardsStack.topAnchor.constraint(equalTo: nutrientCard.bottomAnchor, constant: 12),
            cardsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            cardsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            cardsStack.heightAnchor.constraint(equalToConstant: 150)
        ])
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
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let iconView = UIImageView(image: UIImage(systemName: "fork.knife", withConfiguration: iconConfig))
        iconView.tintColor = .systemOrange
        iconView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)
        
        let titleLabel = UILabel()
        titleLabel.text = "Nutrient Balance"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .systemOrange
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        
        stack.addArrangedSubview(createNutrientItem(name: "Potassium", value: "78/90mg", progress: 0.86, color: .systemGreen))
        stack.addArrangedSubview(createNutrientItem(name: "Sodium", value: "45/70mg", progress: 0.64, color: .systemOrange))
        stack.addArrangedSubview(createNutrientItem(name: "Protein", value: "95/110mg", progress: 0.86, color: .systemYellow))
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),
            
            titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            
            stack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18)
        ])
        
        return container
    }
    
    private func createNutrientItem(name: String, value: String, progress: CGFloat, color: UIColor) -> UIView {
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
    
    private func createProgressCard(value: String, total: String, color: UIColor, progress: CGFloat) -> UIView {
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
        
        // Create semi-circular progress view
        let circularProgress = SemiCircularProgressView(frame: CGRect(x: 0, y: 0, width: 110, height: 70))
        circularProgress.progress = progress
        circularProgress.trackColor = color.withAlphaComponent(0.2)
        circularProgress.progressColor = color
        circularProgress.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(circularProgress)
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
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
        
        NSLayoutConstraint.activate([
            circularProgress.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            circularProgress.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            circularProgress.widthAnchor.constraint(equalToConstant: 110),
            circularProgress.heightAnchor.constraint(equalToConstant: 70),
            
            valueLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: circularProgress.centerYAnchor, constant: 5),
            
            totalLabel.topAnchor.constraint(equalTo: circularProgress.bottomAnchor, constant: 8),
            totalLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
        
        return container
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
        let iconView = UIImageView(image: UIImage(systemName: "scalemass.fill", withConfiguration: iconConfig))
        iconView.tintColor = .systemGreen
        iconView.translatesAutoresizingMaskIntoConstraints = false
        weightCard.addSubview(iconView)
        
        let titleLabel = UILabel()
        titleLabel.text = "Weight"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        weightCard.addSubview(titleLabel)
        
        let valueLabel = UILabel()
        valueLabel.text = "57 Kg"
        valueLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        valueLabel.textColor = .darkGray
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        weightCard.addSubview(valueLabel)
        
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: chevronConfig))
        chevronImageView.tintColor = .gray
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        weightCard.addSubview(chevronImageView)
        
        guard let lastView = contentView.subviews.last(where: { $0 !== weightCard }) else { return }
        
        NSLayoutConstraint.activate([
            weightCard.topAnchor.constraint(equalTo: lastView.bottomAnchor, constant: 12),
            weightCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            weightCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            weightCard.heightAnchor.constraint(equalToConstant: 65),
            weightCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            iconView.leadingAnchor.constraint(equalTo: weightCard.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: weightCard.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: weightCard.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            valueLabel.centerYAnchor.constraint(equalTo: weightCard.centerYAnchor),
            
            chevronImageView.trailingAnchor.constraint(equalTo: weightCard.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: weightCard.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 14),
            chevronImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
}

// MARK: - Semi-Circular Progress View
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
        // Clear the background first
        UIColor.clear.setFill()
        UIRectFill(rect)
        
        let center = CGPoint(x: bounds.midX, y: bounds.maxY - 5)
        let radius = (bounds.width / 2) - (lineWidth / 2)
        
        // Start from bottom left, go to top, then to bottom right (semi-circle)
        let startAngle = CGFloat.pi // Left side (180 degrees)
        let endAngle: CGFloat = 0 // Right side (0 degrees)
        
        // Draw track (full semi-circle)
        let trackPath = UIBezierPath(arcCenter: center,
                                      radius: radius,
                                      startAngle: startAngle,
                                      endAngle: endAngle,
                                      clockwise: true)
        trackPath.lineWidth = lineWidth
        trackPath.lineCapStyle = .round
        trackColor.setStroke()
        trackPath.stroke()
        
        // Draw progress (partial semi-circle based on progress)
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
