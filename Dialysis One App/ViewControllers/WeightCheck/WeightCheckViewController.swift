import UIKit

// MARK: - Models
struct WeightEntry {
    let date: Date
    let weight: Double?
    let bmi: Double?
    let isPreDialysis: Bool
}

struct DayData {
    let date: Date
    var hasEntry: Bool
    var weight: Double?
}

// MARK: - Weight Check View Controller
class WeightCheckViewController: UIViewController {
    
    // MARK: - Properties
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let backButton = UIButton()
    private let titleLabel = UILabel()
    
    // Section 1: Date Picker
    private let dateCardView = UIView()
    private let dateLabel = UILabel()
    private let weekScrollView = UIScrollView()
    private let weekStackView = UIStackView()
    private let previousWeightLabel = UILabel()
    private let previousWeightValueLabel = UILabel()
    
    // Section 2: Weight Input
    private let weightInputCardView = UIView()
    private let weightLabel = UILabel()
    private let weightTextField = UITextField()
    private let bmiLabel = UILabel()
    private let bmiValueLabel = UILabel()
    private let saveButton = UIButton()
    
    // Warning Banner
    private let warningView = UIView()
    private let warningIcon = UILabel()
    private let warningLabel = UILabel()
    
    // Section 3: Summary
    private let summaryCardView = UIView()
    private let summaryTitleLabel = UILabel()
    private let targetWeightLabel = UILabel()
    private let targetWeightValueLabel = UILabel()
    private let weightDifferenceLabel = UILabel()
    private let weightDifferenceValueLabel = UILabel()
    private let dryWeightDifferenceLabel = UILabel()
    private let dryWeightDifferenceValueLabel = UILabel()
    
    // Graph
    private let graphView = WeightGraphView()
    
