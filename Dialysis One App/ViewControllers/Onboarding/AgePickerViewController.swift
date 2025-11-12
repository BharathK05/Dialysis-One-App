import UIKit

final class AgePickerViewController: UIViewController {

    private let ages = Array(10...100)
    private var selectedIndex: Int = 10

    // Perfect for showing exactly 3 numbers at once
    private let cellWidth: CGFloat = 95
    private var cellSpacing: CGFloat = 24   // now computed dynamically
    private let cellID = "AgeCell"

    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.progressTintColor = UIColor(named: "onboarding green")
        pv.trackTintColor = UIColor.systemGray5
        pv.setProgress(0.4, animated: false)  // After gender (0.2) + this (0.2)
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "What's your age?"
        label.font = .systemFont(ofSize: 30, weight: .bold) 
        label.textColor = UIColor(named: "onboarding green")
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    



    private lazy var ageCollectionView: UICollectionView = {
        let layout = OneRowFlowLayout()
        layout.itemSize = CGSize(width: cellWidth, height: 120)
        layout.minimumLineSpacing = cellSpacing

        

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.dataSource = self
        cv.delegate = self
        cv.register(AgeCell.self, forCellWithReuseIdentifier: cellID)
        return cv
    }()

    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.layer.cornerRadius = 14
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(named: "onboarding green")?.withAlphaComponent(0.15)
        button.setTitleColor(.systemGray, for: .normal)
        button.isEnabled = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        centerOnDefault()
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        ageCollectionView.alwaysBounceVertical = false
        ageCollectionView.isScrollEnabled = true
        ageCollectionView.isScrollEnabled = true

        
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let layout = ageCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        layout.itemSize = CGSize(width: cellWidth, height: ageCollectionView.bounds.height)
        layout.minimumLineSpacing = cellSpacing
        layout.minimumInteritemSpacing = .greatestFiniteMagnitude
        
        
    }


    private func setupLayout() {
        view.addSubview(progressView)
        view.addSubview(titleLabel)
        view.addSubview(ageCollectionView)
        view.addSubview(nextButton)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            titleLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 32),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            
            ageCollectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ageCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ageCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ageCollectionView.heightAnchor.constraint(equalToConstant: 120),

            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            nextButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }


    private func centerOnDefault() {
        if let start = ages.firstIndex(of: 21) { selectedIndex = start }
        view.layoutIfNeeded()
        applyInsets()
        scrollToSelected(animated: false)
    }

    private func applyInsets() {
        // Make exactly 3 cells fit perfectly in width
        let totalWidth = view.bounds.width
        let targetCellCount: CGFloat = 3

        let totalCellWidth = cellWidth * targetCellCount
        let remaining = totalWidth - totalCellWidth

        let spacing = max(8, remaining / (targetCellCount - 1)) // dynamic spacing (never below 8)
        
        if let layout = ageCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = spacing
        }

        // Also ensure side inset centers the selected cell
        let sideInset = (totalWidth - cellWidth) / 2
        ageCollectionView.contentInset = UIEdgeInsets(top: 0, left: sideInset, bottom: 0, right: sideInset)
    }
    



    private func scrollToSelected(animated: Bool) {
        ageCollectionView.scrollToItem(at: IndexPath(item: selectedIndex, section: 0), at: .centeredHorizontally, animated: animated)
        ageCollectionView.reloadData()

        // POP animation on center cell
        if let cell = ageCollectionView.cellForItem(at: IndexPath(item: selectedIndex, section: 0)) {
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.6) {
                cell.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
            } completion: { _ in
                UIView.animate(withDuration: 0.2) {
                    cell.transform = .identity
                }
            }
        }

        // Next button activation animation
        UIView.animate(withDuration: 0.25) {
            self.nextButton.backgroundColor = UIColor(named: "onboarding green")
            self.nextButton.setTitleColor(.white, for: .normal)
            self.nextButton.transform = CGAffineTransform(scaleX: 1.01, y: 1.01)
        }
        UIView.animate(withDuration: 0.25, delay: 0.25) {
            self.nextButton.transform = .identity
        }

        nextButton.isEnabled = true
    }


    @objc private func nextTapped() {
        let age = ages[selectedIndex]
        print("Age selected:", age)
        // navigate next screen here...
        let heightVC = HeightPickerViewController()
        navigationController?.pushViewController(heightVC, animated: true)
    }
}

extension AgePickerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { ages.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! AgeCell
        cell.configure(age: ages[indexPath.item], isSelected: indexPath.item == selectedIndex)
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let centerX = ageCollectionView.contentOffset.x + ageCollectionView.bounds.width / 2

        for indexPath in ageCollectionView.indexPathsForVisibleItems {
            guard let cell = ageCollectionView.cellForItem(at: indexPath) as? AgeCell,
                  let attrs = ageCollectionView.layoutAttributesForItem(at: indexPath) else { continue }

            let distance = abs(attrs.center.x - centerX)
            let t = min(1, distance / (cellWidth + cellSpacing))
            let scale = 1 - 0.25 * t
            cell.contentView.transform = CGAffineTransform(scaleX: scale, y: scale)
            cell.alpha = 1 - 0.35 * t

        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { snapToNearest() }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) { if !decelerate { snapToNearest() } }

    private func snapToNearest() {
        let centerX = ageCollectionView.contentOffset.x + ageCollectionView.bounds.width / 2
        var nearest = selectedIndex
        var minDist = CGFloat.greatestFiniteMagnitude

        for indexPath in ageCollectionView.indexPathsForVisibleItems {
            if let attrs = ageCollectionView.layoutAttributesForItem(at: indexPath) {
                let d = abs(attrs.center.x - centerX)
                if d < minDist { minDist = d; nearest = indexPath.item }
            }
        }
        selectedIndex = nearest
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()  // ✅ HAPTIC SNAP
        scrollToSelected(animated: true)
    }
}
