import SwiftUI

struct FeedbackPanel: View {
    let recipe: SentenceRecipe

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("✓")
                    .font(.headline.bold())
                    .frame(width: 28, height: 28)
                    .background(JumlaTheme.ok.opacity(0.18), in: Circle())
                    .overlay(Circle().strokeBorder(JumlaTheme.ok.opacity(0.55)))
                Text("أَحْسَنْتَ!")
                    .font(.title3.bold())
                    .foregroundStyle(JumlaTheme.ok)
            }

            Text(recipe.words.joined(separator: " "))
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(JumlaTheme.ink)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            VStack(spacing: 6) {
                ForEach(recipe.irab, id: \.word) { line in
                    HStack {
                        Text(line.word)
                            .font(.system(size: 17, weight: .bold, design: .serif))
                        Spacer()
                        Text(line.label)
                            .foregroundStyle(JumlaTheme.inkDim)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            Text("ظَهَرَتْ كَلِمَاتٌ جَدِيدَةٌ فِي اللَّوْحَةِ")
                .font(.footnote)
                .foregroundStyle(Color(red: 0.78, green: 0.91, blue: 0.72))
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
        }
        .padding(16)
        .background(Color(red: 0.05, green: 0.16, blue: 0.11).opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color(red: 0.63, green: 0.86, blue: 0.55).opacity(0.35))
        )
    }
}