    // Data
    private var weekDays: [DayData] = []
    private var selectedDate: Date = Date()
    private var weightEntries: [Date: WeightEntry] = [:]
    private let userHeight: Double = 170.0 // cm - Sample height
    private let targetWeight: Double = 64.0
    private var dryWeight: Double = 64.0
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
        updateUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 0.68, green: 0.90, blue: 0.68, alpha: 1.0).cgColor,
            UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        setupScrollView()
        setupHeader()
        setupDateCard()
        setupWeightInputCard()
        setupWarningBanner()
        setupSummaryCard()
        setupGraph()
        
        setupConstraints()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        let backImage = UIImage(systemName: "chevron.left")
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = .black
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Weight Check"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        
        contentView.addSubview(backButton)
        contentView.addSubview(titleLabel)
    }
    
    private func setupDateCard() {
        dateCardView.translatesAutoresizingMaskIntoConstraints = false
        dateCardView.backgroundColor = .white
        dateCardView.layer.cornerRadius = 16
        dateCardView.layer.shadowColor = UIColor.black.cgColor
        dateCardView.layer.shadowOpacity = 0.08
        dateCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        dateCardView.layer.shadowRadius = 8
        
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .systemFont(ofSize: 15, weight: .medium)
        dateLabel.textColor = .secondaryLabel
        dateLabel.textAlignment = .center
        
        weekScrollView.translatesAutoresizingMaskIntoConstraints = false
        weekScrollView.showsHorizontalScrollIndicator = false
        
        weekStackView.translatesAutoresizingMaskIntoConstraints = false
        weekStackView.axis = .horizontal
        weekStackView.spacing = 12
        weekStackView.distribution = .equalSpacing
        
        previousWeightLabel.translatesAutoresizingMaskIntoConstraints = false
        previousWeightLabel.text = "Previous Weight"
        previousWeightLabel.font = .systemFont(ofSize: 15, weight: .medium)
        previousWeightLabel.textColor = .secondaryLabel
        
        previousWeightValueLabel.translatesAutoresizingMaskIntoConstraints = false
        previousWeightValueLabel.text = "No data"
        previousWeightValueLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        previousWeightValueLabel.textAlignment = .right
        previousWeightValueLabel.textColor = .label
        
        weekScrollView.addSubview(weekStackView)
        dateCardView.addSubview(dateLabel)
        dateCardView.addSubview(weekScrollView)
        dateCardView.addSubview(previousWeightLabel)
        dateCardView.addSubview(previousWeightValueLabel)
        contentView.addSubview(dateCardView)
    }
    
    private func setupWeightInputCard() {
        weightInputCardView.translatesAutoresizingMaskIntoConstraints = false
        weightInputCardView.backgroundColor = .white
        weightInputCardView.layer.cornerRadius = 16
        weightInputCardView.layer.shadowColor = UIColor.black.cgColor
        weightInputCardView.layer.shadowOpacity = 0.08
        weightInputCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        weightInputCardView.layer.shadowRadius = 8
        
        weightLabel.translatesAutoresizingMaskIntoConstraints = false
        weightLabel.text = "Weight"
        weightLabel.font = .systemFont(ofSize: 15, weight: .medium)
        weightLabel.textColor = .secondaryLabel
        
        weightTextField.translatesAutoresizingMaskIntoConstraints = false
        weightTextField.font = .systemFont(ofSize: 17, weight: .regular)
        weightTextField.textAlignment = .right
        weightTextField.keyboardType = .decimalPad
        weightTextField.placeholder = "Tap to enter"
        weightTextField.textColor = .label
        weightTextField.tintColor = .systemGreen
        weightTextField.borderStyle = .none
        weightTextField.addTarget(self, action: #selector(weightChanged), for: .editingChanged)
        
        // Add a subtle container for input area
        let inputContainer = UIView()
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.backgroundColor = UIColor(red: 0.68, green: 0.90, blue: 0.68, alpha: 0.08)
        inputContainer.layer.cornerRadius = 10
        inputContainer.layer.borderWidth = 1
        inputContainer.layer.borderColor = UIColor(red: 0.68, green: 0.90, blue: 0.68, alpha: 0.2).cgColor
        
        let kgLabel = UILabel()
        kgLabel.text = " kg"
        kgLabel.font = .systemFont(ofSize: 17, weight: .regular)
        kgLabel.textColor = .secondaryLabel
        kgLabel.sizeToFit()
        
        weightTextField.rightView = kgLabel
        weightTextField.rightViewMode = .always
        
        bmiLabel.translatesAutoresizingMaskIntoConstraints = false
        bmiLabel.text = "BMI"
        bmiLabel.font = .systemFont(ofSize: 15, weight: .medium)
        bmiLabel.textColor = .secondaryLabel
        
        bmiValueLabel.translatesAutoresizingMaskIntoConstraints = false
        bmiValueLabel.text = "-"
        bmiValueLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        bmiValueLabel.textAlignment = .right
        bmiValueLabel.textColor = .label
        
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Save Weight", for: .normal)
        saveButton.backgroundColor = UIColor(red: 0.4, green: 0.7, blue: 0.4, alpha: 1.0)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(self, action: #selector(saveWeight), for: .touchUpInside)
        
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor.separator
        
        weightInputCardView.addSubview(inputContainer)
        weightInputCardView.addSubview(saveButton)

        inputContainer.addSubview(weightLabel)
        inputContainer.addSubview(weightTextField)
        weightInputCardView.addSubview(separator)
        weightInputCardView.addSubview(bmiLabel)
        weightInputCardView.addSubview(bmiValueLabel)
        contentView.addSubview(weightInputCardView)
        
        NSLayoutConstraint.activate([
            inputContainer.topAnchor.constraint(equalTo: weightInputCardView.topAnchor, constant: 16),
            inputContainer.leadingAnchor.constraint(equalTo: weightInputCardView.leadingAnchor, constant: 16),
            inputContainer.trailingAnchor.constraint(equalTo: weightInputCardView.trailingAnchor, constant: -16),
            inputContainer.heightAnchor.constraint(equalToConstant: 52),
            
            weightLabel.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 14),
            weightLabel.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            
            weightTextField.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -14),
            weightTextField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            weightTextField.leadingAnchor.constraint(equalTo: weightLabel.trailingAnchor, constant: 16),
            
            saveButton.topAnchor.constraint(equalTo: bmiLabel.bottomAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: weightInputCardView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: weightInputCardView.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: weightInputCardView.bottomAnchor, constant: -16),
            
            separator.topAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: 16),
            separator.leadingAnchor.constraint(equalTo: weightInputCardView.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: weightInputCardView.trailingAnchor, constant: -16),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            
            bmiLabel.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 16),
            bmiLabel.leadingAnchor.constraint(equalTo: weightInputCardView.leadingAnchor, constant: 20),
            bmiLabel.bottomAnchor.constraint(equalTo: weightInputCardView.bottomAnchor, constant: -20),
            
            bmiValueLabel.centerYAnchor.constraint(equalTo: bmiLabel.centerYAnchor),
            bmiValueLabel.trailingAnchor.constraint(equalTo: weightInputCardView.trailingAnchor, constant: -20)
            
            
        ])
    }
    
    private func setupWarningBanner() {
        warningView.translatesAutoresizingMaskIntoConstraints = false
        warningView.backgroundColor = UIColor(red: 1.0, green: 0.93, blue: 0.76, alpha: 1.0)
        warningView.layer.cornerRadius = 12
        warningView.layer.borderWidth = 1
        warningView.layer.borderColor = UIColor(red: 1.0, green: 0.85, blue: 0.5, alpha: 0.5).cgColor
        warningView.isHidden = true
        
        warningIcon.translatesAutoresizingMaskIntoConstraints = false
        warningIcon.text = "⚠️"
        warningIcon.font = .systemFont(ofSize: 18)
        
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.font = .systemFont(ofSize: 13, weight: .medium)
        warningLabel.numberOfLines = 0
        warningLabel.textColor = UIColor(red: 0.6, green: 0.4, blue: 0.0, alpha: 1.0)
        
        warningView.addSubview(warningIcon)
        warningView.addSubview(warningLabel)
        contentView.addSubview(warningView)
    }
    
    private func setupSummaryCard() {
        summaryCardView.translatesAutoresizingMaskIntoConstraints = false
        summaryCardView.backgroundColor = .white
        summaryCardView.layer.cornerRadius = 16
        summaryCardView.layer.shadowColor = UIColor.black.cgColor
        summaryCardView.layer.shadowOpacity = 0.08
        summaryCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        summaryCardView.layer.shadowRadius = 8
        
        summaryTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryTitleLabel.text = "Summary"
        summaryTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        
        targetWeightLabel.translatesAutoresizingMaskIntoConstraints = false
        targetWeightLabel.text = "Target Weight"
        targetWeightLabel.font = .systemFont(ofSize: 15, weight: .medium)
        targetWeightLabel.textColor = .secondaryLabel
        
        targetWeightValueLabel.translatesAutoresizingMaskIntoConstraints = false
        targetWeightValueLabel.text = "\(targetWeight)kg"
        targetWeightValueLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        targetWeightValueLabel.textColor = .systemBlue
        targetWeightValueLabel.textAlignment = .right
        
        weightDifferenceLabel.translatesAutoresizingMaskIntoConstraints = false
        weightDifferenceLabel.text = "Weight Difference (from target)"
        weightDifferenceLabel.font = .systemFont(ofSize: 13, weight: .regular)
        weightDifferenceLabel.textColor = .tertiaryLabel
        
        weightDifferenceValueLabel.translatesAutoresizingMaskIntoConstraints = false
        weightDifferenceValueLabel.text = "-"
        weightDifferenceValueLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        weightDifferenceValueLabel.textColor = .systemGreen
        weightDifferenceValueLabel.textAlignment = .right
        
        summaryCardView.addSubview(summaryTitleLabel)
        summaryCardView.addSubview(targetWeightLabel)
        summaryCardView.addSubview(targetWeightValueLabel)
        summaryCardView.addSubview(weightDifferenceLabel)
        summaryCardView.addSubview(weightDifferenceValueLabel)
        contentView.addSubview(summaryCardView)
        
        NSLayoutConstraint.activate([
            summaryTitleLabel.topAnchor.constraint(equalTo: summaryCardView.topAnchor, constant: 18),
            summaryTitleLabel.leadingAnchor.constraint(equalTo: summaryCardView.leadingAnchor, constant: 18),
            
            targetWeightLabel.topAnchor.constraint(equalTo: summaryTitleLabel.bottomAnchor, constant: 16),
            targetWeightLabel.leadingAnchor.constraint(equalTo: summaryCardView.leadingAnchor, constant: 18),
            
            targetWeightValueLabel.centerYAnchor.constraint(equalTo: targetWeightLabel.centerYAnchor),
            targetWeightValueLabel.trailingAnchor.constraint(equalTo: summaryCardView.trailingAnchor, constant: -18),
            
            weightDifferenceLabel.topAnchor.constraint(equalTo: targetWeightLabel.bottomAnchor, constant: 16),
            weightDifferenceLabel.leadingAnchor.constraint(equalTo: summaryCardView.leadingAnchor, constant: 18),
            
            weightDifferenceValueLabel.topAnchor.constraint(equalTo: weightDifferenceLabel.bottomAnchor, constant: 6),
            weightDifferenceValueLabel.trailingAnchor.constraint(equalTo: summaryCardView.trailingAnchor, constant: -18),
            weightDifferenceValueLabel.bottomAnchor.constraint(equalTo: summaryCardView.bottomAnchor, constant: -18)
        ])
    }
    
    private func setupGraph() {
        graphView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(graphView)
    }
    
    private func setupConstraints() {
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
            
            backButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            dateCardView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            dateCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dateCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            dateLabel.topAnchor.constraint(equalTo: dateCardView.topAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: dateCardView.leadingAnchor, constant: 20),
            dateLabel.trailingAnchor.constraint(equalTo: dateCardView.trailingAnchor, constant: -20),
            
            weekScrollView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 20),
            weekScrollView.leadingAnchor.constraint(equalTo: dateCardView.leadingAnchor, constant: 20),
            weekScrollView.trailingAnchor.constraint(equalTo: dateCardView.trailingAnchor, constant: -20),
            weekScrollView.heightAnchor.constraint(equalToConstant: 56),
            
            weekStackView.topAnchor.constraint(equalTo: weekScrollView.topAnchor),
            weekStackView.leadingAnchor.constraint(equalTo: weekScrollView.leadingAnchor),
            weekStackView.trailingAnchor.constraint(equalTo: weekScrollView.trailingAnchor),
            weekStackView.bottomAnchor.constraint(equalTo: weekScrollView.bottomAnchor),
            weekStackView.heightAnchor.constraint(equalTo: weekScrollView.heightAnchor),
            
            previousWeightLabel.topAnchor.constraint(equalTo: weekScrollView.bottomAnchor, constant: 24),
            previousWeightLabel.leadingAnchor.constraint(equalTo: dateCardView.leadingAnchor, constant: 20),
            previousWeightLabel.bottomAnchor.constraint(equalTo: dateCardView.bottomAnchor, constant: -20),
            
            previousWeightValueLabel.centerYAnchor.constraint(equalTo: previousWeightLabel.centerYAnchor),
            previousWeightValueLabel.trailingAnchor.constraint(equalTo: dateCardView.trailingAnchor, constant: -20),
            
            weightInputCardView.topAnchor.constraint(equalTo: dateCardView.bottomAnchor, constant: 20),
            weightInputCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            weightInputCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            
            warningView.topAnchor.constraint(equalTo: weightInputCardView.bottomAnchor, constant: 20),
            warningView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            warningView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            warningIcon.topAnchor.constraint(equalTo: warningView.topAnchor, constant: 16),
            warningIcon.leadingAnchor.constraint(equalTo: warningView.leadingAnchor, constant: 16),
            
            warningLabel.topAnchor.constraint(equalTo: warningView.topAnchor, constant: 16),
            warningLabel.leadingAnchor.constraint(equalTo: warningIcon.trailingAnchor, constant: 12),
            warningLabel.trailingAnchor.constraint(equalTo: warningView.trailingAnchor, constant: -16),
            warningLabel.bottomAnchor.constraint(equalTo: warningView.bottomAnchor, constant: -16),
            
            summaryCardView.topAnchor.constraint(equalTo: warningView.bottomAnchor, constant: 20),
            summaryCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            summaryCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            graphView.topAnchor.constraint(equalTo: summaryCardView.bottomAnchor, constant: 20),
            graphView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            graphView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            graphView.heightAnchor.constraint(equalToConstant: 280),
            graphView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Data Setup
    private func setupData() {
        // Generate week data for the past month
        let calendar = Calendar.current
        let today = Date()
        
        // Generate sample data for past 30 days
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let hasEntry = i % 3 != 0 // Some days have entries
                let weight = hasEntry ? 65.0 + Double.random(in: -2...3) : nil
                weekDays.insert(DayData(date: date, hasEntry: hasEntry, weight: weight), at: 0)
                
                if let weight = weight {
                    let bmi = calculateBMI(weight: weight)
                    let entry = WeightEntry(date: date, weight: weight, bmi: bmi, isPreDialysis: i % 2 == 0)
                    weightEntries[date] = entry
                }
            }
        }
        
        setupWeekDayButtons()
        updateGraphData()
    }
    
    private func setupWeekDayButtons() {
        weekStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Show last 7 days
        let visibleDays = Array(weekDays.suffix(7))
        
        for dayData in visibleDays {
            let dayView = createDayView(for: dayData)
            weekStackView.addArrangedSubview(dayView)
        }
    }
    
    private func createDayView(for dayData: DayData) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let dayLabel = UILabel()
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        dayLabel.font = .systemFont(ofSize: 11, weight: .medium)
        dayLabel.textColor = .tertiaryLabel
        dayLabel.textAlignment = .center
        
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        dayLabel.text = formatter.string(from: dayData.date).prefix(1).uppercased()
        
        let circleView = UIView()
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.layer.cornerRadius = 16
        circleView.backgroundColor = dayData.hasEntry ? UIColor(red: 0.4, green: 0.7, blue: 0.4, alpha: 1.0) : UIColor(white: 0.90, alpha: 1.0)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dayTapped(_:)))
        circleView.addGestureRecognizer(tapGesture)
        circleView.isUserInteractionEnabled = true
        circleView.tag = Int(dayData.date.timeIntervalSince1970)
        
        container.addSubview(dayLabel)
        container.addSubview(circleView)
        
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 40),
            
            dayLabel.topAnchor.constraint(equalTo: container.topAnchor),
            dayLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            circleView.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 6),
            circleView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            circleView.widthAnchor.constraint(equalToConstant: 32),
            circleView.heightAnchor.constraint(equalToConstant: 32),
            circleView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    // MARK: - Actions
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func dayTapped(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else { return }
        let date = Date(timeIntervalSince1970: TimeInterval(tag))
        selectedDate = date
        
        if let dayData = weekDays.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }),
           let weight = dayData.weight {
            previousWeightValueLabel.text = String(format: "%.1fkg", weight)
        } else {
            previousWeightValueLabel.text = "No data"
        }
        
        updateDateLabel()
    }
    
    @objc private func weightChanged() {
        guard let text = weightTextField.text,
              let weight = Double(text) else {
            bmiValueLabel.text = "-"
            return
        }
        
        let bmi = calculateBMI(weight: weight)
        bmiValueLabel.text = String(format: "%.1f", bmi)
        
        updateWarnings(weight: weight, bmi: bmi)
        updateSummary(weight: weight)
    }
    @objc private func saveWeight() {
        guard let text = weightTextField.text,
              let weight = Double(text) else {
            // Show alert - invalid input
            let alert = UIAlertController(title: "Invalid Weight", message: "Please enter a valid weight value.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Calculate BMI
        let bmi = calculateBMI(weight: weight)
        
        // Create new entry
        let entry = WeightEntry(
            date: selectedDate,
            weight: weight,
            bmi: bmi,
            isPreDialysis: true  // You can add a toggle for this if needed
        )
        
        // Save to weightEntries
        weightEntries[selectedDate] = entry
        
        // Update the week days data
        if let index = weekDays.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
            weekDays[index].hasEntry = true
            weekDays[index].weight = weight
        }
        
        // Refresh UI
        setupWeekDayButtons()
        updateGraphData()
        
        // Show success feedback
        let alert = UIAlertController(title: "Saved", message: "Weight recorded successfully!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        // Clear the text field
        weightTextField.text = ""
        bmiValueLabel.text = "-"
    }
    
    // MARK: - Calculations
    private func calculateBMI(weight: Double) -> Double {
        let heightInMeters = userHeight / 100.0
        return weight / (heightInMeters * heightInMeters)
    }
    
    private func updateWarnings(weight: Double, bmi: Double) {
        var warnings: [String] = []
        
        // BMI check (normal range 18.5 - 24.9)
        if bmi < 18.5 {
            warnings.append("BMI is below normal range. Consider consulting your care team.")
        } else if bmi > 24.9 {
            warnings.append("BMI exceeds normal range. Monitor your weight closely.")
        }
        
        // Weight gain check
        if let previousWeight = getPreviousWeight() {
            let difference = weight - previousWeight
            if difference > 2.0 {
                warnings.append("Possible weight overload – gained \(String(format: "%.1f", difference)) kg since last dialysis. Contact your care team.")
            }
        }
        
        if warnings.isEmpty {
            warningView.isHidden = true
        } else {
            warningView.isHidden = false
            warningLabel.text = warnings.joined(separator: "\n\n")
        }
    }
    
    private func updateSummary(weight: Double) {
        // Weight difference from target
        let difference = weight - targetWeight
        weightDifferenceValueLabel.text = String(format: "%.1fkg", abs(difference))
        
        if difference > 0 {
            weightDifferenceValueLabel.textColor = .systemRed
            weightDifferenceLabel.text = "Above Target"
        } else if difference < 0 {
            weightDifferenceValueLabel.textColor = .systemGreen
            weightDifferenceLabel.text = "Below Target"
        } else {
            weightDifferenceValueLabel.textColor = .systemGreen
            weightDifferenceLabel.text = "At Target Weight!"
        }
    }
    
    private func getPreviousWeight() -> Double? {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: selectedDate) else {
            return nil
        }
        
        // Find the most recent weight entry before today
        let sortedDates = weightEntries.keys.sorted()
        for date in sortedDates.reversed() {
            if date < selectedDate, let entry = weightEntries[date] {
                return entry.weight
            }
        }
        return nil
    }
    
    private func updateUI() {
        updateDateLabel()
    }
    
    private func updateDateLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd MMMM"
        dateLabel.text = formatter.string(from: selectedDate)
    }
    
    private func updateGraphData() {
        let calendar = Calendar.current
        var preDialysisData: [(Date, Double)] = []
        var postDialysisData: [(Date, Double)] = []
        
        // Get last 7 days of data
        let sortedDates = weightEntries.keys.sorted().suffix(7)
        
        for date in sortedDates {
            if let entry = weightEntries[date], let weight = entry.weight {
                if entry.isPreDialysis {
                    preDialysisData.append((date, weight))
                } else {
                    postDialysisData.append((date, weight))
                }
            }
        }
        
        graphView.updateData(preDialysis: preDialysisData, postDialysis: postDialysisData, dryWeight: dryWeight)
    }
}

