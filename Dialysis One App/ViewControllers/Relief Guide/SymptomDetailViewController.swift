//
//  SymptomDetailViewController.swift
//

import UIKit

final class SymptomDetailViewController: UIViewController {

    var symptom: SymptomDetail!   // set this before pushing

    // Gradient layer holder
    private var gradientLayer: CAGradientLayer?

    // UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stack = UIStackView()

    // Article title (big, centered inside content)
    private let articleTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = .label
        l.numberOfLines = 0
        l.textAlignment = .left
        return l
    }()

    // Header image view (full-width, aspect-preserved)
    private let headerImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit   // preserve entire image
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = .tertiarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private var headerHeightConstraint: NSLayoutConstraint?

    // small metadata row (optional)
    private let metaLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textColor = UIColor.secondaryLabel
        return l
    }()

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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyGradientBackground()
    }

    // MARK: - Gradient
    private func applyGradientBackground() {
        if gradientLayer == nil {
            let g = CAGradientLayer()
            g.colors = [
                UIColor(red: 0.94, green: 0.98, blue: 0.95, alpha: 1).cgColor,
                UIColor(red: 0.88, green: 0.97, blue: 0.89, alpha: 1).cgColor
            ]
            g.startPoint = CGPoint(x: 0, y: 0)
            g.endPoint = CGPoint(x: 1, y: 1)
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
        stack.spacing = 20
        stack.alignment = .fill
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -36)
        ])

        // Article title (in-content)
        stack.addArrangedSubview(articleTitleLabel)

        // Meta row under title
        stack.addArrangedSubview(metaLabel)

        // Header image (full-width)
        stack.addArrangedSubview(headerImageView)
        headerHeightConstraint = headerImageView.heightAnchor.constraint(equalToConstant: 200)
        headerHeightConstraint?.isActive = true

        // small separator
        let sep = UIView()
        sep.backgroundColor = UIColor.separator.withAlphaComponent(0.06)
        sep.heightAnchor.constraint(equalToConstant: 12).isActive = true
        stack.addArrangedSubview(sep)
    }

    // MARK: - Populate content
    private func populate() {
        // Title & meta
        articleTitleLabel.text = symptom.title
        metaLabel.text = symptom.reason

        // Load header image — set height based on image aspect ratio so image is fully visible
        if let imageName = symptom.imageName, let img = loadImage(named: imageName) {
            headerImageView.image = img

            // compute desired height to preserve aspect ratio inside the content width
            // content width = view width - stack horizontal insets
            let contentWidth = view.bounds.width - 18 - 18
            let aspect = img.size.height / img.size.width
            let desired = min(max(contentWidth * aspect, 140), 200)


            headerHeightConstraint?.constant = desired
        } else {
            // no image — collapse header
            headerHeightConstraint?.constant = 0
            headerImageView.isHidden = true
        }

        // Reason as an article card
        let reasonHeader = makeSectionHeader("Reason")
        stack.addArrangedSubview(reasonHeader)

        let reasonCard = makeArticleCard(text: symptom.detailedReason)
        stack.addArrangedSubview(reasonCard)

        // Do's section
        let dosHeader = makeSectionHeader("Do's")
        stack.addArrangedSubview(dosHeader)

        let dosContainer = UIStackView()
        dosContainer.axis = .vertical
        dosContainer.spacing = 12
        stack.addArrangedSubview(dosContainer)

        // Don'ts section (will be added after dos rows)
        let dontsHeader = makeSectionHeader("Don'ts")

        let goods = symptom.cures.filter { $0.isGood }
        let bads = symptom.cures.filter { !$0.isGood }

        goods.forEach { item in
            dosContainer.addArrangedSubview(makeArticleRow(text: item.text, imageName: item.imageName, isGood: true))
        }

        stack.addArrangedSubview(dontsHeader)

        let dontsContainer = UIStackView()
        dontsContainer.axis = .vertical
        dontsContainer.spacing = 12
        stack.addArrangedSubview(dontsContainer)

        bads.forEach { item in
            dontsContainer.addArrangedSubview(makeArticleRow(text: item.text, imageName: item.imageName, isGood: false))
        }

        // final spacer
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 40).isActive = true
        stack.addArrangedSubview(spacer)
    }

    // MARK: - UI helpers (article style)

    private func makeSectionHeader(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor(named: "AppGreen") ?? .systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func makeArticleCard(text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.75)
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.withAlphaComponent(0.06).cgColor
        container.layer.shadowOpacity = 1
        container.layer.shadowRadius = 8
        container.layer.shadowOffset = CGSize(width: 0, height: 4)

        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label

        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14)
        ])

        return container
    }

    private func makeArticleRow(text: String, imageName: String?, isGood: Bool) -> UIView {
        // Row container (card-like)
        let container = UIView()
        container.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.6)
        container.layer.cornerRadius = 12

        // Icon (check / x) small circle
        let statusIcon = UIImageView()
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        statusIcon.widthAnchor.constraint(equalToConstant: 30).isActive = true
        statusIcon.heightAnchor.constraint(equalToConstant: 30).isActive = true
        let systemName = isGood ? "checkmark.circle.fill" : "xmark.circle.fill"
        statusIcon.image = UIImage(systemName: systemName)
        statusIcon.tintColor = isGood ? (UIColor(named: "AppGreen") ?? .systemGreen) : .systemRed

        // Thumbnail (optional)
        let thumb = UIImageView()
        thumb.translatesAutoresizingMaskIntoConstraints = false
        thumb.widthAnchor.constraint(equalToConstant: 46).isActive = true
        thumb.heightAnchor.constraint(equalToConstant: 46).isActive = true
        thumb.layer.cornerRadius = 8
        thumb.clipsToBounds = true
        thumb.contentMode = .scaleAspectFill
        thumb.backgroundColor = UIColor.tertiarySystemFill

        if let name = imageName, let img = loadImage(named: name) {
            thumb.image = img
        } else {
            thumb.isHidden = true
        }

        // Label
        let lbl = UILabel()
        lbl.text = text
        lbl.numberOfLines = 0
        lbl.font = .systemFont(ofSize: 16)
        lbl.textColor = .label

        // layout: statusIcon | thumb? | label
        let hstack = UIStackView(arrangedSubviews: [statusIcon])
        hstack.axis = .horizontal
        hstack.alignment = .center
        hstack.spacing = 12

        if !thumb.isHidden { hstack.addArrangedSubview(thumb) }
        hstack.addArrangedSubview(lbl)

        container.addSubview(hstack)
        hstack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hstack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            hstack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            hstack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            hstack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])

        return container
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
