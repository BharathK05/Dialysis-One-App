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
        let lightGreen = (UIColor(named: "AppGreen") ?? .systemGreen).withAlphaComponent(0.12) // 12% opacity
        card.backgroundColor = lightGreen

        // keep the soft shadow
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius  = 10
        card.layer.shadowOffset  = CGSize(width: 0, height: 5)
        card.layer.masksToBounds = false

        // icon chip (subtle)
        iconImageView.backgroundColor = lightGreen.withAlphaComponent(0.25)
        iconImageView.layer.cornerRadius = 14
        iconImageView.clipsToBounds = true
        iconImageView.contentMode = .center


                // Chevron default
                chevronImageView.image = UIImage(systemName: "chevron.right")
                chevronImageView.tintColor = .tertiaryLabel
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
