import UIKit

class MedicationReviewViewController: UIViewController {
    
    weak var flowDelegate: MedicationFlowStepDelegate?
    var medicationData: MedicationFlowData?
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let reviewCard = UIView()
    private let doneButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        addTopGradientBackground()
        title = "Review"
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Progress bar
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progress = 1.0
        progressBar.tintColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        progressBar.trackTintColor = UIColor.systemGray5
        contentView.addSubview(progressBar)
        
        // Title
        titleLabel.text = "Review Details"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel.text = "Check everything looks correct"
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .left
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // Review card
        reviewCard.backgroundColor = .white
        reviewCard.layer.cornerRadius = 16
        reviewCard.layer.shadowColor = UIColor.black.cgColor
        reviewCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        reviewCard.layer.shadowRadius = 12
        reviewCard.layer.shadowOpacity = 0.1
        reviewCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(reviewCard)
        
        setupReviewContent()
        
        // Done button
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        doneButton.backgroundColor = UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.layer.cornerRadius = 12
        doneButton.layer.shadowColor = UIColor.black.cgColor
        doneButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        doneButton.layer.shadowRadius = 12
        doneButton.layer.shadowOpacity = 0.15
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(doneButton)
        
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
            
            reviewCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            reviewCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            reviewCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            doneButton.topAnchor.constraint(equalTo: reviewCard.bottomAnchor, constant: 24),
            doneButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            doneButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            doneButton.heightAnchor.constraint(equalToConstant: 54),
            doneButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
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
    
    private func setupReviewContent() {
        guard let data = medicationData else { return }
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        reviewCard.addSubview(stack)
        
        // Medication name
        let nameSection = createReviewSection(
            icon: "pill",
            iconColor: UIColor(red: 0.2, green: 0.7, blue: 0.5, alpha: 1.0),
            title: "Medication",
            value: data.name
        )
        stack.addArrangedSubview(nameSection)
        
        // Dosage
        let dosageSection = createReviewSection(
            icon: "cross.vial",
            iconColor: .systemBlue,
            title: "Dosage",
            value: "\(data.dosage) \(data.unit)"
        )
        stack.addArrangedSubview(dosageSection)
        
        // Times
        let timesString = data.selectedTimes
            .sorted { $0.rawValue < $1.rawValue }
            .map { $0.rawValue }
            .joined(separator: ", ")
        
        let timesSection = createReviewSection(
            icon: "clock",
            iconColor: .systemOrange,
            title: "Schedule",
            value: timesString
        )
        stack.addArrangedSubview(timesSection)
        
        // Description (if provided)
        if !data.description.isEmpty && data.description != "No description" {
            let descSection = createReviewSection(
                icon: "doc.text",
                iconColor: .systemPurple,
                title: "Description",
                value: data.description
            )
            stack.addArrangedSubview(descSection)
        }
        
        // Instructions (if provided)
        if !data.instructions.isEmpty {
            let instSection = createReviewSection(
                icon: "info.circle",
                iconColor: .systemIndigo,
                title: "Instructions",
                value: data.instructions
            )
            stack.addArrangedSubview(instSection)
        }
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: reviewCard.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: reviewCard.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: reviewCard.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: reviewCard.bottomAnchor, constant: -24)
        ])
    }
    
    private func createReviewSection(icon: String, iconColor: UIColor, title: String, value: String) -> UIView {
        let container = UIView()
        
        // Icon (smaller)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: config))
        iconView.tintColor = iconColor
        iconView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(titleLabel)
        
        // Value label
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 0
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    // MARK: - Actions
    @objc private func doneTapped() {
        guard let data = medicationData else { return }
        
        flowDelegate?.flowStepDidComplete(.review, data: data)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
