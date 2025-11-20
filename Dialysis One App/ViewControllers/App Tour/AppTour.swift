import UIKit

// -----------------------------------------------------------
// MARK: - AppTourManager (Swift-only, Touch-Safe, Final Version)
// -----------------------------------------------------------

public final class AppTourManager {

    // MARK: Singleton
    public static let shared = AppTourManager()
    private init() {}

    // MARK: Step Model
    public struct Step {
        public let viewID: String?
        public let viewProvider: (() -> UIView?)?
        public let tabIndex: Int?
        public let message: String

        public init(viewID: String? = nil,
                    tabIndex: Int? = nil,
                    viewProvider: (() -> UIView?)? = nil,
                    message: String)
        {
            self.viewID = viewID
            self.tabIndex = tabIndex
            self.viewProvider = viewProvider
            self.message = message
        }
    }

    // MARK: Storage
    private var registry = [String: WeakBox<UIView>]()
    private weak var hostVC: UIViewController?
    private var steps: [Step] = []
    private var currentIndex = 0
    private var currentUID = ""

    // MARK: UI Nodes
    private var overlay: PassthroughOverlay?
    private var maskLayer: CAShapeLayer?
    private var card: UIView?
    private var label: UILabel?
    private var skipButton: UIButton?
    private var nextButton: UIButton?

    // MARK: Config
    private let inset: CGFloat = -8
    private let corner: CGFloat = 14
    private let overlayAlpha: CGFloat = 0.55

    // MARK: Registration
    public func register(view: UIView, for id: String) {
        registry[id] = WeakBox(value: view)
    }

    public func shouldShowTour(uid: String) -> Bool {
        !UserDefaults.standard.bool(forKey: "tour_" + uid)
    }
    public func markDone(uid: String) {
        UserDefaults.standard.set(true, forKey: "tour_" + uid)
    }

    // MARK: Start
    public func showTour(steps: [Step], in parent: UIViewController, uid: String) {
        guard !steps.isEmpty else { return }
        currentUID = uid
        hostVC = parent
        self.steps = steps
        currentIndex = 0

        buildOverlay(on: parent.view)
        showStep()
    }

    // -----------------------------------------------------------
    // MARK: - Overlay Setup
    // -----------------------------------------------------------

