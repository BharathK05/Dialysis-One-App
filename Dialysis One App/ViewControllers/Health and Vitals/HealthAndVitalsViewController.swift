//
//  HealthAndVitalsViewController.swift
//  Dialysis One App
//
//  Created by user@22 on 18/11/25.
//
import HealthKit
import UIKit

class HealthAndVitalsViewController: UIViewController {

    private var isConnected = false

    private let scroll = UIScrollView()
    private let content = UIStackView()

    // Header
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    // Vitals
    private let vitalsTitle = UILabel()
    private let vitalsContainer = UIView()
    @objc var watchCard = UIView()
    private let connectButton = UIButton(type: .system)

    // BPM & SpO2 cards
    private let bpCard = UIView()
    private let bpValueLabel = UILabel()
    private let bpSubtitle = UILabel()

    private let spO2Card = UIView()
    private let spO2ValueLabel = UILabel()
    private let spO2Subtitle = UILabel()

    // Reports
    private let reportsTitle = UILabel()
    private let addReportButton = UIButton(type: .system)
    @objc var reportsStack = UIStackView()

    // Data
    private var reports: [BloodReport] = []
    
    // MARK: - Pending deletion support
    private struct PendingDeletion {
        let report: BloodReport
        let index: Int
        var timer: Timer?
    }

    private var pendingDeletion: PendingDeletion?
    private var snackbarView: UIView?


    override func viewDidLoad() {
        super.viewDidLoad()
        scroll.contentInsetAdjustmentBehavior = .never
        addTopGradientBackground()
        buildUI()
        AppTourManager.shared.register(view: watchCard, for: "health.watch")
        AppTourManager.shared.register(view: reportsStack, for: "health.reports")
        updateWatchUI()
        loadReports()
        setupHealthKit()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        AppTourManager.shared.register(view: watchCard, for: "health.watch")
        AppTourManager.shared.register(view: reportsStack, for: "health.reports")
    }

    
    private func addTopGradientBackground() {
        let gradient = CAGradientLayer()

            // COLORS MATCHING RELIEF GUIDE LOOK
            let topColor = UIColor(red: 225/255, green: 245/255, blue: 235/255, alpha: 1)   // soft mint
            let bottomColor = UIColor(red: 200/255, green: 235/255, blue: 225/255, alpha: 1) // light teal

            gradient.colors = [
                topColor.cgColor,
                bottomColor.cgColor
            ]

            // Same blending behavior as GradientView.swift
            gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradient.endPoint   = CGPoint(x: 0.5, y: 1.0)

            // Match the Relief Guide: bottom color dominates ~70%
            gradient.locations = [0.0, 0.7]

            gradient.type = .axial
            gradient.frame = view.bounds
            gradient.zPosition = -1

            view.layer.insertSublayer(gradient, at: 0)
    }

