//
//  SymptomDetailViewController.swift
//

import UIKit

final class SymptomDetailViewController: UIViewController {

    var symptom: SymptomDetail!   // set this before pushing

    // Gradient layer holder
    private var gradientLayer: CAGradientLayer?
    
    // Progress State
    private var completedCount = 0
    private var totalTasksCount = 0
    private let progressContainer = UIView()
    private let progressLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let feedbackLabel = UILabel()

    // UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stack = UIStackView()

    // Article title (HIG Title 2)
    private let articleTitleLabel: UILabel = {
        let l = UILabel()
        if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2).withSymbolicTraits(.traitBold) {
            l.font = UIFont(descriptor: descriptor, size: 0)
        } else {
            l.font = .systemFont(ofSize: 22, weight: .bold)
        }
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .label
        l.numberOfLines = 0
        l.textAlignment = .left
        return l
    }()
    
    // metaLabel and headerImageView properties removed entirely


    override func viewDidLoad() {
        super.viewDidLoad()

        // nav title intentionally blank (article style uses in-content headline)
        navigationItem.title = "" // keep small top bar minimal

        navigationController?.setNavigationBarHidden(false, animated: false)
        if navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(closeTapped)
            )
        }

        buildLayout()
        populate()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyGradientBackground()
    }

    // MARK: - Gradient
    private func applyGradientBackground() {
        if gradientLayer == nil {
            let g = CAGradientLayer()
            let topColor = UIColor(red: 225/255, green: 245/255, blue: 235/255, alpha: 1)
            let bottomColor = UIColor(red: 200/255, green: 235/255, blue: 225/255, alpha: 1)
            
            g.colors = [topColor.cgColor, bottomColor.cgColor]
            g.startPoint = CGPoint(x: 0.5, y: 0.0)
            g.endPoint = CGPoint(x: 0.5, y: 1.0)
            g.locations = [0.0, 0.7]
            g.type = .axial
            
            view.layer.insertSublayer(g, at: 0)
            gradientLayer = g
        }
        gradientLayer?.frame = view.bounds
    }

    // MARK: - Layout
    private func buildLayout() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        contentView.addSubview(stack)
        stack.axis = .vertical
        stack.spacing = 16 // Unified vertical spacing 16pt
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -36)
        ])

        // Article title (in-content)
        stack.addArrangedSubview(articleTitleLabel)

        // small separator
        let sep = UIView()
        sep.backgroundColor = UIColor.separator.withAlphaComponent(0.06)
        sep.heightAnchor.constraint(equalToConstant: 12).isActive = true
        stack.addArrangedSubview(sep)
    }

    // MARK: - Populate content
    private func populate() {
        articleTitleLabel.text = symptom.title

        let themeColor = UIColor(named: "AppGreen") ?? .systemTeal
        
        // --- Progress Tracking UI ---
        totalTasksCount = (symptom.cures.filter { $0.isGood && resolveContext(for: $0.text, isGood: $0.isGood).isTrackable }).count
        if totalTasksCount > 0 {
            setupProgressUI()
            progressContainer.isHidden = true
            progressContainer.alpha = 0
            stack.addArrangedSubview(progressContainer)
        }
        
        // 1. Overview (Reason) Highlight Card (Minimum text, punchy font)
        let insightLabel = UILabel()
        insightLabel.text = symptom.reason
        insightLabel.numberOfLines = 0
        insightLabel.font = .preferredFont(forTextStyle: .headline)
        insightLabel.adjustsFontForContentSizeCategory = true
        insightLabel.textColor = .label
        insightLabel.textAlignment = .center
        
        // Wrap the image and insight label into a VStack
        let overviewContent = UIStackView()
        overviewContent.axis = .vertical
        overviewContent.spacing = 16
        overviewContent.alignment = .center
        
        // Move Header Image inside Overview
        if let imageName = symptom.imageName, let img = loadImage(named: imageName) {
            let iv = UIImageView(image: img)
            iv.contentMode = .scaleAspectFit
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.heightAnchor.constraint(equalToConstant: 100).isActive = true // 80-120pt recommendation
            overviewContent.addArrangedSubview(iv)
        }
        
        overviewContent.addArrangedSubview(insightLabel)
        
        let reasonCard = makeHighlightCard(categoryText: "Overview",
                                           categoryIconName: "waveform.path.ecg",
                                           categoryColor: themeColor,
                                           mainContent: overviewContent)
        stack.addArrangedSubview(reasonCard)

        // 2. Do's Highlight Card
        let goods = symptom.cures.filter { $0.isGood }
        if !goods.isEmpty {
            let goodsContent = makeListContent(items: goods, isGood: true)
            let dosCard = makeHighlightCard(categoryText: "Recommended",
                                            categoryIconName: "checkmark.seal.fill",
                                            categoryColor: .systemGreen,
                                            mainContent: goodsContent)
            stack.addArrangedSubview(dosCard)
        }

        // 3. Don'ts Highlight Card
        let bads = symptom.cures.filter { !$0.isGood }
        if !bads.isEmpty {
            let badsContent = makeListContent(items: bads, isGood: false)
            let dontsCard = makeHighlightCard(categoryText: "Avoid",
                                              categoryIconName: "xmark.octagon.fill",
                                              categoryColor: .systemRed,
                                              mainContent: badsContent)
            stack.addArrangedSubview(dontsCard)
        }

        // final spacer
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 40).isActive = true
        stack.addArrangedSubview(spacer)
    }
    // MARK: - Progress Helpers
    private func setupProgressUI() {
        progressContainer.backgroundColor = UIColor(named: "AppGreen")?.withAlphaComponent(0.12) ?? .systemBackground
        progressContainer.layer.cornerRadius = 16
        
        progressLabel.font = .preferredFont(forTextStyle: .headline)
        progressLabel.textColor = .label
        
        feedbackLabel.font = .preferredFont(forTextStyle: .subheadline)
        feedbackLabel.textColor = .secondaryLabel
        feedbackLabel.numberOfLines = 0
        
        progressView.progressTintColor = .systemGreen
        progressView.trackTintColor = .systemGray5
        
        let vstack = UIStackView(arrangedSubviews: [progressLabel, progressView, feedbackLabel])
        vstack.axis = .vertical
        vstack.spacing = 10
        
        progressContainer.addSubview(vstack)
        vstack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: progressContainer.topAnchor, constant: 16),
            vstack.bottomAnchor.constraint(equalTo: progressContainer.bottomAnchor, constant: -16),
            vstack.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor, constant: 16),
            vstack.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor, constant: -16)
        ])
        
        updateProgressUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleProgressStarted), name: NSNotification.Name("ProgressStarted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleProgressUpdated), name: NSNotification.Name("ProgressUpdated"), object: nil)
    }
    
    @objc private func handleProgressStarted() {
        if progressContainer.isHidden {
            progressContainer.isHidden = false
            UIView.animate(withDuration: 0.4) {
                self.progressContainer.alpha = 1
                self.stack.layoutIfNeeded()
            }
        }
    }
    
    @objc private func handleProgressUpdated() {
        if completedCount < totalTasksCount {
            completedCount += 1
            updateProgressUI()
        }
    }
    
    private func updateProgressUI() {
        progressLabel.text = "\(completedCount)/\(totalTasksCount) completed today"
        
        let progress = Float(completedCount) / Float(totalTasksCount)
        progressView.setProgress(progress, animated: true)
        
        if completedCount == 0 {
            feedbackLabel.text = "Try starting with something light."
        } else if completedCount == totalTasksCount {
            feedbackLabel.text = "Great job staying consistent! You've accomplished your goal."
        } else {
            feedbackLabel.text = "Keep going! You're making good progress."
        }
    }

    // MARK: - Health App Highlight Helpers

    private func makeHighlightCard(categoryText: String, categoryIconName: String, categoryColor: UIColor, mainContent: UIView) -> UIView {
        let card = UIView()
        // Liquid glass effect matching the main screen grid cells
        card.backgroundColor = UIColor(red: 230/255, green: 250/255, blue: 240/255, alpha: 0.55)
        card.layer.cornerRadius = 24
        card.layer.shadowColor = UIColor(red: 0, green: 80/255, blue: 50/255, alpha: 1).cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowOffset = CGSize(width: 0, height: 8)
        card.layer.shadowRadius = 16
        card.layer.borderWidth = 1.0
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.7).cgColor

        // Category Tag
        let icon = UIImageView(image: UIImage(systemName: categoryIconName))
        icon.tintColor = categoryColor
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let catLabel = UILabel()
        catLabel.text = categoryText.uppercased()
        catLabel.font = .systemFont(ofSize: 14, weight: .bold)
        catLabel.textColor = categoryColor

        let topStack = UIStackView(arrangedSubviews: [icon, catLabel])
        topStack.axis = .horizontal
        topStack.spacing = 6
        topStack.alignment = .center

        // Main vertical stack containing tag and the huge highlight text/list
        let vstack = UIStackView(arrangedSubviews: [topStack, mainContent])
        vstack.axis = .vertical
        vstack.spacing = 16
        vstack.alignment = .fill

        card.addSubview(vstack)
        vstack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            vstack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
            vstack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            vstack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20)
        ])

        return card
    }

    private func makeListContent(items: [CureItem], isGood: Bool) -> UIView {
        let vstack = UIStackView()
        vstack.axis = .vertical
        vstack.spacing = 18 // breathable space between steps
        
        for item in items {
            let row = InteractiveActionRow(item: item, isGood: isGood, delegate: self)
            vstack.addArrangedSubview(row)
        }
        return vstack
    }

    // InteractiveActionRow replaces makeCleanRow
