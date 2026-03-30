import SwiftUI
import Combine

class DietCardState: ObservableObject {
    @Published var isExpanded: Bool = false
}

struct DietCardSwiftUIView: View {
    @ObservedObject var state: DietCardState
    var onCameraTap: () -> Void
    var onSearchTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Base Premium Gradient Background
            if colorScheme == .dark {
                LinearGradient(
                    colors: [Color(red: 0.65, green: 0.40, blue: 0.15), Color(red: 0.40, green: 0.25, blue: 0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [Color(red: 0.98, green: 0.88, blue: 0.70), Color(red: 0.92, green: 0.78, blue: 0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            
            // Subtle glowing accent
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(colorScheme == .light ? 0.4 : 0.08))
                    .blur(radius: 20)
                    .frame(width: geo.size.height * 1.5, height: geo.size.height * 1.5)
                    .position(x: geo.size.width * 0.8, y: geo.size.height * 0.2)
            }
            .allowsHitTesting(false)
            
            HStack(spacing: 0) {
                // Main Icon
                Image(systemName: "fork.knife")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(width: 110)
                
                if state.isExpanded {
                    Spacer()
                    
                    // Camera Button
                    Button(action: onCameraTap) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.primary.opacity(0.08))
                            )
                    }
                    .padding(.trailing, 4)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    
                    // Search Button
                    Button(action: onSearchTap) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.primary.opacity(0.08))
                            )
                    }
                    .padding(.trailing, 16)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    Spacer()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(colorScheme == .light ? 0.06 : 0.15), radius: 8, x: 0, y: 4)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: state.isExpanded)
    }
}
