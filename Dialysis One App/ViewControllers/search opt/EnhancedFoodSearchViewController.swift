//
//  EnhancedFoodSearchViewController.swift
//  Dialysis One App
//
//  Smart, Voice-Enabled, Personalized Food Search
//

import UIKit
import Speech
import AVFoundation

final class EnhancedFoodSearchViewController: UIViewController {
    
    // MARK: - Search State
    
    private enum SearchState {
        case initial        // Showing frequent dishes
        case typing         // User is typing, show suggestions
        case voiceListening // Voice input active
        case loading        // Fetching results
    }
    
    // MARK: - Properties
    
    private var currentState: SearchState = .initial {
        didSet { updateUIForState() }
    }
    
    private var searchQuery: String = ""
    private var searchSuggestions: [DishSuggestion] = []
    private var frequentDishes: [FrequentDish] = []
    private var recentSearches: [String] = []
    
    private let uid: String = FirebaseAuthManager.shared.getUserID() ?? "guest"
    
    // Speech recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var voiceTimeout: Timer?
    
    // MARK: - UI Components
    
    private let searchContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let searchTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Search for food or say it aloud..."
        field.font = .systemFont(ofSize: 16)
        field.returnKeyType = .search
        field.autocorrectionType = .no
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let voiceButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "mic.fill", withConfiguration: config), for: .normal)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let voiceWaveformView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        view.layer.cornerRadius = 20
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private let listeningLabel: UILabel = {
        let label = UILabel()
        label.text = "Listening..."
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .systemRed
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let listeningMicIcon: UIImageView = {
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        iv.image = UIImage(systemName: "waveform", withConfiguration: config)
        iv.tintColor = .systemRed
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.keyboardDismissMode = .onDrag
        table.separatorStyle = .none
        table.backgroundColor = .systemBackground
        return table
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap the microphone or start typing to search"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSpeechRecognition()
        loadFrequentDishes()
        loadRecentSearches()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Don't auto-focus keyboard to allow voice input
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopVoiceRecognition()
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        title = "Add Food"
        view.backgroundColor = .systemBackground
        
        navigationController?.navigationBar.prefersLargeTitles = false
        
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.rightBarButtonItem = closeButton
        
        // Setup delegates
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FrequentDishCell.self, forCellReuseIdentifier: "FrequentDishCell")
        tableView.register(SearchSuggestionCell.self, forCellReuseIdentifier: "SearchSuggestionCell")
        tableView.register(DishResultCard.self, forCellReuseIdentifier: "DishResultCard")
        
        voiceButton.addTarget(self, action: #selector(voiceButtonTapped), for: .touchUpInside)
        
        // Add subviews
        view.addSubview(searchContainerView)
        searchContainerView.addSubview(searchTextField)
        searchContainerView.addSubview(voiceButton)
        view.addSubview(voiceWaveformView)
        view.addSubview(listeningMicIcon)
        view.addSubview(listeningLabel)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            searchContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            searchContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchContainerView.heightAnchor.constraint(equalToConstant: 50),
            
            searchTextField.leadingAnchor.constraint(equalTo: searchContainerView.leadingAnchor, constant: 16),
            searchTextField.trailingAnchor.constraint(equalTo: voiceButton.leadingAnchor, constant: -8),
            searchTextField.centerYAnchor.constraint(equalTo: searchContainerView.centerYAnchor),
            
            voiceButton.trailingAnchor.constraint(equalTo: searchContainerView.trailingAnchor, constant: -12),
            voiceButton.centerYAnchor.constraint(equalTo: searchContainerView.centerYAnchor),
            voiceButton.widthAnchor.constraint(equalToConstant: 40),
            voiceButton.heightAnchor.constraint(equalToConstant: 40),
            
            voiceWaveformView.topAnchor.constraint(equalTo: searchContainerView.bottomAnchor, constant: 8),
            voiceWaveformView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            voiceWaveformView.widthAnchor.constraint(equalToConstant: 200),
            voiceWaveformView.heightAnchor.constraint(equalToConstant: 40),
            
            listeningMicIcon.topAnchor.constraint(equalTo: searchContainerView.bottomAnchor, constant: 40),
            listeningMicIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            listeningMicIcon.widthAnchor.constraint(equalToConstant: 60),
            listeningMicIcon.heightAnchor.constraint(equalToConstant: 60),

            listeningLabel.topAnchor.constraint(equalTo: listeningMicIcon.bottomAnchor, constant: 12),
            listeningLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            listeningLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            listeningLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            tableView.topAnchor.constraint(equalTo: searchContainerView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        updateUIForState()
    }
    
    // MARK: - State Management
    
    private func updateUIForState() {
        switch currentState {
        case .initial:
            emptyStateLabel.isHidden = !frequentDishes.isEmpty
            tableView.isHidden = frequentDishes.isEmpty
            voiceWaveformView.isHidden = true
            activityIndicator.stopAnimating()
            voiceButton.tintColor = .systemBlue
            // For all other cases, add these lines:
            listeningMicIcon.isHidden = true
            listeningLabel.isHidden = true
            
        case .typing:
            emptyStateLabel.isHidden = true
            tableView.isHidden = false
            voiceWaveformView.isHidden = true
            activityIndicator.stopAnimating()
            // For all other cases, add these lines:
            listeningMicIcon.isHidden = true
            listeningLabel.isHidden = true
            
        case .voiceListening:
            emptyStateLabel.isHidden = true
            tableView.isHidden = true
            voiceWaveformView.isHidden = false
            listeningMicIcon.isHidden = false
            listeningLabel.isHidden = false
            voiceButton.tintColor = .systemRed
            animateVoiceWaveform()
            animateListeningIndicators()
            
        case .loading:
            emptyStateLabel.isHidden = true
            tableView.isHidden = true
            activityIndicator.startAnimating()
            voiceWaveformView.isHidden = true
            // For all other cases, add these lines:
            listeningMicIcon.isHidden = true
            listeningLabel.isHidden = true
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Data Loading
    
    private func loadFrequentDishes() {
        Task {
            do {
                guard let userId = FirebaseAuthManager.shared.getUserID() else { return }
                
                let meals = try await SupabaseService.shared.fetchMeals(userId: userId)
                
                // Count dish frequency
                var dishCounts: [String: Int] = [:]
                for meal in meals {
                    dishCounts[meal.dish_name, default: 0] += 1
                }
                
                // Sort by frequency
                let sorted = dishCounts.sorted { $0.value > $1.value }
                let topDishes = sorted.prefix(10)
                
                await MainActor.run {
                    self.frequentDishes = topDishes.map { dish in
                        FrequentDish(
                            name: dish.key,
                            count: dish.value,
                            lastEaten: Date(),
                            emoji: self.getEmojiForDish(dish.key)
                        )
                    }
                    self.updateUIForState()
                }
                
                print("✅ Loaded \(topDishes.count) frequent dishes")
                
            } catch {
                print("⚠️ Failed to load frequent dishes: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadRecentSearches() {
        let key = "RecentSearches_\(uid)"
        if let data = UserDefaults.standard.array(forKey: key) as? [String] {
            recentSearches = Array(data.prefix(5))
        }
    }
    
    private func saveRecentSearch(_ query: String) {
        guard !query.isEmpty else { return }
        
        var searches = recentSearches
        searches.removeAll { $0.lowercased() == query.lowercased() }
        searches.insert(query, at: 0)
        searches = Array(searches.prefix(10))
        
        let key = "RecentSearches_\(uid)"
        UserDefaults.standard.set(searches, forKey: key)
        
        recentSearches = Array(searches.prefix(5))
    }
    
    // MARK: - Search Logic
    
    @objc private func searchTextChanged() {
        let query = searchTextField.text ?? ""
        searchQuery = query
        
        if query.isEmpty {
            currentState = .initial
            searchSuggestions = []
        } else {
            currentState = .typing
            performSearch(query)
        }
    }
    
    private func performSearch(_ query: String) {
        // Intelligent search with suggestions
        Task {
            let suggestions = await fetchSearchSuggestions(for: query)
            
            await MainActor.run {
                self.searchSuggestions = suggestions
                self.tableView.reloadData()
            }
        }
    }
    
    private func fetchSearchSuggestions(for query: String) async -> [DishSuggestion] {
        do {
            // Call Supabase search function
            let results = try await FoodSearchService.shared.searchDishes(
                query: query,
                userId: uid,
                limit: 10
            )
            
            // Convert to DishSuggestion for UI
            let suggestions = results.map { $0.toDishSuggestion() }
            
            print("✅ Found \(suggestions.count) suggestions for '\(query)'")
            
            // Log confidence info for debugging
            if let topResult = results.first {
                print("📊 Top result: \(topResult.dish_name) (confidence: \(topResult.confidence), source: \(topResult.source))")
            }
            
            return suggestions
            
        } catch {
            print("❌ Search failed:", error.localizedDescription)
            return []
        }
    }

    
    
    
    // MARK: - Voice Recognition
    
    private func setupSpeechRecognition() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("✅ Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    print("⚠️ Speech recognition not authorized")
                @unknown default:
                    break
                }
            }
        }
    }
    
    @objc private func voiceButtonTapped() {
        if audioEngine.isRunning {
            stopVoiceRecognition()
        } else {
            startVoiceRecognition()
        }
    }
    
    private func startVoiceRecognition() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            showVoiceUnavailableAlert()
            return
        }
        
        currentState = .voiceListening
        
        // Configure audio session first
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ Failed to configure audio session: \(error)")
            stopVoiceRecognition()
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        // Remove any existing taps first
        inputNode.removeTap(onBus: 0)
        
        // Use the input node's format (now properly configured)
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("⚠️ Invalid audio format: \(recordingFormat)")
            stopVoiceRecognition()
            return
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                // Cancel existing timeout
                self.voiceTimeout?.invalidate()
                
                if let result = result {
                    let spokenText = result.bestTranscription.formattedString
                    
                    DispatchQueue.main.async {
                        self.searchTextField.text = spokenText
                        self.searchQuery = spokenText
                        
                        // Trigger search as user speaks
                        if !spokenText.isEmpty {
                            self.performSearch(spokenText)
                        }
                    }
                    
                    // Set timeout to auto-stop after 1.5 seconds of silence
                    self.voiceTimeout = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                        DispatchQueue.main.async {
                            print("🎤 Voice recognition auto-stopped after silence")
                            self?.stopVoiceRecognition()
                            
                            // Show suggestions
                            if let query = self?.searchQuery, !query.isEmpty {
                                self?.currentState = .typing
                            }
                        }
                    }
                }
                
                if error != nil {
                    DispatchQueue.main.async {
                        self.stopVoiceRecognition()
                    }
                }
            }
        } catch {
            print("⚠️ Failed to start audio engine: \(error)")
            stopVoiceRecognition()
        }
    }
    
    private func stopVoiceRecognition() {
        // Cancel timeout timer
        voiceTimeout?.invalidate()
        voiceTimeout = nil
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        // Deactivate audio session
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        
        if currentState == .voiceListening {
            currentState = .typing
        }
        listeningMicIcon.layer.removeAllAnimations()
        listeningMicIcon.alpha = 1.0
        listeningLabel.text = "Listening..."
    }
    
    private func processVoiceInput(_ spokenText: String) {
        print("🎤 Voice input completed: \(spokenText)")
        
        saveRecentSearch(spokenText)
        
        // Perform search to show suggestions instead of directly navigating
        if !spokenText.isEmpty {
            performSearch(spokenText)
        }
    }
    
    private func animateVoiceWaveform() {
        UIView.animate(withDuration: 0.6, delay: 0, options: [.repeat, .autoreverse]) {
            self.voiceWaveformView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
    }
    private func animateListeningIndicators() {
        // Pulse animation for microphone icon
        UIView.animate(withDuration: 0.8, delay: 0, options: [.repeat, .autoreverse, .allowUserInteraction]) {
            self.listeningMicIcon.alpha = 0.3
        }
        
        // Text animation - fade in/out with dots
        animateListeningText()
    }

    private func animateListeningText() {
        let texts = ["Listening", "Listening.", "Listening..", "Listening..."]
        var currentIndex = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self, self.currentState == .voiceListening else {
                timer.invalidate()
                return
            }
            
            self.listeningLabel.text = texts[currentIndex]
            currentIndex = (currentIndex + 1) % texts.count
        }
    }
    
    // MARK: - Dish Selection
    
    private func selectDish(named dishName: String, fromVoice: Bool = false) {
        saveRecentSearch(dishName)
        searchTextField.resignFirstResponder()
        
        if !fromVoice {
            currentState = .loading
        }
        
        Task {
            await fetchNutritionForDish(named: dishName, fromVoice: fromVoice)
        }
    }
    
    private func fetchNutritionForDish(named dishName: String, fromVoice: Bool) async {
        print("\n🔍 Fetching nutrition for: \(dishName)")
        
        // Check cache first
        if let cachedNutrients = UserDishCache.shared.nutrients(forDetectedName: dishName) {
            print("✅ Found cached nutrients")
            await showDishDetail(dishName: dishName, fromVoice: fromVoice)
            return
        }
        
        // Check template/DB
        if let nutrients = DishTemplateManager.shared.nutrients(forDetectedName: dishName) {
            print("✅ Found in template/DB")
            UserDishCache.shared.saveNutrients(nutrients, forDetectedName: dishName)
            await showDishDetail(dishName: dishName, fromVoice: fromVoice)
            return
        }
        
        // Fallback to LLM
        print("⚠️ No DB/cache hit, using LLM...")
        let estimate = await LLMNutritionService.shared.estimateNutrients(
            forDishName: dishName,
            categoryHint: nil,
            quantityHint: nil
        )
        
        if let estimate = estimate {
            print("✅ LLM estimate received")
            UserDishCache.shared.saveNutrients(estimate, forDetectedName: dishName)
        }
        
        await showDishDetail(dishName: dishName, fromVoice: fromVoice)
    }
    
    private func showDishDetail(dishName: String, fromVoice: Bool) async {
        await MainActor.run {
            let detectedFood = DetectedFood(
                name: dishName,
                type: nil,
                quantity: nil,
                confidence: fromVoice ? "0.95" : "1.0"
            )
            
            let detailVC = DishDetailViewController()
            let placeholderImage = UIImage(systemName: "photo")?.withTintColor(.systemGray4, renderingMode: .alwaysOriginal)
            
            detailVC.configureWithDetectedFood(
                primary: detectedFood,
                allFoods: [detectedFood],
                image: placeholderImage ?? UIImage(),
                fromSearch: true  // ✅ Indicate this is from search
            )
            
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    // MARK: - Helpers
    
    private func getEmojiForDish(_ dishName: String) -> String {
        // Return empty string for professional, text-only display
        return ""
    }
    
    private func showVoiceUnavailableAlert() {
        let alert = UIAlertController(
            title: "Voice Input Unavailable",
            message: "Please enable microphone access in Settings to use voice search.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func closeTapped() {
        searchTextField.resignFirstResponder()
        stopVoiceRecognition()
        
        if let navigationController = navigationController {
            if navigationController.viewControllers.first == self {
                navigationController.dismiss(animated: true)
            } else {
                navigationController.popViewController(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }
}

// MARK: - UITextField Delegate

extension EnhancedFoodSearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let query = textField.text, !query.isEmpty else { return true }
        textField.resignFirstResponder()
        selectDish(named: query)
        return true
    }
}

// MARK: - UITableView DataSource & Delegate

extension EnhancedFoodSearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch currentState {
        case .initial:
            return 1
        case .typing:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentState {
        case .initial:
            return frequentDishes.count
        case .typing:
            return searchSuggestions.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch currentState {
        case .initial:
            return frequentDishes.isEmpty ? nil : "Frequently Added"
        case .typing:
            return searchSuggestions.isEmpty ? nil : "Suggestions"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch currentState {
        case .initial:
            return 70
        case .typing:
            return 115 // Increased height for polished cards
        default:
            return 70
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch currentState {
        case .initial:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FrequentDishCell", for: indexPath) as! FrequentDishCell
            let dish = frequentDishes[indexPath.row]
            cell.configure(with: dish)
            return cell
            
        case .typing:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DishResultCard", for: indexPath) as! DishResultCard
            let suggestion = searchSuggestions[indexPath.row]
            cell.configure(with: suggestion)
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let dishName: String
        
        switch currentState {
        case .initial:
            dishName = frequentDishes[indexPath.row].name
        case .typing:
            dishName = searchSuggestions[indexPath.row].name
        default:
            return
        }
        
        selectDish(named: dishName)
    }
}

// MARK: - Data Models

struct FrequentDish {
    let name: String
    let count: Int
    let lastEaten: Date
    let emoji: String
}

struct DishSuggestion {
    let name: String
    let description: String
    let attributes: [String]
    var matchScore: Int
}

// MARK: - Custom Cells

class FrequentDishCell: UITableViewCell {
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(countLabel)
        containerView.addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -12),
            
            countLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            countLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            countLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
            countLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -12),
            
            chevronImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 13),
            chevronImageView.heightAnchor.constraint(equalToConstant: 13)
        ])
    }
    
    func configure(with dish: FrequentDish) {
        nameLabel.text = dish.name
        let timesText = dish.count == 1 ? "time" : "times"
        countLabel.text = "Added \(dish.count) \(timesText)"
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.2) {
            self.containerView.alpha = highlighted ? 0.7 : 1.0
            self.containerView.transform = highlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
        }
    }
}

