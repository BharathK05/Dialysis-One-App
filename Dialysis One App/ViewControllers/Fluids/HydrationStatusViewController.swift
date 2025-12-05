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
            UIColor(hex: 0xF5F5F5, alpha: 0.75).cgColor,
            UIColor(hex: 0x93C3E8, alpha: 0.75).cgColor
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

// MARK: - Activity Row (for future logs / previous logs screen)

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

// MARK: - Rounded message card (“Today’s Log”, “Previous Logs”)

final class RoundedMessageCard: UIView {
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = UIColor(hex: 0xD7E8FA, alpha: 0.65)
        layer.cornerRadius = 24
        
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = UIColor(hex: 0x152B3C)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    func update(text: String) {
        label.text = text
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
        didSet { progressLayer.strokeEnd = max(0, min(progress, 1)) }
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
        let endAngle: CGFloat   = .pi * 0.1
        
        let path = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        
        trackLayer.path = path.cgPath
        progressLayer.path = path.cgPath
        
        trackLayer.frame = bounds
        gradientLayer.frame = bounds
    }
}

// MARK: - Animated Wave View

class WaveView: UIView {
    private let gradientLayer1 = CAGradientLayer()
    private let gradientLayer2 = CAGradientLayer()
    private let waveLayer1 = CAShapeLayer()
    private let waveLayer2 = CAShapeLayer()

    private var displayLink: CADisplayLink?
    private var phase1: CGFloat = 0
    private var phase2: CGFloat = 0

