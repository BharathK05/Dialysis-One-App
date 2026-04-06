//
//  InsightChartKit.swift
//  Dialysis One App
//
//  Reusable Apple Health–style chart components.
//  All accept generic [Double] + [String] arrays.
//  All support optional goal line + entrance animation.
//

import UIKit

// MARK: - InsightBarChartView

/// Vertical bar chart — Apple Health style.
/// Used for: Medication adherence, Nutrients.
final class InsightBarChartView: UIView {

    struct Config {
        var barColor: UIColor         = .systemBlue
        var trackColor: UIColor       = UIColor.systemBlue.withAlphaComponent(0.08)
        var goalLineColor: UIColor    = UIColor.systemOrange.withAlphaComponent(0.7)
        var todayHighlightColor: UIColor? = nil  // auto from barColor if nil
        var labelFont: UIFont         = .systemFont(ofSize: 10, weight: .medium)
        var labelColor: UIColor       = .tertiaryLabel
        var showGoalLine: Bool        = true
        var showValueLabels: Bool     = false
        var cornerRadius: CGFloat     = 6
        var todayIndex: Int?          = nil  // index of "today" bar to highlight
    }

    private var values:    [Double] = []
    private var labels:    [String] = []
    private var goalValue: Double?
    private var config:    Config

    private var animatedScales: [CGFloat] = []   // current animation progress 0–1

    init(config: Config = Config()) {
        self.config = config
        super.init(frame: .zero)
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(values: [Double], labels: [String], goalValue: Double? = nil) {
        self.values    = values
        self.labels    = labels
        self.goalValue = goalValue
        animatedScales = Array(repeating: 0, count: values.count)
        setNeedsDisplay()
    }

    /// Animate bars growing up from zero.
    func animateIn(duration: TimeInterval = 0.6) {
        guard !values.isEmpty else { return }
        let count    = values.count
        let interval = 0.03

        for i in 0..<count {
            let delay = Double(i) * interval
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                UIView.animate(withDuration: duration, delay: 0,
                               usingSpringWithDamping: 0.75, initialSpringVelocity: 0.3,
                               options: [.curveEaseOut]) {
                    self.animatedScales[i] = 1.0
                    self.setNeedsDisplay()
                }
            }
        }
    }

    override func draw(_ rect: CGRect) {
        guard !values.isEmpty else { return }

        let labelH: CGFloat  = 18
        let topPad: CGFloat  = 10
        let chartArea = CGRect(x: 0, y: topPad, width: rect.width, height: rect.height - labelH - topPad)
        let maxV = values.max() ?? 1
        let safeMax = maxV > 0 ? maxV : 1

        let gap: CGFloat     = values.count > 15 ? 4 : 8
        let barW             = (chartArea.width - gap * CGFloat(values.count - 1)) / CGFloat(values.count)

        for (i, v) in values.enumerated() {
            let x = CGFloat(i) * (barW + gap) + chartArea.minX
            let isToday = config.todayIndex == i

            // Track
            let trackR = CGRect(x: x, y: chartArea.minY, width: barW, height: chartArea.height)
            UIBezierPath(roundedRect: trackR, cornerRadius: config.cornerRadius).withFill(config.trackColor)

            // Bar (animated)
            let scale      = i < animatedScales.count ? animatedScales[i] : 0
            let normalised = CGFloat(v / safeMax) * scale
            let barH       = max(chartArea.height * normalised, scale > 0 ? 4 : 0)
            let barR       = CGRect(x: x, y: chartArea.maxY - barH, width: barW, height: barH)

            let barColor   = isToday ? (config.todayHighlightColor ?? config.barColor) : config.barColor.withAlphaComponent(i == values.count - 1 ? 1.0 : 0.55)
            UIBezierPath(roundedRect: barR, cornerRadius: config.cornerRadius).withFill(barColor)

            // Today ring
            if isToday, scale > 0.5 {
                let ring = UIBezierPath(roundedRect: trackR.insetBy(dx: -1.5, dy: -1.5), cornerRadius: config.cornerRadius + 1.5)
                ring.lineWidth = 1.5
                config.barColor.setStroke()
                ring.stroke()
            }

            // Label
            if i < labels.count {
                let lbl = labels[i] as NSString
                let attrs: [NSAttributedString.Key: Any] = [.font: config.labelFont, .foregroundColor: config.labelColor]
                let lRect = CGRect(x: x, y: chartArea.maxY + 4, width: barW + gap, height: labelH)
                lbl.draw(in: lRect, withAttributes: attrs)
            }
        }

        // Goal line
        if config.showGoalLine, let goal = goalValue, safeMax > 0, goal <= maxV * 1.5 {
            let goalY = chartArea.maxY - chartArea.height * CGFloat(goal / safeMax)
            let dashes: [CGFloat] = [4, 3]
            let path = UIBezierPath()
            path.setLineDash(dashes, count: 2, phase: 0)
            path.lineWidth = 1
            path.move(to: CGPoint(x: chartArea.minX, y: goalY))
            path.addLine(to: CGPoint(x: chartArea.maxX, y: goalY))
            config.goalLineColor.setStroke()
            path.stroke()
        }
    }
}

