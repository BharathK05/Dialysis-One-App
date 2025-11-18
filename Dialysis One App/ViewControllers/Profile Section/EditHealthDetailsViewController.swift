//
//  EditHealthDetailsViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 18/11/25.
//

import UIKit
import PhotosUI
import MobileCoreServices

protocol EditHealthDetailsDelegate: AnyObject {
    /// Called when user saves changes (image optional)
    func editHealthDetailsDidSave(firstName: String?,
                                  lastName: String?,
                                  age: Int?,
                                  gender: String?,
                                  heightCm: Int?,
                                  bloodGroup: String?,
                                  ckdStage: String?,
                                  dialysisFrequency: [String],
                                  profileImage: UIImage?)
}

final class EditHealthDetailsViewController: UIViewController {

    weak var delegate: EditHealthDetailsDelegate?

    // MARK: - UI
    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let profileImageView = UIImageView()
    private let nameStack = UIStackView()
    private let firstNameField = UITextField()
    private let lastNameField = UITextField()

    private let ageField = UITextField()
    private let heightField = UITextField()
    
    private let genderButton = UIButton(type: .system)
    private let bloodGroupButton = UIButton(type: .system)
    private let ckdStageButton = UIButton(type: .system)

    // Frequency: multi select list
    private let frequencyTitle = UILabel()
    private var frequencyOptions: [String] = [
        "Every Monday","Every Tuesday","Every Wednesday","Every Thursday","Every Friday","Every Saturday","Every Sunday"
    ]
    private var selectedFrequency = Set<String>()

    private let frequencyStack = UIStackView()

    // Data model (local for now)
    private var firstName: String?
    private var lastName: String?
    private var age: Int?
    private var heightCm: Int?
    private var gender: String?
    private var bloodGroup: String?
    private var ckdStage: String?
    private var profileImage: UIImage?

    // Pickers lists
    private let genders = ["Male","Female","Other"]
    private let bloodGroups = ["A+","A-","B+","B-","AB+","AB-","O+","O-"]
    private let ckdStages = ["Stage 1","Stage 2","Stage 3","Stage 4","Stage 5","Preventive"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        setupNavBar()
        setupUI()
        loadSavedValuesIfAny()
    }

