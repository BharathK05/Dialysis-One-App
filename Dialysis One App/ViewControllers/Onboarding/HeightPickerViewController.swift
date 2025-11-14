import UIKit

class HeightPickerViewController: UIViewController {
    
    // MARK: - Properties
    private var selectedFeet: Int = 5
    private var selectedInches: Int = 10
    private var selectedCm: Int = 170
    private var isFeetMode: Bool = true
    
    // Color constant
    private let onboardingGreen = UIColor(red: 0x6B/255.0, green: 0xA1/255.0, blue: 0x7F/255.0, alpha: 1.0)
    
    // MARK: - UI Components
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progress = 0.6
        progress.progressTintColor = UIColor(red: 0x6B/255.0, green: 0xA1/255.0, blue: 0x7F/255.0, alpha: 1.0)
        progress.trackTintColor = UIColor.lightGray.withAlphaComponent(0.3)
        progress.layer.cornerRadius = 2
        progress.clipsToBounds = true
        return progress
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "How tall are you?"
        label.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        label.textColor = UIColor(red: 0x6B/255.0, green: 0xA1/255.0, blue: 0x7F/255.0, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let unitSegmentedControl: UISegmentedControl = {
        let items = ["Ft", "Cm"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        control.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        control.selectedSegmentTintColor = UIColor(red: 0x6B/255.0, green: 0xA1/255.0, blue: 0x7F/255.0, alpha: 1.0)
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
        return control
    }()
    
    private let heightDisplayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()
    
    private let rulerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        scroll.bounces = true
        return scroll
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0x6B/255.0, green: 0xA1/255.0, blue: 0x7F/255.0, alpha: 1.0)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let centerIndicatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0x6B/255.0, green: 0xA1/255.0, blue: 0x7F/255.0, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRuler()
        updateHeightDisplay()
        
        unitSegmentedControl.addTarget(self, action: #selector(unitChanged), for: .valueChanged)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        scrollView.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Delay scroll to ensure content size is properly set
        DispatchQueue.main.async {
            self.scrollToCurrentHeight(animated: false)
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(progressView)
        view.addSubview(titleLabel)
        view.addSubview(unitSegmentedControl)
        view.addSubview(heightDisplayLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(rulerView)
        view.addSubview(centerIndicatorLine)
        view.addSubview(nextButton)
        
        NSLayoutConstraint.activate([
            // Progress View
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Unit Segmented Control
            unitSegmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            unitSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            unitSegmentedControl.widthAnchor.constraint(equalToConstant: 140),
            unitSegmentedControl.heightAnchor.constraint(equalToConstant: 40),
            
            // Height Display
            heightDisplayLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            heightDisplayLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -50),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: unitSegmentedControl.bottomAnchor, constant: 40),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -40),
            scrollView.widthAnchor.constraint(equalToConstant: 80),
            
            // Ruler View
            rulerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            rulerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            rulerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            rulerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            rulerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Center Indicator Line
            centerIndicatorLine.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            centerIndicatorLine.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            centerIndicatorLine.widthAnchor.constraint(equalToConstant: 60),
            centerIndicatorLine.heightAnchor.constraint(equalToConstant: 3),
            
            // Next Button
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            nextButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupRuler() {
        // Clear existing subviews
        rulerView.subviews.forEach { $0.removeFromSuperview() }
        
        let itemHeight: CGFloat = 20
        
        // Different ranges for feet vs cm
        let minValue: Int
        let maxValue: Int
        
        if isFeetMode {
            minValue = 48  // 4 feet in inches
            maxValue = 96  // 8 feet in inches
        } else {
            minValue = 130 // 130 cm
            maxValue = 200 // 200 cm
        }
        
        let totalItems = maxValue - minValue + 1
        
        let totalHeight = CGFloat(totalItems) * itemHeight
        let paddingTop = view.bounds.height / 2
        let paddingBottom = view.bounds.height / 2
        
        let containerHeight = totalHeight + paddingTop + paddingBottom
        
        rulerView.heightAnchor.constraint(equalToConstant: containerHeight).isActive = true
        
        for i in 0..<totalItems {
            let value = minValue + i
            let yPosition = paddingTop + CGFloat(i) * itemHeight
            
            // Determine tick length
            let isMainMark: Bool
            let isHalfMark: Bool
            
            if isFeetMode {
                isMainMark = value % 12 == 0  // Every foot
                isHalfMark = value % 6 == 0   // Every half foot
            } else {
                isMainMark = value % 10 == 0  // Every 10 cm
                isHalfMark = value % 5 == 0   // Every 5 cm
            }
            
            let tickLength: CGFloat
            let tickHeight: CGFloat
            
            if isMainMark {
                tickLength = 45
                tickHeight = 2.5
            } else if isHalfMark {
                tickLength = 32
                tickHeight = 2.0
            } else {
                tickLength = 22
                tickHeight = 1.5
            }
            
            let tickView = UIView()
            tickView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.6)
            tickView.translatesAutoresizingMaskIntoConstraints = false
            rulerView.addSubview(tickView)
            
            NSLayoutConstraint.activate([
                tickView.trailingAnchor.constraint(equalTo: rulerView.trailingAnchor),
                tickView.centerYAnchor.constraint(equalTo: rulerView.topAnchor, constant: yPosition),
                tickView.widthAnchor.constraint(equalToConstant: tickLength),
                tickView.heightAnchor.constraint(equalToConstant: tickHeight)
            ])
        }
        
        scrollView.contentSize = CGSize(width: 80, height: containerHeight)
    }
    
    private func scrollToCurrentHeight(animated: Bool) {
        let itemHeight: CGFloat = 20
        let paddingTop = view.bounds.height / 2
        
        let value: Int
        let minValue: Int
        
        if isFeetMode {
            value = selectedFeet * 12 + selectedInches
            minValue = 48 // 4 feet
        } else {
            value = selectedCm
            minValue = 130
        }
        
        let targetY = CGFloat(value - minValue) * itemHeight
        let scrollY = targetY - (scrollView.bounds.height / 2) + paddingTop
        
        scrollView.setContentOffset(CGPoint(x: 0, y: scrollY), animated: animated)
    }
    
    private func updateHeightDisplay() {
        let attributedString = NSMutableAttributedString()
        
        if isFeetMode {
            let feetString = "\(selectedFeet)"
            let feetAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 72, weight: .bold),
                .foregroundColor: UIColor(red: 0x6B/255.0, green: 0xA1/255.0, blue: 0x7F/255.0, alpha: 1.0)
            ]
            attributedString.append(NSAttributedString(string: feetString, attributes: feetAttributes))
            
            let ftString = " ft "
            let unitAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            attributedString.append(NSAttributedString(string: ftString, attributes: unitAttributes))
            
            let inchesString = "\(selectedInches)"
            attributedString.append(NSAttributedString(string: inchesString, attributes: feetAttributes))
            
            let inString = " in"
            attributedString.append(NSAttributedString(string: inString, attributes: unitAttributes))
        } else {
            let cmString = "\(selectedCm)"
            let cmAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 72, weight: .bold),
                .foregroundColor: UIColor(red: 0x6B/255.0, green: 0xA1/255.0, blue: 0x7F/255.0, alpha: 1.0)
            ]
            attributedString.append(NSAttributedString(string: cmString, attributes: cmAttributes))
            