class DishResultCard: UITableViewCell {
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.08
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let dishNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let attributesScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let attributesStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let chevronImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chevron.right")
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(cardView)
        cardView.addSubview(dishNameLabel)
        cardView.addSubview(descriptionLabel)
        cardView.addSubview(attributesScrollView)
        cardView.addSubview(chevronImageView)
        attributesScrollView.addSubview(attributesStackView)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            dishNameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            dishNameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            dishNameLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -12),
            
            descriptionLabel.topAnchor.constraint(equalTo: dishNameLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -12),
            
            attributesScrollView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10),
            attributesScrollView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            attributesScrollView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            attributesScrollView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
            attributesScrollView.heightAnchor.constraint(equalToConstant: 28),
            
            chevronImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12),
            
            attributesStackView.topAnchor.constraint(equalTo: attributesScrollView.topAnchor),
            attributesStackView.leadingAnchor.constraint(equalTo: attributesScrollView.leadingAnchor),
            attributesStackView.trailingAnchor.constraint(equalTo: attributesScrollView.trailingAnchor),
            attributesStackView.bottomAnchor.constraint(equalTo: attributesScrollView.bottomAnchor),
            attributesStackView.heightAnchor.constraint(equalTo: attributesScrollView.heightAnchor)
        ])
    }
    
    func configure(with suggestion: DishSuggestion) {
        dishNameLabel.text = suggestion.name
        descriptionLabel.text = suggestion.description
        
        // Clear existing attributes
        attributesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add attribute chips
        for attribute in suggestion.attributes {
            let chip = createAttributeChip(text: attribute)
            attributesStackView.addArrangedSubview(chip)
        }
    }
    
    private func createAttributeChip(text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 14
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
            container.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        return container
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState], animations: {
            self.cardView.transform = highlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            self.cardView.alpha = highlighted ? 0.8 : 1.0
        })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Update shadow path for better performance
        cardView.layer.shadowPath = UIBezierPath(roundedRect: cardView.bounds, cornerRadius: 12).cgPath
    }
}

class SearchSuggestionCell: UITableViewCell {
    
    private let searchIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "magnifyingglass")
        iv.tintColor = .systemGray
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let suggestionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(searchIcon)
        contentView.addSubview(suggestionLabel)
        
        NSLayoutConstraint.activate([
            searchIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            searchIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),
            
            suggestionLabel.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 12),
            suggestionLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            suggestionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40)
        ])
        
        accessoryType = .disclosureIndicator
    }
    
    func configure(with text: String) {
        suggestionLabel.text = text
    }
}
//v20