    private func setupNavBar() {
        title = "Edit Health Details"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "checkmark"),
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(saveTapped))
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        // collect values
        firstName = firstNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        lastName = lastNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let a = Int(ageField.text ?? "") { age = a } else { age = nil }
        if let h = Int(heightField.text ?? "") { heightCm = h } else { heightCm = nil }

        // call delegate
        delegate?.editHealthDetailsDidSave(firstName: firstName,
                                          lastName: lastName,
                                          age: age,
                                          gender: gender,
                                          heightCm: heightCm,
                                          bloodGroup: bloodGroup,
                                          ckdStage: ckdStage,
                                          dialysisFrequency: Array(selectedFrequency),
                                          profileImage: profileImage)

        // persist locally for demo (UserDefaults)
        saveLocally()
        dismiss(animated: true)
    }

    private func saveLocally() {
        var dict = [String: Any]()
        dict["firstName"] = firstName
        dict["lastName"] = lastName
        dict["age"] = age
        dict["heightCm"] = heightCm
        dict["gender"] = gender
        dict["bloodGroup"] = bloodGroup
        dict["ckdStage"] = ckdStage
        dict["frequency"] = Array(selectedFrequency)
        UserDefaults.standard.set(dict, forKey: "EditHealthDetailsLocal_v1")

        if let img = profileImage {
            if let data = img.jpegData(compressionQuality: 0.8) {
                UserDefaults.standard.set(data, forKey: "ProfileImageData_v1")
            }
        }
    }

    private func loadSavedValuesIfAny() {
        if let dict = UserDefaults.standard.dictionary(forKey: "EditHealthDetailsLocal_v1") {
            firstName = dict["firstName"] as? String
            lastName = dict["lastName"] as? String
            age = dict["age"] as? Int
            heightCm = dict["heightCm"] as? Int
            gender = dict["gender"] as? String
            bloodGroup = dict["bloodGroup"] as? String
            ckdStage = dict["ckdStage"] as? String
            if let freq = dict["frequency"] as? [String] {
                selectedFrequency = Set(freq)
            }
        }

        if let data = UserDefaults.standard.data(forKey: "ProfileImageData_v1"),
           let img = UIImage(data: data) {
            profileImage = img
        }

        // populate fields
        firstNameField.text = firstName
        lastNameField.text = lastName
        ageField.text = age != nil ? "\(age!)" : ""
        heightField.text = heightCm != nil ? "\(heightCm!)" : ""
        genderButton.setTitle(gender ?? "Gender", for: .normal)
        bloodGroupButton.setTitle(bloodGroup ?? "Blood Group", for: .normal)
        ckdStageButton.setTitle(ckdStage ?? "CKD Stage", for: .normal)
        updateProfileImageView()
        buildFrequencyRows() // ensure selections visualized
    }

    // MARK: - UI Construction
    private func setupUI() {
        // Scroll + content stack
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        content.axis = .vertical
        content.spacing = 18
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 10),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        // Grabber (visual)
        let grabber = UIView()
        grabber.backgroundColor = UIColor.systemGray4
        grabber.layer.cornerRadius = 2
        grabber.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(grabber)
        grabber.heightAnchor.constraint(equalToConstant: 4).isActive = true
        // center the grabber by wrapping into a container
        let grabberWrap = UIView()
        grabberWrap.translatesAutoresizingMaskIntoConstraints = false
        grabberWrap.addSubview(grabber)
        NSLayoutConstraint.activate([
            grabber.centerXAnchor.constraint(equalTo: grabberWrap.centerXAnchor),
            grabber.centerYAnchor.constraint(equalTo: grabberWrap.centerYAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 36),
            grabber.heightAnchor.constraint(equalToConstant: 4),
            grabberWrap.heightAnchor.constraint(equalToConstant: 24)
        ])

        // replace last arranged item (we want a centered grabber)
        content.removeArrangedSubview(grabber)
        grabber.removeFromSuperview()
        content.addArrangedSubview(grabberWrap)

        // Profile image
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 48
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.systemGreen.cgColor
        profileImageView.backgroundColor = .secondarySystemBackground
        profileImageView.isUserInteractionEnabled = true
        profileImageView.widthAnchor.constraint(equalToConstant: 96).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 96).isActive = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(tap)

        let profileContainer = UIStackView(arrangedSubviews: [profileImageView])
        profileContainer.axis = .vertical
        profileContainer.alignment = .center
        profileContainer.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(profileContainer)

        // Name fields
        let names = UIStackView()
        names.axis = .horizontal
        names.spacing = 12
        names.distribution = .fillEqually
        names.translatesAutoresizingMaskIntoConstraints = false

        firstNameField.placeholder = "First Name"
        firstNameField.borderStyle = .none
        firstNameField.backgroundColor = .clear
        firstNameField.font = UIFont.systemFont(ofSize: 16)
        firstNameField.autocapitalizationType = .words
        firstNameField.translatesAutoresizingMaskIntoConstraints = false
        addUnderline(to: firstNameField)

        lastNameField.placeholder = "Last Name"
        lastNameField.borderStyle = .none
        lastNameField.font = UIFont.systemFont(ofSize: 16)
        lastNameField.translatesAutoresizingMaskIntoConstraints = false

        names.addArrangedSubview(wrapTextField(firstNameField))
        names.addArrangedSubview(wrapTextField(lastNameField))

        content.addArrangedSubview(names)

        // Age + Height row
        let rowAH = UIStackView()
        rowAH.axis = .horizontal
        rowAH.spacing = 12
        rowAH.distribution = .fillEqually
        rowAH.translatesAutoresizingMaskIntoConstraints = false

        ageField.placeholder = "Age"
        ageField.keyboardType = .numberPad
        addUnderline(to: ageField)
        heightField.placeholder = "Height (cm)"
        heightField.keyboardType = .numberPad
        addUnderline(to: heightField)

        rowAH.addArrangedSubview(wrapTextField(ageField))
        rowAH.addArrangedSubview(wrapTextField(heightField))
        content.addArrangedSubview(rowAH)

        // Gender / Blood / CKD buttons
        let rowButtons = UIStackView()
        rowButtons.axis = .horizontal
        rowButtons.spacing = 12
        rowButtons.distribution = .fillEqually
        rowButtons.translatesAutoresizingMaskIntoConstraints = false

        setupValueButton(genderButton, title: "Gender", action: #selector(genderTapped))
        setupValueButton(bloodGroupButton, title: "Blood Group", action: #selector(bloodTapped))
        setupValueButton(ckdStageButton, title: "CKD Stage", action: #selector(ckdTapped))

        rowButtons.addArrangedSubview(genderButton)
        rowButtons.addArrangedSubview(bloodGroupButton)
        rowButtons.addArrangedSubview(ckdStageButton)
        content.addArrangedSubview(rowButtons)

        // Dialysis Frequency title
        frequencyTitle.text = "Dialysis Details"
        frequencyTitle.font = UIFont.boldSystemFont(ofSize: 16)
        frequencyTitle.textColor = .darkGray
        content.addArrangedSubview(frequencyTitle)

        // Frequency card like your design
        frequencyStack.axis = .vertical
        frequencyStack.spacing = 8
        frequencyStack.translatesAutoresizingMaskIntoConstraints = false
        frequencyStack.backgroundColor = .white
        frequencyStack.layer.cornerRadius = 16
        frequencyStack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        frequencyStack.isLayoutMarginsRelativeArrangement = true

        // Add frequency rows
        buildFrequencyRows()

        content.addArrangedSubview(frequencyStack)
    }

    private func wrapTextField(_ tf: UITextField) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 48).isActive = true

        tf.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tf)

        NSLayoutConstraint.activate([
            tf.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            tf.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            tf.topAnchor.constraint(equalTo: container.topAnchor),
            tf.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    private func addUnderline(to tf: UITextField) {
        // we show an underlined label style (no visible full white card)
        tf.borderStyle = .none
    }

    private func setupValueButton(_ btn: UIButton, title: String, action: Selector) {
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.label, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 12
        btn.contentHorizontalAlignment = .left
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        btn.addTarget(self, action: action, for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    private func buildFrequencyRows() {
        frequencyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for option in frequencyOptions {
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 12
            row.translatesAutoresizingMaskIntoConstraints = false
            row.heightAnchor.constraint(equalToConstant: 44).isActive = true

            let check = UIImageView(image: UIImage(systemName: selectedFrequency.contains(option) ? "checkmark.circle.fill" : "circle"))
            check.tintColor = selectedFrequency.contains(option) ? .systemBlue : .systemGray3
            check.translatesAutoresizingMaskIntoConstraints = false
            check.widthAnchor.constraint(equalToConstant: 24).isActive = true
            check.heightAnchor.constraint(equalToConstant: 24).isActive = true

            let lbl = UILabel()
            lbl.text = option
            lbl.font = UIFont.systemFont(ofSize: 15)
            lbl.textColor = .label

            row.addArrangedSubview(check)
            row.addArrangedSubview(lbl)
            row.addArrangedSubview(UIView()) // spacer

            frequencyStack.addArrangedSubview(row)

            // tap
            let tap = UITapGestureRecognizer(target: self, action: #selector(frequencyRowTapped(_:)))
            row.addGestureRecognizer(tap)
            row.isUserInteractionEnabled = true
        }
    }

    @objc private func frequencyRowTapped(_ g: UITapGestureRecognizer) {
        guard let row = g.view as? UIStackView,
              let lbl = (row.arrangedSubviews[1] as? UILabel),
              let text = lbl.text else { return }

        if selectedFrequency.contains(text) {
            selectedFrequency.remove(text)
        } else {
            selectedFrequency.insert(text)
        }
        buildFrequencyRows()
    }

    // MARK: - Pickers / Actions

    @objc private func profileImageTapped() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
            self.presentImagePicker(source: .camera)
        }))
        sheet.addAction(UIAlertAction(title: "Choose from Library", style: .default, handler: { _ in
            self.presentImagePicker(source: .photoLibrary)
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(sheet, animated: true)
    }

    private func presentImagePicker(source: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(source) else {
            let alert = UIAlertController(title: "Not available", message: "This source is not available on the device.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    @objc private func genderTapped() {
        showSingleChoicePicker(title: "Gender", options: genders) { [weak self] selection in
            self?.gender = selection
            self?.genderButton.setTitle(selection, for: .normal)
        }
    }

    @objc private func bloodTapped() {
        showSingleChoicePicker(title: "Blood Group", options: bloodGroups) { [weak self] selection in
            self?.bloodGroup = selection
            self?.bloodGroupButton.setTitle(selection, for: .normal)
        }
    }

    @objc private func ckdTapped() {
        showSingleChoicePicker(title: "CKD Stage", options: ckdStages) { [weak self] selection in
            self?.ckdStage = selection
            self?.ckdStageButton.setTitle(selection, for: .normal)
        }
    }

    private func showSingleChoicePicker(title: String, options: [String], completion: @escaping (String)->Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        for opt in options {
            alert.addAction(UIAlertAction(title: opt, style: .default, handler: { _ in completion(opt) }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true)
    }

    private func updateProfileImageView() {
        if let img = profileImage {
            profileImageView.image = img
            profileImageView.contentMode = .scaleAspectFill
        } else {
            profileImageView.image = UIImage(systemName: "person.circle")
            profileImageView.contentMode = .center
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension EditHealthDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        let img = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        if let chosen = img {
            profileImage = chosen
            updateProfileImageView()
            // notify delegate immediately (optional) so the sheet updates while still open
            delegate?.editHealthDetailsDidSave(firstName: nil,
                                              lastName: nil,
                                              age: nil,
                                              gender: nil,
                                              heightCm: nil,
                                              bloodGroup: nil,
                                              ckdStage: nil,
                                              dialysisFrequency: Array(selectedFrequency),
                                              profileImage: profileImage)
        }
    }
}