// MARK: - Interactive Action Row

class InteractiveActionRow: UIView {
    private let item: CureItem
    private let isGood: Bool
    private weak var delegate: UIViewController?
    private let context: ActionContext
    
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let expandIndicator = UIImageView()
    
    private let topStack = UIStackView()
    private let detailContainer = UIStackView()
    private let promptStack = UIStackView()
    private let promptStatusLabel = UILabel()
    
    private var isExpanded = false
    private var isCompleted = false
    
    init(item: CureItem, isGood: Bool, delegate: UIViewController?) {
        self.item = item
        self.isGood = isGood
        self.delegate = delegate
        self.context = resolveContext(for: item.text, isGood: isGood)
        super.init(frame: .zero)
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) { nil }
    
    private func setupUI() {
        self.isUserInteractionEnabled = true
        self.clipsToBounds = true
        self.layer.cornerRadius = 12
        
        // Icon
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 38).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 38).isActive = true
        iconView.contentMode = .scaleAspectFill
        iconView.layer.cornerRadius = 8
        iconView.clipsToBounds = true
        
        // Fallback resolution logic natively supported in the original makeCleanRow
        if let name = item.imageName, let img = UIImage(named: name) {
            iconView.image = img
        } else if let name = item.imageName, name.contains("/"), let data = try? Data(contentsOf: URL(fileURLWithPath: name)) {
            iconView.image = UIImage(data: data)
        } else {
            iconView.image = UIImage(systemName: isGood ? "checkmark.circle.fill" : "xmark.circle.fill")
            iconView.tintColor = isGood ? .systemGreen : .systemRed
        }
        
        // Title
        titleLabel.text = item.text
        titleLabel.numberOfLines = 0
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .label
        
        // Indicator
        expandIndicator.image = UIImage(systemName: "chevron.right")
        expandIndicator.tintColor = .tertiaryLabel
        expandIndicator.contentMode = .scaleAspectFit
        expandIndicator.widthAnchor.constraint(equalToConstant: 16).isActive = true
        
        topStack.addArrangedSubview(iconView)
        topStack.addArrangedSubview(titleLabel)
        topStack.addArrangedSubview(expandIndicator)
        topStack.axis = .horizontal
        topStack.spacing = 16
        topStack.alignment = .center
        
        // Detail content
        detailContainer.axis = .vertical
        detailContainer.spacing = 12
        detailContainer.isHidden = true
        detailContainer.isLayoutMarginsRelativeArrangement = true
        detailContainer.layoutMargins = UIEdgeInsets(top: 8, left: 54, bottom: 8, right: 16)
        
        let explanationLabel = UILabel()
        explanationLabel.text = context.explanation
        explanationLabel.numberOfLines = 0
        explanationLabel.font = .preferredFont(forTextStyle: .subheadline)
        explanationLabel.textColor = .secondaryLabel
        detailContainer.addArrangedSubview(explanationLabel)
        
        // Bullet steps
        if !context.steps.isEmpty {
            let stepsStack = UIStackView()
            stepsStack.axis = .vertical
            stepsStack.spacing = 6
            for step in context.steps {
                let lbl = UILabel()
                lbl.text = "• \(step)"
                lbl.font = .preferredFont(forTextStyle: .footnote)
                lbl.textColor = .secondaryLabel
                lbl.numberOfLines = 0
                stepsStack.addArrangedSubview(lbl)
            }
            detailContainer.addArrangedSubview(stepsStack)
        }
        
        // Meta duration
        if let meta = context.meta {
            let metaLabel = UILabel()
            metaLabel.text = meta
            metaLabel.font = .systemFont(ofSize: 13, weight: .semibold)
            metaLabel.textColor = UIColor(named: "AppGreen") ?? .systemGreen
            detailContainer.addArrangedSubview(metaLabel)
        }
        
        // Interactive Follow up Prompt
        if context.isTrackable {
            promptStack.axis = .vertical
            promptStack.spacing = 10
            
            promptStatusLabel.text = "Did you try this today?"
            promptStatusLabel.font = .preferredFont(forTextStyle: .footnote)
            promptStatusLabel.textColor = .label
            
            let btnStack = UIStackView()
            btnStack.axis = .horizontal
            btnStack.spacing = 12
            btnStack.distribution = .fillEqually
            
            let noBtn = UIButton(type: .system)
            noBtn.setTitle("Not yet", for: .normal)
            noBtn.backgroundColor = .systemGray5
            noBtn.tintColor = .label
            noBtn.layer.cornerRadius = 10
            noBtn.layer.borderWidth = 1
            noBtn.layer.borderColor = UIColor.systemGray4.cgColor
            noBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            noBtn.addTarget(self, action: #selector(handleNotYetTapped), for: .touchUpInside)
            
            let yesBtn = UIButton(type: .system)
            yesBtn.setTitle("Yes", for: .normal)
            yesBtn.backgroundColor = .systemGreen.withAlphaComponent(0.15)
            yesBtn.tintColor = .systemGreen
            yesBtn.layer.cornerRadius = 10
            yesBtn.layer.borderWidth = 1
            yesBtn.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.3).cgColor
            yesBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            yesBtn.addTarget(self, action: #selector(handleYesTapped), for: .touchUpInside)
            
            btnStack.addArrangedSubview(noBtn)
            btnStack.addArrangedSubview(yesBtn)
            btnStack.heightAnchor.constraint(equalToConstant: 44).isActive = true
            
            promptStack.addArrangedSubview(promptStatusLabel)
            promptStack.addArrangedSubview(btnStack)
            detailContainer.addArrangedSubview(promptStack)
            
            promptStack.addArrangedSubview(promptStatusLabel)
            promptStack.addArrangedSubview(btnStack)
            detailContainer.addArrangedSubview(promptStack)
        }
        
        let verticalStack = UIStackView(arrangedSubviews: [topStack, detailContainer])
        verticalStack.axis = .vertical
        verticalStack.spacing = 0
        
        addSubview(verticalStack)
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            verticalStack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            verticalStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            verticalStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            verticalStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        ])
    }
    
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        
        if context.isTrackable {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
            swipe.direction = .right
            addGestureRecognizer(swipe)
        }
    }
    
    @objc private func handleTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        // Log interaction logic
        if !isExpanded && context.isTrackable {
            // Unhide prompt to grab user attention
            promptStack.isHidden = false
        }
        
        isExpanded.toggle()
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.detailContainer.isHidden = !self.isExpanded
            self.expandIndicator.transform = self.isExpanded ? CGAffineTransform(rotationAngle: .pi/2) : .identity
            self.superview?.layoutIfNeeded()
        }
    }
    
    @objc private func handleYesTapped(_ sender: UIButton) {
        guard !isCompleted else { return }
        NotificationCenter.default.post(name: NSNotification.Name("ProgressStarted"), object: nil)
        
        UIView.animate(withDuration: 0.2) {
            sender.backgroundColor = .systemGreen.withAlphaComponent(0.3)
        }
        
        promptStatusLabel.text = "Great! Keep it up 👍"
        promptStatusLabel.textColor = .systemGreen
        
        // Hide the action buttons, leave the label
        if let btnStack = promptStack.arrangedSubviews.last {
            UIView.animate(withDuration: 0.3) {
                btnStack.isHidden = true
            }
        }
        
        handleSwipe()
    }
    
    @objc private func handleNotYetTapped(_ sender: UIButton) {
        if !isCompleted {
            NotificationCenter.default.post(name: NSNotification.Name("ProgressStarted"), object: nil)
            promptStatusLabel.text = "Try starting with a small step today."
            
            UIView.animate(withDuration: 0.2) {
                sender.backgroundColor = .systemGray4
            }
            
            // Hide the action buttons, leave the label
            if let btnStack = promptStack.arrangedSubviews.last {
                UIView.animate(withDuration: 0.3) {
                    btnStack.isHidden = true
                }
            }
        }
    }
    
    @objc private func handleSwipe() {
        guard !isCompleted else { return }
        isCompleted = true
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut) {
            self.backgroundColor = (UIColor(named: "AppGreen") ?? .systemGreen).withAlphaComponent(0.15)
            self.iconView.image = UIImage(systemName: "checkmark.circle.fill")
            self.iconView.tintColor = .systemGreen
            
            let attrString = NSMutableAttributedString(string: self.titleLabel.text ?? "")
            attrString.addAttribute(.strikethroughStyle, value: 2, range: NSMakeRange(0, attrString.length))
            self.titleLabel.attributedText = attrString
            
            self.alpha = 0.7
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("ProgressStarted"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("ProgressUpdated"), object: nil)
    }
}

    // MARK: - Image loading (bundle assets or file path)

    private func loadImage(named name: String) -> UIImage? {
        if let img = UIImage(named: name) { return img }

        // helpful developer fallback — the file you uploaded earlier:
        // /mnt/data/Screenshot 2025-11-25 at 11.33.29 AM.png
        if name.contains("/") {
            let url = URL(fileURLWithPath: name)
            if let data = try? Data(contentsOf: url) {
                return UIImage(data: data)
            }
        }
        return nil
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        if presentingViewController != nil {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}