    private func buildOverlay(on root: UIView) {
        removeOverlay()

        let ov = PassthroughOverlay(frame: root.bounds)
        ov.backgroundColor = UIColor.black.withAlphaComponent(overlayAlpha)
        ov.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(ov)

        NSLayoutConstraint.activate([
            ov.topAnchor.constraint(equalTo: root.topAnchor),
            ov.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            ov.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            ov.trailingAnchor.constraint(equalTo: root.trailingAnchor)
        ])

        let mask = CAShapeLayer()
        ov.layer.mask = mask

        let card = UIView()
        card.backgroundColor = UIColor(white: 1, alpha: 0.12)
        card.layer.cornerRadius = 15
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        let skip = UIButton(type: .system)
        skip.setTitle("Skip", for: .normal)
        skip.setTitleColor(.white, for: .normal)
        skip.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        skip.backgroundColor = UIColor(white: 1, alpha: 0.08)
        skip.layer.cornerRadius = 10
        skip.translatesAutoresizingMaskIntoConstraints = false
        skip.addTarget(self, action: #selector(skipTap), for: .touchUpInside)

        let next = UIButton(type: .system)
        next.setTitle("Next", for: .normal)
        next.setTitleColor(.white, for: .normal)
        next.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        next.backgroundColor = UIColor.systemGreen
        next.layer.cornerRadius = 10
        next.translatesAutoresizingMaskIntoConstraints = false
        next.addTarget(self, action: #selector(nextTap), for: .touchUpInside)

        ov.addSubview(card)
        card.addSubview(label)
        card.addSubview(skip)
        card.addSubview(next)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),

            skip.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            skip.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 10),
            skip.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            skip.heightAnchor.constraint(equalToConstant: 40),
            skip.widthAnchor.constraint(equalToConstant: 85),

            next.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            next.centerYAnchor.constraint(equalTo: skip.centerYAnchor),
            next.heightAnchor.constraint(equalToConstant: 40),
            next.widthAnchor.constraint(equalToConstant: 85)
        ])

        overlay = ov
        maskLayer = mask
        self.card = card
        self.label = label
        self.skipButton = skip
        self.nextButton = next
    }

    private func removeOverlay() {
        overlay?.removeFromSuperview()
        overlay = nil
        maskLayer = nil
        card = nil
        label = nil
        skipButton = nil
        nextButton = nil
    }

    // -----------------------------------------------------------
    // MARK: - Step Rendering
    // -----------------------------------------------------------

    private func showStep() {
        guard currentIndex < steps.count, let host = hostVC else {
            done()
            return
        }

        let s = steps[currentIndex]

        // Switch tabs if needed
        if let t = s.tabIndex {
            if let tab = host as? UITabBarController { tab.selectedIndex = t }
            else if let tab = host.tabBarController { tab.selectedIndex = t }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            self.render(step: s)
        }
    }

    private func render(step: Step) {
        guard let host = hostVC else { return }

        label?.text = step.message

        var target: UIView?
        if let provider = step.viewProvider { target = provider() }
        if target == nil, let id = step.viewID { target = registry[id]?.value }

        let rect = target?.convert(target?.bounds ?? .zero, to: host.view)

        updateMask(rect)
        positionCard(near: rect)
    }

    private func updateMask(_ rect: CGRect?) {
        guard let ov = overlay, let mask = maskLayer else { return }

        let path = UIBezierPath(rect: ov.bounds)

        if let r = rect {
            let cut = r.insetBy(dx: inset, dy: inset)
            let rounded = UIBezierPath(roundedRect: cut, cornerRadius: corner)
            path.append(rounded)
            path.usesEvenOddFillRule = true
            ov.holeRect = cut
        } else {
            ov.holeRect = .zero
        }

        mask.path = path.cgPath
        mask.fillRule = .evenOdd
    }

    private func positionCard(near r: CGRect?) {
        guard let ov = overlay, let card = card else { return }

        card.removeFromSuperview()
        ov.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        if let rect = r {
            let above = rect.minY
            let below = ov.bounds.height - rect.maxY

            if below >= above {
                NSLayoutConstraint.activate([
                    card.topAnchor.constraint(equalTo: ov.topAnchor, constant: rect.maxY + 16),
                    card.centerXAnchor.constraint(equalTo: ov.centerXAnchor),
                    card.widthAnchor.constraint(lessThanOrEqualToConstant: ov.bounds.width - 40)
                ])
            } else {
                NSLayoutConstraint.activate([
                    card.bottomAnchor.constraint(equalTo: ov.topAnchor, constant: rect.minY - 16),
                    card.centerXAnchor.constraint(equalTo: ov.centerXAnchor),
                    card.widthAnchor.constraint(lessThanOrEqualToConstant: ov.bounds.width - 40)
                ])
            }
        } else {
            NSLayoutConstraint.activate([
                card.centerXAnchor.constraint(equalTo: ov.centerXAnchor),
                card.centerYAnchor.constraint(equalTo: ov.centerYAnchor),
                card.widthAnchor.constraint(lessThanOrEqualToConstant: ov.bounds.width - 40)
            ])
        }
    }

    // -----------------------------------------------------------
    // MARK: - Navigation
    // -----------------------------------------------------------

    @objc private func nextTap() {
        currentIndex += 1
        showStep()
    }

    @objc private func skipTap() {
        done()
    }

    private func done() {
        markDone(uid: currentUID)
        removeOverlay()
        steps.removeAll()
    }
}

// -----------------------------------------------------------
// MARK: PassthroughOverlay – FINAL FIXED VERSION
// -----------------------------------------------------------

private final class PassthroughOverlay: UIView {

    /// area where touches pass through
    var holeRect: CGRect = .zero

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {

        // 1️⃣ Allow touches inside highlight cutout
        if holeRect.contains(point) { return false }

        
        for sub in subviews {
                    // Convert point into subview coordinate space
                    let subPoint = sub.convert(point, from: self)
                    if sub.bounds.contains(subPoint) {
                        return true
                    }
                }

        // 3️⃣ Block touches on the dark overlay
        return true
    }
}

// -----------------------------------------------------------
// Weak wrapper
// -----------------------------------------------------------
private final class WeakBox<T: AnyObject> {
    weak var value: T?
    init(value: T?) { self.value = value }
}
