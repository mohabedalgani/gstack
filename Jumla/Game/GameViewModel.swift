import Foundation
import SwiftUI
import UIKit

@MainActor
final class GameViewModel: ObservableObject {
    let rows = BoardLogic.rows
    let cols = BoardLogic.cols

    @Published var board: [[WordTile]] = []
    @Published var path: [GridPos] = []
    @Published var score = 0
    @Published var level = 1
    @Published var adjacency: Adjacency = .four
    @Published var isMuted = false
    @Published var isBusy = false
    @Published var lastRecipe: SentenceRecipe?
    @Published var showFeedback = false
    @Published var scoreDelta: Int?
    @Published var motions: [UUID: TileMotion] = [:]
    @Published var flashBad: Set<GridPos> = []
    @Published var vanishing: Set<GridPos> = []
    @Published var mergeOrigin: CGPoint?
    @Published var particles: [BurstParticle] = []
    @Published var ghostTiles: [GhostTile] = []

    private var dragging = false
    private var solvedIds = Set<String>()
    private let audio = SoundPlayer.shared

    struct GhostTile: Identifiable, Equatable {
        let id: UUID
        var text: String
        var tint: Int
        var start: CGPoint
        var size: CGSize
        var isLast: Bool
        var progress: CGFloat = 0
    }

    init() {
        newLevel()
    }

    var levelTitle: String {
        "المستوى \(WesternArabicDigits.format(level)) — بناء الجملة الفعلية"
    }

    func toggleMute() {
        audio.unlock()
        isMuted.toggle()
        audio.isMuted = isMuted
    }

    func resetGame() {
        guard !isBusy else { return }
        score = 0
        level = 1
        solvedIds.removeAll()
        scoreDelta = nil
        showFeedback = false
        lastRecipe = nil
        newLevel()
    }

    func newLevel() {
        path = []
        dragging = false
        isBusy = false
        vanishing = []
        particles = []
        ghostTiles = []
        mergeOrigin = nil
        motions = [:]
        let recipes = pickRecipes(count: 3)
        board = BoardLogic.placeRecipes(recipes, adjacency: adjacency)
    }

    func beginPath(at pos: GridPos) {
        guard !isBusy, board.indices.contains(pos.row), board[pos.row].indices.contains(pos.col) else { return }
        audio.unlock()
        dragging = true
        path = [pos]
        showFeedback = false
        audio.playSelect()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func extendPath(to pos: GridPos) {
        guard dragging, !isBusy, let last = path.last else { return }
        if last == pos { return }

        if path.count >= 2, path[path.count - 2] == pos {
            path.removeLast()
            return
        }
        if path.contains(pos) { return }
        guard BoardLogic.areAdjacent(last, pos, adjacency: adjacency) else { return }
        path.append(pos)
        audio.playSelect()
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func endPath(cellFrames: [GridPos: CGRect]) {
        guard dragging, !isBusy else { return }
        dragging = false
        let texts = path.map { board[$0.row][$0.col].text }
        guard let recipe = BoardLogic.matchRecipe(texts: texts, in: ContentCatalog.recipes) else {
            Task { await failPath() }
            return
        }
        Task { await resolveSuccess(recipe: recipe, cellFrames: cellFrames) }
    }

    private func failPath() async {
        audio.playMiss()
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        flashBad = Set(path)
        try? await Task.sleep(nanoseconds: 280_000_000)
        flashBad = []
        path = []
    }

    private func resolveSuccess(
        recipe: SentenceRecipe,
        cellFrames: [GridPos: CGRect]
    ) async {
        isBusy = true
        let pathCopy = path
        guard let last = pathCopy.last,
              let lastFrame = cellFrames[last] else {
            isBusy = false
            return
        }

        let target = CGPoint(x: lastFrame.midX, y: lastFrame.midY)
        mergeOrigin = target

        ghostTiles = pathCopy.compactMap { pos -> GhostTile? in
            guard let frame = cellFrames[pos] else { return nil }
            let tile = board[pos.row][pos.col]
            return GhostTile(
                id: tile.id,
                text: tile.text,
                tint: tile.tint,
                start: CGPoint(x: frame.minX, y: frame.minY),
                size: frame.size,
                isLast: pos == last
            )
        }
        vanishing = Set(pathCopy)
        path = []

        withAnimation(.easeInOut(duration: 0.28)) {
            for i in ghostTiles.indices {
                ghostTiles[i].progress = 1
            }
        }
        audio.playExplode(index: 0)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        try? await Task.sleep(nanoseconds: 320_000_000)

        // Burst
        particles = (0..<14).map { i in
            BurstParticle(
                origin: target,
                angle: (Double.pi * 2 * Double(i) / 14) + Double.random(in: 0...0.2),
                distance: CGFloat.random(in: 36...84),
                color: JumlaTheme.tileColors[ghostTiles[i % max(ghostTiles.count, 1)].tint]
            )
        }
        audio.playExplode(index: 1)
        audio.playExplode(index: 2)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        try? await Task.sleep(nanoseconds: 380_000_000)

        ghostTiles = []
        particles = []
        mergeOrigin = nil
        vanishing = []

        audio.playSuccess()
        let delta = recipe.words.count * 25
        score += delta
        scoreDelta = delta
        lastRecipe = recipe
        showFeedback = true
        solvedIds.insert(recipe.id)
        if solvedIds.count % 3 == 0 { level += 1 }

        let unused = ContentCatalog.recipes.filter { !solvedIds.contains($0.id) }
        let pool = unused.isEmpty ? ContentCatalog.recipes : unused
        let refill = BoardLogic.refill(
            board: board,
            cleared: Set(pathCopy),
            adjacency: adjacency,
            recipesPool: Array(pool.shuffled().prefix(2))
        )
        motions = refill.motions
        board = refill.board
        audio.playFall()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let maxFall = motions.values.compactMap { motion -> Int? in
            if case .fall(let rows) = motion { return rows }
            return nil
        }.max() ?? 0
        try? await Task.sleep(nanoseconds: UInt64(300 + maxFall * 45) * 1_000_000)

        let spawnCount = motions.values.filter {
            if case .spawn = $0 { return true }
            return false
        }.count
        for i in 0..<min(spawnCount, 6) { audio.playSpawn(index: i) }
        try? await Task.sleep(nanoseconds: 420_000_000)

        motions = [:]
        scoreDelta = nil
        isBusy = false
    }

    private func pickRecipes(count: Int) -> [SentenceRecipe] {
        let unused = ContentCatalog.recipes.filter { !solvedIds.contains($0.id) }
        let pool = unused.isEmpty ? ContentCatalog.recipes : unused
        return Array(pool.shuffled().prefix(count))
    }
}