    /// 0.0 – 1.0 : water height linked to progress
    var level: CGFloat = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        displayLink?.invalidate()
    }

    private func setup() {
        backgroundColor = .clear

        gradientLayer1.colors = [
            UIColor(hex: 0x43A7EF, alpha: 0.40).cgColor,
            UIColor(hex: 0x5BB2F0, alpha: 0.38).cgColor
        ]
        gradientLayer1.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer1.endPoint   = CGPoint(x: 1, y: 1)
        gradientLayer1.mask = waveLayer1

        gradientLayer2.colors = [
            UIColor(hex: 0x43A7EF, alpha: 0.35).cgColor,
            UIColor(hex: 0x5BB2F0, alpha: 0.45).cgColor
        ]
        gradientLayer2.startPoint = CGPoint(x: 1, y: 0)
        gradientLayer2.endPoint   = CGPoint(x: 0, y: 1)
        gradientLayer2.mask = waveLayer2

        layer.addSublayer(gradientLayer1)
        layer.addSublayer(gradientLayer2)

        displayLink = CADisplayLink(target: self, selector: #selector(updateWaves))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func updateWaves() {
        phase1 += 0.00375
        phase2 += 0.00315

        animateWave(
            layer: waveLayer1,
            phase: phase1,
            baseAmplitude: 50,
            level: level,
            baselineOffset: 0,
            wavelengthFactor: 1.6,
            bobbingStrength: 10,
            bobbingSpeed: 0.9
        )

        animateWave(
            layer: waveLayer2,
            phase: phase2 + .pi/2,
            baseAmplitude: 55,
            level: level,
            baselineOffset: 16,
            wavelengthFactor: 1.4,
            bobbingStrength: 12,
            bobbingSpeed: 1.1
        )
    }

    private func animateWave(layer: CAShapeLayer,
                             phase: CGFloat,
                             baseAmplitude: CGFloat,
                             level: CGFloat,
                             baselineOffset: CGFloat,
                             wavelengthFactor: CGFloat,
                             bobbingStrength: CGFloat,
                             bobbingSpeed: CGFloat) {

        guard bounds.width > 0, bounds.height > 0 else { return }

        let width  = bounds.width
        let height = bounds.height

        let path = UIBezierPath()
        let clamped = max(0, min(level, 1))

        let verticalBob = sin(phase * bobbingSpeed) * bobbingStrength
        let baseline = height * clamped + baselineOffset + verticalBob

        let amplitude  = baseAmplitude
        let wavelength = width * wavelengthFactor
        let k = (2 * .pi) / wavelength

        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: height - baseline))

        var x: CGFloat = 0
        while x <= width {
            let y = (height - baseline) + sin(k * x + phase) * amplitude
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

    // Activity section containers
    private var todaysLogContainer: UIView!
    private var previousLogsCard: GradientCardView!

    
    // MARK: - Shared data with Home
    
    private var uid: String {
        FirebaseAuthManager.shared.getUserID() ?? "guest"
    }
    
    private var consumedAmount: CGFloat = 0
    private var goalAmount: CGFloat = 2500
    
    private func loadHydrationFromStore() {
        let storedConsumed = UserDataManager.shared.loadInt("waterConsumed",
                                                            uid: uid,
                                                            defaultValue: 0)
        let storedGoal = UserDataManager.shared.loadInt("waterGoal",
                                                        uid: uid,
                                                        defaultValue: 2500)

        consumedAmount = CGFloat(max(storedConsumed, 0))
        goalAmount = CGFloat(max(storedGoal, 1))
    }

    
    // “reset once per app run” flag
    private static var didResetForThisRun = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBase()
        setupHeader()
        setupProgress()
        setupStatsCards()
        setupActivitySection()   // <- THIS name
        setupWaveView()

        loadHydrationFromStore()
        syncProgressToWave()
    }


    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)

        // Refresh progress + cards from latest data
        loadHydrationFromStore()
        syncProgressToWave()
        updateActivityContent()
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    // MARK: - Data
    
    private func loadHydrationValues() {
        // For now: when app is freshly run, reset everything to 0 once.
        // Later we’ll move this “daily reset” into a separate file.
        if !Self.didResetForThisRun {
            let storedGoal = UserDataManager.shared.loadInt("waterGoal",
                                                            uid: uid,
                                                            defaultValue: 2500)
            goalAmount = CGFloat(max(storedGoal, 1))
            consumedAmount = 0
            
            UserDataManager.shared.save("waterConsumed", value: 0, uid: uid)
            UserDataManager.shared.save("waterGoal", value: Int(goalAmount), uid: uid)
            
            Self.didResetForThisRun = true
        } else {
            let consumed = UserDataManager.shared.loadInt("waterConsumed",
                                                          uid: uid,
                                                          defaultValue: 0)
            let goal = UserDataManager.shared.loadInt("waterGoal",
                                                      uid: uid,
                                                      defaultValue: 2500)
            consumedAmount = CGFloat(max(consumed, 0))
            goalAmount = CGFloat(max(goal, 1))
        }
    }
    
    private func syncProgressToWave() {
        let ratio = max(0, min(consumedAmount / goalAmount, 1))

        // Ring in the center
        progressView.valueLabel.text = "\(Int(consumedAmount))/\(Int(goalAmount))ml"
        progressView.progress = ratio

        // Wave at the bottom
        waveView.level = ratio

        // Cards just under the ring
        goalValue.text = "\(Int(goalAmount)) ml"
        let remaining = max(goalAmount - consumedAmount, 0)
        remainingValue.text = "\(Int(remaining)) ml"
        streakValue.text = "3 days"   // placeholder for now
    }

    
    
    
    // MARK: - Setup UI
    
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
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        titleLabel.text = "Hydration Status"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textColor = UIColor(hex: 0x152B3C)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        dateButton.setTitle(formatter.string(from: Date()), for: .normal)
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
                      valueText: "0 ml")
        
        configureCard(card: remainingCard,
                      title: remainingTitle,
                      value: remainingValue,
                      iconName: "hourglass",
                      titleText: "Remaining",
                      valueText: "0 ml")
        
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
    
    
    // MARK: - Today's Log + Previous Logs
    private func setupActivitySection() {
        // "Today’s Log" title
        let todaysLogTitle = UILabel()
        todaysLogTitle.text = "Today’s Log"
        todaysLogTitle.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        todaysLogTitle.textColor = UIColor(hex: 0x152B3C)
        todaysLogTitle.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(todaysLogTitle)

        // Container for dynamic today's logs (empty state or list of rows)
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)
        todaysLogContainer = container

        // "Previous Logs" title + "View all" button
        previousLogsLabel.text = "Previous Logs"
        previousLogsLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        previousLogsLabel.textColor = UIColor(hex: 0x152B3C)
        previousLogsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(previousLogsLabel)

        viewAllButton.setTitle("View all", for: .normal)
        viewAllButton.setTitleColor(UIColor(hex: 0x152B3C), for: .normal)
        viewAllButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        viewAllButton.translatesAutoresizingMaskIntoConstraints = false
        viewAllButton.addTarget(self, action: #selector(viewAllTapped), for: .touchUpInside)
        contentView.addSubview(viewAllButton)

        // Static Previous Logs info card
        let prevCard = GradientCardView()
        prevCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(prevCard)
        previousLogsCard = prevCard

        let prevText = UILabel()
        prevText.text = "Enter your fluid intake everyday to have a track of it!"
        prevText.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        prevText.textColor = UIColor(hex: 0x152B3C)
        prevText.numberOfLines = 0
        prevText.translatesAutoresizingMaskIntoConstraints = false
        prevCard.addSubview(prevText)

        NSLayoutConstraint.activate([
            // Today’s Log title under the stats cards
            todaysLogTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            todaysLogTitle.topAnchor.constraint(equalTo: goalCard.bottomAnchor, constant: 32),

            // Container right under the title
            container.topAnchor.constraint(equalTo: todaysLogTitle.bottomAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Previous Logs title & button under the container
            previousLogsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            previousLogsLabel.topAnchor.constraint(equalTo: container.bottomAnchor, constant: 28),

            viewAllButton.centerYAnchor.constraint(equalTo: previousLogsLabel.centerYAnchor),
            viewAllButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Previous Logs card
            prevCard.topAnchor.constraint(equalTo: previousLogsLabel.bottomAnchor, constant: 12),
            prevCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            prevCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            prevCard.heightAnchor.constraint(equalToConstant: 90),
            prevCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            prevText.leadingAnchor.constraint(equalTo: prevCard.leadingAnchor, constant: 20),
            prevText.trailingAnchor.constraint(equalTo: prevCard.trailingAnchor, constant: -20),
            prevText.topAnchor.constraint(equalTo: prevCard.topAnchor, constant: 18),
            prevText.bottomAnchor.constraint(equalTo: prevCard.bottomAnchor, constant: -18)
        ])

        // Fill the container with empty state or rows
        updateActivityContent()
    }

    
    // Build today's log section based on current FluidLogStore
    private func updateActivityContent() {
        // Clean previous content
        todaysLogContainer.subviews.forEach { $0.removeFromSuperview() }

        let logs = FluidLogStore.shared.todayLogs()

        if logs.isEmpty {
            // Show the empty state card
            let card = GradientCardView()
            card.translatesAutoresizingMaskIntoConstraints = false
            todaysLogContainer.addSubview(card)

            let label = UILabel()
            label.text = "You haven’t logged anything yet!"
            label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            label.textColor = UIColor(hex: 0x152B3C)
            label.textAlignment = .center
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(label)

            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: todaysLogContainer.topAnchor),
                card.leadingAnchor.constraint(equalTo: todaysLogContainer.leadingAnchor),
                card.trailingAnchor.constraint(equalTo: todaysLogContainer.trailingAnchor),
                card.bottomAnchor.constraint(equalTo: todaysLogContainer.bottomAnchor),
                card.heightAnchor.constraint(equalToConstant: 80),

                label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
                label.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
                label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
            ])

        } else {
            // Show actual fluid entries using ActivityRowView (your card design)
            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 10
            stack.translatesAutoresizingMaskIntoConstraints = false
            todaysLogContainer.addSubview(stack)

            let formatter = DateFormatter()
            formatter.dateFormat = "hh:mm a"

            for log in logs {
                let iconName: String
                switch log.type.lowercased() {
                case "water":  iconName = "drop"
                case "coffee": iconName = "cup.and.saucer"
                case "juice":  iconName = "takeoutbag.and.cup.and.straw"
                default:       iconName = "drop"
                }

                let timeString = formatter.string(from: log.date)

                let row = ActivityRowView(
                    title: log.type,
                    subtitle: "\(log.quantity) ml",
                    time: timeString,
                    icon: UIImage(systemName: iconName)
                )
                row.translatesAutoresizingMaskIntoConstraints = false
                stack.addArrangedSubview(row)
            }

            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: todaysLogContainer.topAnchor),
                stack.leadingAnchor.constraint(equalTo: todaysLogContainer.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: todaysLogContainer.trailingAnchor),
                stack.bottomAnchor.constraint(equalTo: todaysLogContainer.bottomAnchor)
            ])
        }
    }



    
    
    
    private func setupWaveView() {
        waveView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(waveView, at: 0)
        
        NSLayoutConstraint.activate([
            waveView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            waveView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            waveView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            waveView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func viewAllTapped() {
        let vc = PreviousLogsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Shared fluid log store (in-memory for this run)

struct FluidLog {
    let type: String
    let quantity: Int
    let date: Date
}

final class FluidLogStore {
    static let shared = FluidLogStore()
    private init() {}

    private var logs: [FluidLog] = []

    func addLog(type: String, quantity: Int, date: Date = Date()) {
        let log = FluidLog(type: type, quantity: quantity, date: date)
        logs.append(log)
    }

    func todayLogs() -> [FluidLog] {
        let calendar = Calendar.current
        return logs.filter { calendar.isDateInToday($0.date) }
    }
}
