//
//  OnboardingViewController.swift
//  Dialysis One App
//
//  Created by user@1 on 10/11/25.
//

import UIKit

class OnboardingViewController: UIViewController {
    
    @IBOutlet weak var femaleCard: UIView!
    @IBOutlet weak var maleCard: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var femaleLabel: UILabel!
    @IBOutlet weak var maleLabel: UILabel!

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
        
    }

    @objc func selectFemale() {
        femaleCard.layer.borderColor = UIColor(named: "onboarding green")?.cgColor
        femaleCard.backgroundColor = UIColor(named: "onboarding green")
        femaleLabel.textColor = .black

                // Unselected state - white background, black text, gray border
        maleCard.layer.borderColor = UIColor.lightGray.cgColor
        maleCard.backgroundColor = .white
        maleLabel.textColor = .black
        enableNextButton()
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        }


        
    }
    @objc func selectMale() {
        print("Male card tapped")
        print("Male label text color before: \(maleLabel.textColor ?? .clear)")
            
        maleCard.layer.borderColor = UIColor(named: "onboarding green")?.cgColor
        maleCard.backgroundColor = UIColor(named: "onboarding green")
        maleLabel.textColor = .black
            
        print("Male label text color after: \(maleLabel.textColor ?? .clear)")
            
        femaleCard.layer.borderColor = UIColor.lightGray.cgColor
        femaleCard.backgroundColor = .white
        femaleLabel.textColor = .black

        enableNextButton()
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        }
        
        

    }
    
    func enableNextButton() {
        nextButton.isEnabled = true
        nextButton.backgroundColor = UIColor(named: "onboarding green")
    }
    @IBAction func nextButtonTapped(_ sender: UIButton) {
        let ageVC = AgePickerViewController()       // Programmatic age picker screen
        navigationController?.pushViewController(ageVC, animated: true)
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