    private func buildUI() {
        // scroll + content
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        content.axis = .vertical
        content.spacing = 18
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 18),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -18),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -36)
        ])

        // Header
        titleLabel.text = "Health and Vitals"
        titleLabel.font = UIFont.systemFont(ofSize: 33, weight: .bold)

        subtitleLabel.text = "Track key vitals and review your recent reports."
        subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = UIColor(white: 0.30, alpha: 1)


        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 6
        headerStack.setCustomSpacing(2, after: titleLabel)
        headerStack.layoutMargins = .zero
        headerStack.isLayoutMarginsRelativeArrangement = false
        content.addArrangedSubview(headerStack)

        // Vitals title
        vitalsTitle.text = "Vitals"
        vitalsTitle.font = UIFont.boldSystemFont(ofSize: 18)
        content.addArrangedSubview(vitalsTitle)

        // Watch card (connect)
        watchCard.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        watchCard.layer.cornerRadius = 22
        watchCard.layer.shadowColor = UIColor.black.withAlphaComponent(0.09).cgColor
        watchCard.layer.shadowOpacity = 1
        watchCard.layer.shadowRadius = 12
        watchCard.layer.shadowOffset = CGSize(width: 0, height: 4)
        watchCard.translatesAutoresizingMaskIntoConstraints = false
        watchCard.heightAnchor.constraint(equalToConstant: 220).isActive = true

        let icon = UIImageView(image: UIImage(systemName: "applewatch"))
        icon.tintColor = .black
        icon.translatesAutoresizingMaskIntoConstraints = false
        connectButton.setTitle("Connect", for: .normal)
        connectButton.backgroundColor = UIColor.systemGreen
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 20
        connectButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 22, bottom: 8, right: 22)
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)

        let title = UILabel()
        title.text = "Connect to Apple Watch"
        title.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "To see your latest blood pressure and oxygen readings, connect your Apple Watch."
        subtitle.font = UIFont.systemFont(ofSize: 14)
        subtitle.textColor = .gray
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        let watchVstack = UIStackView(arrangedSubviews: [
            icon,
            title,
            subtitle,
            connectButton
        ])
        watchVstack.axis = .vertical
        watchVstack.alignment = .center
        watchVstack.spacing = 8
        watchVstack.translatesAutoresizingMaskIntoConstraints = false

        watchCard.addSubview(watchVstack)

        NSLayoutConstraint.activate([
            watchVstack.centerXAnchor.constraint(equalTo: watchCard.centerXAnchor),
            watchVstack.centerYAnchor.constraint(equalTo: watchCard.centerYAnchor),

            icon.heightAnchor.constraint(equalToConstant: 36),
            icon.widthAnchor.constraint(equalToConstant: 36),

            // Make sure text fits inside card
            watchVstack.leadingAnchor.constraint(equalTo: watchCard.leadingAnchor, constant: 16),
            watchVstack.trailingAnchor.constraint(equalTo: watchCard.trailingAnchor, constant: -16)
        ])


        content.addArrangedSubview(watchCard)

        // Two small cards (BP / SpO2) in row
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 12
        row.distribution = .fillEqually

        [bpCard, spO2Card].forEach {
            $0.backgroundColor = .white
            $0.layer.cornerRadius = 20
            $0.heightAnchor.constraint(equalToConstant: 120).isActive = true
        }

        // bp layout
        let bpTitle = UILabel(); bpTitle.text = "Blood Pressure"; bpTitle.textColor = .systemRed; bpTitle.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        bpValueLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold); bpValueLabel.text = "--"
        bpSubtitle.text = "—"
        bpSubtitle.font = UIFont.systemFont(ofSize: 12); bpSubtitle.textColor = .gray

        let bpStack = UIStackView(arrangedSubviews: [bpTitle, bpValueLabel, bpSubtitle])
        bpStack.axis = .vertical; bpStack.alignment = .center; bpStack.spacing = 6
        bpCard.addSubview(bpStack); bpStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([bpStack.centerXAnchor.constraint(equalTo: bpCard.centerXAnchor),
                                     bpStack.centerYAnchor.constraint(equalTo: bpCard.centerYAnchor)])

        // spO2 layout
        let spTitle = UILabel(); spTitle.text = "Blood Oxygen"; spTitle.textColor = .systemBlue; spTitle.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        spO2ValueLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold); spO2ValueLabel.text = "--"
        spO2Subtitle.font = UIFont.systemFont(ofSize: 12); spO2Subtitle.textColor = .gray

        let spStack = UIStackView(arrangedSubviews: [spTitle, spO2ValueLabel, spO2Subtitle])
        spStack.axis = .vertical; spStack.alignment = .center; spStack.spacing = 6
        spO2Card.addSubview(spStack); spStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([spStack.centerXAnchor.constraint(equalTo: spO2Card.centerXAnchor),
                                     spStack.centerYAnchor.constraint(equalTo: spO2Card.centerYAnchor)])

        row.addArrangedSubview(bpCard)
        row.addArrangedSubview(spO2Card)
        content.addArrangedSubview(row)

        // Reports section
        reportsTitle.text = "Health and Blood Report"
        reportsTitle.font = UIFont.boldSystemFont(ofSize: 18)
        content.addArrangedSubview(reportsTitle)

        addReportButton.setTitle("+ Add Report", for: .normal)
        addReportButton.setTitleColor(.systemBlue, for: .normal)
        addReportButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)

        addReportButton.backgroundColor = UIColor(white: 0.96, alpha: 1)
        addReportButton.layer.cornerRadius = 16
        addReportButton.layer.borderWidth = 1
        addReportButton.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor

        addReportButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        addReportButton.contentHorizontalAlignment = .center
        content.addArrangedSubview(addReportButton)
        addReportButton.addTarget(self, action: #selector(addReportTapped), for: .touchUpInside)


        reportsStack.axis = .vertical
        reportsStack.spacing = 12
        content.addArrangedSubview(reportsStack)
    }

    private func setupHealthKit() {
        HealthKitManager.shared.requestAuthorization { ok, err in
            if ok {
                self.refreshVitals()
            } else {
                print("HealthKit not authorized: \(err?.localizedDescription ?? "no error")")
            }
        }
    }
    
    private func updateWatchUI() {
        watchCard.isHidden = isConnected

        // vitals cards visible only when connected
        bpCard.isHidden = !isConnected
        spO2Card.isHidden = !isConnected
    }


    private func refreshVitals() {
        DispatchQueue.main.async {
            // heart rate -> BPM
            HealthKitManager.shared.readMostRecentSample(ofType: .heartRate) { value, date, err in
                DispatchQueue.main.async {
                    if let v = value {
                        self.bpValueLabel.text = "\(Int(round(v))) BPM"
                        if let d = date { self.bpSubtitle.text = DateFormatter.localizedString(from: d, dateStyle: .none, timeStyle: .short) }
                    } else {
                        self.bpValueLabel.text = "—"
                        self.bpSubtitle.text = "No data"
                    }
                }
            }
            // SpO2
            HealthKitManager.shared.readMostRecentSample(ofType: .oxygenSaturation) { value, date, err in
                DispatchQueue.main.async {
                    if let v = value {
                        // oxygen is fraction (0.99) so convert to percent
                        let pct = Int(round(v * 100))
                        self.spO2ValueLabel.text = "\(pct) %"
                        if let d = date { self.spO2Subtitle.text = DateFormatter.localizedString(from: d, dateStyle: .none, timeStyle: .short) }
                    } else {
                        self.spO2ValueLabel.text = "—"
                        self.spO2Subtitle.text = "No data"
                    }
                }
            }
        }
    }

    // Reports
    private func loadReports() {
        reports = FileStorage.shared.loadReports()
        refreshReportListAnimatedInsertFade()
    }

    private func refreshReportListAnimatedInsertFade() {
        // Clear existing views
        reportsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if reports.isEmpty {
            let emptyBox = UIView()
            emptyBox.heightAnchor.constraint(equalToConstant: 140).isActive = true   // adds spacing

            let lbl = UILabel()
            lbl.text = "No reports added yet"
            lbl.textAlignment = .center
            lbl.textColor = .gray
            lbl.translatesAutoresizingMaskIntoConstraints = false

            emptyBox.addSubview(lbl)

            NSLayoutConstraint.activate([
                lbl.centerXAnchor.constraint(equalTo: emptyBox.centerXAnchor),
                lbl.centerYAnchor.constraint(equalTo: emptyBox.centerYAnchor)
            ])

            reportsStack.addArrangedSubview(emptyBox)
        }

        for r in reports {
            let card = ReportCardView()
            card.report = r
            card.swipeDelegate = self
            card.translatesAutoresizingMaskIntoConstraints = false
            card.heightAnchor.constraint(equalToConstant: 80).isActive = true

            // initially hidden
            card.alpha = 0
            reportsStack.addArrangedSubview(card)

            // fade in with slight delay per item
            let delay = 0.05 * Double(reportsStack.arrangedSubviews.count - 1)
            UIView.animate(withDuration: 0.28, delay: delay, options: .curveEaseOut, animations: {
                card.alpha = 1
            }, completion: nil)

            // maintain tap behavior if you have onTap
            card.onTap = { [weak self] in
                guard let url = r.attachmentURL else { return }
                let vc = ReportPreviewViewController()
                vc.fileURL = url
                vc.reportTitle = r.title
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }


    // MARK: - Actions
    @objc private func connectTapped() {
        let healthStore = HKHealthStore()
        
        healthStore.getRequestStatusForAuthorization(toShare: [], read: HealthKitManager.shared.readTypes) { status, error in
            DispatchQueue.main.async {
                switch status {
                case .shouldRequest:
                    // show actual popup
                    self.askForHealthKitPermissions()
                    
                case .unnecessary:
                    // already granted earlier
                    self.isConnected = true
                    self.updateWatchUI()
                    self.refreshVitals()
                    
                case .unknown:
                    self.showSettingsAlert()
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func animateConnection() {
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.fromValue = 0.85
        pulse.toValue = 1.0
        pulse.duration = 0.4
        pulse.initialVelocity = 0.8
        pulse.damping = 0.8
        pulse.autoreverses = false
        pulse.repeatCount = 1

        bpCard.layer.add(pulse, forKey: nil)
        spO2Card.layer.add(pulse, forKey: nil)
    }


    private func askForHealthKitPermissions() {
        HealthKitManager.shared.requestAuthorization { ok, err in
            DispatchQueue.main.async {
                if ok {
                    self.isConnected = true
                    self.updateWatchUI()
                    self.refreshVitals()
                    self.animateConnection() 
                } else {
                    self.showSettingsAlert()
                }
            }
        }
    }

    private func showSettingsAlert() {
        let alert = UIAlertController(
            title: "Permission Required",
            message: "Enable Health permissions in Settings → Health → Apps → Dialysis One",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }


    @objc private func addReportTapped() {
        let add = AddReportViewController()
        add.delegate = self
        let nav = UINavigationController(rootViewController: add)
        present(nav, animated: true)
    }
    
    
    // Call this to perform UI delete animation + schedule final deletion
    private func performSoftDelete(cardView: ReportCardView, report: BloodReport) {
        // 1) find index
        guard let idx = reports.firstIndex(where: { $0.id == report.id }) else {
            // fallback: just animate removal of view
            animateRemoveView(cardView)
            return
        }

        // keep backup
        let originalIndex = idx
        pendingDeletion?.timer?.invalidate()
        pendingDeletion = PendingDeletion(report: report, index: originalIndex, timer: nil)

        // 2) animate slide-left like Mail
        UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseIn, animations: {
            cardView.transform = CGAffineTransform(translationX: -cardView.bounds.width * 0.9, y: 0)
            cardView.alpha = 0.0
        }, completion: { _ in
            // 3) remove view from stack
            cardView.removeFromSuperview()

            // 4) remove from model immediately (but we keep pendingDeletion backup)
            self.reports.removeAll { $0.id == report.id }

            // 5) refresh UI list heights if needed
            self.refreshReportListAnimatedInsertFade() // we'll add this helper below

            // 6) show snackbar with Undo
            self.showUndoSnackbar()
            
            // 7) start timer to finalize deletion (5s)
            self.pendingDeletion?.timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { _ in
                self.finalizePendingDeletion()
            })
        })
    }

    // fallback generic removal animation (fade)
    private func animateRemoveView(_ v: UIView) {
        UIView.animate(withDuration: 0.18, animations: {
            v.alpha = 0
        }, completion: { _ in
            v.removeFromSuperview()
        })
    }
    
    private func showUndoSnackbar() {
        // remove existing first
        hideSnackbar()

        let snackbar = UIView()
        snackbar.backgroundColor = UIColor(white: 0.06, alpha: 0.95)
        snackbar.layer.cornerRadius = 12
        snackbar.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "Report deleted"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 15)

        let undoBtn = UIButton(type: .system)
        undoBtn.setTitle("Undo", for: .normal)
        undoBtn.setTitleColor(.systemGreen, for: .normal)
        undoBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        undoBtn.addTarget(self, action: #selector(undoDeletionTapped), for: .touchUpInside)

        snackbar.addSubview(label)
        snackbar.addSubview(undoBtn)

        label.translatesAutoresizingMaskIntoConstraints = false
        undoBtn.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(snackbar)

        NSLayoutConstraint.activate([
            snackbar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            snackbar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            snackbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            snackbar.heightAnchor.constraint(equalToConstant: 56),

            label.leadingAnchor.constraint(equalTo: snackbar.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: snackbar.centerYAnchor),

            undoBtn.trailingAnchor.constraint(equalTo: snackbar.trailingAnchor, constant: -16),
            undoBtn.centerYAnchor.constraint(equalTo: snackbar.centerYAnchor)
        ])

        // entry animation
        snackbar.alpha = 0
        snackbar.transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(withDuration: 0.28, animations: {
            snackbar.alpha = 1
            snackbar.transform = .identity
        })

        snackbarView = snackbar
    }

    private func hideSnackbar() {
        guard let s = snackbarView else { return }
        UIView.animate(withDuration: 0.18, animations: {
            s.alpha = 0
            s.transform = CGAffineTransform(translationX: 0, y: 20)
        }, completion: { _ in
            s.removeFromSuperview()
        })
        snackbarView = nil
    }

    @objc private func undoDeletionTapped() {
        guard var pd = pendingDeletion else { return }
        pd.timer?.invalidate()

        // Insert back into reports array at the original index (or end if index invalid)
        let insertIndex = min(max(0, pd.index), reports.count)
        reports.insert(pd.report, at: insertIndex)

        // Persist
        FileStorage.shared.saveReports(reports)

        // Refresh UI with nice fade-in
        refreshReportListAnimatedInsertFade()

        // Clear pending
        pendingDeletion = nil
        hideSnackbar()
    }

    
    private func finalizePendingDeletion() {
        guard let pd = pendingDeletion else { return }
        defer { pendingDeletion = nil; hideSnackbar() }

        // delete stored file (PDF) if exists
        if let filename = pd.report.filename {
            if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = docs.appendingPathComponent(filename)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    do { try FileManager.default.removeItem(at: fileURL) } catch {
                        print("⚠️ Failed to remove pdf file: \(error)")
                    }
                }
            }
        }

        // Persist current reports array (already removed earlier)
        FileStorage.shared.saveReports(reports)
    }


}


extension HealthAndVitalsViewController: AddReportDelegate {
    func addReportDidSave(_ report: BloodReport) {
        // reload full list
        loadReports()
    }
}

extension HealthAndVitalsViewController: ReportCardSwipeDelegate {
    func didRequestDelete(_ card: ReportCardView) {
        guard let report = card.report else { return }

        // Optionally confirm with the user (we're doing soft delete + undo, so optional)
        performSoftDelete(cardView: card, report: report)
    }
}