            let unitString = " cm"
            let unitAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            attributedString.append(NSAttributedString(string: unitString, attributes: unitAttributes))
        }
        
        heightDisplayLabel.attributedText = attributedString
    }
    
    // MARK: - Actions
    @objc private func unitChanged() {
        let wasFeetMode = isFeetMode
        isFeetMode = unitSegmentedControl.selectedSegmentIndex == 0
        
        if wasFeetMode != isFeetMode {
            // Convert between units
            if isFeetMode {
                // Convert cm to feet/inches
                let totalInches = Int(Double(selectedCm) / 2.54)
                selectedFeet = totalInches / 12
                selectedInches = totalInches % 12
            } else {
                // Convert feet/inches to cm
                let totalInches = selectedFeet * 12 + selectedInches
                selectedCm = Int(Double(totalInches) * 2.54)
            }
            
            // Rebuild ruler for new unit
            setupRuler()
            updateHeightDisplay()
            scrollToCurrentHeight(animated: true)
        }
    }
    
    @objc private func nextButtonTapped() {
        if isFeetMode {
            print("Selected height: \(selectedFeet) ft \(selectedInches) in")
        } else {
            print("Selected height: \(selectedCm) cm")
        }
        
        // Navigate to WeightPickerViewController
        let weightVC = WeightPickerViewController()
        navigationController?.pushViewController(weightVC, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension HeightPickerViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let itemHeight: CGFloat = 20
        let paddingTop = view.bounds.height / 2
        
        let scrollY = scrollView.contentOffset.y
        let centerY = scrollY + (scrollView.bounds.height / 2)
        let adjustedY = centerY - paddingTop
        
        if isFeetMode {
            let minHeight = 48 // 4 feet
            let totalInches = minHeight + Int(round(adjustedY / itemHeight))
            let clampedInches = max(48, min(96, totalInches))
            
            selectedFeet = clampedInches / 12
            selectedInches = clampedInches % 12
        } else {
            let minHeight = 130
            let totalCm = minHeight + Int(round(adjustedY / itemHeight))
            selectedCm = max(130, min(200, totalCm))
        }
        
        updateHeightDisplay()
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let itemHeight: CGFloat = 20
        let paddingTop = view.bounds.height / 2
        
        let targetY = targetContentOffset.pointee.y
        let centerY = targetY + (scrollView.bounds.height / 2)
        let adjustedY = centerY - paddingTop
        
        if isFeetMode {
            let minHeight = 48 // 4 feet
            let totalInches = minHeight + Int(round(adjustedY / itemHeight))
            let clampedInches = max(48, min(96, totalInches))
            
            let snappedY = CGFloat(clampedInches - minHeight) * itemHeight - (scrollView.bounds.height / 2) + paddingTop
            targetContentOffset.pointee.y = snappedY
        } else {
            let minHeight = 130
            let totalCm = minHeight + Int(round(adjustedY / itemHeight))
            let clampedCm = max(130, min(200, totalCm))
            
            let snappedY = CGFloat(clampedCm - minHeight) * itemHeight - (scrollView.bounds.height / 2) + paddingTop
            targetContentOffset.pointee.y = snappedY
        }
    }
}
