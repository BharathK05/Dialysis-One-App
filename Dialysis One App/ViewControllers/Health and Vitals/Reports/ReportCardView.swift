//
//  ReportCardView.swift
//  Dialysis One App
//
//  Created by user@22 on 18/11/25.
//

import UIKit

protocol ReportCardSwipeDelegate: AnyObject {
    func didRequestDelete(_ card: ReportCardView)
}

class ReportCardView: UIView {

    weak var swipeDelegate: ReportCardSwipeDelegate?

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        enableSwipe()
    }

    private func enableSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipe.direction = .left
        addGestureRecognizer(swipe)
    }

    @objc private func handleSwipe() {
        swipeDelegate?.didRequestDelete(self)
    }

    private let thumb = UIImageView()
    private let titleLabel = UILabel()
    private let typeLabel = UILabel()
    private let dateLabel = UILabel()

    var onTap: (() -> Void)?

    var report: BloodReport? {
        didSet { configure() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); build() }

    private func build() {
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width:0, height:2)

        thumb.translatesAutoresizingMaskIntoConstraints = false
        thumb.layer.cornerRadius = 6
        thumb.clipsToBounds = true
        thumb.backgroundColor = UIColor(white: 0.95, alpha: 1)

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        typeLabel.font = UIFont.systemFont(ofSize: 13)
        typeLabel.textColor = .gray
        dateLabel.font = UIFont.systemFont(ofSize: 13)
        dateLabel.textColor = .gray

        let vstack = UIStackView(arrangedSubviews: [titleLabel, typeLabel, dateLabel])
        vstack.axis = .vertical
        vstack.spacing = 4
        vstack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(thumb)
        addSubview(vstack)

        NSLayoutConstraint.activate([
            thumb.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            thumb.centerYAnchor.constraint(equalTo: centerYAnchor),
            thumb.widthAnchor.constraint(equalToConstant: 56),
            thumb.heightAnchor.constraint(equalToConstant: 56),

            vstack.leadingAnchor.constraint(equalTo: thumb.trailingAnchor, constant: 12),
            vstack.centerYAnchor.constraint(equalTo: centerYAnchor),
            vstack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    private func configure() {
        guard let r = report else { return }
        titleLabel.text = r.title
        typeLabel.text = r.type
        let fmt = DateFormatter(); fmt.dateStyle = .medium
        dateLabel.text = fmt.string(from: r.date)

        if let data = r.thumbnailData, let im = UIImage(data: data) {
            thumb.image = im
            thumb.contentMode = .scaleAspectFill
        } else if let url = r.attachmentURL, let im = FileStorage.shared.generatePDFThumbnail(url: url, size: CGSize(width:120, height:120)) {
            thumb.image = im
            thumb.contentMode = .scaleAspectFill
        } else {
            thumb.image = UIImage(systemName: "doc.text.fill")
            thumb.tintColor = .systemRed
            thumb.contentMode = .center
        }
    }

    @objc private func tapped() { onTap?() }
}