// MARK: - Weight Graph View
class WeightGraphView: UIView {
    
    private var preDialysisData: [(Date, Double)] = []
    private var postDialysisData: [(Date, Double)] = []
    private var dryWeight: Double = 64.0
    
    private let titleLabel = UILabel()
    private let dryWeightLabel = UILabel()
    private let legendStackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Weight Trend"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        
        dryWeightLabel.translatesAutoresizingMaskIntoConstraints = false
        dryWeightLabel.text = "64.0 kg (Target)"
        dryWeightLabel.font = .systemFont(ofSize: 13, weight: .regular)
        dryWeightLabel.textColor = .secondaryLabel
        
        legendStackView.translatesAutoresizingMaskIntoConstraints = false
        legendStackView.axis = .horizontal
        legendStackView.spacing = 20
        legendStackView.distribution = .fillEqually
        
        let preDialysisLegend = createLegendItem(color: .systemBlue, text: "Pre-dialysis Weight")
        let postDialysisLegend = createLegendItem(color: .systemGreen, text: "Post-dialysis Weight")
        
        legendStackView.addArrangedSubview(preDialysisLegend)
        legendStackView.addArrangedSubview(postDialysisLegend)
        
        addSubview(titleLabel)
        addSubview(dryWeightLabel)
        addSubview(legendStackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            dryWeightLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            dryWeightLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            legendStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            legendStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            legendStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])
    }
    
    private func createLegendItem(color: UIColor, text: String) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 8
        container.alignment = .center
        
        let colorView = UIView()
        colorView.backgroundColor = color
        colorView.layer.cornerRadius = 4
        colorView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = .secondaryLabel
        
        container.addArrangedSubview(colorView)
        container.addArrangedSubview(label)
        
        NSLayoutConstraint.activate([
            colorView.widthAnchor.constraint(equalToConstant: 20),
            colorView.heightAnchor.constraint(equalToConstant: 4)
        ])
        
        return container
    }
    
    func updateData(preDialysis: [(Date, Double)], postDialysis: [(Date, Double)], dryWeight: Double) {
        self.preDialysisData = preDialysis
        self.postDialysisData = postDialysis
        self.dryWeight = dryWeight
        
        dryWeightLabel.text = String(format: "%.1f kg (Target)", dryWeight)
        
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard !preDialysisData.isEmpty || !postDialysisData.isEmpty else { return }
        
        let graphRect = CGRect(x: 40, y: 80, width: rect.width - 60, height: rect.height - 100)
        
        // Find min and max values
        var allWeights: [Double] = []
        allWeights.append(contentsOf: preDialysisData.map { $0.1 })
        allWeights.append(contentsOf: postDialysisData.map { $0.1 })
        allWeights.append(dryWeight)
        
        guard let minWeight = allWeights.min(),
              let maxWeight = allWeights.max() else { return }
        
        let padding: Double = 2.0
        let minY = minWeight - padding
        let maxY = maxWeight + padding
        let rangeY = maxY - minY
        
        // Draw Y-axis labels
        drawYAxisLabels(in: graphRect, minY: minY, maxY: maxY)
        
        // Draw X-axis labels (days)
        drawXAxisLabels(in: graphRect)
        
        // Draw grid lines
        drawGridLines(in: graphRect)
        
        // Draw lines
        if preDialysisData.count > 1 {
            drawLine(data: preDialysisData, in: graphRect, minY: minY, rangeY: rangeY, color: .systemBlue)
        }
        
        if postDialysisData.count > 1 {
            drawLine(data: postDialysisData, in: graphRect, minY: minY, rangeY: rangeY, color: .systemGreen)
        }
        
        // Draw data points
        drawPoints(data: preDialysisData, in: graphRect, minY: minY, rangeY: rangeY, color: .systemBlue)
        drawPoints(data: postDialysisData, in: graphRect, minY: minY, rangeY: rangeY, color: .systemGreen)
    }
    
    private func drawYAxisLabels(in rect: CGRect, minY: Double, maxY: Double) {
        let labels = [maxY, (maxY + minY) / 2, minY]
        let positions = [rect.minY, rect.midY, rect.maxY]
        
        for (label, position) in zip(labels, positions) {
            let text = String(format: "%.0f", label)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]
            let size = (text as NSString).size(withAttributes: attributes)
            let point = CGPoint(x: rect.minX - size.width - 8, y: position - size.height / 2)
            (text as NSString).draw(at: point, withAttributes: attributes)
        }
    }
    
    private func drawXAxisLabels(in rect: CGRect) {
        let days = ["S", "M", "W", "T", "F", "S"]
        let spacing = rect.width / CGFloat(days.count - 1)
        
        for (index, day) in days.enumerated() {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]
            let size = (day as NSString).size(withAttributes: attributes)
            let x = rect.minX + CGFloat(index) * spacing - size.width / 2
            let y = rect.maxY + 8
            (day as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attributes)
        }
    }
    
    private func drawGridLines(in rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setStrokeColor(UIColor(white: 0.9, alpha: 1.0).cgColor)
        context.setLineWidth(0.5)
        
        // Horizontal lines
        for i in 0...2 {
            let y = rect.minY + rect.height * CGFloat(i) / 2
            context.move(to: CGPoint(x: rect.minX, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        
        context.strokePath()
    }
    
    private func drawLine(data: [(Date, Double)], in rect: CGRect, minY: Double, rangeY: Double, color: UIColor) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(2.0)
        
        let spacing = rect.width / CGFloat(data.count - 1)
        
        for (index, point) in data.enumerated() {
            let x = rect.minX + CGFloat(index) * spacing
            let normalizedY = (point.1 - minY) / rangeY
            let y = rect.maxY - (normalizedY * rect.height)
            
            if index == 0 {
                context.move(to: CGPoint(x: x, y: y))
            } else {
                context.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        context.strokePath()
    }
    
    private func drawPoints(data: [(Date, Double)], in rect: CGRect, minY: Double, rangeY: Double, color: UIColor) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let spacing = rect.width / CGFloat(max(1, data.count - 1))
        
        for (index, point) in data.enumerated() {
            let x = rect.minX + CGFloat(index) * spacing
            let normalizedY = (point.1 - minY) / rangeY
            let y = rect.maxY - (normalizedY * rect.height)
            
            context.setFillColor(color.cgColor)
            context.fillEllipse(in: CGRect(x: x - 4, y: y - 4, width: 8, height: 8))
            
            context.setStrokeColor(UIColor.white.cgColor)
            context.setLineWidth(2)
            context.strokeEllipse(in: CGRect(x: x - 4, y: y - 4, width: 8, height: 8))
        }
    }
}
