//
//  CameraCaptureViewController.swift
//  FIXED: Proper navigation and memory management
//
import UIKit
import AVFoundation
import Photos

final class CameraCaptureViewController: UIViewController {
    weak var delegate: CameraCaptureDelegate?
    
    // MARK: - UI Elements
    private let previewContainer = UIView()
    private let overlayView = UIView()
    private let cropBoxView = UIView()
    private let closeButton = UIButton(type: .system)
    private let statusBadge = UIView()
    private let statusLabel = UILabel()
    private var isFoodDetected = false {
        didSet { updateDetectionStatus() }
    }
    private var detectedFoods: [DetectedFood] = []  // Changed from detectedLabels
   // private var recognitionResult: FoodRecognitionResult?
    private let crossButton = UIButton(type: .system)
    private let tickButton = UIButton(type: .system)
    private let galleryButton = UIButton(type: .system)
    private let shutterButton = UIButton(type: .system)
    
    // MARK: - AVCapture
    private let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue", qos: .userInitiated)
    private var isSessionRunning = false
    
    private var lastCapturedImage: UIImage?
    private var isPreviewingCapturedImage = false {
        didSet { updateUIForPreviewState() }
    }
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupButtonTargets()
        configureSessionAsync()
        // Listen for rescan requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRescanRequest),
            name: .reopenCamera,
            object: nil
        )
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkCameraAuthorization { [weak self] authorized in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if authorized {
                    self.startSession()
                } else {
                    self.showPermissionsAlert()
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewContainer.bounds
        applyOverlayMask()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        recognitionTask?.cancel()
        recognitionTask = nil
        stopSession()
    }
    
    deinit {
        recognitionTask?.cancel()
        print("🗑️ CameraCaptureViewController deinit")
       // stopSession()
        
        
        
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
    }
    // MARK: - Setup Views
    
    private func setupViews() {
        view.backgroundColor = .black
        
        view.addSubview(previewContainer)
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        view.addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        view.addSubview(cropBoxView)
        cropBoxView.translatesAutoresizingMaskIntoConstraints = false
        cropBoxView.layer.borderColor = UIColor.white.cgColor
        cropBoxView.layer.borderWidth = 3.0
        cropBoxView.layer.cornerRadius = 20.0
        cropBoxView.backgroundColor = .clear
        
        let cropSize: CGFloat = min(view.bounds.width, view.bounds.height) *  0.85

        NSLayoutConstraint.activate([
            cropBoxView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cropBoxView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            cropBoxView.widthAnchor.constraint(equalToConstant: cropSize),
            cropBoxView.heightAnchor.constraint(equalToConstant: cropSize)
        ])
        
        setupTopBar()
        setupStatusBadge()
        setupActionButtons()
        setupBottomControls()
    }
    
    private func setupTopBar() {
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        closeButton.layer.cornerRadius = 20
        closeButton.clipsToBounds = true
        
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupStatusBadge() {
        statusBadge.backgroundColor = UIColor(red: 0.8, green: 0.85, blue: 0.8, alpha: 1.0)
        statusBadge.layer.cornerRadius = 20
        statusBadge.clipsToBounds = true
        statusBadge.alpha = 0
        
        view.addSubview(statusBadge)
        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusBadge.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            statusBadge.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusBadge.heightAnchor.constraint(equalToConstant: 40),
            statusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 140)
        ])
        
        
        statusLabel.text = "Food Detected"
        statusLabel.textColor = UIColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 1.0)
        statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        statusLabel.textAlignment = .center
        
        statusBadge.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: statusBadge.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: statusBadge.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: statusBadge.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: statusBadge.trailingAnchor, constant: -20)
        ])
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: statusBadge.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: statusBadge.bottomAnchor, constant: 12)
        ])
    }
    
    private func setupActionButtons() {
        crossButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        crossButton.tintColor = .white
        crossButton.backgroundColor = UIColor(white: 0.3, alpha: 0.8)
        crossButton.layer.cornerRadius = 30
        crossButton.clipsToBounds = true
        crossButton.alpha = 0
        
        view.addSubview(crossButton)
        crossButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            crossButton.centerYAnchor.constraint(equalTo: cropBoxView.centerYAnchor),
            crossButton.trailingAnchor.constraint(equalTo: cropBoxView.leadingAnchor, constant: -20),
            crossButton.widthAnchor.constraint(equalToConstant: 60),
            crossButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        tickButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
        tickButton.tintColor = .white
        tickButton.backgroundColor = UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0)
        tickButton.layer.cornerRadius = 25
        tickButton.clipsToBounds = true