// MARK: - InsightLineChartView

/// Smooth line chart with gradient fill — Apple Health style.
/// Used for: Fluid intake trends.
final class InsightLineChartView: UIView {

    struct Config {
        var lineColor: UIColor   = .systemBlue
        var lineWidth: CGFloat   = 2.5
        var dotRadius: CGFloat   = 4
        var labelFont: UIFont    = .systemFont(ofSize: 10, weight: .medium)
        var labelColor: UIColor  = .tertiaryLabel
        var showDots: Bool       = true
        var showGoalLine: Bool   = true
        var goalLineColor: UIColor = UIColor.systemOrange.withAlphaComponent(0.6)
        var fillOpacityTop: CGFloat = 0.20
        var fillOpacityBottom: CGFloat = 0.0
    }

    private var values: [Double] = []
    private var labels: [String] = []
    private var goalValue: Double?
    private var config: Config

    private var animationProgress: CGFloat = 0  // 0–1, how much of the line to draw

    init(config: Config = Config()) {
        self.config = config
        super.init(frame: .zero)
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(values: [Double], labels: [String], goalValue: Double? = nil) {
        self.values    = values
        self.labels    = labels
        self.goalValue = goalValue
        animationProgress = 0
        setNeedsDisplay()
    }

    func animateIn(duration: TimeInterval = 0.8) {
        animationProgress = 0
        let startTime = CACurrentMediaTime()
        let displayLink = CADisplayLink(target: DisplayLinkProxy(callback: { [weak self] in
            guard let self else { return }
            let elapsed = CACurrentMediaTime() - startTime
            self.animationProgress = min(CGFloat(elapsed / duration), 1)
            self.setNeedsDisplay()
        }), selector: #selector(DisplayLinkProxy.tick))
        displayLink.add(to: .main, forMode: .common)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
            displayLink.invalidate()
        }
    }

    override func draw(_ rect: CGRect) {
        guard values.count > 1 else { return }

        let labelH: CGFloat = 18
        let topPad: CGFloat = 12
        let chartArea = CGRect(x: 0, y: topPad, width: rect.width, height: rect.height - labelH - topPad)

        let maxV   = values.max() ?? 1
        let minV   = values.min() ?? 0
        let range  = maxV - minV > 0 ? maxV - minV : 1
        let stepX  = chartArea.width / CGFloat(values.count - 1)

        func pointAt(_ i: Int) -> CGPoint {
            let x = CGFloat(i) * stepX + chartArea.minX
            let y = chartArea.maxY - chartArea.height * CGFloat((values[i] - minV) / range)
            return CGPoint(x: x, y: y)
        }

        // Clip to animated fraction
        let visibleCount = max(2, Int(ceil(Double(values.count) * animationProgress)))
        let visibleValues = Array(values.prefix(visibleCount))

        // Smooth bezier line
        let linePath  = UIBezierPath()
        linePath.move(to: pointAt(0))
        for i in 1..<visibleValues.count {
            let cp1 = CGPoint(x: pointAt(i-1).x + stepX/3, y: pointAt(i-1).y)
            let cp2 = CGPoint(x: pointAt(i).x   - stepX/3, y: pointAt(i).y)
            linePath.addCurve(to: pointAt(i), controlPoint1: cp1, controlPoint2: cp2)
        }

        // Gradient fill
        let fillPath = linePath.copy() as! UIBezierPath
        if let lastPt = visibleValues.indices.last {
            fillPath.addLine(to: CGPoint(x: pointAt(lastPt).x, y: chartArea.maxY))
            fillPath.addLine(to: CGPoint(x: chartArea.minX, y: chartArea.maxY))
            fillPath.close()
        }

        if let ctx = UIGraphicsGetCurrentContext() {
            ctx.saveGState()
            fillPath.addClip()
            let colors = [config.lineColor.withAlphaComponent(config.fillOpacityTop).cgColor,
                          config.lineColor.withAlphaComponent(config.fillOpacityBottom).cgColor]
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: colors as CFArray, locations: [0, 1])!
            ctx.drawLinearGradient(grad,
                                   start: CGPoint(x: 0, y: chartArea.minY),
                                   end: CGPoint(x: 0, y: chartArea.maxY),
                                   options: [])
            ctx.restoreGState()
        }

        // Stroke
        config.lineColor.setStroke()
        linePath.lineWidth  = config.lineWidth
        linePath.lineCapStyle  = .round
        linePath.lineJoinStyle = .round
        linePath.stroke()

        // Endpoint dot
        if config.showDots, let lastIdx = visibleValues.indices.last {
            let pt = pointAt(lastIdx)
            let dot = UIBezierPath(arcCenter: pt, radius: config.dotRadius,
                                   startAngle: 0, endAngle: .pi * 2, clockwise: true)
            config.lineColor.setFill()
            dot.fill()
            UIColor.systemBackground.withAlphaComponent(0.6).setFill()
            UIBezierPath(arcCenter: pt, radius: config.dotRadius * 0.5,
                         startAngle: 0, endAngle: .pi * 2, clockwise: true).fill()
        }

        // Goal line
        if config.showGoalLine, let goal = goalValue, range > 0 {
            let goalY = chartArea.maxY - chartArea.height * CGFloat((goal - minV) / range)
            if goalY > chartArea.minY && goalY < chartArea.maxY {
                let path = UIBezierPath()
                path.setLineDash([5, 4], count: 2, phase: 0)
                path.lineWidth = 1.5
                path.move(to: CGPoint(x: chartArea.minX, y: goalY))
                path.addLine(to: CGPoint(x: chartArea.maxX, y: goalY))
                config.goalLineColor.setStroke()
                path.stroke()
            }
        }

        // Labels
        for (i, label) in labels.prefix(values.count).enumerated() {
            guard i < visibleValues.count else { break }
            let lbl   = label as NSString
            let attrs: [NSAttributedString.Key: Any] = [.font: config.labelFont, .foregroundColor: config.labelColor]
            let x     = CGFloat(i) * stepX + chartArea.minX - stepX * 0.5
            let lRect = CGRect(x: x, y: chartArea.maxY + 4, width: stepX, height: labelH)
            lbl.draw(in: lRect, withAttributes: attrs)
        }
    }
}

