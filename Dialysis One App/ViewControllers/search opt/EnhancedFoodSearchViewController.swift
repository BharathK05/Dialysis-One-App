//
//  EnhancedFoodSearchViewController.swift
//  Dialysis One App
//
//  Smart, Voice-Enabled, Personalized Food Search
//  v22 - Fixed search pipeline, MainActor safety, voice→search, caching,
//        haptics, highlight, animations, sticky total calories
//

import UIKit
import Speech
import AVFoundation

// MARK: - Delegates

protocol IngredientSearchDelegate: AnyObject {
    func didSelectIngredient(_ ingredient: IngredientItem)
}

// MARK: - ViewController

@MainActor
final class EnhancedFoodSearchViewController: UIViewController {
    
    // MARK: - Search State
    
    private enum SearchState: Equatable {
        case initial
        case loading
        case results
        case empty
        case voiceListening
    }
    
    // MARK: - Mode
    
    var isIngredientMode: Bool = false
    weak var ingredientSearchDelegate: IngredientSearchDelegate?
    
    // MARK: - State
    
    private var currentState: SearchState = .initial {
        didSet {
            guard oldValue != currentState else { return }
            updateUIForState()
        }
    }
    
    private var searchSuggestions: [DishSuggestion] = []
    private var frequentDishes: [FrequentDish] = []
    private var currentQuery: String = ""
    
    private let uid: String = FirebaseAuthManager.shared.getUserID() ?? "guest"
    
    // Debounce
    private var debounceTask: Task<Void, Never>?
    
    // Voice
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var voiceTimer: Timer?
    private var listeningDotsTimer: Timer?
    
    // Haptics
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    // MARK: - UI: Search Bar
    
