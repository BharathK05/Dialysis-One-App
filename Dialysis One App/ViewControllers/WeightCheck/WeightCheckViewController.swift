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
    var isDialysisDay: Bool = false
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
    private let datePickerScrollView = UIScrollView()
    private let datePickerStackView = UIStackView()
    private let previousWeightContainer = UIView()
    private let previousWeightLabel = UILabel()
    private let previousWeightValueLabel = UILabel()
    private let previousWeightChevron = UIImageView()
    
    // Section 2: Weight Input
    private let weightInputCardView = UIView()
    private let weightLabel = UILabel()
    private let weightTextField = UITextField()
    private let bmiLabel = UILabel()
    private let bmiTextField = UITextField()
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
    
    // Graph
    private let graphView = WeightGraphView()
    
    // Data
    private var weekDays: [DayData] = []
    private var selectedDate: Date = Date()
    private var weightEntries: [Date: WeightEntry] = [:]
    private let userHeight: Double = 170.0
    private let targetWeight: Double = 64.0
    private var dryWeight: Double = 64.0
    
    // Colors - Modern purple/blue theme
    private let primaryColor = UIColor(red: 0.42, green: 0.45, blue: 0.76, alpha: 1.0)
    private let accentColor = UIColor(red: 0.35, green: 0.60, blue: 0.85, alpha: 1.0)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
        updateUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0)
        
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
        scrollView.contentInsetAdjustmentBehavior = .never
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        let backImage = UIImage(systemName: "chevron.left")
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = .label
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
        dateCardView.layer.shadowOpacity = 0.06
        dateCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        dateCardView.layer.shadowRadius = 12
        
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .systemFont(ofSize: 15, weight: .medium)
        dateLabel.textColor = .secondaryLabel
        dateLabel.textAlignment = .left
        
        datePickerScrollView.translatesAutoresizingMaskIntoConstraints = false
        datePickerScrollView.showsHorizontalScrollIndicator = false
        
        datePickerStackView.translatesAutoresizingMaskIntoConstraints = false
        datePickerStackView.axis = .horizontal
        datePickerStackView.spacing = 8
        datePickerStackView.distribution = .equalSpacing
        
        // Previous weight container
        previousWeightContainer.translatesAutoresizingMaskIntoConstraints = false
        previousWeightContainer.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0)
        previousWeightContainer.layer.cornerRadius = 12
        
        previousWeightLabel.translatesAutoresizingMaskIntoConstraints = false
        previousWeightLabel.text = "Previous Weight"
        previousWeightLabel.font = .systemFont(ofSize: 13, weight: .medium)
        previousWeightLabel.textColor = .secondaryLabel
        
        previousWeightValueLabel.translatesAutoresizingMaskIntoConstraints = false
        previousWeightValueLabel.text = "No data"
        previousWeightValueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        previousWeightValueLabel.textColor = .label
        
        previousWeightChevron.translatesAutoresizingMaskIntoConstraints = false
        previousWeightChevron.image = UIImage(systemName: "chevron.right")
        previousWeightChevron.tintColor = .tertiaryLabel
        previousWeightChevron.contentMode = .scaleAspectFit
        
        previousWeightContainer.addSubview(previousWeightLabel)
        previousWeightContainer.addSubview(previousWeightValueLabel)
        previousWeightContainer.addSubview(previousWeightChevron)
        
        datePickerScrollView.addSubview(datePickerStackView)
        dateCardView.addSubview(dateLabel)
        dateCardView.addSubview(datePickerScrollView)
        dateCardView.addSubview(previousWeightContainer)
        contentView.addSubview(dateCardView)
        
        NSLayoutConstraint.activate([
            previousWeightLabel.topAnchor.constraint(equalTo: previousWeightContainer.topAnchor, constant: 12),
            previousWeightLabel.leadingAnchor.constraint(equalTo: previousWeightContainer.leadingAnchor, constant: 16),
            
            previousWeightValueLabel.topAnchor.constraint(equalTo: previousWeightLabel.bottomAnchor, constant: 4),
            previousWeightValueLabel.leadingAnchor.constraint(equalTo: previousWeightContainer.leadingAnchor, constant: 16),
            previousWeightValueLabel.bottomAnchor.constraint(equalTo: previousWeightContainer.bottomAnchor, constant: -12),
            
            previousWeightChevron.centerYAnchor.constraint(equalTo: previousWeightContainer.centerYAnchor),
            previousWeightChevron.trailingAnchor.constraint(equalTo: previousWeightContainer.trailingAnchor, constant: -16),
            previousWeightChevron.widthAnchor.constraint(equalToConstant: 12),
            previousWeightChevron.heightAnchor.constraint(equalToConstant: 12),
            
            previousWeightContainer.topAnchor.constraint(equalTo: datePickerScrollView.bottomAnchor, constant: 16),
            previousWeightContainer.leadingAnchor.constraint(equalTo: dateCardView.leadingAnchor, constant: 20),
            previousWeightContainer.trailingAnchor.constraint(equalTo: dateCardView.trailingAnchor, constant: -20),
            previousWeightContainer.bottomAnchor.constraint(equalTo: dateCardView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupWeightInputCard() {
        weightInputCardView.translatesAutoresizingMaskIntoConstraints = false
        weightInputCardView.backgroundColor = .white
        weightInputCardView.layer.cornerRadius = 16
        weightInputCardView.layer.shadowColor = UIColor.black.cgColor
        weightInputCardView.layer.shadowOpacity = 0.06
        weightInputCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        weightInputCardView.layer.shadowRadius = 12
        
        let weightInputContainer = UIView()
        weightInputContainer.translatesAutoresizingMaskIntoConstraints = false
        weightInputContainer.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0)
        weightInputContainer.layer.cornerRadius = 12
        weightInputContainer.layer.borderWidth = 1
        weightInputContainer.layer.borderColor = UIColor(red: 0.42, green: 0.45, blue: 0.76, alpha: 0.15).cgColor
        
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
        weightTextField.tintColor = primaryColor
        weightTextField.borderStyle = .none
        weightTextField.addTarget(self, action: #selector(weightChanged), for: .editingChanged)
        
        let kgLabel = UILabel()
        kgLabel.text = " kg"
        kgLabel.font = .systemFont(ofSize: 17, weight: .regular)
        kgLabel.textColor = .secondaryLabel
        kgLabel.sizeToFit()
        weightTextField.rightView = kgLabel
        weightTextField.rightViewMode = .always
        
        let bmiInputContainer = UIView()
        bmiInputContainer.translatesAutoresizingMaskIntoConstraints = false
        bmiInputContainer.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0)
        bmiInputContainer.layer.cornerRadius = 12
        bmiInputContainer.layer.borderWidth = 1
        bmiInputContainer.layer.borderColor = UIColor(red: 0.42, green: 0.45, blue: 0.76, alpha: 0.15).cgColor
        
        bmiLabel.translatesAutoresizingMaskIntoConstraints = false
        bmiLabel.text = "BMI"
        bmiLabel.font = .systemFont(ofSize: 15, weight: .medium)
        bmiLabel.textColor = .secondaryLabel
        
        bmiTextField.translatesAutoresizingMaskIntoConstraints = false
        bmiTextField.font = .systemFont(ofSize: 17, weight: .semibold)
        bmiTextField.textAlignment = .right
        bmiTextField.text = "-"
        bmiTextField.textColor = .label
        bmiTextField.isUserInteractionEnabled = false
        bmiTextField.borderStyle = .none
        
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Save", for: .normal)
        saveButton.backgroundColor = primaryColor
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(self, action: #selector(saveWeight), for: .touchUpInside)
        
        weightInputContainer.addSubview(weightLabel)
        weightInputContainer.addSubview(weightTextField)
        bmiInputContainer.addSubview(bmiLabel)
        bmiInputContainer.addSubview(bmiTextField)
        
        weightInputCardView.addSubview(weightInputContainer)
        weightInputCardView.addSubview(bmiInputContainer)
        weightInputCardView.addSubview(saveButton)
        contentView.addSubview(weightInputCardView)
        
        NSLayoutConstraint.activate([
            weightInputContainer.topAnchor.constraint(equalTo: weightInputCardView.topAnchor, constant: 16),
            weightInputContainer.leadingAnchor.constraint(equalTo: weightInputCardView.leadingAnchor, constant: 16),
            weightInputContainer.trailingAnchor.constraint(equalTo: weightInputCardView.trailingAnchor, constant: -16),
            weightInputContainer.heightAnchor.constraint(equalToConstant: 56),
            
            weightLabel.leadingAnchor.constraint(equalTo: weightInputContainer.leadingAnchor, constant: 16),
            weightLabel.centerYAnchor.constraint(equalTo: weightInputContainer.centerYAnchor),
            
            weightTextField.trailingAnchor.constraint(equalTo: weightInputContainer.trailingAnchor, constant: -16),
            weightTextField.centerYAnchor.constraint(equalTo: weightInputContainer.centerYAnchor),
            weightTextField.leadingAnchor.constraint(equalTo: weightLabel.trailingAnchor, constant: 16),
            
            bmiInputContainer.topAnchor.constraint(equalTo: weightInputContainer.bottomAnchor, constant: 12),
            bmiInputContainer.leadingAnchor.constraint(equalTo: weightInputCardView.leadingAnchor, constant: 16),
            bmiInputContainer.trailingAnchor.constraint(equalTo: weightInputCardView.trailingAnchor, constant: -16),
            bmiInputContainer.heightAnchor.constraint(equalToConstant: 56),
            
            bmiLabel.leadingAnchor.constraint(equalTo: bmiInputContainer.leadingAnchor, constant: 16),
            bmiLabel.centerYAnchor.constraint(equalTo: bmiInputContainer.centerYAnchor),
            
            bmiTextField.trailingAnchor.constraint(equalTo: bmiInputContainer.trailingAnchor, constant: -16),
            bmiTextField.centerYAnchor.constraint(equalTo: bmiInputContainer.centerYAnchor),
            bmiTextField.leadingAnchor.constraint(equalTo: bmiLabel.trailingAnchor, constant: 16),
            
            saveButton.topAnchor.constraint(equalTo: bmiInputContainer.bottomAnchor, constant: 16),
            saveButton.leadingAnchor.constraint(equalTo: weightInputCardView.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: weightInputCardView.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: weightInputCardView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupWarningBanner() {
        warningView.translatesAutoresizingMaskIntoConstraints = false
        warningView.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.80, alpha: 1.0)
        warningView.layer.cornerRadius = 12
        warningView.layer.borderWidth = 1
        warningView.layer.borderColor = UIColor(red: 1.0, green: 0.85, blue: 0.5, alpha: 0.3).cgColor
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
        summaryCardView.layer.shadowOpacity = 0.06
        summaryCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        summaryCardView.layer.shadowRadius = 12
        
        summaryTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryTitleLabel.text = "Summary"
        summaryTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        
        targetWeightLabel.translatesAutoresizingMaskIntoConstraints = false
        targetWeightLabel.text = "Target"
        targetWeightLabel.font = .systemFont(ofSize: 15, weight: .medium)
        targetWeightLabel.textColor = .secondaryLabel
        
        targetWeightValueLabel.translatesAutoresizingMaskIntoConstraints = false
        targetWeightValueLabel.text = "\(targetWeight)kg"
        targetWeightValueLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        targetWeightValueLabel.textColor = accentColor
        targetWeightValueLabel.textAlignment = .right
        
        weightDifferenceLabel.translatesAutoresizingMaskIntoConstraints = false
        weightDifferenceLabel.text = "Weight Difference (from target)"
        weightDifferenceLabel.font = .systemFont(ofSize: 13, weight: .regular)
        weightDifferenceLabel.textColor = .tertiaryLabel
        
        weightDifferenceValueLabel.translatesAutoresizingMaskIntoConstraints = false
        weightDifferenceValueLabel.text = "-"
        weightDifferenceValueLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        weightDifferenceValueLabel.textColor = primaryColor
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
            
            dateCardView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 28),
            dateCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dateCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            dateLabel.topAnchor.constraint(equalTo: dateCardView.topAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: dateCardView.leadingAnchor, constant: 20),
            dateLabel.trailingAnchor.constraint(equalTo: dateCardView.trailingAnchor, constant: -20),
            
            datePickerScrollView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 16),
            datePickerScrollView.leadingAnchor.constraint(equalTo: dateCardView.leadingAnchor, constant: 20),
            datePickerScrollView.trailingAnchor.constraint(equalTo: dateCardView.trailingAnchor, constant: -20),
            datePickerScrollView.heightAnchor.constraint(equalToConstant: 70),
            
            datePickerStackView.topAnchor.constraint(equalTo: datePickerScrollView.topAnchor),
            datePickerStackView.leadingAnchor.constraint(equalTo: datePickerScrollView.leadingAnchor),
            datePickerStackView.trailingAnchor.constraint(equalTo: datePickerScrollView.trailingAnchor),
            datePickerStackView.bottomAnchor.constraint(equalTo: datePickerScrollView.bottomAnchor),
            datePickerStackView.heightAnchor.constraint(equalTo: datePickerScrollView.heightAnchor),
            
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
            
            summaryCardView.topAnchor.constraint(equalTo: warningView.bottomAnchor, constant: 16),
            summaryCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            summaryCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            graphView.topAnchor.constraint(equalTo: summaryCardView.bottomAnchor, constant: 16),
            graphView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            graphView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            graphView.heightAnchor.constraint(equalToConstant: 280),
            graphView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    // MARK: - Data Setup
    private func setupData() {
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<14 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let hasEntry = i % 3 != 0
                let weight = hasEntry ? 65.0 + Double.random(in: -2...3) : nil
                let isDialysisDay = i % 3 == 0 // Every 3rd day is dialysis
                
                weekDays.insert(DayData(date: date, hasEntry: hasEntry, weight: weight, isDialysisDay: isDialysisDay), at: 0)
                
                if let weight = weight {
                    let bmi = calculateBMI(weight: weight)
                    let entry = WeightEntry(date: date, weight: weight, bmi: bmi, isPreDialysis: i % 2 == 0)
                    weightEntries[normalizeDate(date)] = entry
                }
            }
        }
        
        setupDatePickerButtons()
        updateGraphData()
    }
    
    private func normalizeDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: date)
    }
    
    private func setupDatePickerButtons() {
        datePickerStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for dayData in weekDays {
            let dayView = createModernDayView(for: dayData)
            datePickerStackView.addArrangedSubview(dayView)
        }
    }
    
    private func createModernDayView(for dayData: DayData) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let isSelected = Calendar.current.isDate(dayData.date, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDate(dayData.date, inSameDayAs: Date())
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "E"
        let dayName = dayFormatter.string(from: dayData.date).prefix(3).uppercased()
        
        let dayLabel = UILabel()
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        dayLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        dayLabel.textColor = isSelected ? primaryColor : (isToday ? .systemRed : .secondaryLabel)
        dayLabel.textAlignment = .center
        dayLabel.text = String(dayName)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        let dateNumber = dateFormatter.string(from: dayData.date)
        
        let dateButton = UIButton()
        dateButton.translatesAutoresizingMaskIntoConstraints = false
        dateButton.setTitle(dateNumber, for: .normal)
        dateButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        dateButton.tag = Int(dayData.date.timeIntervalSince1970)
        dateButton.addTarget(self, action: #selector(dayTapped(_:)), for: .touchUpInside)
        
        if isSelected {
            dateButton.backgroundColor = primaryColor
            dateButton.setTitleColor(.white, for: .normal)
        } else {
            dateButton.backgroundColor = isToday ? UIColor.systemRed.withAlphaComponent(0.1) : UIColor(white: 0.95, alpha: 1.0)
            dateButton.setTitleColor(isToday ? .systemRed : .label, for: .normal)
        }
        
        dateButton.layer.cornerRadius = 22
        
        let dotView = UIView()
        dotView.translatesAutoresizingMaskIntoConstraints = false
        dotView.backgroundColor = dayData.hasEntry ? primaryColor : .clear
        dotView.layer.cornerRadius = 3
        dotView.alpha = isSelected ? 0 : 1
        
        container.addSubview(dayLabel)
        container.addSubview(dateButton)
        container.addSubview(dotView)
        
        NSLayoutConstraint.activate([
            dayLabel.topAnchor.constraint(equalTo: container.topAnchor),
            dayLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            dateButton.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 4),
            dateButton.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            dateButton.widthAnchor.constraint(equalToConstant: 44),
            dateButton.heightAnchor.constraint(equalToConstant: 44),
            
            dotView.topAnchor.constraint(equalTo: dateButton.bottomAnchor, constant: 4),
            dotView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            dotView.widthAnchor.constraint(equalToConstant: 6),
            dotView.heightAnchor.constraint(equalToConstant: 6),
            dotView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            container.widthAnchor.constraint(equalToConstant: 52)
        ])
        
        return container
    }
    
    // MARK: - Actions
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func dayTapped(_ sender: UIButton) {
        let timestamp = TimeInterval(sender.tag)
        selectedDate = Date(timeIntervalSince1970: timestamp)
        updateUI()
    }
    
    @objc private func weightChanged() {
        guard let text = weightTextField.text,
              let weight = Double(text) else {
            bmiTextField.text = "-"
            return
        }
        
        let bmi = calculateBMI(weight: weight)
        bmiTextField.text = String(format: "%.1f", bmi)
        
        let difference = weight - dryWeight
        if difference > 2.0 {
            warningView.isHidden = false
            warningLabel.text = "Your weight is \(String(format: "%.1f", difference))kg over your dry weight. Please consult with your healthcare provider."
        } else {
            warningView.isHidden = true
        }
    }
    
    @objc private func saveWeight() {
        guard let text = weightTextField.text,
              let weight = Double(text) else {
            showAlert(message: "Please enter a valid weight")
            return
        }
        
        let bmi = calculateBMI(weight: weight)
        let normalizedDate = normalizeDate(selectedDate)
        let entry = WeightEntry(date: normalizedDate, weight: weight, bmi: bmi, isPreDialysis: true)
        
        weightEntries[normalizedDate] = entry
        
        if let index = weekDays.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
            weekDays[index].hasEntry = true
            weekDays[index].weight = weight
        }
        
        updateUI()
        updateGraphData()
        view.endEditing(true)
        showSuccessMessage()
    }
    
    // MARK: - UI Updates
    private func updateUI() {
        setupDatePickerButtons()
        updateDateLabel()
        updatePreviousWeight()
        updateWeightInput()
        updateSummary()
    }
    
    private func updateDateLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        dateLabel.text = formatter.string(from: selectedDate)
    }
    
    private func updatePreviousWeight() {
        let calendar = Calendar.current
        var previousWeight: Double?
        
        for i in 1...14 {
            if let previousDate = calendar.date(byAdding: .day, value: -i, to: selectedDate) {
                let normalized = normalizeDate(previousDate)
                if let entry = weightEntries[normalized], let weight = entry.weight {
                    previousWeight = weight
                    break
                }
            }
        }
        
        if let weight = previousWeight {
            previousWeightValueLabel.text = String(format: "%.1f kg", weight)
        } else {
            previousWeightValueLabel.text = "No data"
        }
    }
    
    private func updateWeightInput() {
        let normalizedDate = normalizeDate(selectedDate)
        
        if let entry = weightEntries[normalizedDate] {
            if let weight = entry.weight {
                weightTextField.text = String(format: "%.1f", weight)
            }
            if let bmi = entry.bmi {
                bmiTextField.text = String(format: "%.1f", bmi)
            }
        } else {
            weightTextField.text = ""
            bmiTextField.text = "-"
            warningView.isHidden = true
        }
    }
    
    private func updateSummary() {
        let normalizedDate = normalizeDate(selectedDate)
        
        guard let entry = weightEntries[normalizedDate],
              let currentWeight = entry.weight else {
            weightDifferenceValueLabel.text = "-"
            return
        }
        
        let difference = currentWeight - targetWeight
        let sign = difference >= 0 ? "+" : ""
        weightDifferenceValueLabel.text = "\(sign)\(String(format: "%.1f", difference)) kg"
        
        if difference > 0 {
            weightDifferenceValueLabel.textColor = .systemRed
        } else if difference < 0 {
            weightDifferenceValueLabel.textColor = .systemGreen
        } else {
            weightDifferenceValueLabel.textColor = primaryColor
        }
    }
    
    private func updateGraphData() {
        var dataPoints: [(date: Date, weight: Double, isDialysis: Bool)] = []
        
        for dayData in weekDays {
            if let weight = dayData.weight {
                dataPoints.append((date: dayData.date, weight: weight, isDialysis: dayData.isDialysisDay))
            }
        }
        
        graphView.updateData(dataPoints: dataPoints, targetWeight: targetWeight)
    }
    
    // MARK: - Helpers
    private func calculateBMI(weight: Double) -> Double {
        let heightInMeters = userHeight / 100.0
        return weight / (heightInMeters * heightInMeters)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccessMessage() {
        let alert = UIAlertController(title: "Saved", message: "Weight entry saved successfully", preferredStyle: .alert)
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
    }
}

