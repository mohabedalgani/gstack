import SwiftUI

enum JumlaTheme {
    static let ink = Color(red: 0.91, green: 0.96, blue: 0.89)
    static let inkDim = Color(red: 0.72, green: 0.83, blue: 0.69)
    static let glow = Color(red: 0.83, green: 1.0, blue: 0.42)
    static let ok = Color(red: 0.49, green: 1.0, blue: 0.60)
    static let tileInk = Color(red: 0.10, green: 0.18, blue: 0.10)

    static let tileColors: [Color] = [
        Color(red: 0.78, green: 0.90, blue: 0.75),
        Color(red: 0.72, green: 0.83, blue: 0.91),
        Color(red: 0.91, green: 0.86, blue: 0.75),
        Color(red: 0.94, green: 0.78, blue: 0.69),
    ]

    static var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.16, blue: 0.09),
                    Color(red: 0.07, green: 0.22, blue: 0.13),
                    Color(red: 0.04, green: 0.12, blue: 0.08),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [
                    Color(red: 0.24, green: 0.47, blue: 0.20).opacity(0.45),
                    .clear,
                ],
                center: .top,
                startRadius: 20,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}
