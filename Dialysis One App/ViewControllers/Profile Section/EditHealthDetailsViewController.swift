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
    func editHealthDetailsDidSave(name: String?,
                                  age: Int?,
                                  gender: String?,
                                  heightCm: Int?,
                                  weightKg: Double?,
                                  profileImage: UIImage?)
}

final class EditHealthDetailsViewController: UIViewController {

    weak var delegate: EditHealthDetailsDelegate?

    // MARK: - UI
    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let profileImageView = UIImageView()
    private let nameStack = UIStackView()
    private let nameField = UITextField()

    private let ageField = UITextField()
    private let heightField = UITextField()
    private let weightField = UITextField()
    
    private let genderButton = UIButton(type: .system)

    // Data model (local for now)
    private var name: String?
    private var age: Int?
    private var heightCm: Int?
    private var weightKg: Double?
    private var gender: String?
    private var profileImage: UIImage?

    private let genders = ["Male","Female","Other"]

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
        name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let a = Int(ageField.text ?? "") { age = a } else { age = nil }
        if let h = Int(heightField.text ?? "") { heightCm = h } else { heightCm = nil }
        if let w = Double(weightField.text ?? "") { weightKg = w } else { weightKg = nil }

        if let profile = ProfileManager.shared.currentProfile {
            if let n = name, !n.isEmpty { profile.name = n }
            profile.gender = gender ?? profile.gender
            if let a = age { profile.age = a }
            if let h = heightCm {
                profile.heightCm = Double(h)
            }
            if let w = weightKg {
                profile.weightKg = w
            }
            ProfileManager.shared.updateProfile(profile)
        }

        // call delegate
        delegate?.editHealthDetailsDidSave(name: name,
                                          age: age,
                                          gender: gender,
                                          heightCm: heightCm,
                                          weightKg: weightKg,
                                          profileImage: profileImage)

        dismiss(animated: true)
    }

    private func loadSavedValuesIfAny() {
        if let profile = ProfileManager.shared.currentProfile {
            name = profile.name
            age = profile.age
            heightCm = Int(profile.heightCm)
            weightKg = profile.weightKg
            gender = profile.gender
        }
        
        let localID = LocalUserManager.shared.getLocalUserID()
        if let data = UserDefaults.standard.data(forKey: "profileImage_\(localID)"),
           let img = UIImage(data: data) {
            profileImage = img
        }

        // populate fields
        nameField.text = name
        ageField.text = age != nil ? "\(age!)" : ""
        heightField.text = heightCm != nil ? "\(heightCm!)" : ""
        weightField.text = weightKg != nil ? "\(weightKg!)" : ""
        genderButton.setTitle(gender ?? "Gender", for: .normal)
        updateProfileImageView()
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

        // Name field
        nameField.placeholder = "Full Name"
        nameField.borderStyle = .none
        nameField.backgroundColor = .clear
        nameField.font = UIFont.systemFont(ofSize: 16)
        nameField.autocapitalizationType = .words
        nameField.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(wrapTextField(nameField))

        // Age + Height + Weight row
        let rowAHW = UIStackView()
        rowAHW.axis = .horizontal
        rowAHW.spacing = 12
        rowAHW.distribution = .fillEqually
        rowAHW.translatesAutoresizingMaskIntoConstraints = false

        ageField.placeholder = "Age"
        ageField.keyboardType = .numberPad
        addUnderline(to: ageField)
        
        heightField.placeholder = "Height (cm)"
        heightField.keyboardType = .numberPad
        addUnderline(to: heightField)
        
        weightField.placeholder = "Weight (kg)"
        weightField.keyboardType = .decimalPad
        addUnderline(to: weightField)

        rowAHW.addArrangedSubview(wrapTextField(ageField))
        rowAHW.addArrangedSubview(wrapTextField(heightField))
        rowAHW.addArrangedSubview(wrapTextField(weightField))
        content.addArrangedSubview(rowAHW)

        // Gender button
        setupValueButton(genderButton, title: "Gender", action: #selector(genderTapped))
        content.addArrangedSubview(genderButton)
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
            let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
            profileImageView.image = UIImage(systemName: "person.circle", withConfiguration: config)
            profileImageView.tintColor = .systemBlue
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
            delegate?.editHealthDetailsDidSave(name: nil,
                                              age: nil,
                                              gender: nil,
                                              heightCm: nil,
                                              weightKg: nil,
                                              profileImage: profileImage)
        }
    }
}

