//
//  LogoSplashView.swift
//  Dialysis One App
//
//  Created by user@22 on 11/12/25.
//

import SwiftUI
import UIKit

struct LogoTextSplashView: View {

    // MARK: Public config (tweak these)
    let title: String = "Dialysis One"
    let subtitle: String? = "Daily care, right at home."
    
    // subtitle opacity so we can dissolve it quickly
    @State private var subtitleOpacity: Double = 1.0

    // small guard so we only start the sequence after initial hold
    @State private var didStartSequence: Bool = false


    // start with a comfortable size that should fit a single line on modern phones
    // you can increase to 72 or decrease to 56 depending on taste; i set 64 as a good default
    var targetFontSize: CGFloat = 64.0
    var subtitleSize: CGFloat = 16.0
    let fontPostScriptName: String? = "FONTSPRINGDEMO-TheSeasonsBold" // your PostScript name

    // Optional manual anchor fallback (if computation fails) - will be replaced by computedAnchor when available
    private let fallbackAnchor = UnitPoint(x: 0.74, y: 0.50)

    // Snapshot image of home UI (may be nil)
    let homeSnapshot: Image?

    // Called when the animation finishes
    let completion: () -> Void

    // MARK: internal state
    @State private var shineX: CGFloat = -1.2
    @State private var titleScale: CGFloat = 1.0
    @State private var didZoom = false

    // computed anchor (we compute once in onAppear)
    @State private var computedAnchor: UnitPoint? = nil

    // debug: set true to show a red crosshair at the computed anchor
    @State private var debugShowAnchor: Bool = false
    
    // add this to the state section (inside the struct, with other @State vars)
    @State private var textSize: CGSize = .zero   // measured size of the title text

    init(homeSnapshot: Image? = nil,
         targetFontSize: CGFloat = 64.0,
         subtitleSize: CGFloat = 16.0,
         completion: @escaping () -> Void)
    {
        self.homeSnapshot = homeSnapshot
        self.targetFontSize = targetFontSize
        self.subtitleSize = subtitleSize
        self.completion = completion
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Home snapshot underneath (scales up anchored at computedAnchor)
                if let snapshot = homeSnapshot {
                    snapshot
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                        .scaleEffect(didZoom ? 1.0 : 0.30, anchor: computedAnchor ?? fallbackAnchor)
                        .opacity(didZoom ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.9), value: didZoom)
                } else {
                    // fallback background
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(UIColor(hex: 0xE1F5EB)), location: 0.0),  // top soft mint
                            .init(color: Color(UIColor(hex: 0xC8EBE1)), location: 0.7)   // bottom light teal (dominant)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }

                // Title + subtitle — vertically centered
                // --- replace the previous VStack block with this ---
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        logoText()
                            .scaleEffect(titleScale)
                            .scaleEffect(didZoom ? 28.0 : 1.0, anchor: computedAnchor ?? fallbackAnchor)
                            .animation(.easeInOut(duration: didZoom ? 0.9 : 0.0), value: didZoom)

