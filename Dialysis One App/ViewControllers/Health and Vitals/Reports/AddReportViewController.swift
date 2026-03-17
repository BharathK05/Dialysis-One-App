//
//  AddReportViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 18/11/25.
//

import UIKit
import UniformTypeIdentifiers
import PDFKit
import VisionKit

protocol AddReportDelegate: AnyObject {
    func addReportDidSave(_ report: BloodReport)
}

class AddReportViewController: UIViewController, UIDocumentPickerDelegate {
    
    private var selectedDate: Date = Date()

    private var formattedDate: String {
        let df = DateFormatter()
        df.dateFormat = "dd MMM yyyy"
        return df.string(from: selectedDate)
    }


    weak var delegate: AddReportDelegate?

    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let titleField = UITextField()

    private let dateButton = UIButton(type: .system)
    private let fileAddButton = UIButton(type: .system)

    private let attachmentContainer = UIView()   // shows file name + X button
    private let attachmentLabel = UILabel()
    private let removeAttachmentButton = UIButton(type: .system)

    private var selectedFileURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        buildUI()
        setupNav()
        addKeyboardDoneButton()
    }

    private func setupNav() {
        navigationItem.title = "Add Blood Report"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(saveTapped))
    }

    // MARK: - UI Setup
    private func buildUI() {

        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        content.axis = .vertical
        content.spacing = 24
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor)
        ])

        // --- TITLE FIELD ---
        content.addArrangedSubview(makeLabel("Title"))
        styleTextField(titleField, placeholder: "Enter Report Title")
        content.addArrangedSubview(titleField)

        // --- DATE SECTION ---
        content.addArrangedSubview(makeLabel("Date"))
        let dateRow = buildDateRow()
        dateRow.tag = 999
        content.addArrangedSubview(dateRow)


        // --- ATTACH SECTION ---
        content.addArrangedSubview(makeLabel("Attach Report"))
        content.addArrangedSubview(buildAttachOptions())

        // attachment preview container (hidden until file selected)
        configureAttachmentContainer()
        attachmentContainer.isHidden = true
        content.addArrangedSubview(attachmentContainer)

    }

    private func styleTextField(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.font = .systemFont(ofSize: 16)
        field.backgroundColor = UIColor(white: 0.95, alpha: 1)
        field.layer.cornerRadius = 14
        field.heightAnchor.constraint(equalToConstant: 52).isActive = true
        field.setLeftPadding(15)
    }

    private func makeLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = UIFont.boldSystemFont(ofSize: 18)
        return lbl
    }

    // --- DATE BUTTON (Right side button) ---
    private func configureDateButton() {
        dateButton.setTitle(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none), for: .normal)
        dateButton.setTitleColor(.systemBlue, for: .normal)
        dateButton.titleLabel?.font = .systemFont(ofSize: 16)

        // NEW: Align text to right
        dateButton.contentHorizontalAlignment = .right

        dateButton.backgroundColor = UIColor(white: 0.95, alpha: 1)
        dateButton.layer.cornerRadius = 14
        dateButton.heightAnchor.constraint(equalToConstant: 52).isActive = true

        dateButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)

        dateButton.addTarget(self, action: #selector(openDatePicker), for: .touchUpInside)
    }

    // --- ADD (+) BUTTON ---
    private func configureAddButton() {
        fileAddButton.setTitle(nil, for: .normal)
        fileAddButton.setImage(UIImage(systemName: "plus"), for: .normal)
        fileAddButton.tintColor = .systemBlue

        fileAddButton.backgroundColor = UIColor(white: 0.95, alpha: 1)
        fileAddButton.layer.cornerRadius = 14

        // Figma-like height + padding
        fileAddButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        fileAddButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        fileAddButton.addTarget(self, action: #selector(openFilePicker), for: .touchUpInside)
    }
    
    // --- ATTACHMENT PREVIEW BOX ---
    private func configureAttachmentContainer() {
        attachmentContainer.backgroundColor = UIColor(white: 0.95, alpha: 1)
        attachmentContainer.layer.cornerRadius = 14
        attachmentContainer.heightAnchor.constraint(equalToConstant: 52).isActive = true

        attachmentLabel.font = .systemFont(ofSize: 16)
        attachmentLabel.textColor = .darkGray

        removeAttachmentButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        removeAttachmentButton.tintColor = .gray
        removeAttachmentButton.addTarget(self, action: #selector(removeAttachment), for: .touchUpInside)

        attachmentContainer.addSubview(attachmentLabel)
        attachmentContainer.addSubview(removeAttachmentButton)

        attachmentLabel.translatesAutoresizingMaskIntoConstraints = false
        removeAttachmentButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            attachmentLabel.leadingAnchor.constraint(equalTo: attachmentContainer.leadingAnchor, constant: 12),
            attachmentLabel.centerYAnchor.constraint(equalTo: attachmentContainer.centerYAnchor),

            removeAttachmentButton.trailingAnchor.constraint(equalTo: attachmentContainer.trailingAnchor, constant: -12),
            removeAttachmentButton.centerYAnchor.constraint(equalTo: attachmentContainer.centerYAnchor),
            removeAttachmentButton.widthAnchor.constraint(equalToConstant: 24),
            removeAttachmentButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func buildAttachRow() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(white: 0.95, alpha: 1)
        container.layer.cornerRadius = 14
        container.heightAnchor.constraint(equalToConstant: 52).isActive = true
        
        let plusIcon = UIImageView(image: UIImage(systemName: "plus"))
        plusIcon.tintColor = .systemBlue
        
        let label = UILabel()
        label.text = "Add"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .systemBlue
        
        let hStack = UIStackView(arrangedSubviews: [plusIcon, label])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 6
        
        container.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            hStack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(openFilePicker))
        container.addGestureRecognizer(tap)
        
        return container
    }
    
    // MARK: - Attach Options (Scan / Upload)

    private func buildAttachOptions() -> UIStackView {

        let scanRow = makeActionRow(
            icon: "camera.viewfinder",
            title: "Scan Document",
            selector: #selector(scanDocument)
        )

        let uploadRow = makeActionRow(
            icon: "doc.fill",
            title: "Upload PDF",
            selector: #selector(openFilePicker)
        )

        let stack = UIStackView(arrangedSubviews: [scanRow, uploadRow])
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }

    private func makeActionRow(icon: String, title: String, selector: Selector) -> UIView {

        let container = UIView()
        container.backgroundColor = UIColor(white: 0.95, alpha: 1)
        container.layer.cornerRadius = 14
        container.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .systemBlue

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .systemBlue

        let hStack = UIStackView(arrangedSubviews: [iconView, label])
        hStack.axis = .horizontal
        hStack.spacing = 10
        hStack.alignment = .center

        container.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            hStack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: selector)
        container.addGestureRecognizer(tap)

        return container
    }
    
    @objc private func scanDocument() {
        guard VNDocumentCameraViewController.isSupported else {
            alert("Document scanning is not supported on this device.")
            return
        }

        let scanner = VNDocumentCameraViewController()
        scanner.delegate = self
        present(scanner, animated: true)
    }

    
    private func buildDateRow() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(white: 0.95, alpha: 1)
        container.layer.cornerRadius = 14
        container.heightAnchor.constraint(equalToConstant: 52).isActive = true
        
        let label = UILabel()
        label.text = formattedDate
        label.font = .systemFont(ofSize: 16)
        label.textColor = .systemBlue
        label.textAlignment = .center   // ← CENTERED DATE
        
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(openDatePicker))
        container.addGestureRecognizer(tap)
        
        return container
    }

    
    private func refreshDateRow() {
        let newRow = buildDateRow()
        newRow.tag = 999

        if let index = content.arrangedSubviews.firstIndex(where: { $0.tag == 999 }) {
            let oldRow = content.arrangedSubviews[index]
            content.removeArrangedSubview(oldRow)
            oldRow.removeFromSuperview()

            content.insertArrangedSubview(newRow, at: index)
        }
    }




    // MARK: - Actions

    @objc private func openDatePicker() {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.date = selectedDate

        let alert = UIAlertController(title: "Select Date", message: "\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        alert.view.addSubview(picker)

        picker.frame = CGRect(x: 0, y: 40, width: alert.view.frame.width - 20, height: 150)

        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
            self.selectedDate = picker.date
            self.refreshDateRow()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }


    @objc private func openFilePicker() {
        let types = [UTType.pdf]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = self
        present(picker, animated: true)
    }

    // handle selected file
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selected = urls.first else { return }
        selectedFileURL = selected

        attachmentLabel.text = selected.lastPathComponent
        attachmentContainer.isHidden = false
    }

    @objc private func removeAttachment() {
        selectedFileURL = nil
        attachmentContainer.isHidden = true
    }
    
    private func addKeyboardDoneButton() {

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(doneTyping)
        )

        toolbar.items = [flex, done]

        titleField.inputAccessoryView = toolbar
    }

    @objc private func doneTyping() {
        view.endEditing(true)
    }


    @objc private func saveTapped() {

        guard let title = titleField.text, !title.isEmpty else {
            alert("Please enter a report title")
            return
        }

        var filename: String? = nil
        var thumbnail: Data? = nil

        if let fileURL = selectedFileURL {
            do {
                let savedName = try FileStorage.shared.copyFileToDocuments(sourceURL: fileURL)
                filename = savedName

                if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fullURL = docs.appendingPathComponent(savedName)
                    if let img = FileStorage.shared.generatePDFThumbnail(
                        url: fullURL,
                        size: CGSize(width: 80, height: 80)
                    ),
                    let d = img.pngData() {
                        thumbnail = d
                    }
                }
            } catch {
                alert("File save failed")
                return
            }
        }

        // ✅ NO EXTRACTION HERE
        let report = BloodReport(
            title: title,
            date: selectedDate,
            filename: filename,
            thumbnailData: thumbnail
        )

        var reports = FileStorage.shared.loadReports()
        reports.append(report)
        FileStorage.shared.saveReports(reports)

        delegate?.addReportDidSave(report)
        dismiss(animated: true)
    }


    private func alert(_ msg: String) {
        let a = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

extension UITextField {
    func setLeftPadding(_ value: CGFloat) {
        let pad = UIView(frame: CGRect(x: 0, y: 0, width: value, height: self.frame.height))
        leftView = pad
        leftViewMode = .always
    }
}

extension AddReportViewController: VNDocumentCameraViewControllerDelegate {

    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController,
        didFinishWith scan: VNDocumentCameraScan
    ) {
        controller.dismiss(animated: true)

        do {
            let title = titleField.text?.isEmpty == false
                ? titleField.text!
                : "Scanned Report"

            let pdfURL = try FileStorage.shared.saveScanAsPDF(
                scan,
                filename: title
            )
            selectedFileURL = pdfURL
            attachmentLabel.text = pdfURL.lastPathComponent
            attachmentContainer.isHidden = false
        } catch {
            alert("Failed to save scanned document.")
        }
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
}
