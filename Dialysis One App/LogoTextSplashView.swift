//
//  LogoSplashView.swift
//  Dialysis One App
//
//  Created by user@22 on 11/12/25.
//

import SwiftUI

/// Text-based splash view:
/// - Title uses custom PostScript font FONTSPRINGDEMO-TheSeasonsBold at 86.5
/// - Subtitle "Daily care, right at home." at 16
/// - Slanted shine across glyphs
/// - Zoom anchored at `oAnchor`. While zooming, the provided `homeSnapshot` scales up from the same anchor.
struct LogoTextSplashView: View {

    // MARK: Public config (matching your request)
    let title: String = "Dialysis One"
    let subtitle: String? = "Daily care, right at home."
    let fontName: String? = "FONTSPRINGDEMO-TheSeasonsBold" // PostScript name you provided
    let fontSize: CGFloat = 86.5
    let subtitleSize: CGFloat = 16
    let oAnchor: UnitPoint

    // Provide an Image snapshot of the real home UI to reveal while zooming
    let homeSnapshot: Image?

    // Completion closure called when animation finishes; host should swap to actual app root
    let completion: () -> Void

    // MARK: animation state
    @State private var shineX: CGFloat = -1.2
    @State private var titleScale: CGFloat = 1.0
    @State private var didZoom = false
    @State private var debugShowAnchor = false   // toggle true to show crosshair for tuning

    init(oAnchor: UnitPoint = UnitPoint(x: 0.74, y: 0.5),
         homeSnapshot: Image? = nil,
         completion: @escaping () -> Void)
    {
        self.oAnchor = oAnchor
        self.homeSnapshot = homeSnapshot
        self.completion = completion
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Home snapshot underneath (scales up from oAnchor while logo zooms)
                if let snapshot = homeSnapshot {
                    snapshot
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                        .scaleEffect(didZoom ? 1.0 : 0.60, anchor: oAnchor)
                        .opacity(didZoom ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.9), value: didZoom)
                } else {
                    // fallback gradient if snapshot unavailable
                    LinearGradient(
                        colors: [Color(red: 0.78, green: 0.93, blue: 0.55),
                                 Color(red: 0.89, green: 0.97, blue: 0.70)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }

                // Logo (Text) centered
                VStack(spacing: 6) {
                    logoText()
                        .scaleEffect(titleScale)
                        // large scale anchored at oAnchor to keep O fixed while it grows
                        .scaleEffect(didZoom ? 12.0 : 1.0, anchor: oAnchor)
                        .animation(.easeInOut(duration: didZoom ? 0.9 : 0.0), value: didZoom)

                    if let s = subtitle {
                        Text(s)
                            .font(chosenFont(size: subtitleSize))
                            .foregroundColor(Color.black.opacity(0.7))
                            .opacity(didZoom ? 0.0 : 1.0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)

                // debug anchor crosshair
                if debugShowAnchor {
                    crosshair(fullSize: geo.size, anchor: oAnchor)
                }
            }
            .onAppear { runSequence() }
        }
    }

    // MARK: logo text + shine mask
    @ViewBuilder
    private func logoText() -> some View {
        let text = Text(title)
            .font(chosenFont(size: fontSize))
            .foregroundColor(.black)

        ZStack {
            text

            GeometryReader { g in
                let bandW = g.size.width * 0.5
                let bandH = g.size.height * 1.8

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
                    .offset(x: g.size.width * shineX, y: 0)
                    .blendMode(.plusLighter)
                    .mask(text)
                    .allowsHitTesting(false)
                    .animation(.linear(duration: 0.85), value: shineX)
            }
            .allowsHitTesting(false)
        }
    }

    private func chosenFont(size: CGFloat) -> Font {
        if let name = fontName, !name.isEmpty {
            return .custom(name, size: size)
        } else {
            return .system(size: size, weight: .regular, design: .serif)
        }
    }

    // debug crosshair view
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

    // MARK: animation sequence: shine -> pulse -> zoom -> completion
    private func runSequence() {
        // 1 - shine left -> right
        shineX = -1.2
        withAnimation(.linear(duration: 0.85)) {
            shineX = 1.2
        }

        // 2 - small pause then pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.7)) {
                titleScale = 1.03
            }

            withAnimation(.spring(response: 0.45, dampingFraction: 0.75).delay(0.12)) {
                titleScale = 1.0
            }

            // 3 - zoom (logo out, home in)
            withAnimation(.easeInOut(duration: 0.9)) {
                didZoom = true
            }

            // 4 - complete shortly after zoom
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    completion()
                }
            }
        }
    }
}
