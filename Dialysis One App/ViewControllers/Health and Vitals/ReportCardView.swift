//
//  ReportCardView.swift
//  Dialysis One App
//
//  Created by user@22 on 09/11/25.
//

import UIKit

class ReportCardView: UIView {
    
    // MARK: - IBOutlets
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    // MARK: - Properties
    var report: BloodReport? {
        didSet {
            updateUI()
        }
    }
    
    var onTap: (() -> Void)?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        let nib = UINib(nibName: "ReportCardView", bundle: nil)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else { return }
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        
        setupGesture()
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Card styling
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 2)
        backgroundColor = .white
        
        // Thumbnail styling
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
    }
    
    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    @objc private func viewTapped() {
        // Add tap animation
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
        
        onTap?()
    }
    
    // MARK: - Update UI
    private func updateUI() {
        guard let report = report else { return }
        
        // Set title (from form)
        titleLabel.text = report.title
        
        // Set type (from form)
        typeLabel.text = report.type
        
        // Format and set date (from form)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        dateLabel.text = formatter.string(from: report.date)
        
        // Set thumbnail from PDF
        if let thumbnailData = report.thumbnailImage,
           let thumbnailImage = PDFHelper.dataToImage(thumbnailData) {
            // Use actual PDF thumbnail
            thumbnailImageView.image = thumbnailImage
        } else if let fileURL = report.attachmentURL {
            // Generate thumbnail if not already stored
            if let thumbnail = PDFHelper.generateThumbnail(from: fileURL, size: CGSize(width: 120, height: 120)) {
                thumbnailImageView.image = thumbnail
            } else {
                // Fallback: show PDF icon
                showPDFIcon()
            }
        } else {
            // No attachment: show PDF icon
            showPDFIcon()
        }
    }
    
    private func showPDFIcon() {
        thumbnailImageView.image = UIImage(systemName: "doc.text.fill")
        thumbnailImageView.tintColor = .systemRed
        thumbnailImageView.contentMode = .scaleAspectFit
        thumbnailImageView.backgroundColor = UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1.0)
    }
}