//        tickButton.alpha = 0
        tickButton.isEnabled = false
        
        view.addSubview(tickButton)
        tickButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tickButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            tickButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tickButton.widthAnchor.constraint(equalToConstant: 50),
            tickButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupBottomControls() {
        let galleryIconConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        galleryButton.setImage(UIImage(systemName: "photo.on.rectangle", withConfiguration: galleryIconConfig), for: .normal)
        galleryButton.tintColor = .white
        galleryButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        galleryButton.layer.cornerRadius = 28
        galleryButton.clipsToBounds = true
        
        view.addSubview(galleryButton)
        galleryButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            galleryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            galleryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            galleryButton.widthAnchor.constraint(equalToConstant: 56),
            galleryButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        shutterButton.backgroundColor = .white
        shutterButton.layer.cornerRadius = 35
        shutterButton.layer.borderWidth = 5
        shutterButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        shutterButton.clipsToBounds = true
        shutterButton.isEnabled = false
        
        let innerCircle = UIView()
        innerCircle.backgroundColor = .white
        innerCircle.isUserInteractionEnabled = false
        shutterButton.addSubview(innerCircle)
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            innerCircle.centerXAnchor.constraint(equalTo: shutterButton.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 56),
            innerCircle.heightAnchor.constraint(equalToConstant: 56)
        ])
        innerCircle.layer.cornerRadius = 28
        
        view.addSubview(shutterButton)
        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.widthAnchor.constraint(equalToConstant: 70),
            shutterButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    private func setupButtonTargets() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        crossButton.addTarget(self, action: #selector(crossTapped), for: .touchUpInside)
        tickButton.addTarget(self, action: #selector(tickTapped), for: .touchUpInside)
        shutterButton.addTarget(self, action: #selector(shutterTapped), for: .touchUpInside)
        galleryButton.addTarget(self, action: #selector(galleryTapped), for: .touchUpInside)
    }
    private func showLoadingIndicator() {
        loadingIndicator.startAnimating()
    }

    private func hideLoadingIndicator() {
        loadingIndicator.stopAnimating()
    }
    
    // MARK: - Detection Status
    
    private func updateDetectionStatus() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.3) {
                if self.isFoodDetected {
                    self.statusBadge.alpha = 1.0
                    self.statusBadge.backgroundColor = UIColor(red: 0.7, green: 0.9, blue: 0.7, alpha: 1.0)
                    
                    self.statusLabel.text = "Food detected"


                    
                    self.statusLabel.textColor = UIColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 1.0)
                    self.tickButton.isEnabled = true
                    self.tickButton.backgroundColor = UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
                } else {
                    self.statusBadge.backgroundColor = UIColor(red: 0.9, green: 0.8, blue: 0.8, alpha: 1.0)
                    self.statusLabel.text = "No Food Detected"
                    self.statusLabel.textColor = UIColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 1.0)
                    self.tickButton.isEnabled = false
                    self.tickButton.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
                }
            }
        }
    }
    
    // MARK: - UI State
    
    private func updateUIForPreviewState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.3) {
                if self.isPreviewingCapturedImage {
                    self.crossButton.alpha = 1.0
                    self.tickButton.alpha = 1.0
                    self.statusBadge.alpha = 1.0
                    self.shutterButton.alpha = 0.3
                    self.shutterButton.isEnabled = false
                    self.galleryButton.alpha = 0.3
                    self.galleryButton.isEnabled = false
                    
                    if let image = self.lastCapturedImage {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            self.recognizeFood(image: image)
                        }

                    }
                } else {
                    self.crossButton.alpha = 0.0
                    self.tickButton.alpha = 0.0
                    self.statusBadge.alpha = 0.0
                    self.shutterButton.alpha = 1.0
                    self.shutterButton.isEnabled = true
                    self.galleryButton.alpha = 1.0
                    self.galleryButton.isEnabled = true
                }
            }
        }
    }
    
    // MARK: - Food Recognition
    
    // MARK: - Food Recognition
    private var recognitionTask: Task<Void, Never>?

    private func recognizeFood(image: UIImage) {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionTask = Task { [weak self] in
            guard let self else { return }
            guard !self.isBeingDismissed else { return }
            
            await MainActor.run {
                self.statusLabel.text = "Analyzing..."
                self.statusBadge.backgroundColor = UIColor(red: 0.85, green: 0.85, blue: 0.9, alpha: 1.0)
                self.statusBadge.alpha = 1.0
                
                // Show loading indicator
                self.showLoadingIndicator()
            }
            
            // Call Gemini Vision API
            let foods = await GeminiVisionService.shared.detectFood(in: image)
            
            guard !Task.isCancelled, !self.isBeingDismissed else { return }
            
            await MainActor.run {
                self.hideLoadingIndicator()
                
                if !foods.isEmpty {
                    self.handleVisionSuccess(foods)
                    // Auto-proceed after success
                    self.proceedToConfirmation()
                } else {
                    self.handleVisionError()
                }
            }
        }
    }
    
    private func handleVisionSuccess(_ foods: [DetectedFood]) {
        print("\n✅ ========== GEMINI VISION RESULTS ==========")
        print("📋 Total food items detected: \(foods.count)")
        print("📝 Detected foods:")
        for (index, food) in foods.enumerated() {
            print("   \(index + 1). \(food.name)")
            if let type = food.type {
                print("      └─ Type: \(type)")
            }
            if let quantity = food.quantity {
                print("      └─ Quantity: \(quantity)")
            }
        }
        print("============================================\n")
        
        self.detectedFoods = foods
        
        // Show all detected food names in status
        
        isFoodDetected = true
        statusLabel.text = "Food detected"
        statusBadge.backgroundColor = UIColor(red: 0.7, green: 0.9, blue: 0.7, alpha: 1.0)
        statusLabel.textColor = UIColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 1.0)
        tickButton.isEnabled = true
        tickButton.backgroundColor = UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
    }

    private func handleVisionError() {
        print("❌ No food detected by Gemini Vision")
        
        isFoodDetected = false
        detectedFoods = []
        
        statusLabel.text = "No Food Detected"
        statusBadge.backgroundColor = UIColor(red: 0.9, green: 0.8, blue: 0.8, alpha: 1.0)
        statusLabel.textColor = UIColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 1.0)
        tickButton.isEnabled = false
        tickButton.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
    }
    
    private func showRecognitionErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "Recognition Error",
            message: "Could not analyze the image. Please try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            if let img = self?.lastCapturedImage {
                self?.recognizeFood(image: img)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.crossTapped()
        })
        present(alert, animated: true)
    }
    
    // MARK: - Button Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    
    @objc private func crossTapped() {
        clearCapturedImagePreview()
        lastCapturedImage = nil
        detectedFoods = []
        isPreviewingCapturedImage = false
        isFoodDetected = false
        
        // Restart session safely on the session queue
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.shutterButton.isEnabled = true
                }
            }
        }
    }

    
    @objc private func tickTapped() {
        proceedToConfirmation()
    }
    
    private func proceedToConfirmation() {
        guard let img = lastCapturedImage, !detectedFoods.isEmpty else { return }

        print("\n✅ Auto-proceeding to confirmation")

        Task {
            var primary: DetectedFood?
            
            if isCompositeIndianMeal(detectedFoods) {
                let mealName = await MealNamingService.shared.nameMeal(from: detectedFoods)
                let finalName: String

                if let mealName, !mealName.isEmpty {
                    finalName = normalizeMealName(mealName)
                    print("🧠 Gemini meal name:", finalName)
                } else {
                    finalName = "South Indian Vegetarian Meal"
                    print("⚠️ Gemini failed — using fallback meal name")
                }

                primary = DetectedFood(
                    name: finalName,
                    type: "composite meal",
                    quantity: "1 plate",
                    confidence: "0.95"
                )
            } else {
                primary = detectedFoods.first
            }
            
            await MainActor.run {
                let confirmVC = DishConfirmationViewController()
                confirmVC.capturedImage = img
                confirmVC.detectedFoods = detectedFoods
                confirmVC.selectedDish = primary
                confirmVC.modalPresentationStyle = .fullScreen

                self.present(confirmVC, animated: true)
            }
        }
    }
    
    @objc private func shutterTapped() {
        guard !isPreviewingCapturedImage else { return }
        
        UIView.animate(withDuration: 0.1, animations: {
            self.shutterButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.shutterButton.transform = .identity
            }
        }
        
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .off
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    @objc private func handleRescanRequest() {
        // Reset camera state
        clearCapturedImagePreview()
        lastCapturedImage = nil
        detectedFoods = []
        isPreviewingCapturedImage = false
        isFoodDetected = false
        
        // Restart session
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.shutterButton.isEnabled = true
                }
            }
        }
    }
    @objc private func galleryTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        present(picker, animated: true)
    }
    
    // MARK: - Permissions & Session
    
    private func checkCameraAuthorization(_ completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        default:
            completion(false)
        }
    }
    
    private func showPermissionsAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please enable Camera permission in Settings.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func configureSessionAsync() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    private func normalizeMealName(_ raw: String) -> String {
        let lower = raw.lowercased()

        if lower == "south" {
            return "South Indian Vegetarian Meal"
        }

        if lower.contains("south") && lower.contains("indian") {
            return "South Indian Vegetarian Meal"
        }

        if lower.contains("thali") {
            return "Vegetarian Thali"
        }

        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        do {
            guard let backDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .back
            ) else {
                print("No back camera available")
                session.commitConfiguration()
                return
            }
            
            let input = try AVCaptureDeviceInput(device: backDevice)
            if session.canAddInput(input) {
                session.addInput(input)
                self.videoDeviceInput = input
            }
        } catch {
            print("Error configuring camera input:", error)
            session.commitConfiguration()
            return
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }
        
        session.commitConfiguration()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.setupPreviewLayer()
        }
    }
    
    private func setupPreviewLayer() {
        guard previewLayer == nil else { return }
        
        let pl = AVCaptureVideoPreviewLayer(session: session)
        pl.videoGravity = .resizeAspectFill
        pl.frame = previewContainer.bounds
        previewContainer.layer.insertSublayer(pl, at: 0)
        previewLayer = pl
    }
    
    private func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                DispatchQueue.main.async {
                    self.shutterButton.isEnabled = true
                }
            }
        }
    }
    
    private func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                self.isSessionRunning = false
            }
        }
    }
    
    private func applyOverlayMask() {
        let overlayBounds = overlayView.bounds
        let path = UIBezierPath(rect: overlayBounds)
        
        let holeFrame = overlayView.convert(cropBoxView.frame, from: cropBoxView.superview)
        let holePath = UIBezierPath(
            roundedRect: holeFrame,
            cornerRadius: cropBoxView.layer.cornerRadius
        )
        path.append(holePath.reversing())
        
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        overlayView.layer.mask = mask
    }
    
    private func normalizeImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up { return image }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalized ?? image
    }
    
    private func cropImageToCropBox(_ image: UIImage) -> UIImage? {
        guard let pl = previewLayer else { return nil }
        
        let cropRectInPreview = previewContainer.convert(cropBoxView.frame, from: cropBoxView.superview)
        let normalizedCropRect = pl.metadataOutputRectConverted(fromLayerRect: cropRectInPreview)
        
        guard let cgImage = image.cgImage else { return nil }
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        let cropX = normalizedCropRect.origin.x * imageWidth
        let cropY = normalizedCropRect.origin.y * imageHeight
        let cropW = normalizedCropRect.size.width * imageWidth
        let cropH = normalizedCropRect.size.height * imageHeight
        
        var cropRectPixels = CGRect(x: cropX, y: cropY, width: cropW, height: cropH).integral
        cropRectPixels = cropRectPixels.intersection(CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        guard cropRectPixels.width > 0 && cropRectPixels.height > 0 else { return nil }
        
        guard let croppedCg = cgImage.cropping(to: cropRectPixels) else { return nil }
        return UIImage(cgImage: croppedCg, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func displayCapturedImage(_ image: UIImage) {
        clearCapturedImagePreview()
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tag = 9999
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        previewContainer.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor)
        ])
    }
    
    private func clearCapturedImagePreview() {
        previewContainer.subviews.filter({ $0.tag == 9999 }).forEach({ $0.removeFromSuperview() })
    }
}