// MARK: - Weight Graph View
class WeightGraphView: UIView {
    
    private var dataPoints: [(date: Date, weight: Double, isDialysis: Bool)] = []
    private var targetWeight: Double = 64.0
    private let titleLabel = UILabel()
    private let legendStackView = UIStackView()
    private let graphContainerView = UIView()
    
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
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 12
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Weight Trend"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        
        // Legend
        legendStackView.translatesAutoresizingMaskIntoConstraints = false
        legendStackView.axis = .horizontal
        legendStackView.spacing = 16
        legendStackView.alignment = .center
        
        let targetLegend = createLegendItem(color: UIColor(red: 0.35, green: 0.60, blue: 0.85, alpha: 1.0), text: "Target", isDashed: true)
        let dialysisLegend = createLegendItem(color: UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 1.0), text: "Dialysis", isDashed: false)
        
        legendStackView.addArrangedSubview(targetLegend)
        legendStackView.addArrangedSubview(dialysisLegend)
        
        graphContainerView.translatesAutoresizingMaskIntoConstraints = false
        graphContainerView.backgroundColor = .clear
        
        addSubview(titleLabel)
        addSubview(legendStackView)
        addSubview(graphContainerView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            
            legendStackView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            legendStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            
            graphContainerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            graphContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            graphContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            graphContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18)
        ])
    }
    
    private func createLegendItem(color: UIColor, text: String, isDashed: Bool) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = isDashed ? .clear : color
        
        if isDashed {
            let dashedLayer = CAShapeLayer()
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: 6))
            path.addLine(to: CGPoint(x: 16, y: 6))
            dashedLayer.path = path.cgPath
            dashedLayer.strokeColor = color.cgColor
            dashedLayer.lineWidth = 2
            dashedLayer.lineDashPattern = [3, 2]
            line.layer.addSublayer(dashedLayer)
        }
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        
        container.addSubview(line)
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            line.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            line.widthAnchor.constraint(equalToConstant: 16),
            line.heightAnchor.constraint(equalToConstant: 12),
            
            label.leadingAnchor.constraint(equalTo: line.trailingAnchor, constant: 4),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return container
    }
    
    func updateData(dataPoints: [(date: Date, weight: Double, isDialysis: Bool)], targetWeight: Double) {
        self.dataPoints = dataPoints
        self.targetWeight = targetWeight
        graphContainerView.setNeedsDisplay()
        graphContainerView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        graphContainerView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawGraph()
    }
    
    private func drawGraph() {
        guard !dataPoints.isEmpty else { return }
        
        let rect = graphContainerView.bounds
        let padding: CGFloat = 50
        let graphWidth = rect.width - padding * 2
        let graphHeight = rect.height - padding * 2
        let graphRect = CGRect(x: padding, y: padding, width: graphWidth, height: graphHeight)
        
        let weights = dataPoints.map { $0.weight }
        guard let minWeight = weights.min(), let maxWeight = weights.max() else { return }
        
        let adjustedMin = max(minWeight - 2, 0)
        let adjustedMax = maxWeight + 2
        
        // Draw grid lines
        drawGridLines(in: graphRect, minWeight: adjustedMin, maxWeight: adjustedMax)
        
        // Draw Y-axis labels
        drawYAxisLabels(in: graphRect, minWeight: adjustedMin, maxWeight: adjustedMax)
        
        // Draw dialysis indicators
        drawDialysisIndicators(in: graphRect, minWeight: adjustedMin, maxWeight: adjustedMax)
        
        // Draw target line
        drawTargetLine(in: graphRect, targetWeight: targetWeight, minWeight: adjustedMin, maxWeight: adjustedMax)
        
        // Draw gradient area under line
        drawGradientArea(in: graphRect, minWeight: adjustedMin, maxWeight: adjustedMax)
        
        // Draw weight line
        drawWeightLine(in: graphRect, minWeight: adjustedMin, maxWeight: adjustedMax)
        
        // Draw data points
        drawDataPoints(in: graphRect, minWeight: adjustedMin, maxWeight: adjustedMax)
        
        // Draw X-axis labels
        drawXAxisLabels(in: graphRect)
    }
    
    private func drawDialysisIndicators(in rect: CGRect, minWeight: Double, maxWeight: Double) {
        for (index, point) in dataPoints.enumerated() {
            guard point.isDialysis else { continue }
            
            let xPosition = rect.minX + (CGFloat(index) / CGFloat(dataPoints.count - 1)) * rect.width
            
            // Vertical line
            let lineLayer = CAShapeLayer()
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: xPosition, y: rect.minY))
            linePath.addLine(to: CGPoint(x: xPosition, y: rect.maxY))
            
            lineLayer.path = linePath.cgPath
            lineLayer.strokeColor = UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 0.2).cgColor
            lineLayer.lineWidth = 1.5
            
            graphContainerView.layer.insertSublayer(lineLayer, at: 0)
            
            // Label
            let label = UILabel()
            label.text = "D"
            label.font = .systemFont(ofSize: 9, weight: .bold)
            label.textColor = UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 1.0)
            label.textAlignment = .center
            label.backgroundColor = UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 0.1)
            label.layer.cornerRadius = 8
            label.layer.masksToBounds = true
            label.frame = CGRect(x: xPosition - 8, y: rect.minY - 20, width: 16, height: 16)
            
            graphContainerView.addSubview(label)
        }
    }
    
    private func drawGridLines(in rect: CGRect, minWeight: Double, maxWeight: Double) {
        let gridLayer = CAShapeLayer()
        let gridPath = UIBezierPath()
        
        // Horizontal grid lines (5 lines)
        for i in 0...4 {
            let y = rect.minY + (CGFloat(i) / 4.0) * rect.height
            gridPath.move(to: CGPoint(x: rect.minX, y: y))
            gridPath.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        
        gridLayer.path = gridPath.cgPath
        gridLayer.strokeColor = UIColor.systemGray5.cgColor
        gridLayer.lineWidth = 1
        gridLayer.lineDashPattern = [3, 3]
        
        graphContainerView.layer.addSublayer(gridLayer)
    }
    
    private func drawYAxisLabels(in rect: CGRect, minWeight: Double, maxWeight: Double) {
        let range = maxWeight - minWeight
        
        for i in 0...4 {
            let weight = maxWeight - (Double(i) / 4.0) * range
            let y = rect.minY + (CGFloat(i) / 4.0) * rect.height
            
            let label = UILabel()
            label.text = String(format: "%.0f", weight)
            label.font = .systemFont(ofSize: 11, weight: .medium)
            label.textColor = .secondaryLabel
            label.textAlignment = .right
            label.frame = CGRect(x: 0, y: y - 8, width: rect.minX - 10, height: 16)
            
            graphContainerView.addSubview(label)
        }
        
        // Add "kg" label
        let kgLabel = UILabel()
        kgLabel.text = "kg"
        kgLabel.font = .systemFont(ofSize: 10, weight: .medium)
        kgLabel.textColor = .tertiaryLabel
        kgLabel.textAlignment = .right
        kgLabel.frame = CGRect(x: 0, y: rect.minY - 24, width: rect.minX - 10, height: 16)
        
        graphContainerView.addSubview(kgLabel)
    }
    
    private func drawXAxisLabels(in rect: CGRect) {
        guard dataPoints.count > 1 else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        // Show labels for first, middle, and last points
        let indices = [0, dataPoints.count / 2, dataPoints.count - 1]
        
        for index in indices {
            let point = dataPoints[index]
            let xPosition = rect.minX + (CGFloat(index) / CGFloat(dataPoints.count - 1)) * rect.width
            
            let label = UILabel()
            label.text = dateFormatter.string(from: point.date)
            label.font = .systemFont(ofSize: 11, weight: .medium)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.frame = CGRect(x: xPosition - 30, y: rect.maxY + 8, width: 60, height: 16)
            
            graphContainerView.addSubview(label)
        }
    }
    
    private func drawTargetLine(in rect: CGRect, targetWeight: Double, minWeight: Double, maxWeight: Double) {
        let range = maxWeight - minWeight
        let yPosition = rect.maxY - CGFloat((targetWeight - minWeight) / range) * rect.height
        
        let targetLayer = CAShapeLayer()
        let targetPath = UIBezierPath()
        targetPath.move(to: CGPoint(x: rect.minX, y: yPosition))
        targetPath.addLine(to: CGPoint(x: rect.maxX, y: yPosition))
        
        targetLayer.path = targetPath.cgPath
        targetLayer.strokeColor = UIColor(red: 0.35, green: 0.60, blue: 0.85, alpha: 0.8).cgColor
        targetLayer.lineWidth = 2
        targetLayer.lineDashPattern = [6, 4]
        
        graphContainerView.layer.addSublayer(targetLayer)
    }
    
    private func drawGradientArea(in rect: CGRect, minWeight: Double, maxWeight: Double) {
        guard dataPoints.count > 1 else { return }
        
        let range = maxWeight - minWeight
        let gradientPath = UIBezierPath()
        
        // Start from bottom left
        gradientPath.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        
        // Draw to first point
        let firstX = rect.minX
        let firstY = rect.maxY - CGFloat((dataPoints[0].weight - minWeight) / range) * rect.height
        gradientPath.addLine(to: CGPoint(x: firstX, y: firstY))
        
        // Draw through all points
        for (index, point) in dataPoints.enumerated() {
            let xPosition = rect.minX + (CGFloat(index) / CGFloat(dataPoints.count - 1)) * rect.width
            let yPosition = rect.maxY - CGFloat((point.weight - minWeight) / range) * rect.height
            gradientPath.addLine(to: CGPoint(x: xPosition, y: yPosition))
        }
        
        // Complete the path
        let lastX = rect.minX + rect.width
        gradientPath.addLine(to: CGPoint(x: lastX, y: rect.maxY))
        gradientPath.close()
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = graphContainerView.bounds
        gradientLayer.colors = [
            UIColor(red: 0.42, green: 0.45, blue: 0.76, alpha: 0.15).cgColor,
            UIColor(red: 0.42, green: 0.45, blue: 0.76, alpha: 0.05).cgColor,
            UIColor(red: 0.42, green: 0.45, blue: 0.76, alpha: 0.0).cgColor
        ]
        gradientLayer.locations = [0, 0.5, 1]
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = gradientPath.cgPath
        gradientLayer.mask = shapeLayer
        
        graphContainerView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func drawWeightLine(in rect: CGRect, minWeight: Double, maxWeight: Double) {
        guard dataPoints.count > 1 else { return }
        
        let range = maxWeight - minWeight
        let linePath = UIBezierPath()
        
        for (index, point) in dataPoints.enumerated() {
            let xPosition = rect.minX + (CGFloat(index) / CGFloat(dataPoints.count - 1)) * rect.width
            let yPosition = rect.maxY - CGFloat((point.weight - minWeight) / range) * rect.height
            
            if index == 0 {
                linePath.move(to: CGPoint(x: xPosition, y: yPosition))
            } else {
                linePath.addLine(to: CGPoint(x: xPosition, y: yPosition))
            }
        }
        
        let lineLayer = CAShapeLayer()
        lineLayer.path = linePath.cgPath
        lineLayer.strokeColor = UIColor(red: 0.42, green: 0.45, blue: 0.76, alpha: 1.0).cgColor
        lineLayer.lineWidth = 3
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineCap = .round
        lineLayer.lineJoin = .round
        
        graphContainerView.layer.addSublayer(lineLayer)
    }
    
    
    private func drawDataPoints(in rect: CGRect, minWeight: Double, maxWeight: Double) {
        let range = maxWeight - minWeight
        
        for (index, point) in dataPoints.enumerated() {
            let xPosition = rect.minX + (CGFloat(index) / CGFloat(dataPoints.count - 1)) * rect.width
            let yPosition = rect.maxY - CGFloat((point.weight - minWeight) / range) * rect.height
            
            let outerCircle = CAShapeLayer()
            let outerPath = UIBezierPath(
                arcCenter: CGPoint(x: xPosition, y: yPosition),
                radius: 6,
                startAngle: 0,
                endAngle: .pi * 2,
                clockwise: true
            )
            
            outerCircle.path = outerPath.cgPath
            outerCircle.fillColor = point.isDialysis
                ? UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 0.2).cgColor
                : UIColor.white.cgColor
            
            outerCircle.strokeColor = point.isDialysis
                ? UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 1.0).cgColor
                : UIColor(red: 0.42, green: 0.45, blue: 0.76, alpha: 1.0).cgColor
            
            outerCircle.lineWidth = 3
            outerCircle.shadowColor = UIColor.black.cgColor
            outerCircle.shadowOpacity = 0.15
            outerCircle.shadowOffset = CGSize(width: 0, height: 2)
            outerCircle.shadowRadius = 4
            
            graphContainerView.layer.addSublayer(outerCircle)
        }
    }
}

