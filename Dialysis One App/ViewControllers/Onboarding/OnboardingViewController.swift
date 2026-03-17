//
//  OnboardingViewController.swift
//  Dialysis One App
//
//  Created by user@1 on 10/11/25.
//

import UIKit

class OnboardingViewController: UIViewController , UITextFieldDelegate{
    
    @IBOutlet weak var femaleCard: UIView!
    @IBOutlet weak var maleCard: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var femaleLabel: UILabel!
    @IBOutlet weak var maleLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    
    private var selectedGender: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        femaleCard.layer.cornerRadius = 20
        maleCard.layer.cornerRadius = 20
            
        femaleCard.layer.borderWidth = 2
        maleCard.layer.borderWidth = 2
            
        femaleCard.layer.borderColor = UIColor.lightGray.cgColor
        maleCard.layer.borderColor = UIColor.lightGray.cgColor

        femaleCard.isUserInteractionEnabled = true
        maleCard.isUserInteractionEnabled = true

        femaleCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectFemale)))
        maleCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectMale)))
        nextButton.isEnabled = false
        nextButton.backgroundColor = .lightGray

        nameTextField.delegate = self
        nameTextField.addTarget(
            self,
            action: #selector(nameDidChange),
            for: .editingChanged
        )
        DispatchQueue.main.async {
            self.nameTextField.becomeFirstResponder()
        }
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
    }

    @objc func selectFemale() {
        view.endEditing(true)
        selectedGender = "female"
        femaleCard.isUserInteractionEnabled = false
        maleCard.isUserInteractionEnabled = false
        femaleCard.layer.borderColor = UIColor(named: "onboarding green")?.cgColor
        femaleCard.backgroundColor = UIColor(named: "onboarding green")
        femaleLabel.textColor = .black

        maleCard.layer.borderColor = UIColor.lightGray.cgColor
        maleCard.backgroundColor = .white
        maleLabel.textColor = .black

        validateNextButton()
    }
    @objc func selectMale() {
        view.endEditing(true)
        selectedGender = "male"
        femaleCard.isUserInteractionEnabled = false
        maleCard.isUserInteractionEnabled = false
        maleCard.layer.borderColor = UIColor(named: "onboarding green")?.cgColor
        maleCard.backgroundColor = UIColor(named: "onboarding green")
        maleLabel.textColor = .black

        femaleCard.layer.borderColor = UIColor.lightGray.cgColor
        femaleCard.backgroundColor = .white
        femaleLabel.textColor = .black

        validateNextButton()
    }
    @objc func nameDidChange() {
        validateNextButton()
    }
    
    
    @IBAction func nextButtonTapped(_ sender: UIButton) {

        guard
            let name = nameTextField.text?.trimmingCharacters(in: .whitespaces),
            !name.isEmpty,
            let gender = selectedGender
        else { return }

        let localID = LocalUserManager.shared.getLocalUserID()

        UserDefaults.standard.set(name, forKey: "name_\(localID)")
        UserDefaults.standard.set(gender, forKey: "gender_\(localID)")

        let ageVC = AgePickerViewController()
        navigationController?.pushViewController(ageVC, animated: true)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    func validateNextButton() {
        let nameValid = !(nameTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        let genderValid = selectedGender != nil

        if nameValid && genderValid {
            nextButton.isEnabled = true
            nextButton.backgroundColor = UIColor(named: "onboarding green")
        } else {
            nextButton.isEnabled = false
            nextButton.backgroundColor = .lightGray
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.layer.borderColor = UIColor(named: "onboarding green")?.cgColor
        textField.layer.borderWidth = 1.5
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.borderWidth = 1
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
