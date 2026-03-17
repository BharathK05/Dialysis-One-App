//
//  InsightCardView.swift
//  Dialysis One App
//
//  Created by user@22 on 04/02/26.
//


import UIKit

final class InsightCardView: UIView {

    init(insight: ReportInsight) {
        super.init(frame: .zero)
        build(insight)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func build(_ insight: ReportInsight) {

        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)

        let title = UILabel()
        title.text = insight.title
        title.font = .boldSystemFont(ofSize: 17)

        let message = UILabel()
        message.text = insight.message
        message.font = .systemFont(ofSize: 14)
        message.textColor = .secondaryLabel
        message.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [title, message])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
}
