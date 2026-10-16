import SwiftUI

struct BoardView: View {
    @ObservedObject var model: GameViewModel
    @Binding var cellFrames: [GridPos: CGRect]
    @Binding var boardFrame: CGRect

    private let spacing: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = (side - spacing * CGFloat(model.cols - 1)) / CGFloat(model.cols)

            ZStack {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(cell), spacing: spacing), count: model.cols),
                    spacing: spacing
                ) {
                    ForEach(0..<model.rows, id: \.self) { r in
                        ForEach(0..<model.cols, id: \.self) { c in
                            let pos = GridPos(row: r, col: c)
                            let tile = model.board[r][c]
                            TileView(
                                tile: tile,
                                isOnPath: model.path.contains(pos),
                                isBad: model.flashBad.contains(pos),
                                isVanishing: model.vanishing.contains(pos),
                                motion: model.motions[tile.id],
                                cellSize: cell,
                                spacing: spacing
                            )
                            .background(
                                GeometryReader { tileGeo in
                                    Color.clear.preference(
                                        key: CellFrameKey.self,
                                        value: [pos: tileGeo.frame(in: .named("board"))]
                                    )
                                }
                            )
                        }
                    }
                }
                .frame(width: side, height: side)

                PathOverlay(path: model.path, frames: cellFrames)
                    .allowsHitTesting(false)

                ForEach(model.ghostTiles) { ghost in
                    let target = model.mergeOrigin ?? ghost.start
                    let t = ghost.progress
                    let x = ghost.start.x + (target.x - ghost.size.width / 2 - ghost.start.x) * t
                    let y = ghost.start.y + (target.y - ghost.size.height / 2 - ghost.start.y) * t
                    Text(ghost.text)
                        .font(.system(size: max(14, cell * 0.28), weight: .bold, design: .serif))
                        .foregroundStyle(JumlaTheme.tileInk)
                        .frame(width: ghost.size.width, height: ghost.size.height)
                        .background(JumlaTheme.tileColors[ghost.tint], in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .scaleEffect(ghost.isLast ? 1.08 : max(0.45, 1 - 0.45 * t))
                        .opacity(ghost.isLast ? 1 : max(0.2, 1 - 0.7 * t))
                        .shadow(color: JumlaTheme.glow.opacity(0.5), radius: 10)
                        .position(x: x + ghost.size.width / 2, y: y + ghost.size.height / 2)
                        .allowsHitTesting(false)
                }

                ForEach(model.particles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: 10, height: 10)
                        .shadow(color: p.color.opacity(0.8), radius: 4)
                        .modifier(BurstMove(particle: p))
                        .allowsHitTesting(false)
                }

                if let origin = model.mergeOrigin {
                    Circle()
                        .stroke(JumlaTheme.glow, lineWidth: 3)
                        .frame(width: cell * 0.9, height: cell * 0.9)
                        .position(origin)
                        .modifier(RingBurst())
                        .allowsHitTesting(false)
                }
            }
            .coordinateSpace(named: "board")
            .frame(width: side, height: side)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .contentShape(Rectangle())
            .gesture(dragGesture(cell: cell, side: side))
            .allowsHitTesting(!model.isBusy)
            .onPreferenceChange(CellFrameKey.self) { cellFrames = $0 }
            .onAppear { boardFrame = CGRect(x: 0, y: 0, width: side, height: side) }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func dragGesture(cell: CGFloat, side: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("board"))
            .onChanged { value in
                guard let pos = hitTest(value.location, cell: cell, side: side) else { return }
                if model.path.isEmpty {
                    model.beginPath(at: pos)
                } else {
                    model.extendPath(to: pos)
                }
            }
            .onEnded { _ in
                model.endPath(cellFrames: cellFrames)
            }
    }

    private func hitTest(_ point: CGPoint, cell: CGFloat, side: CGFloat) -> GridPos? {
        // Board is centered in GeometryReader; gesture uses board coordinate space
        // so origin is top-leading of the ZStack content (side×side).
        guard point.x >= 0, point.y >= 0, point.x <= side, point.y <= side else { return nil }
        let step = cell + spacing
        let c = Int(point.x / step)
        let r = Int(point.y / step)
        guard (0..<model.rows).contains(r), (0..<model.cols).contains(c) else { return nil }
        // Ensure inside the cell (not deep in gap)
        let localX = point.x - CGFloat(c) * step
        let localY = point.y - CGFloat(r) * step
        guard localX <= cell + spacing / 2, localY <= cell + spacing / 2 else { return nil }
        return GridPos(row: r, col: c)
    }
}