// MARK: - InsightSparklineView

/// Ultra-compact mini sparkline for highlight cards.
final class InsightSparklineView: UIView {

    private var values: [Double] = []
    private var color:  UIColor  = .systemBlue

    override init(frame: CGRect) { super.init(frame: frame); backgroundColor = .clear }
    required init?(coder: NSCoder) { fatalError() }

    func configure(values: [Double], color: UIColor) {
        self.values = values
        self.color  = color
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard values.count > 1 else { return }
        let maxV = values.max() ?? 1
        let minV = values.min() ?? 0
        let range = maxV - minV > 0 ? maxV - minV : 1
        let stepX = rect.width / CGFloat(values.count - 1)

        let path = UIBezierPath()
        for (i, v) in values.enumerated() {
            let x = CGFloat(i) * stepX
            let y = rect.height - rect.height * CGFloat((v - minV) / range)
            i == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
        }

        color.setStroke()
        path.lineWidth = 2
        path.lineCapStyle  = .round
        path.lineJoinStyle = .round
        path.stroke()

        // Fill
        let fill = path.copy() as! UIBezierPath
        fill.addLine(to: CGPoint(x: rect.width, y: rect.height))
        fill.addLine(to: CGPoint(x: 0, y: rect.height))
        fill.close()
        color.withAlphaComponent(0.12).setFill()
        fill.fill()

        // End dot
        let last = values.count - 1
        let dotX = CGFloat(last) * stepX
        let dotY = rect.height - rect.height * CGFloat((values[last] - minV) / range)
        let dot  = UIBezierPath(arcCenter: CGPoint(x: dotX, y: dotY), radius: 3,
                                startAngle: 0, endAngle: .pi * 2, clockwise: true)
        color.setFill()
        dot.fill()
    }
}

// MARK: - InsightHeatmapView

/// Calendar-grid adherence heatmap — medication adherence only.
final class InsightHeatmapView: UIView {

    private var cells:     [InsightHeatmapData.Cell] = []
    private var startDate: Date = Date()
    private var color:     UIColor = .systemPurple
    private var animationIndex: Int = -1

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(data: InsightHeatmapData, color: UIColor) {
        self.cells     = data.cells
        self.startDate = data.startDate
        self.color     = color
        animationIndex = -1
        setNeedsLayout()
        setNeedsDisplay()
    }

