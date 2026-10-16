import Foundation

enum BoardLogic {
    static let rows = 5
    static let cols = 5

    static func neighbors(of pos: GridPos, adjacency: Adjacency) -> [GridPos] {
        let deltas: [(Int, Int)]
        switch adjacency {
        case .four:
            deltas = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        case .eight:
            deltas = [
                (-1, 0), (1, 0), (0, -1), (0, 1),
                (-1, -1), (-1, 1), (1, -1), (1, 1),
            ]
        }
        return deltas.compactMap { dr, dc in
            let r = pos.row + dr
            let c = pos.col + dc
            guard (0..<rows).contains(r), (0..<cols).contains(c) else { return nil }
            return GridPos(row: r, col: c)
        }
    }

    static func areAdjacent(_ a: GridPos, _ b: GridPos, adjacency: Adjacency) -> Bool {
        neighbors(of: a, adjacency: adjacency).contains(b)
    }

    static func matchRecipe(texts: [String], in recipes: [SentenceRecipe]) -> SentenceRecipe? {
        recipes.first { recipe in
            recipe.words.count == texts.count &&
                zip(recipe.words, texts).allSatisfy { $0 == $1 }
        }
    }

    static func growPath(
        start: GridPos,
        length: Int,
        occupied: Set<GridPos>,
        adjacency: Adjacency
    ) -> [GridPos]? {
        guard !occupied.contains(start) else { return nil }
        var path = [start]
        var used: Set<GridPos> = [start]
        while path.count < length {
            let opts = neighbors(of: path[path.count - 1], adjacency: adjacency)
                .filter { !used.contains($0) && !occupied.contains($0) }
                .shuffled()
            guard let next = opts.first else { return nil }
            path.append(next)
            used.insert(next)
        }
        return path
    }

    static func placeRecipes(
        _ recipes: [SentenceRecipe],
        adjacency: Adjacency
    ) -> [[WordTile]] {
        var grid: [[WordTile?]] = Array(
            repeating: Array(repeating: nil, count: cols),
            count: rows
        )
        var occupied = Set<GridPos>()
        var cells: [GridPos] = []
        for r in 0..<rows {
            for c in 0..<cols { cells.append(GridPos(row: r, col: c)) }
        }
        cells.shuffle()

        for recipe in recipes {
            var placed = false
            for _ in 0..<80 where !placed {
                guard let start = cells.randomElement(),
                      let path = growPath(
                        start: start,
                        length: recipe.words.count,
                        occupied: occupied,
                        adjacency: adjacency
                      ) else { continue }
                for (i, p) in path.enumerated() {
                    grid[p.row][p.col] = WordTile(text: recipe.words[i])
                    occupied.insert(p)
                }
                placed = true
            }
            if !placed {
                for word in recipe.words {
                    guard let free = cells.first(where: { !occupied.contains($0) }) else { break }
                    grid[free.row][free.col] = WordTile(text: word)
                    occupied.insert(free)
                }
            }
        }

        var distractors = ContentCatalog.distractors.shuffled()
        var di = 0
        for r in 0..<rows {
            for c in 0..<cols where grid[r][c] == nil {
                grid[r][c] = WordTile(text: distractors[di % distractors.count])
                di += 1
            }
        }
        return grid.map { row in row.map { $0! } }
    }

    struct RefillResult {
        var board: [[WordTile]]
        var motions: [UUID: TileMotion]
    }

    static func refill(
        board: [[WordTile]],
        cleared: Set<GridPos>,
        adjacency: Adjacency,
        recipesPool: [SentenceRecipe]
    ) -> RefillResult {
        var working: [[WordTile?]] = board.map { $0.map { Optional($0) } }
        for p in cleared { working[p.row][p.col] = nil }

        var after: [[WordTile?]] = Array(
            repeating: Array(repeating: nil, count: cols),
            count: rows
        )
        var motions: [UUID: TileMotion] = [:]

        for c in 0..<cols {
            var stack: [(tile: WordTile, fromRow: Int)] = []
            for r in 0..<rows {
                if let tile = working[r][c] {
                    stack.append((tile, r))
                }
            }
            var write = rows - 1
            for item in stack.reversed() {
                after[write][c] = item.tile
                if item.fromRow != write {
                    motions[item.tile.id] = .fall(rows: write - item.fromRow)
                }
                write -= 1
            }
        }

        var occupied = Set<GridPos>()
        for r in 0..<rows {
            for c in 0..<cols where after[r][c] != nil {
                occupied.insert(GridPos(row: r, col: c))
            }
        }

        for recipe in recipesPool.shuffled().prefix(2) {
            var empties: [GridPos] = []
            for r in 0..<rows {
                for c in 0..<cols where after[r][c] == nil {
                    empties.append(GridPos(row: r, col: c))
                }
            }
            guard empties.count >= recipe.words.count else { continue }
            var placed = false
            for _ in 0..<40 where !placed {
                guard let start = empties.randomElement(),
                      let path = growPath(
                        start: start,
                        length: recipe.words.count,
                        occupied: occupied,
                        adjacency: adjacency
                      ) else { continue }
                for (i, p) in path.enumerated() {
                    let tile = WordTile(text: recipe.words[i])
                    after[p.row][p.col] = tile
                    occupied.insert(p)
                    motions[tile.id] = .spawn(dropRows: p.row + 1)
                }
                placed = true
            }
            if placed { break }
        }

        var pool = (ContentCatalog.distractors + ContentCatalog.recipes.flatMap(\.words)).shuffled()
        var pi = 0
        for r in 0..<rows {
            for c in 0..<cols where after[r][c] == nil {
                let tile = WordTile(text: pool[pi % pool.count])
                pi += 1
                after[r][c] = tile
                motions[tile.id] = .spawn(dropRows: r + 1)
            }
        }

        return RefillResult(
            board: after.map { row in row.map { $0! } },
            motions: motions
        )
    }
}
