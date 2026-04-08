import UIKit

protocol AddFluidDelegate: AnyObject {
    func didAddFluid(type: String, quantity: Int)
}

class AddFluidViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    weak var delegate: AddFluidDelegate?
    private var fluidTypes = ["Water", "Coffee", "Tea", "Juice", "Milk", "Soda"]
    private var selectedType = "Water"
    
    private let typeField = UITextField()
    private let qtyField = UITextField()
    private let pickerView = UIPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Add Fluid"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        let closeButton = UIButton(type: .close)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        let typeLabel = UILabel()
        typeLabel.text = "Fluid Type"
        typeLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(typeLabel)
        
        typeField.borderStyle = .roundedRect
        typeField.placeholder = "Water / Coffee / Tea..."
        typeField.text = selectedType
        typeField.delegate = self
        typeField.backgroundColor = .secondarySystemBackground
        typeField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(typeField)
        
        pickerView.delegate = self
        pickerView.dataSource = self
        typeField.inputView = pickerView
        
        // Add toolbar to pickerView
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(pickerDoneTapped))
        toolbar.setItems([flexSpace, doneBtn], animated: false)
        typeField.inputAccessoryView = toolbar
        
        let qtyLabel = UILabel()
        qtyLabel.text = "Quantity (ml)"
        qtyLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        qtyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(qtyLabel)
        
        qtyField.borderStyle = .roundedRect
        qtyField.keyboardType = .numberPad
        qtyField.text = "250"
        qtyField.backgroundColor = .secondarySystemBackground
        qtyField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(qtyField)
        
        let qtyToolbar = UIToolbar()
        qtyToolbar.sizeToFit()
        let qtyDoneBtn = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(qtyDoneTapped))
        qtyToolbar.setItems([flexSpace, qtyDoneBtn], animated: false)
        qtyField.inputAccessoryView = qtyToolbar
        
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save Fluid", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 14
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            typeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            typeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            
            typeField.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 8),
            typeField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            typeField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            typeField.heightAnchor.constraint(equalToConstant: 44),
            
            qtyLabel.topAnchor.constraint(equalTo: typeField.bottomAnchor, constant: 24),
            qtyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            
            qtyField.topAnchor.constraint(equalTo: qtyLabel.bottomAnchor, constant: 8),
            qtyField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            qtyField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            qtyField.heightAnchor.constraint(equalToConstant: 44),
            
            saveButton.topAnchor.constraint(equalTo: qtyField.bottomAnchor, constant: 40),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func pickerDoneTapped() {
        typeField.resignFirstResponder()
    }
    
    @objc private func qtyDoneTapped() {
        qtyField.resignFirstResponder()
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        let finalType = typeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Water"
        let quantityStr = qtyField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "250"
        let qty = Int(quantityStr) ?? 250
        
        delegate?.didAddFluid(type: finalType.isEmpty ? "Water" : finalType, quantity: qty)
        dismiss(animated: true)
    }
    
    // MARK: - UIPickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { return fluidTypes.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { return fluidTypes[row] }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedType = fluidTypes[row]
        typeField.text = selectedType
    }
}
