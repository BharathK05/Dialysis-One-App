import UIKit

class WeightPickerViewController: UIViewController {
    
    // MARK: - Properties
    private var currentWeight: Double = 50.0
    private var isKilogram: Bool = true
    private let minWeight: Double = 30.0
    private let maxWeight: Double = 200.0
    
    // MARK: - UI Components
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progress = 0.8
        progress.progressTintColor = UIColor(red: 106/255, green: 156/255, blue: 137/255, alpha: 1.0)
        progress.trackTintColor = UIColor.lightGray.withAlphaComponent(0.3)
        return progress
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "What's your weight?"
        label.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        label.textColor = UIColor(red: 106/255, green: 156/255, blue: 137/255, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let unitSegmentedControl: UISegmentedControl = {
        let items = ["kg", "lbs"]
        let segment = UISegmentedControl(items: items)
        segment.selectedSegmentIndex = 0
        segment.translatesAutoresizingMaskIntoConstraints = false
        segment.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        segment.selectedSegmentTintColor = UIColor(red: 106/255, green: 156/255, blue: 137/255, alpha: 1.0)
        segment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segment.setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
        return segment
    }()
    
    private let weightLabel: UILabel = {
        let label = UILabel()
        label.text = "65.0"
        label.font = UIFont.systemFont(ofSize: 72, weight: .bold)
        label.textColor = UIColor(red: 106/255, green: 156/255, blue: 137/255, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let unitLabel: UILabel = {
        let label = UILabel()
        label.text = "kg"
        label.font = UIFont.systemFont(ofSize: 32, weight: .semibold)
        label.textColor = UIColor(red: 106/255, green: 156/255, blue: 137/255, alpha: 1.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.bounces = true
        return scroll
    }()
    
    private let rulerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private let centerIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 106/255, green: 156/255, blue: 137/255, alpha: 1.0)
        view.layer.cornerRadius = 2
        return view
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        button.backgroundColor = UIColor(red: 106/255, green: 156/255, blue: 137/255, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRuler()
        setupActions()
        scrollToCurrentWeight()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        // Add subviews
        view.addSubview(progressView)
        view.addSubview(titleLabel)
        view.addSubview(unitSegmentedControl)
        view.addSubview(weightLabel)
        view.addSubview(unitLabel)
        view.addSubview(scrollView)
        view.addSubview(centerIndicator)
        view.addSubview(nextButton)
        
        scrollView.addSubview(rulerView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Progress View
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Segmented Control
            unitSegmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            unitSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            unitSegmentedControl.widthAnchor.constraint(equalToConstant: 140),
            unitSegmentedControl.heightAnchor.constraint(equalToConstant: 44),
            
            // Weight Label
            weightLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -20),
            weightLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            
            // Unit Label
            unitLabel.leadingAnchor.constraint(equalTo: weightLabel.trailingAnchor, constant: 5),
            unitLabel.bottomAnchor.constraint(equalTo: weightLabel.bottomAnchor, constant: -8),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: weightLabel.bottomAnchor, constant: 40),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 100),
            
            // Ruler View
            rulerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            rulerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            rulerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            rulerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            rulerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            
            // Center Indicator - bottom aligned
            centerIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerIndicator.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            centerIndicator.widthAnchor.constraint(equalToConstant: 4),
            centerIndicator.heightAnchor.constraint(equalToConstant: 80),
            
            // Next Button
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            nextButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupRuler() {
        let spacing: CGFloat = 4.0 // Reduced spacing for 0.1 increments
        let screenWidth = UIScreen.main.bounds.width
        let padding = screenWidth / 2
        
        let totalMarks = Int((maxWeight - minWeight) * 10) // 0.1 increments for visual
        let totalWidth = CGFloat(totalMarks) * spacing + padding * 2
        
        for i in 0...totalMarks {
            let weight = minWeight + Double(i) / 10.0 // 0.1 increments
            let xPosition = padding + CGFloat(i) * spacing
            
            let markView = UIView()
            markView.backgroundColor = UIColor.lightGray
            markView.translatesAutoresizingMaskIntoConstraints = false
            
            // Different heights based on increment type
            let isFullUnit = Int(weight * 10) % 10 == 0 // Full kg (30, 31, 32...)
            let isHalfUnit = Int(weight * 10) % 5 == 0 && !isFullUnit // Half kg (30.5, 31.5...)
            
            let height: CGFloat
            if isFullUnit {
                height = 50 // Tallest for full kg
            } else if isHalfUnit {
                height = 35 // Medium for 0.5 kg
            } else {
                height = 20 // Shortest for 0.1, 0.2, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9
            }
            
            let yPosition: CGFloat = 80 - height // Align all marks at the bottom
            
            rulerView.addSubview(markView)
            
            NSLayoutConstraint.activate([
                markView.leadingAnchor.constraint(equalTo: rulerView.leadingAnchor, constant: xPosition),
                markView.topAnchor.constraint(equalTo: rulerView.topAnchor, constant: yPosition),
                markView.widthAnchor.constraint(equalToConstant: 1.5),
                markView.heightAnchor.constraint(equalToConstant: height)
            ])
        }
        
        // Set content size
        rulerView.widthAnchor.constraint(equalToConstant: totalWidth).isActive = true
    }
    
    private func setupActions() {
        unitSegmentedControl.addTarget(self, action: #selector(unitChanged), for: .valueChanged)
        scrollView.delegate = self
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    private func scrollToCurrentWeight() {
        let spacing: CGFloat = 4.0 // Spacing for 0.1 visual increments
        let screenWidth = UIScreen.main.bounds.width
        let padding = screenWidth / 2
        
        let index = (currentWeight - minWeight) * 10 // Convert to 0.1 increments
        let offset = CGFloat(index) * spacing
        
        scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
    }
    
    private func updateWeight() {
        let spacing: CGFloat = 4.0 // Spacing for 0.1 visual increments
        let screenWidth = UIScreen.main.bounds.width
        let padding = screenWidth / 2
        
        let offset = scrollView.contentOffset.x
        let index = round(offset / spacing)
        
        // Calculate weight in 0.1 increments
        let rawWeight = minWeight + (Double(index) / 10.0)
        
        // Round to nearest 0.5 for selection
        currentWeight = round(rawWeight * 2) / 2.0
        currentWeight = max(minWeight, min(maxWeight, currentWeight))
        
        let displayWeight = isKilogram ? currentWeight : currentWeight * 2.20462
        weightLabel.text = String(format: "%.1f", displayWeight)
    }
    
    // MARK: - Actions
    @objc private func unitChanged() {
        isKilogram = unitSegmentedControl.selectedSegmentIndex == 0
        unitLabel.text = isKilogram ? "kg" : "lbs"
        
        let displayWeight = isKilogram ? currentWeight : currentWeight * 2.20462
        weightLabel.text = String(format: "%.1f", displayWeight)
    }
    
    @objc private func nextButtonTapped() {
        print("Selected weight: \(currentWeight) kg")
        // Handle next action
    }
}

// MARK: - UIScrollViewDelegate
extension WeightPickerViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ UIScrollView: UIScrollView) {
        updateWeight()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            snapToNearest()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        snapToNearest()
    }
    
    private func snapToNearest() {
        let spacing: CGFloat = 4.0 // Spacing for 0.1 visual increments
        let offset = scrollView.contentOffset.x
        
        // Calculate current weight
        let index = offset / spacing
        let rawWeight = minWeight + (Double(index) / 10.0)
        
        // Round to nearest 0.5
        let snappedWeight = round(rawWeight * 2) / 2.0
        let snappedIndex = (snappedWeight - minWeight) * 10
        let snappedOffset = CGFloat(snappedIndex) * spacing
        
        scrollView.setContentOffset(CGPoint(x: snappedOffset, y: 0), animated: true)
    }
}
