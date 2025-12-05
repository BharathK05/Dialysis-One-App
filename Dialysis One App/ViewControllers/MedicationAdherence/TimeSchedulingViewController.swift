import UIKit

class TimeSchedulingViewController: UIViewController {
    
    weak var flowDelegate: MedicationFlowStepDelegate?
    var initialData: MedicationFlowData?
    
    private var selectedTimes: Set<TimeOfDay> = []
    private var timeButtons: [TimeOfDay: UIButton] = [:]
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let timeStackView = UIStackView()
    private let nextButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let data = initialData {
            selectedTimes = data.selectedTimes
        }
        
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        addTopGradientBackground()
        title = "Schedule"
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Progress bar
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progress = 0.6 // Step 3 of 5
        progressBar.tintColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        progressBar.trackTintColor = UIColor.systemGray5
        contentView.addSubview(progressBar)
        
        // Title
        titleLabel.text = "When to Take"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "Select one or more times"
        subtitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // Time selection stack
        timeStackView.axis = .vertical
        timeStackView.spacing = 16
        timeStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeStackView)
        
        // Create time option cards
        for timeOfDay in TimeOfDay.allCases {
            let card = createTimeCard(for: timeOfDay)
            timeButtons[timeOfDay] = card
            timeStackView.addArrangedSubview(card)
            
            NSLayoutConstraint.activate([
                card.heightAnchor.constraint(equalToConstant: 70)
            ])
        }
        
        // Next button
        nextButton.setTitle("Next", for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        nextButton.backgroundColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 12
        nextButton.layer.shadowColor = UIColor.black.cgColor
        nextButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        nextButton.layer.shadowRadius = 12
        nextButton.layer.shadowOpacity = 0.15
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.isEnabled = !selectedTimes.isEmpty
        nextButton.alpha = selectedTimes.isEmpty ? 0.5 : 1.0
        contentView.addSubview(nextButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            progressBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            progressBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            progressBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            progressBar.heightAnchor.constraint(equalToConstant: 4),
            
            titleLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            timeStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            timeStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            timeStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            nextButton.topAnchor.constraint(equalTo: timeStackView.bottomAnchor, constant: 32),
            nextButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            nextButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            nextButton.heightAnchor.constraint(equalToConstant: 54),
            nextButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
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
    
    private func createTimeCard(for timeOfDay: TimeOfDay) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.clear.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.08
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon (smaller)
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: timeOfDay.icon, withConfiguration: iconConfig))
        iconView.tintColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(iconView)
        
        // Label
        let label = UILabel()
        label.text = timeOfDay.rawValue
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(label)
        
        // Checkmark (hidden by default)
        let checkConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        let checkmarkView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill", withConfiguration: checkConfig))
        checkmarkView.tintColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        checkmarkView.alpha = 0
        checkmarkView.tag = 999
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(checkmarkView)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 20),
            iconView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            
            checkmarkView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -20),
            checkmarkView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        button.tag = timeOfDay.hashValue
        button.addTarget(self, action: #selector(timeCardTapped(_:)), for: .touchUpInside)
        
        // Set initial state
        if selectedTimes.contains(timeOfDay) {
            updateCardAppearance(button, selected: true)
        }
        
        return button
    }
    
    @objc private func timeCardTapped(_ sender: UIButton) {
        guard let timeOfDay = TimeOfDay.allCases.first(where: { $0.hashValue == sender.tag }) else { return }
        
        let isSelected: Bool
        if selectedTimes.contains(timeOfDay) {
            selectedTimes.remove(timeOfDay)
            isSelected = false
        } else {
            selectedTimes.insert(timeOfDay)
            isSelected = true
        }
        
        updateCardAppearance(sender, selected: isSelected)
        updateNextButton()
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func updateCardAppearance(_ button: UIButton, selected: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            if selected {
                button.backgroundColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 0.15)
                button.layer.borderColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0).cgColor
                button.layer.borderWidth = 2
                
                if let checkmark = button.viewWithTag(999) {
                    checkmark.alpha = 1
                    checkmark.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    UIView.animate(withDuration: 0.2) {
                        checkmark.transform = .identity
                    }
                }
            } else {
                button.backgroundColor = UIColor.white.withAlphaComponent(0.7)
                button.layer.borderColor = UIColor.clear.cgColor
                button.layer.borderWidth = 2
                
                if let checkmark = button.viewWithTag(999) {
                    checkmark.alpha = 0
                }
            }
        }
    }
    
    private func updateNextButton() {
        let isValid = !selectedTimes.isEmpty
        nextButton.isEnabled = isValid
        
        UIView.animate(withDuration: 0.2) {
            self.nextButton.alpha = isValid ? 1.0 : 0.5
        }
    }
    
    @objc private func nextTapped() {
        guard !selectedTimes.isEmpty else { return }
        
        var data = initialData ?? MedicationFlowData()
        data.selectedTimes = selectedTimes
        
        flowDelegate?.flowStepDidComplete(.time, data: data)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
