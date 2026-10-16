import SwiftUI

struct GameView: View {
    @StateObject private var model = GameViewModel()
    @State private var cellFrames: [GridPos: CGRect] = [:]
    @State private var boardFrame: CGRect = .zero

    var body: some View {
        ZStack {
            JumlaTheme.background

            VStack(spacing: 12) {
                header
                hint
                BoardView(
                    model: model,
                    cellFrames: $cellFrames,
                    boardFrame: $boardFrame
                )
                .padding(.horizontal, 8)

                if model.showFeedback, let recipe = model.lastRecipe {
                    FeedbackPanel(recipe: recipe)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer(minLength: 0)
                footer
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: model.showFeedback)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("جُمْلَة")
                    .font(.system(size: 44, weight: .bold, design: .serif))
                    .foregroundStyle(JumlaTheme.ink)
                    .shadow(color: .black.opacity(0.35), radius: 0, y: 2)
                Text(model.levelTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(JumlaTheme.inkDim)
            }
            Spacer()
            HStack(spacing: 8) {
                scorePill
                Button {
                    model.toggleMute()
                } label: {
                    Image(systemName: model.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(CircleIconStyle())

                Button {
                    model.resetGame()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(CircleIconStyle())
            }
            .padding(.top, 8)
        }
    }

    private var scorePill: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color(red: 1, green: 0.84, blue: 0.42))
                Text(WesternArabicDigits.format(model.score))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(JumlaTheme.ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.white.opacity(0.1), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.18)))

            if let delta = model.scoreDelta {
                Text("+\(WesternArabicDigits.format(delta))")
                    .font(.caption.bold())
                    .foregroundStyle(JumlaTheme.glow)
                    .offset(y: -18)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private var hint: some View {
        Text("كَوِّنْ جُمْلَةً صَحِيحَةً بِرَبْطِ الْكَلِمَاتِ الْمُتَجَاوِرَةِ")
            .font(.subheadline.weight(.semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(Color(red: 0.87, green: 0.96, blue: 0.83))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(red: 0.7, green: 0.9, blue: 0.59).opacity(0.2))
            )
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Picker("الاتجاهات", selection: $model.adjacency) {
                ForEach(Adjacency.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .tint(JumlaTheme.ink)
            .disabled(model.isBusy)
            .onChange(of: model.adjacency) { _, _ in
                if !model.isBusy { model.newLevel() }
            }

            Text("اسحب بين المربعات المتجاورة · ارفع الإصبع للتحقق")
                .font(.caption)
                .foregroundStyle(JumlaTheme.inkDim)
        }
    }
}

private struct CircleIconStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(JumlaTheme.ink)
            .background(Color.black.opacity(0.25), in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.2)))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

#Preview {
    GameView()
}