// MARK: - AVCapturePhotoCaptureDelegate


extension CameraCaptureViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            print("Photo capture error:", error)
            return
        }
        
        guard let data = photo.fileDataRepresentation(),
              let captured = UIImage(data: data) else {
            print("Failed to convert captured photo to UIImage")
            return
        }
        
        let normalizedImage = normalizeImageOrientation(captured)
        
        DispatchQueue.main.async { [weak self] in
            self?.stopSession()
            self?.isPreviewingCapturedImage = true
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var finalImage: UIImage?
            if let cropped = self.cropImageToCropBox(normalizedImage) {
                finalImage = cropped
            } else {
                finalImage = normalizedImage.centerSquareCrop()
            }
            
            guard let outputImage = finalImage else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.showCaptureErrorAlert()
                    self.isPreviewingCapturedImage = false
                    self.startSession()
                }
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.displayCapturedImage(outputImage)
                self.lastCapturedImage = outputImage
            }
        }
    }
    
    private func showCaptureErrorAlert() {
        let alert = UIAlertController(
            title: "Capture Failed",
            message: "Could not process captured image.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension CameraCaptureViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            guard let selected = image else { return }
            
            let cropped = selected.centerSquareCrop()
            
            self.stopSession()
            self.isPreviewingCapturedImage = true
            self.lastCapturedImage = cropped
            
            self.displayCapturedImage(cropped)
        }
    }
}

// MARK: - UIImage Extensions

private extension UIImage {
    func centerSquareCrop() -> UIImage {
        guard let cg = self.cgImage else { return self }
        let width = CGFloat(cg.width)
        let height = CGFloat(cg.height)
        let length = min(width, height)
        let originX = (width - length) / 2.0
        let originY = (height - length) / 2.0
        let cropRect = CGRect(x: originX, y: originY, width: length, height: length).integral
        guard let cropped = cg.cropping(to: cropRect) else { return self }
        return UIImage(cgImage: cropped, scale: self.scale, orientation: self.imageOrientation)
    }
}
