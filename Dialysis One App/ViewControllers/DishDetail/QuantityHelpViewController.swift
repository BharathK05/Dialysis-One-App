//
//  QuantityHelpViewController.swift
//  Dialysis One App
//
//  Visual guide for portion sizes - Healthify style
//

import UIKit

final class QuantityHelpViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        sv.backgroundColor = .systemBackground
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Quantity Help"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose a portion to estimate serving size. Use the images and labels below to match the container you used. If a portion doesn't match, choose 'grams' and enter the weight."
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let gridView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.isScrollEnabled = false
        return cv
    }()
    
    private let tipCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.1)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let tipIcon: UILabel = {
        let label = UILabel()
        label.text = "💡"
        label.font = .systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tipLabel: UILabel = {
        let label = UILabel()
        label.text = "If you know the weight in grams, choose 'grams' and enter the exact number for the most accurate results."
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = UIColor(red: 0.4, green: 0.7, blue: 0.5, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Data
    
    private let helpItems = PortionLibrary.helpItems
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(gridView)
        contentView.addSubview(tipCard)
        
        tipCard.addSubview(tipIcon)
        tipCard.addSubview(tipLabel)
        
        contentView.addSubview(closeButton)
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        // Calculate grid height based on number of items (2 columns)
        let rows = ceil(Double(helpItems.count) / 2.0)
        let gridHeight = (rows * 160.0) + ((rows - 1) * 12.0)
        
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
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            gridView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 24),
            gridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            gridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            gridView.heightAnchor.constraint(equalToConstant: gridHeight),
            
            tipCard.topAnchor.constraint(equalTo: gridView.bottomAnchor, constant: 24),
            tipCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tipCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            tipIcon.topAnchor.constraint(equalTo: tipCard.topAnchor, constant: 16),
            tipIcon.leadingAnchor.constraint(equalTo: tipCard.leadingAnchor, constant: 16),
            tipIcon.widthAnchor.constraint(equalToConstant: 24),
            
            tipLabel.topAnchor.constraint(equalTo: tipCard.topAnchor, constant: 16),
            tipLabel.leadingAnchor.constraint(equalTo: tipIcon.trailingAnchor, constant: 12),
            tipLabel.trailingAnchor.constraint(equalTo: tipCard.trailingAnchor, constant: -16),
            tipLabel.bottomAnchor.constraint(equalTo: tipCard.bottomAnchor, constant: -16),
            
            closeButton.topAnchor.constraint(equalTo: tipCard.bottomAnchor, constant: 24),
            closeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            closeButton.heightAnchor.constraint(equalToConstant: 50),
            closeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    private func setupCollectionView() {
        gridView.delegate = self
        gridView.dataSource = self
        gridView.register(PortionHelpCell.self, forCellWithReuseIdentifier: "PortionHelpCell")
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UICollectionView Delegate & DataSource

extension QuantityHelpViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return helpItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PortionHelpCell", for: indexPath) as! PortionHelpCell
        
        let item = helpItems[indexPath.item]
        cell.configure(imageName: item.imageName, label: item.label, volume: item.volume)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 12
        let width = (collectionView.bounds.width - padding) / 2
        return CGSize(width: width, height: 160)
    }
}

// MARK: - Portion Help Cell

final class PortionHelpCell: UICollectionViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemGray2
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let volumeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray5.cgColor
        
        contentView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(volumeLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 70),
            imageView.heightAnchor.constraint(equalToConstant: 70),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            volumeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            volumeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            volumeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            volumeLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(imageName: String, label: String, volume: String) {
        imageView.image = UIImage(systemName: imageName)
        nameLabel.text = label
        volumeLabel.text = volume
    }
}
