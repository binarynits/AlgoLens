import SwiftUI

struct GraphBFSVisualizer: View {
    let nodes: [GraphNode]
    let edges: [GraphEdge]
    let startID: String
    let targetID: String
    let accent: Color

    @State private var currentStep: Int = -1
    @State private var isPlaying: Bool = false

    private let stepDuration: Duration = .milliseconds(900)
    private let canvasHeight: CGFloat = 280

    private struct VisitedHop: Hashable {
        let nodeID: String
        let depth: Int
    }

    private var trace: [VisitedHop] {
        var adj: [String: [String]] = [:]
        for e in edges {
            adj[e.from, default: []].append(e.to)
            adj[e.to, default: []].append(e.from)
        }
        var queue: [(String, Int)] = [(startID, 0)]
        var seen: Set<String> = [startID]
        var result: [VisitedHop] = []
        while !queue.isEmpty {
            let (node, depth) = queue.removeFirst()
            result.append(VisitedHop(nodeID: node, depth: depth))
            if node == targetID { break }
            for neighbor in (adj[node] ?? []) where !seen.contains(neighbor) {
                seen.insert(neighbor)
                queue.append((neighbor, depth + 1))
            }
        }
        return result
    }

    private var totalSteps: Int { trace.count }
    private var lastIndex: Int { totalSteps - 1 }

    private var visitedIDs: Set<String> {
        guard currentStep >= 0 else { return [] }
        return Set(trace.prefix(currentStep + 1).map { $0.nodeID })
    }

    private var currentNodeID: String? {
        guard currentStep >= 0, currentStep < trace.count else { return nil }
        return trace[currentStep].nodeID
    }

    private var currentDepth: Int {
        guard currentStep >= 0 else { return 0 }
        return trace[currentStep].depth
    }

    private var foundTarget: Bool {
        currentNodeID == targetID
    }

    var body: some View {
        VStack(spacing: 14) {
            statsRow
            graphCanvas
            statusLine
            controls
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .task(id: isPlaying) {
            guard isPlaying else { return }
            while !Task.isCancelled && isPlaying {
                try? await Task.sleep(for: stepDuration)
                if !isPlaying { break }
                if currentStep < lastIndex && !foundTarget {
                    stepForward()
                } else {
                    isPlaying = false
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatChip(label: "Hops", value: "\(currentDepth)", icon: "arrow.left.and.right", tint: accent)
            StatChip(label: "Visited", value: "\(visitedIDs.count) of \(nodes.count)", icon: "checkmark.circle.fill", tint: .green)
        }
    }

    private var graphCanvas: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(edges.enumerated()), id: \.offset) { _, edge in
                    let p1 = position(of: edge.from, in: geo.size)
                    let p2 = position(of: edge.to, in: geo.size)
                    EdgeLine(from: p1, to: p2, isActive: isEdgeActive(edge))
                }
                ForEach(nodes) { node in
                    NodeBubble(
                        name: node.name,
                        state: nodeState(for: node.id),
                        isStart: node.id == startID,
                        isTarget: node.id == targetID,
                        accent: accent
                    )
                    .position(position(of: node.id, in: geo.size))
                }
            }
        }
        .frame(height: canvasHeight)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    private func position(of nodeID: String, in size: CGSize) -> CGPoint {
        guard let node = nodes.first(where: { $0.id == nodeID }) else { return .zero }
        let padding: CGFloat = 36
        return CGPoint(
            x: padding + (size.width - padding * 2) * node.x,
            y: padding + (size.height - padding * 2) * node.y
        )
    }

    private func nodeState(for id: String) -> NodeBubble.BubbleState {
        if id == currentNodeID { return .current }
        if visitedIDs.contains(id) { return .visited }
        return .pending
    }

    private func isEdgeActive(_ edge: GraphEdge) -> Bool {
        visitedIDs.contains(edge.from) && visitedIDs.contains(edge.to)
    }

    @ViewBuilder
    private var statusLine: some View {
        HStack(spacing: 6) {
            if foundTarget {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                Text("Found target in \(currentDepth) hop\(currentDepth == 1 ? "" : "s").")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            } else if let id = currentNodeID, let name = nodes.first(where: { $0.id == id })?.name {
                Image(systemName: "eye.fill").foregroundStyle(accent)
                Text("Visiting \(name) at depth \(currentDepth)…")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "play.circle").foregroundStyle(.secondary)
                Text("Tap → to start BFS from \(nodes.first(where: { $0.id == startID })?.name ?? "start").")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button { reset() } label: { Image(systemName: "arrow.counterclockwise") }
                .buttonStyle(.bordered)
                .disabled(currentStep < 0 && !isPlaying)
            Spacer()
            Button { stepBack() } label: { Image(systemName: "chevron.left") }
                .buttonStyle(.bordered)
                .disabled(currentStep < 0)
            Button { togglePlay() } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
            Button { stepForward() } label: { Image(systemName: "chevron.right") }
                .buttonStyle(.bordered)
                .disabled(currentStep >= lastIndex || foundTarget)
            Spacer()
            Color.clear.frame(width: 44, height: 1)
        }
    }

    private func reset() {
        isPlaying = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentStep = -1
        }
    }

    private func stepForward() {
        guard currentStep < lastIndex, !foundTarget else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            currentStep += 1
        }
    }

    private func stepBack() {
        guard currentStep >= 0 else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            currentStep -= 1
        }
    }

    private func togglePlay() {
        if currentStep >= lastIndex || foundTarget { currentStep = -1 }
        isPlaying.toggle()
    }
}

private struct EdgeLine: View {
    let from: CGPoint
    let to: CGPoint
    let isActive: Bool

    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(isActive ? Color.green.opacity(0.75) : Color.secondary.opacity(0.30),
                style: StrokeStyle(lineWidth: isActive ? 2.5 : 1.5, lineCap: .round))
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

private struct NodeBubble: View {
    enum BubbleState { case pending, current, visited }

    let name: String
    let state: BubbleState
    let isStart: Bool
    let isTarget: Bool
    let accent: Color

    private let diameter: CGFloat = 56

    var body: some View {
        ZStack {
            Circle()
                .fill(bgColor)
                .frame(width: diameter, height: diameter)
            Circle()
                .strokeBorder(borderColor, lineWidth: state == .current ? 3 : (isStart || isTarget ? 2 : 1.5))
                .frame(width: diameter, height: diameter)
            VStack(spacing: 1) {
                Text(name)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if isTarget {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.yellow)
                } else if isStart && state == .pending {
                    Text("START")
                        .font(.system(size: 7).weight(.bold))
                        .foregroundStyle(accent)
                }
            }
            .padding(.horizontal, 4)
        }
        .scaleEffect(state == .current ? 1.12 : 1.0)
        .shadow(color: state == .current ? accent.opacity(0.5) : .clear, radius: 8)
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: state)
    }

    private var bgColor: Color {
        switch state {
        case .current: accent.opacity(0.22)
        case .visited: Color.green.opacity(0.18)
        case .pending: Color.secondary.opacity(0.10)
        }
    }

    private var borderColor: Color {
        switch state {
        case .current: accent
        case .visited: .green.opacity(0.7)
        case .pending: isStart ? accent.opacity(0.6) : (isTarget ? Color.yellow.opacity(0.7) : Color.secondary.opacity(0.4))
        }
    }

    private var textColor: Color {
        switch state {
        case .current: .primary
        case .visited: .primary
        case .pending: .secondary
        }
    }
}

private struct StatChip: View {
    let label: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.caption)
            VStack(alignment: .leading, spacing: 0) {
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: 0))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}