    private let searchContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray6
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.separator.withAlphaComponent(0.3).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let searchIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iv.tintColor = .secondaryLabel
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let searchTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Search by food name or dish…"
        tf.font = .systemFont(ofSize: 16)
        tf.returnKeyType = .search
        tf.autocorrectionType = .no
        tf.clearButtonMode = .whileEditing
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let voiceButton: UIButton = {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        b.setImage(UIImage(systemName: "mic.fill", withConfiguration: cfg), for: .normal)
        b.tintColor = .systemBlue
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    // MARK: - UI: TableView
    
    private let tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .plain)
        t.backgroundColor = .systemBackground
        t.separatorStyle = .none
        t.keyboardDismissMode = .onDrag
        t.translatesAutoresizingMaskIntoConstraints = false
        return t
    }()
    
    // MARK: - UI: Loading
    
    private let loadingContainer: UIView = {
        let v = UIView()
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let a = UIActivityIndicatorView(style: .medium)
        a.color = .secondaryLabel
        a.translatesAutoresizingMaskIntoConstraints = false
        return a
    }()
    
    private let loadingLabel: UILabel = {
        let l = UILabel()
        l.text = "Searching…"
        l.font = .systemFont(ofSize: 15)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    // MARK: - UI: Empty State
    
    private let emptyView: UIView = {
        let v = UIView()
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let emptyIcon: UIImageView = {
        let cfg = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)
        let iv = UIImageView(image: UIImage(systemName: "fork.knife.circle", withConfiguration: cfg))
        iv.tintColor = .tertiaryLabel
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let emptyTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "No results found"
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let emptySubtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Try a different search term, or\ncreate your own food below."
        l.font = .systemFont(ofSize: 14)
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    // MARK: - UI: Voice Listening
    
    private let voiceOverlay: UIView = {
        let v = UIView()
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let voiceMicIcon: UIImageView = {
        let cfg = UIImage.SymbolConfiguration(pointSize: 44, weight: .light)
        let iv = UIImageView(image: UIImage(systemName: "waveform", withConfiguration: cfg))
        iv.tintColor = .systemRed
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let voiceStatusLabel: UILabel = {
        let l = UILabel()
        l.text = "Listening…"
        l.font = .systemFont(ofSize: 17, weight: .medium)
        l.textColor = .systemRed
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    // MARK: - UI: Sticky Footer ("Can't find?")
    
    private let footerView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let footerSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let cantFindButton: UIButton = {
        var cfg = UIButton.Configuration.plain()
        cfg.title = "Can't find your food?"
        cfg.baseForegroundColor = UIColor(red: 0.0, green: 0.5, blue: 0.45, alpha: 1.0)
        cfg.image = UIImage(systemName: "plus.circle.fill")
        cfg.imagePlacement = .trailing
        cfg.imagePadding = 8
        let b = UIButton(configuration: cfg)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = false
        title = isIngredientMode ? "Add Ingredient" : "Add Food"
        
        setupNavigationBar()
        setupUI()
        setupDelegates()
        
        selectionFeedback.prepare()
        impactFeedback.prepare()
        
        SFSpeechRecognizer.requestAuthorization { _ in }
        
        loadFrequentDishes()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopVoice()
        debounceTask?.cancel()
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        let back = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain, target: self, action: #selector(backTapped))
        back.tintColor = .label
        navigationItem.leftBarButtonItem = back
    }
    
    private func setupDelegates() {
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        voiceButton.addTarget(self, action: #selector(voiceButtonTapped), for: .touchUpInside)
        cantFindButton.addTarget(self, action: #selector(cantFindTapped), for: .touchUpInside)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FrequentDishCell.self, forCellReuseIdentifier: FrequentDishCell.reuseID)
        tableView.register(FoodSearchResultCell.self, forCellReuseIdentifier: FoodSearchResultCell.reuseID)
    }
    
    private func setupUI() {
        // Search bar
        view.addSubview(searchContainer)
        searchContainer.addSubview(searchIcon)
        searchContainer.addSubview(searchTextField)
        searchContainer.addSubview(voiceButton)
        
        // Loading
        loadingContainer.addSubview(activityIndicator)
        loadingContainer.addSubview(loadingLabel)
        view.addSubview(loadingContainer)
        
        // Empty
        emptyView.addSubview(emptyIcon)
        emptyView.addSubview(emptyTitleLabel)
        emptyView.addSubview(emptySubtitleLabel)
        view.addSubview(emptyView)
        
        // Voice overlay
        voiceOverlay.addSubview(voiceMicIcon)
        voiceOverlay.addSubview(voiceStatusLabel)
        view.addSubview(voiceOverlay)
        
        // Table
        view.addSubview(tableView)
        
        // Footer (only in normal mode)
        if !isIngredientMode {
            footerView.addSubview(footerSeparator)
            footerView.addSubview(cantFindButton)
            view.addSubview(footerView)
        }
        
        let footerH: CGFloat = isIngredientMode ? 0 : 56
        let footerAnchor: NSLayoutYAxisAnchor = isIngredientMode
            ? view.safeAreaLayoutGuide.bottomAnchor
            : footerView.topAnchor
        
        NSLayoutConstraint.activate([
            // Search bar
            searchContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchContainer.heightAnchor.constraint(equalToConstant: 50),
            
            searchIcon.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 12),
            searchIcon.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),
            
            searchTextField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 8),
            searchTextField.trailingAnchor.constraint(equalTo: voiceButton.leadingAnchor, constant: -4),
            searchTextField.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            
            voiceButton.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -10),
            voiceButton.centerYAnchor.constraint(equalTo: searchContainer.centerYAnchor),
            voiceButton.widthAnchor.constraint(equalToConstant: 40),
            voiceButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Table
            tableView.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: footerAnchor),
            
            // Loading
            loadingContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            
            activityIndicator.topAnchor.constraint(equalTo: loadingContainer.topAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor),
            
            loadingLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 10),
            loadingLabel.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor),
            loadingLabel.bottomAnchor.constraint(equalTo: loadingContainer.bottomAnchor),
            
            // Empty
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            emptyIcon.topAnchor.constraint(equalTo: emptyView.topAnchor),
            emptyIcon.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyIcon.widthAnchor.constraint(equalToConstant: 64),
            emptyIcon.heightAnchor.constraint(equalToConstant: 64),
            
            emptyTitleLabel.topAnchor.constraint(equalTo: emptyIcon.bottomAnchor, constant: 16),
            emptyTitleLabel.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor),
            emptyTitleLabel.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor),
            
            emptySubtitleLabel.topAnchor.constraint(equalTo: emptyTitleLabel.bottomAnchor, constant: 6),
            emptySubtitleLabel.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor),
            emptySubtitleLabel.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor),
            emptySubtitleLabel.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor),
            
            // Voice overlay
            voiceOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            voiceOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            
            voiceMicIcon.topAnchor.constraint(equalTo: voiceOverlay.topAnchor),
            voiceMicIcon.centerXAnchor.constraint(equalTo: voiceOverlay.centerXAnchor),
            voiceMicIcon.widthAnchor.constraint(equalToConstant: 64),
            voiceMicIcon.heightAnchor.constraint(equalToConstant: 64),
            
            voiceStatusLabel.topAnchor.constraint(equalTo: voiceMicIcon.bottomAnchor, constant: 14),
            voiceStatusLabel.centerXAnchor.constraint(equalTo: voiceOverlay.centerXAnchor),
            voiceStatusLabel.bottomAnchor.constraint(equalTo: voiceOverlay.bottomAnchor),
        ])
        
        // Footer constraints (only when not ingredient mode)
        if !isIngredientMode {
            NSLayoutConstraint.activate([
                footerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                footerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                footerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                footerView.heightAnchor.constraint(equalToConstant: footerH),
                
                footerSeparator.topAnchor.constraint(equalTo: footerView.topAnchor),
                footerSeparator.leadingAnchor.constraint(equalTo: footerView.leadingAnchor),
                footerSeparator.trailingAnchor.constraint(equalTo: footerView.trailingAnchor),
                footerSeparator.heightAnchor.constraint(equalToConstant: 0.5),
                
                cantFindButton.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
                cantFindButton.centerYAnchor.constraint(equalTo: footerView.centerYAnchor),
            ])
        }
    }
    
    // MARK: - State Machine
    
    private func updateUIForState() {
        // All on main thread — class is @MainActor
        switch currentState {
        case .initial:
            tableView.isHidden = frequentDishes.isEmpty
            loadingContainer.isHidden = true
            emptyView.isHidden = true
            voiceOverlay.isHidden = true
            activityIndicator.stopAnimating()
            voiceButton.tintColor = .systemBlue
            
        case .loading:
            tableView.isHidden = true
            loadingContainer.isHidden = false
            emptyView.isHidden = true
            voiceOverlay.isHidden = true
            activityIndicator.startAnimating()
            
        case .results:
            tableView.isHidden = false
            loadingContainer.isHidden = true
            emptyView.isHidden = true
            voiceOverlay.isHidden = true
            activityIndicator.stopAnimating()
            
        case .empty:
            tableView.isHidden = true
            loadingContainer.isHidden = true
            emptyView.isHidden = false
            voiceOverlay.isHidden = true
            activityIndicator.stopAnimating()
            
        case .voiceListening:
            tableView.isHidden = true
            loadingContainer.isHidden = true
            emptyView.isHidden = true
            voiceOverlay.isHidden = false
            voiceButton.tintColor = .systemRed
            startMicPulse()
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Data Loading
    
    private func loadFrequentDishes() {
        Task { [weak self] in
            guard let self else { return }
            guard let userId = FirebaseAuthManager.shared.getUserID() else { return }
            
            do {
                let meals = try await SupabaseService.shared.fetchMeals(userId: userId)
                var counts: [String: Int] = [:]
                for m in meals { counts[m.dish_name, default: 0] += 1 }
                let top = counts.sorted { $0.value > $1.value }.prefix(10)
                
                self.frequentDishes = top.map {
                    FrequentDish(name: $0.key, count: $0.value, lastEaten: Date(), emoji: "")
                }
                if self.currentState == .initial {
                    self.updateUIForState()
                }
                print("✅ Loaded \(top.count) frequent dishes")
            } catch {
                print("⚠️ Could not load frequent dishes: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Search Pipeline
    
    @objc private func searchTextChanged() {
        let query = (searchTextField.text ?? "").trimmingCharacters(in: .whitespaces)
        currentQuery = query
        
        // Cancel in-flight debounce
        debounceTask?.cancel()
        
        print("⌨️ [Search] Text changed: '\(query)'")
        
        guard query.count >= 2 else {
            // Clear to initial if query too short
            searchSuggestions = []
            currentState = query.isEmpty ? .initial : .initial
            return
        }
        
        // Check cache before showing loading
        if let cached = SearchCache.shared.get(query: query) {
            print("💾 [Search] Cache hit for '\(query)' — \(cached.count) results")
            searchSuggestions = cached
            currentState = cached.isEmpty ? .empty : .results
            return
        }
        
        // Show loading immediately
        currentState = .loading
        
        // 300ms debounce
        debounceTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                print("⏳ [Search] Debounce started for '\(query)'")
                try await Task.sleep(nanoseconds: 300_000_000)
            } catch {
                print("🚫 [Search] Debounce cancelled for '\(query)'")
                return
            }
            
            guard !Task.isCancelled else { return }
            
            // Confirm query hasn't changed
            guard self.currentQuery == query else {
                print("⚠️ [Search] Query changed — skipping '\(query)'")
                return
            }
            
            print("🚀 [Search] Firing API for '\(query)'")
            await self.executeSearch(query: query)
        }
    }
    
    private func executeSearch(query: String) async {
        print("📡 [Search] executeSearch called for '\(query)'")
        
        // Safety timeout using TaskGroup
        let suggestions: [DishSuggestion]? = await withTaskGroup(of: [DishSuggestion]?.self) { group in
            group.addTask {
                do {
                    let results = try await FoodSearchService.shared.searchDishes(query: query, userId: self.uid, limit: 20)
                    return results.map { $0.toDishSuggestion() }
                } catch {
                    print("❌ [Search] Error in fetch: \(error)")
                    return nil
                }
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 sec timeout
                print("⏱️ [Search] API timeout reached for '\(query)'")
                return nil
            }
            
            for await result in group {
                if let result = result {
                    group.cancelAll()
                    return result
                }
            }
            return []
        }
        
        await MainActor.run {
            let finalSuggestions = suggestions ?? []
            print("📦 [Search] Results count: \(finalSuggestions.count) for '\(query)'")
            
            guard self.currentQuery == query else {
                print("⚠️ [Search] Stale result — discarding '\(query)'")
                return
            }
            
            SearchCache.shared.set(finalSuggestions, for: query)
            self.searchSuggestions = finalSuggestions
            
            if finalSuggestions.isEmpty {
                self.currentState = .empty
            } else {
                self.currentState = .results
            }
        }
    }
    
    // MARK: - Voice Recognition
    
    @objc private func voiceButtonTapped() {
        audioEngine.isRunning ? stopVoice() : startVoice()
    }
    
    private func startVoice() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            showAlert("Voice Unavailable", "Enable microphone access in Settings.")
            return
        }
        
        currentState = .voiceListening
        debounceTask?.cancel()
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("⚠️ Audio session error: \(error)"); stopVoice(); return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let req = recognitionRequest else { return }
        req.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        
        let fmt = inputNode.outputFormat(forBus: 0)
        guard fmt.sampleRate > 0 else { stopVoice(); return }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: fmt) { buf, _ in
            req.append(buf)
        }
        
        audioEngine.prepare()
        do { try audioEngine.start() } catch { stopVoice(); return }
        
        recognitionTask = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            
            self.voiceTimer?.invalidate()
            
            if let spokenText = result?.bestTranscription.formattedString, !spokenText.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    print("🎤 [Voice] Recognized: '\(spokenText)'")
                    self.searchTextField.text = spokenText
                    self.currentQuery = spokenText
                    
                    // ✅ Trigger the SAME search pipeline after voice input
                    Task { [weak self] in
                        guard let self else { return }
                        if spokenText.count >= 2 {
                            // Check cache first
                            if let cached = SearchCache.shared.get(query: spokenText) {
                                await MainActor.run {
                                    self.searchSuggestions = cached
                                    self.currentState = cached.isEmpty ? .empty : .results
                                }
                                return
                            }
                            await MainActor.run { self.currentState = .loading }
                            await self.executeSearch(query: spokenText)
                        }
                    }
                }
                
                // Auto-stop after 1.5s silence
                self.voiceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                    DispatchQueue.main.async { [weak self] in
                        self?.stopVoice()
                    }
                }
            }
            
            if error != nil {
                DispatchQueue.main.async { [weak self] in self?.stopVoice() }
            }
        }
        
        startDotsAnimation()
    }
    
    private func stopVoice() {
        voiceTimer?.invalidate(); voiceTimer = nil
        listeningDotsTimer?.invalidate(); listeningDotsTimer = nil
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        voiceMicIcon.layer.removeAllAnimations()
        voiceButton.tintColor = .systemBlue
        
        // Return to appropriate state
        if !searchSuggestions.isEmpty {
            currentState = .results
        } else if currentQuery.isEmpty {
            currentState = .initial
        }
    }
    
    // MARK: - Voice Animations
    
    private func startMicPulse() {
        voiceMicIcon.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.7, delay: 0,
                       options: [.repeat, .autoreverse, .allowUserInteraction]) {
            self.voiceMicIcon.alpha = 0.25
        }
    }
    
    private func startDotsAnimation() {
        let phases = ["Listening", "Listening.", "Listening..", "Listening..."]
        var i = 0
        listeningDotsTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] t in
            DispatchQueue.main.async { [weak self] in
                guard let self, self.currentState == .voiceListening else { t.invalidate(); return }
                self.voiceStatusLabel.text = phases[i % phases.count]
                i += 1
            }
        }
    }
    
    // MARK: - Dish Selection
    
    private func selectDish(named dishName: String, calories: Int? = nil) {
        impactFeedback.impactOccurred()
        
        // Save recent search
        var recents = (UserDefaults.standard.array(forKey: "RecentSearches_\(uid)") as? [String]) ?? []
        recents.removeAll { $0.lowercased() == dishName.lowercased() }
        recents.insert(dishName, at: 0)
        UserDefaults.standard.set(Array(recents.prefix(10)), forKey: "RecentSearches_\(uid)")
        
        searchTextField.resignFirstResponder()
        currentState = .loading
        
        Task { [weak self] in
            guard let self else { return }
            await self.navigateToDishDetail(dishName: dishName)
        }
    }
    
    private func navigateToDishDetail(dishName: String) async {
        print("\n🔍 [NavDetail] Looking up: \(dishName)")
        
        // Check cache / DB / LLM (same pattern as before)
        if UserDishCache.shared.nutrients(forDetectedName: dishName) == nil {
            if let n = DishTemplateManager.shared.nutrients(forDetectedName: dishName) {
                UserDishCache.shared.saveNutrients(n, forDetectedName: dishName)
            } else {
                _ = await LLMNutritionService.shared.estimateNutrients(
                    forDishName: dishName, categoryHint: nil, quantityHint: nil)
            }
        }
        
        let food = DetectedFood(name: dishName, type: nil, quantity: nil, confidence: "1.0")
        let placeholder = UIImage(systemName: "photo")?.withTintColor(.systemGray4, renderingMode: .alwaysOriginal) ?? UIImage()
        
        let detailVC = DishDetailViewController()
        detailVC.isIngredientMode = self.isIngredientMode
        detailVC.ingredientDelegate = self
        detailVC.configureWithDetectedFood(
            primary: food, allFoods: [food], image: placeholder, fromSearch: true)
        
        navigationController?.pushViewController(detailVC, animated: true)
        
        // Restore state after push
        if !searchSuggestions.isEmpty {
            currentState = .results
        } else {
            currentState = .initial
        }
    }
    
    // MARK: - Navigation Actions
    
    @objc private func cantFindTapped() {
        FoodBuilderManager.shared.reset()
        let vc = CreateFoodViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func backTapped() {
        if navigationController?.viewControllers.first == self {
            navigationController?.dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Helpers
    
    private func showAlert(_ title: String, _ message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - IngredientSelectionDelegate

extension EnhancedFoodSearchViewController: IngredientSelectionDelegate {
    func didConfirmIngredient(_ ingredient: IngredientItem) {
        ingredientSearchDelegate?.didSelectIngredient(ingredient)
        if let navVCs = navigationController?.viewControllers {
            for vc in navVCs where vc is CreateFoodViewController {
                navigationController?.popToViewController(vc, animated: true)
                return
            }
        }
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension EnhancedFoodSearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let q = textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !q.isEmpty else { return true }
        textField.resignFirstResponder()
        selectDish(named: q)
        return true
    }
}

// MARK: - UITableView DataSource & Delegate

extension EnhancedFoodSearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentState {
        case .initial:   return frequentDishes.count
        case .results:   return searchSuggestions.count
        default:         return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch currentState {
        case .initial:   return frequentDishes.isEmpty ? nil : "Recently Tracked"
        case .results:   return "Search Results"
        default:         return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch currentState {
        case .initial:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: FrequentDishCell.reuseID, for: indexPath) as! FrequentDishCell
            cell.configure(with: frequentDishes[indexPath.row])
            return cell
            
        case .results:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: FoodSearchResultCell.reuseID, for: indexPath) as! FoodSearchResultCell
            let suggestion = searchSuggestions[indexPath.row]
            cell.configure(with: suggestion, highlight: currentQuery)
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectionFeedback.selectionChanged()
        
        switch currentState {
        case .initial:
            selectDish(named: frequentDishes[indexPath.row].name)
        case .results:
            let s = searchSuggestions[indexPath.row]
            selectDish(named: s.name, calories: s.calories)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Slide-in animation for search results
        guard currentState == .results else { return }
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 12)
        UIView.animate(withDuration: 0.22, delay: Double(indexPath.row) * 0.03,
                       options: [.curveEaseOut], animations: {
            cell.alpha = 1
            cell.transform = .identity
        })
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
    var calories: Int?
}

// MARK: - Cells

final class FrequentDishCell: UITableViewCell {
    static let reuseID = "FrequentDishCell"
    
    private let nameLabel = UILabel()
    private let countLabel = UILabel()
    private let addIcon = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        countLabel.font = .systemFont(ofSize: 13)
        countLabel.textColor = .secondaryLabel
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        addIcon.image = UIImage(systemName: "plus.circle", withConfiguration: cfg)
        addIcon.tintColor = UIColor(red: 0.0, green: 0.5, blue: 0.45, alpha: 1)
        addIcon.contentMode = .scaleAspectFit
        addIcon.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(countLabel)
        contentView.addSubview(addIcon)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: addIcon.leadingAnchor, constant: -12),
            
            countLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            countLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            countLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
            
            addIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            addIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addIcon.widthAnchor.constraint(equalToConstant: 26),
            addIcon.heightAnchor.constraint(equalToConstant: 26),
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with dish: FrequentDish) {
        nameLabel.text = dish.name
        countLabel.text = "Added \(dish.count) \(dish.count == 1 ? "time" : "times")"
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.15) {
            self.contentView.alpha = highlighted ? 0.6 : 1.0
        }
    }
}

/// Clean search result cell with right-aligned kcal and highlighted matched text
final class FoodSearchResultCell: UITableViewCell {
    static let reuseID = "FoodSearchResultCell"
    
    private let foodNameLabel = UILabel()
    private let caloriesLabel = UILabel()
    private let chevron = UIImageView()
    private let separator = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .default
        
        foodNameLabel.font = .systemFont(ofSize: 16)
        foodNameLabel.textColor = .label
        foodNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        caloriesLabel.font = .systemFont(ofSize: 14)
        caloriesLabel.textColor = .secondaryLabel
        caloriesLabel.textAlignment = .right
        caloriesLabel.translatesAutoresizingMaskIntoConstraints = false
        caloriesLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        let cfg = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
        chevron.image = UIImage(systemName: "chevron.right", withConfiguration: cfg)
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        chevron.translatesAutoresizingMaskIntoConstraints = false
        
        separator.backgroundColor = .separator.withAlphaComponent(0.4)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(foodNameLabel)
        contentView.addSubview(caloriesLabel)
        contentView.addSubview(chevron)
        contentView.addSubview(separator)
        
        NSLayoutConstraint.activate([
            foodNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            foodNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            foodNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: caloriesLabel.leadingAnchor, constant: -12),
            
            caloriesLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            caloriesLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            chevron.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            chevron.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 12),
            
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    /// Configure with highlighted prefix match
    func configure(with suggestion: DishSuggestion, highlight: String) {
        // Build attributed string: bold the matching prefix
        let full = suggestion.name
        let attr = NSMutableAttributedString(string: full,
            attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .regular),
                         .foregroundColor: UIColor.label])
        
        if !highlight.isEmpty {
            let lower = full.lowercased()
            let lowerH = highlight.lowercased()
            if let range = lower.range(of: lowerH) {
                let nsRange = NSRange(range, in: full)
                attr.addAttributes([
                    .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                    .foregroundColor: UIColor(red: 0.0, green: 0.5, blue: 0.45, alpha: 1.0)
                ], range: nsRange)
            }
        }
        
        foodNameLabel.attributedText = attr
        
        if let cal = suggestion.calories, cal > 0 {
            caloriesLabel.text = "\(cal) Cal"
        } else {
            caloriesLabel.text = ""
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.15) {
            self.contentView.backgroundColor = highlighted
                ? UIColor.systemGray5.withAlphaComponent(0.5) : .clear
        }
    }
}

// Kept for any backward compat references
final class DishResultCard: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(with suggestion: DishSuggestion) { textLabel?.text = suggestion.name }
}

final class SearchSuggestionCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(with text: String) { textLabel?.text = text }
}
//v22
