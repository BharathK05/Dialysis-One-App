import UIKit
import QuartzCore

// MARK: - UIColor helper

extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(hex & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

// MARK: - Gradient Card View

class GradientCardView: UIView {
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        layer.cornerRadius = 18
        layer.masksToBounds = true
        
        gradientLayer.colors = [
            UIColor(hex: 0xF5F5F5).cgColor,
            UIColor(hex: 0x93C3E8).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

// MARK: - Activity Row

class ActivityRowView: GradientCardView {
    let iconView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let timeLabel = UILabel()
    
    init(title: String, subtitle: String, time: String, icon: UIImage?) {
        super.init(frame: .zero)
        setup(title: title, subtitle: subtitle, time: time, icon: icon)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(title: "", subtitle: "", time: "", icon: nil)
    }
    
    private func setup(title: String, subtitle: String, time: String, icon: UIImage?) {
        iconView.image = icon
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = UIColor(hex: 0x152B3C)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = UIColor(hex: 0x152B3C)
        
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .darkGray
        
        timeLabel.text = time
        timeLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        timeLabel.textColor = UIColor(hex: 0x152B3C)
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 2
        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        
        let mainStack = UIStackView(arrangedSubviews: [iconView, labelsStack, timeLabel])
        mainStack.axis = .horizontal
        mainStack.alignment = .center
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }
}

// MARK: - Circular Progress View

class CircularProgressView: UIView {
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    
    let valueLabel = UILabel()
    let dropIcon = UIImageView()
    
    var progress: CGFloat = 0.0 {
        didSet {
            progressLayer.strokeEnd = max(0, min(progress, 1))
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        setupCenterContent()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
        setupCenterContent()
    }
    
    private func setupLayers() {
        backgroundColor = .clear
        
        trackLayer.strokeColor = UIColor(hex: 0xE0E0E0).cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = 18
        trackLayer.lineCap = .round
        
        progressLayer.strokeColor = UIColor.white.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 18
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = progress
        
        gradientLayer.colors = [
            UIColor(hex: 0x43A7EF).cgColor,
            UIColor(hex: 0x5BB2F0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.mask = progressLayer
        
        layer.addSublayer(trackLayer)
        layer.addSublayer(gradientLayer)
    }
    
    private func setupCenterContent() {
        dropIcon.image = UIImage(systemName: "drop.fill")
        dropIcon.tintColor = UIColor(hex: 0x152B3C)
        dropIcon.translatesAutoresizingMaskIntoConstraints = false
        
        valueLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        valueLabel.textColor = UIColor(hex: 0x152B3C)
        valueLabel.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [dropIcon, valueLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            dropIcon.widthAnchor.constraint(equalToConstant: 20),
            dropIcon.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let rect = bounds.insetBy(dx: 18, dy: 18)
        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(rect.width, rect.height) / 2
        let startAngle: CGFloat = .pi * 0.9
        let endAngle: CGFloat = .pi * 0.1
        
        let path = UIBezierPath(arcCenter: centerPoint,
                                radius: radius,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)
        
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
        
        trackLayer.frame = bounds
        gradientLayer.frame = bounds
    }
}

// MARK: - Animated Wave View

// MARK: - Animated Wave View

// MARK: - Animated Wave View (Natural Floating Water Effect)

class WaveView: UIView {
    private let gradientLayer1 = CAGradientLayer()
    private let gradientLayer2 = CAGradientLayer()
    private let waveLayer1 = CAShapeLayer()
    private let waveLayer2 = CAShapeLayer()

    private var displayLink: CADisplayLink?
    private var phase1: CGFloat = 0
    private var phase2: CGFloat = 0

    /// 0.0 – 1.0 water height
    var level: CGFloat = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit { displayLink?.invalidate() }

    private func setup() {
        backgroundColor = .clear

        // Perfect blue hues, NO grey tint
        gradientLayer1.colors = [
            UIColor(hex: 0x43A7EF, alpha: 0.48).cgColor,
            UIColor(hex: 0x5BB2F0, alpha: 0.55).cgColor
        ]

        gradientLayer2.colors = [
            UIColor(hex: 0x43A7EF, alpha: 0.40).cgColor,
            UIColor(hex: 0x5BB2F0, alpha: 0.50).cgColor
        ]

        gradientLayer1.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer1.endPoint   = CGPoint(x: 1, y: 1)
        gradientLayer1.mask = waveLayer1

        gradientLayer2.startPoint = CGPoint(x: 1, y: 0)
        gradientLayer2.endPoint   = CGPoint(x: 0, y: 1)
        gradientLayer2.mask = waveLayer2

        layer.addSublayer(gradientLayer1)
        layer.addSublayer(gradientLayer2)

        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func update() {
        // Slow & calming motion
        phase1 += 0.004
        phase2 += 0.003

        animateWave(layer: waveLayer1,
                    phase: phase1,
                    baseAmplitude: 45,
                    level: level)

        animateWave(layer: waveLayer2,
                    phase: phase2,
                    baseAmplitude: 60,
                    level: level)
    }

    private func animateWave(layer: CAShapeLayer,
                             phase: CGFloat,
                             baseAmplitude: CGFloat,
                             level: CGFloat) {

        guard bounds.width > 0 else { return }

        let width = bounds.width
        let height = bounds.height

        let path = UIBezierPath()
        let clamped = max(0, min(level, 1))

        // Floating vertical bob (water rising/falling gently)
        let bobbing = sin(phase * 0.6) * 6

        let baseline = height * clamped + bobbing

        // amplitude slightly changes over time → natural turbulence
        let dynamicAmp = baseAmplitude + sin(phase * 0.4) * 8

        // wide wavelength → only one crest visible
        let wavelength = width * 1.7

        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: height - baseline))

        var x: CGFloat = 0
        while x <= width {
            let y = (height - baseline)
                + sin((2 * .pi / wavelength) * x + phase) * dynamicAmp

            path.addLine(to: CGPoint(x: x, y: y))
            x += 4
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.close()

        layer.path = path.cgPath
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer1.frame = bounds
        gradientLayer2.frame = bounds
    }
}



// MARK: - Placeholder ViewAll VC

class PreviousLogsViewController: UIViewController {
    
    private let backButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = ""  // We will use a custom title
        
        setupHeader()
    }
    
    private func setupHeader() {
        // Back button
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = UIColor(hex: 0x152B3C)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = "All Logs"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textColor = UIColor(hex: 0x152B3C)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.widthAnchor.constraint(equalToConstant: 28),
            backButton.heightAnchor.constraint(equalToConstant: 28),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor)
        ])
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}


// MARK: - Main View Controller

class HydrationStatusViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let waveView = WaveView()
    
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let dateButton = UIButton(type: .system)
    private let progressView = CircularProgressView()
    private let subtitleLabel = UILabel()
    
    private let goalCard = GradientCardView()
    private let remainingCard = GradientCardView()
    private let streakCard = GradientCardView()
    
    private let goalTitle = UILabel()
    private let goalValue = UILabel()
    private let remainingTitle = UILabel()
    private let remainingValue = UILabel()
    private let streakTitle = UILabel()
    private let streakValue = UILabel()
    
    private let recentActivityLabel = UILabel()
    private let previousLogsLabel = UILabel()
    private let viewAllButton = UIButton(type: .system)
    
    // Data for this screen
    private let consumedAmount: CGFloat = 75
    private let goalAmount: CGFloat = 250
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBase()
        setupHeader()
        setupProgress()
        setupStatsCards()
        setupActivitySection()
        setupWaveView()
        syncProgressToWave()
    }
    
    private func syncProgressToWave() {
        let ratio = consumedAmount / goalAmount  // 75/250 = 0.3
        
        // Progress ring
        progressView.valueLabel.text = "\(Int(consumedAmount))/\(Int(goalAmount))ml"
        progressView.progress = ratio
        
        // Wave height linked to same ratio
        waveView.level = ratio
        
        // Stats labels derived from same values
        remainingValue.text = "\(Int(goalAmount - consumedAmount)) ml"
    }
    
    private func setupBase() {
        view.backgroundColor = .white
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupHeader() {
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = UIColor(hex: 0x152B3C)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        
        titleLabel.text = "Hydration Status"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textColor = UIColor(hex: 0x152B3C)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        dateButton.setTitle("Oct 30, 2025", for: .normal)
        dateButton.setTitleColor(UIColor(hex: 0x152B3C), for: .normal)
        dateButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        dateButton.backgroundColor = UIColor(hex: 0xF3F4F6)
        dateButton.layer.cornerRadius = 18
        dateButton.translatesAutoresizingMaskIntoConstraints = false
        dateButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        
        contentView.addSubview(backButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(dateButton)
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            backButton.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.widthAnchor.constraint(equalToConstant: 28),
            backButton.heightAnchor.constraint(equalToConstant: 28),
            
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            
            dateButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dateButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16)
        ])
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupProgress() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.text = "See how close you are to your limit"
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .darkGray
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(progressView)
        contentView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            progressView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            progressView.topAnchor.constraint(equalTo: dateButton.bottomAnchor, constant: 18),
            progressView.widthAnchor.constraint(equalToConstant: 220),
            progressView.heightAnchor.constraint(equalToConstant: 220),
            
            subtitleLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30)
        ])
    }
    
    private func setupStatsCards() {
        let statsStack = UIStackView(arrangedSubviews: [goalCard, remainingCard, streakCard])
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = 12
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(statsStack)
        
        func configureCard(card: GradientCardView,
                           title: UILabel,
                           value: UILabel,
                           iconName: String,
                           titleText: String,
                           valueText: String) {
            let iconView = UIImageView(image: UIImage(systemName: iconName))
            iconView.tintColor = UIColor(hex: 0x152B3C)
            iconView.translatesAutoresizingMaskIntoConstraints = false
            
            title.text = titleText
            title.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            title.textColor = UIColor(hex: 0x152B3C)
            
            value.text = valueText
            value.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            value.textColor = UIColor(hex: 0x152B3C)
            
            let stack = UIStackView(arrangedSubviews: [title, value])
            stack.axis = .vertical
            stack.spacing = 2
            stack.translatesAutoresizingMaskIntoConstraints = false
            
            let mainStack = UIStackView(arrangedSubviews: [iconView, stack])
            mainStack.axis = .horizontal
            mainStack.spacing = 8
            mainStack.alignment = .center
            mainStack.translatesAutoresizingMaskIntoConstraints = false
            
            card.addSubview(mainStack)
            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: 18),
                iconView.heightAnchor.constraint(equalToConstant: 18),
                mainStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
                mainStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
                mainStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
                mainStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
            ])
        }
        
        configureCard(card: goalCard,
                      title: goalTitle,
                      value: goalValue,
                      iconName: "target",
                      titleText: "Goal",
                      valueText: "\(Int(goalAmount)) ml")
        
        configureCard(card: remainingCard,
                      title: remainingTitle,
                      value: remainingValue,
                      iconName: "hourglass",
                      titleText: "Remaining",
                      valueText: "\(Int(goalAmount - consumedAmount)) ml")
        
        configureCard(card: streakCard,
                      title: streakTitle,
                      value: streakValue,
                      iconName: "flame.fill",
                      titleText: "Streak",
                      valueText: "3 days")
        
        NSLayoutConstraint.activate([
            statsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 18),
            statsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsStack.heightAnchor.constraint(equalToConstant: 72)
        ])
    }
    
    private func setupActivitySection() {
        recentActivityLabel.text = "Recent Activity"
        recentActivityLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        recentActivityLabel.textColor = UIColor(hex: 0x152B3C)
        recentActivityLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(recentActivityLabel)
        
        let waterRecent = ActivityRowView(title: "Water",
                                          subtitle: "75 ml",
                                          time: "04:30 PM",
                                          icon: UIImage(systemName: "drop"))
        let coffeeRecent = ActivityRowView(title: "Coffee",
                                           subtitle: "25 ml",
                                           time: "12:00 PM",
                                           icon: UIImage(systemName: "cup.and.saucer"))
        let juiceRecent = ActivityRowView(title: "Juice",
                                          subtitle: "50 ml",
                                          time: "08:00 AM",
                                          icon: UIImage(systemName: "takeoutbag.and.cup.and.straw"))
        
        [waterRecent, coffeeRecent, juiceRecent].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        let recentStack = UIStackView(arrangedSubviews: [waterRecent, coffeeRecent, juiceRecent])
        recentStack.axis = .vertical
        recentStack.spacing = 10
        recentStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(recentStack)
        
        previousLogsLabel.text = "Previous Logs"
        previousLogsLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        previousLogsLabel.textColor = UIColor(hex: 0x152B3C)
        previousLogsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        viewAllButton.setTitle("View all", for: .normal)
        viewAllButton.setTitleColor(UIColor(hex: 0x152B3C), for: .normal)
        viewAllButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        viewAllButton.translatesAutoresizingMaskIntoConstraints = false
        viewAllButton.addTarget(self, action: #selector(viewAllTapped), for: .touchUpInside)
        
        contentView.addSubview(previousLogsLabel)
        contentView.addSubview(viewAllButton)
        
        let yesterdayLabel = UILabel()
        yesterdayLabel.text = "Yesterday"
        yesterdayLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        yesterdayLabel.textColor = UIColor(hex: 0x152B3C)
        yesterdayLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(yesterdayLabel)
        
        let waterPrev = ActivityRowView(title: "Water",
                                        subtitle: "75 ml",
                                        time: "04:30 PM",
                                        icon: UIImage(systemName: "drop"))
        let coffeePrev = ActivityRowView(title: "Coffee",
                                         subtitle: "25 ml",
                                         time: "12:00 PM",
                                         icon: UIImage(systemName: "cup.and.saucer"))
        
        [waterPrev, coffeePrev].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        let previousStack = UIStackView(arrangedSubviews: [waterPrev, coffeePrev])
        previousStack.axis = .vertical
        previousStack.spacing = 10
        previousStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(previousStack)
        
        NSLayoutConstraint.activate([
            recentActivityLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            recentActivityLabel.topAnchor.constraint(equalTo: goalCard.bottomAnchor, constant: 24),
            
            recentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            recentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            recentStack.topAnchor.constraint(equalTo: recentActivityLabel.bottomAnchor, constant: 10),
            
            previousLogsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            previousLogsLabel.topAnchor.constraint(equalTo: recentStack.bottomAnchor, constant: 26),
            
            viewAllButton.centerYAnchor.constraint(equalTo: previousLogsLabel.centerYAnchor),
            viewAllButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            
            yesterdayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            yesterdayLabel.topAnchor.constraint(equalTo: previousLogsLabel.bottomAnchor, constant: 10),
            
            previousStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            previousStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            previousStack.topAnchor.constraint(equalTo: yesterdayLabel.bottomAnchor, constant: 8),
            previousStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func setupWaveView() {
        waveView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(waveView, at: 0)
        
        NSLayoutConstraint.activate([
            waveView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            waveView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            waveView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            // taller so only one large crest is visible
            waveView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7)
        ])
    }
    
    @objc private func viewAllTapped() {
        let vc = PreviousLogsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