    func animateIn() {
        animationIndex = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            self.animationIndex += 1
            if self.animationIndex >= self.cells.count { t.invalidate() }
            self.setNeedsDisplay()
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    override func draw(_ rect: CGRect) {
        guard !cells.isEmpty else { return }

        // Build a 7-column (Mon–Sun) calendar grid
        let cal       = Calendar.current
        let columns   = 7
        let labelH: CGFloat = 18
        let headerH: CGFloat = labelH + 6
        let availH  = rect.height - headerH
        let cellW   = rect.width  / CGFloat(columns)
        let cellH   = cellW  // square cells

        // Day of week headers
        let dayHeaders = ["S", "M", "T", "W", "T", "F", "S"]
        for (i, h) in dayHeaders.enumerated() {
            let x = CGFloat(i) * cellW
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            (h as NSString).draw(in: CGRect(x: x, y: 0, width: cellW, height: labelH), withAttributes: attrs)
        }

        // Build date-to-cell map
        let cellMap = Dictionary(cells.map { ($0.label, $0.value) }, uniquingKeysWith: { a, _ in a })

        // First weekday offset
        let firstWeekday = cal.component(.weekday, from: startDate) - 1   // 0 = Sunday

        // Draw cells
        var idx = 0
        for cellIdx in 0..<(cells.count + firstWeekday) {
            let col = cellIdx % columns
            let row = cellIdx / columns
            let x   = CGFloat(col) * cellW
            let y   = headerH + CGFloat(row) * cellH

            if y + cellH > rect.height { break }

            if cellIdx >= firstWeekday, idx < cells.count {
                let cell = cells[idx]
                let val  = cell.value         // 0–1

                // Perfect circle, never overlapping
                // Subtract 4pt on each side for an 8pt gap
                let pad: CGFloat = 6
                let circleSize = min(cellW - (pad * 2), cellH - (pad * 2))
                let cx = x + (cellW - circleSize) / 2
                let cy = y + (cellH - circleSize) / 2
                let circleR = CGRect(x: cx, y: cy, width: circleSize, height: circleSize)
                let circle = UIBezierPath(ovalIn: circleR)

                if idx <= animationIndex || animationIndex == -1 {
                    // Strict coloring rules
                    if val == 0 {
                        UIColor.tertiarySystemFill.setFill()
                    } else if val < 0.5 {
                        color.withAlphaComponent(0.25).setFill()
                    } else if val < 0.8 {
                        color.withAlphaComponent(0.6).setFill()
                    } else {
                        color.setFill()
                    }

                    // Optional scale pop for the animated-in cell
                    if idx == animationIndex && animationIndex != -1 {
                        let center = CGPoint(x: cx + circleSize/2, y: cy + circleSize/2)
                        let t = CGAffineTransform(translationX: center.x, y: center.y)
                            .scaledBy(x: 1.15, y: 1.15)
                            .translatedBy(x: -center.x, y: -center.y)
                        circle.apply(t)
                    }

                    circle.fill()
                }

                // Day number label
                let isFull = val >= 0.8
                let dayAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11, weight: isFull ? .semibold : .regular),
                    .foregroundColor: isFull ? UIColor.white : UIColor.label.withAlphaComponent(0.7)
                ]
                let labelHeight: CGFloat = 14
                let labelR = CGRect(x: x, y: y + (cellH - labelHeight)/2, width: cellW, height: labelHeight)
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                var finalAttrs = dayAttrs
                finalAttrs[.paragraphStyle] = paragraphStyle
                
                (cell.label as NSString).draw(in: labelR, withAttributes: finalAttrs)

                idx += 1
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        guard !cells.isEmpty else { return CGSize(width: UIView.noIntrinsicMetric, height: 120) }
        let columns  = 7
        let rows     = Int(ceil(Double(cells.count + 6) / Double(columns)))
        let cellW    = bounds.width > 0 ? bounds.width / CGFloat(columns) : 40
        return CGSize(width: UIView.noIntrinsicMetric, height: cellW * CGFloat(rows) + 24)
    }
}

// MARK: - CADisplayLink helper

private final class DisplayLinkProxy: NSObject {
    var callback: () -> Void
    init(callback: @escaping () -> Void) { self.callback = callback }
    @objc func tick() { callback() }
}

// MARK: - UIBezierPath fill helper

private extension UIBezierPath {
    func withFill(_ color: UIColor) {
        color.setFill()
        fill()
    }
}
