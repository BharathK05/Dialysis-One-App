//
//  SymptomTableViewCell.swift
//  ReliefGuide
//
//  Created by user@100 on 11/11/25.
//

import UIKit

class SymptomTableViewCell: UITableViewCell {

    @IBOutlet weak var card: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var chevronImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        // Modern, crisp iOS native card
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 20
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius = 14
        card.layer.shadowOffset = CGSize(width: 0, height: 6)
        card.layer.masksToBounds = false
        
        // Add subtle border for depth on light/dark mode
        card.layer.borderWidth = 0.5
        card.layer.borderColor = UIColor.systemGray5.cgColor

        let lightGreen = (UIColor(named: "AppGreen") ?? .systemGreen).withAlphaComponent(0.15)
        
        // Icon chip (subtle background, larger corner radius)
        iconImageView.backgroundColor = lightGreen
        iconImageView.layer.cornerRadius = 14
        iconImageView.clipsToBounds = true
        iconImageView.contentMode = .scaleAspectFill

        // Chevron default
        chevronImageView.image = UIImage(systemName: "chevron.right")?.withConfiguration(UIImage.SymbolConfiguration(weight: .semibold))
        chevronImageView.tintColor = .tertiaryLabel
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
