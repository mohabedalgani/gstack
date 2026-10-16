import Foundation
import SwiftUI

struct GridPos: Hashable, Sendable {
    var row: Int
    var col: Int
}

struct WordTile: Identifiable, Hashable, Sendable {
    let id: UUID
    var text: String
    var tint: Int

    init(text: String, tint: Int? = nil) {
        self.id = UUID()
        self.text = text
        self.tint = tint ?? Int.random(in: 0..<4)
    }
}

struct IrabLine: Hashable, Sendable {
    var word: String
    var label: String
}

struct SentenceRecipe: Identifiable, Hashable, Sendable {
    let id: String
    var words: [String]
    var irab: [IrabLine]
}

enum Adjacency: String, CaseIterable, Identifiable {
    case four = "٤ اتجاهات"
    case eight = "٨ اتجاهات"
    var id: String { rawValue }
}

enum TileMotion: Equatable {
    case none
    case fall(rows: Int)
    case spawn(dropRows: Int)
}

struct BurstParticle: Identifiable, Equatable {
    let id = UUID()
    var origin: CGPoint
    var angle: Double
    var distance: CGFloat
    var color: Color
}

enum WesternArabicDigits {
    private static let map: [Character] = Array("٠١٢٣٤٥٦٧٨٩")

    static func format(_ value: Int) -> String {
        String(value).map { ch -> Character in
            guard let d = ch.wholeNumberValue else { return ch }
            return map[d]
        }.map(String.init).joined()
    }
}
