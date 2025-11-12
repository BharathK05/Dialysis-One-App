import UIKit

final class AgeCell: UICollectionViewCell {

    let ageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(ageLabel)

        NSLayoutConstraint.activate([
            ageLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            ageLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(age: Int, isSelected: Bool) {
        ageLabel.text = "\(age)"

        if isSelected {
            ageLabel.font = .systemFont(ofSize: 80, weight: .heavy)
            ageLabel.textColor = UIColor(named: "onboarding green") ?? .systemGreen
            ageLabel.alpha = 1.0
            ageLabel.layer.shadowColor = UIColor(named: "onboarding green")?.cgColor
            ageLabel.layer.shadowOpacity = 0.25
            ageLabel.layer.shadowRadius = 6
            ageLabel.layer.shadowOffset = .zero

        } else {
            ageLabel.font = .systemFont(ofSize: 50, weight: .heavy) //
            ageLabel.textColor = .systemGray3

            ageLabel.alpha = 0.45   // softer fade, still visible
            ageLabel.layer.shadowOpacity = 0

        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds   
    }


}