                        if let s = subtitle {
                            Text(s)
                                .font(chosenFont(size: subtitleSize))
                                .foregroundColor(Color.black.opacity(0.7))
                                .opacity(subtitleOpacity)
                                .animation(.easeOut(duration: 0.22), value: subtitleOpacity)
                                .padding(.top, -2)
                        }
                    }
                    .fixedSize() // keep the inner size intrinsic
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                .position(x: geo.size.width / 2.0, y: geo.size.height / 2.0 - 50)
                
                // debug anchor visualization
                if debugShowAnchor {
                    // use computed anchor if available, otherwise fallbackAnchor
                    let anchor = computedAnchor ?? fallbackAnchor
                    crosshair(fullSize: geo.size, anchor: anchor)
                }
            }
            .onAppear {
                // compute the anchor for the "O" glyph and then run sequence
                computeOAnchorThenRun()
            }
        }
    }
    
    // MARK: render logo text with shine masked to text (measuring text size)
    @ViewBuilder
    private func logoText() -> some View {
        // single-line forced, no wrap; use minimumScaleFactor so the text will shrink slightly to fit.
        let txt = Text(title)
            .font(chosenFont(size: targetFontSize))
            .foregroundColor(.black)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .fixedSize(horizontal: true, vertical: false) // force single-line measuring
            // measure the text size into textSize
            .background(GeometryReader { proxy -> Color in
                DispatchQueue.main.async {
                    // update measured text size
                    self.textSize = proxy.size
                }
                return Color.clear
            })

        ZStack {
            txt

            // Use explicit measured textSize for band dimensions and offset
            if textSize.width > 0 {
                let bandW = textSize.width * 0.55      // slightly wider band
                let bandH = textSize.height * 1.8

                let gradient = LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0.0), location: 0.0),
                        .init(color: Color.white.opacity(0.75), location: 0.45),
                        .init(color: Color.white.opacity(0.0), location: 0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )

                Rectangle()
                    .fill(gradient)
                    .frame(width: bandW, height: bandH)
                    .rotationEffect(.degrees(-18))
                    // offset using measured width so it aligns exactly with glyphs
                    .offset(x: (textSize.width * (shineX)), y: 0)
                    .blendMode(.plusLighter)
                    .mask(txt)
                    .allowsHitTesting(false)
                    .animation(.linear(duration: 0.65), value: shineX)
            }
        }
    }


    // MARK: compute anchor for "O" using NSString sizing (accurate for glyph widths)
    private func computeOAnchorThenRun() {
        // Attempt to build the UIFont we need
        let uiFont: UIFont
        if let ps = fontPostScriptName, let f = UIFont(name: ps, size: targetFontSize) {
            uiFont = f
        } else {
            uiFont = UIFont.systemFont(ofSize: targetFontSize, weight: .regular)
        }

        // Entire title width
        let titleNSString = NSString(string: title)
        let attrs: [NSAttributedString.Key: Any] = [.font: uiFont]
        let totalSize = titleNSString.size(withAttributes: attrs)

        // Find index of the 'O' in the title (first uppercase O in "One")
        // We want the center x of that glyph.
        if let rangeOfO = title.range(of: "O") {
            let nsRangeO = NSRange(rangeOfO, in: title)
            // string before the O
            let prefix = NSString(string: String(titleNSString.substring(to: nsRangeO.location)))
            let prefixWidth = prefix.size(withAttributes: attrs).width

            // width of the O glyph (approx)
            let oChar = NSString(string: titleNSString.substring(with: NSRange(location: nsRangeO.location, length: 1)))
            let oWidth = oChar.size(withAttributes: attrs).width

            // center X of O relative to entire text
            let oCenterX = prefixWidth + (oWidth / 2.0)

            // anchor X is proportion of centerX in total width
            var computedX: CGFloat = fallbackAnchor.x
            if totalSize.width > 0 {
                computedX = max(0.0, min(1.0, oCenterX / totalSize.width))
            }

            // Vertical anchor: we use 0.5 (center); fine-tune by eye if needed
            let computedY: CGFloat = 0.50

            // Save state now (this will be used by the animations)
            self.computedAnchor = UnitPoint(x: computedX, y: computedY)

        } else {
            // fallback if O not found
            self.computedAnchor = fallbackAnchor
        }

        // Start the animation sequence *after* we've set computedAnchor so the zoom uses it
        runSequence()
    }

    private func chosenFont(size: CGFloat) -> Font {
        if let name = fontPostScriptName, !name.isEmpty {
            return .custom(name, size: size)
        } else {
            return .system(size: size, weight: .regular, design: .serif)
        }
    }

    // MARK: sequence (shine -> pulse -> zoom -> completion)
    private func runSequence() {
        // Guard so we don't run twice
        guard !didStartSequence else { return }
        didStartSequence = true
        
        // 1) initial hold so splash stays visible for ~0.85s before any animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            
            // 2) shine left -> right
            shineX = -1.2
            withAnimation(.linear(duration: 0.85)) {
                shineX = 1.2
            }
            
            // 3) small pause then pulse
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.7)) {
                    titleScale = 1.03
                }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75).delay(0.12)) {
                    titleScale = 1.0
                }
                
                // 4) fade subtitle faster right before zoom (quick dissolve)
                withAnimation(.easeOut(duration: 0.20)) {
                    subtitleOpacity = 0.0
                }
                
                // 5) zoom sequence: make logo scale huge anchored at O and reveal home by scaling it up
                withAnimation(.easeInOut(duration: 0.9)) {
                    didZoom = true
                }
                // 6) complete right after zoom finishes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.90) {
                    completion()
                    
                }
            }
        }
    }

    // debug crosshair overlay
    @ViewBuilder
    private func crosshair(fullSize: CGSize, anchor: UnitPoint) -> some View {
        let x = fullSize.width * anchor.x
        let y = fullSize.height * anchor.y
        ZStack {
            Circle().stroke(Color.red, lineWidth: 2).frame(width: 18, height: 18).position(x: x, y: y)
            Path { p in
                p.move(to: CGPoint(x: x - 30, y: y)); p.addLine(to: CGPoint(x: x + 30, y: y))
                p.move(to: CGPoint(x: x, y: y - 30)); p.addLine(to: CGPoint(x: x, y: y + 30))
            }
            .stroke(Color.red, lineWidth: 1)
        }
    }
}