private struct TileView: View {
    let tile: WordTile
    let isOnPath: Bool
    let isBad: Bool
    let isVanishing: Bool
    let motion: TileMotion?
    let cellSize: CGFloat
    let spacing: CGFloat

    @State private var fallOffset: CGFloat = 0
    @State private var shakeX: CGFloat = 0
    @State private var motionToken: UUID?

    var body: some View {
        Text(tile.text)
            .font(.system(size: max(14, cellSize * 0.28), weight: .bold, design: .serif))
            .foregroundStyle(JumlaTheme.tileInk)
            .frame(width: cellSize, height: cellSize)
            .background(JumlaTheme.tileColors[tile.tint], in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                if isOnPath {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(JumlaTheme.glow, lineWidth: 3)
                        .shadow(color: JumlaTheme.glow.opacity(0.55), radius: 8)
                }
            }
            .scaleEffect(isOnPath ? 1.06 : (isVanishing ? 0.2 : 1))
            .opacity(isVanishing ? 0 : 1)
            .offset(x: shakeX, y: fallOffset)
            .onAppear { runMotion(motion) }
            .onChange(of: motion) { _, new in runMotion(new) }
            .onChange(of: isBad) { _, bad in
                guard bad else { return }
                withAnimation(.linear(duration: 0.06).repeatCount(4, autoreverses: true)) { shakeX = 4 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { shakeX = 0 }
            }
            .animation(.easeOut(duration: 0.2), value: isVanishing)
    }

    private func runMotion(_ motion: TileMotion?) {
        let token = UUID()
        motionToken = token
        guard let motion else {
            fallOffset = 0
            return
        }
        let step = cellSize + spacing
        switch motion {
        case .none:
            fallOffset = 0
        case .fall(let rows):
            fallOffset = -CGFloat(rows) * step
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                if motionToken == token { fallOffset = 0 }
            }
        case .spawn(let dropRows):
            fallOffset = -CGFloat(dropRows) * step
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                if motionToken == token { fallOffset = 0 }
            }
        }
    }
}

private struct PathOverlay: View {
    let path: [GridPos]
    let frames: [GridPos: CGRect]

    var body: some View {
        Canvas { context, _ in
            guard path.count >= 2 else { return }
            var line = Path()
            for (i, pos) in path.enumerated() {
                guard let f = frames[pos] else { continue }
                let p = CGPoint(x: f.midX, y: f.midY)
                if i == 0 { line.move(to: p) } else { line.addLine(to: p) }
            }
            context.stroke(
                line,
                with: .color(JumlaTheme.glow),
                style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
            )
            for pos in path {
                guard let f = frames[pos] else { continue }
                let rect = CGRect(x: f.midX - 7, y: f.midY - 7, width: 14, height: 14)
                context.fill(Path(ellipseIn: rect), with: .color(JumlaTheme.glow))
            }
        }
    }
}

private struct BurstMove: ViewModifier {
    let particle: BurstParticle
    @State private var progress: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(
                x: cos(particle.angle) * particle.distance * progress,
                y: sin(particle.angle) * particle.distance * progress
            )
            .opacity(1 - progress)
            .scaleEffect(1 - 0.7 * progress)
            .position(particle.origin)
            .onAppear {
                withAnimation(.easeOut(duration: 0.42)) { progress = 1 }
            }
    }
}

private struct RingBurst: ViewModifier {
    @State private var scale: CGFloat = 0.3
    @State private var opacity: CGFloat = 0.9

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.42)) {
                    scale = 2.2
                    opacity = 0
                }
            }
    }
}

private struct CellFrameKey: PreferenceKey {
    static var defaultValue: [GridPos: CGRect] = [:]
    static func reduce(value: inout [GridPos: CGRect], nextValue: () -> [GridPos: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
