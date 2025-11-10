//
//  AddReportViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 09/11/25.
//

import UIKit
import UniformTypeIdentifiers

protocol AddReportDelegate: AnyObject {
    func didAddReport(report: BloodReport)
}

class AddReportViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var typeTextField: UITextField!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var addAttachmentButton: UIButton!
    @IBOutlet weak var attachedFileView: UIView!
    @IBOutlet weak var filenameLabel: UILabel!
    
    
    // MARK: - Properties
    weak var delegate: AddReportDelegate?
    var selectedDate: Date = Date()
    var attachedFileURL: URL?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
    }
    
    // MARK: - Setup
    func setupNavigationBar() {
        title = "Add Blood Report"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
    }
    
    func setupUI() {
        attachedFileView.isHidden = true
        updateDateButton()
    }
    
    func updateDateButton() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy"
        dateButton.setTitle(formatter.string(from: selectedDate), for: .normal)
    }
    
    // MARK: - IBActions
    @IBAction func dateButtonTapped(_ sender: UIButton) {
        showDatePicker()
    }
    
    @IBAction func addAttachmentTapped(_ sender: UIButton) {
        showDocumentPicker()
    }
    
    @IBAction func removeAttachmentTapped(_ sender: UIButton) {
        attachedFileURL = nil
        attachedFileView.isHidden = true
    }
    
    // MARK: - Navigation Actions
    @objc func backTapped() {
        dismiss(animated: true)
    }
    
    @objc func saveTapped() {
        guard let title = titleTextField.text, !title.isEmpty else {
            showAlert(message: "Please enter a title")
            return
        }
        
        guard let type = typeTextField.text, !type.isEmpty else {
            showAlert(message: "Please enter a type")
            return
        }
        
        // Generate thumbnail from PDF (if file attached)
        var thumbnailData: Data?
        if let fileURL = attachedFileURL {
            if let thumbnail = PDFHelper.generateThumbnail(from: fileURL, size: CGSize(width: 120, height: 120)) {
                thumbnailData = PDFHelper.imageToData(thumbnail)
                print("✅ PDF thumbnail generated successfully")
            } else {
                print("⚠️ Failed to generate thumbnail, but continuing...")
            }
        }
        
        // Create report with all data from form
        let report = BloodReport(
            title: title,
            type: type,
            date: selectedDate,
            attachmentURL: attachedFileURL,
            thumbnailImage: thumbnailData
        )
        
        // Debug print
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        print("📋 Report Created:")
        print("   Title: \(report.title)")
        print("   Type: \(report.type)")
        print("   Date: \(formatter.string(from: report.date))")
        print("   Has File: \(report.attachmentURL != nil)")
        print("   Has Thumbnail: \(report.thumbnailImage != nil)")
        
        // Show success message
        showSuccessAndDismiss(report: report)
    }
    
    // MARK: - Date Picker
    func showDatePicker() {
        let alert = UIAlertController(title: "Select Date", message: "\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.date = selectedDate
        datePicker.frame = CGRect(x: 0, y: 50, width: alert.view.frame.width - 20, height: 200)
        
        alert.view.addSubview(datePicker)
        
        alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            self.selectedDate = datePicker.date
            self.updateDateButton()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - Document Picker
    func showDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    // MARK: - Success
    func showSuccessAndDismiss(report: BloodReport) {
        let alert = UIAlertController(
            title: "Report Added Successfully!",
            message: nil,
            preferredStyle: .alert
        )
        
        present(alert, animated: true)
        
        // Auto-dismiss after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true) {
                self.delegate?.didAddReport(report: report)
                self.dismiss(animated: true)
            }
        }
    }
    
    // MARK: - Alert
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension AddReportViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            showAlert(message: "Cannot access file")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Copy file to app's documents directory
        let fileName = url.lastPathComponent
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            // Remove old file if exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Copy file to documents directory
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            // Store the copied file URL (this persists)
            attachedFileURL = destinationURL
            filenameLabel.text = fileName
            attachedFileView.isHidden = false
            
            print("File copied to: \(destinationURL.path)")
            
        } catch {
            print("Error copying file: \(error.localizedDescription)")
            showAlert(message: "Failed to save file: \(error.localizedDescription)")
        }
    }
}
    
