import SwiftUI

struct FolderTreeVisualizer: View {
    let root: FolderNode
    let accent: Color

    @State private var currentIndex: Int = -1
    @State private var isPlaying: Bool = false

    private let stepDuration: Duration = .milliseconds(950)

    private struct FlatRow {
        let node: FolderNode
        let depth: Int
    }

    private var flat: [FlatRow] {
        var result: [FlatRow] = []
        func visit(_ node: FolderNode, depth: Int) {
            result.append(FlatRow(node: node, depth: depth))
            for child in node.children {
                visit(child, depth: depth + 1)
            }
        }
        visit(root, depth: 0)
        return result
    }

    private var totalSteps: Int { flat.count }
    private var lastIndex: Int { totalSteps - 1 }

    private var visitedIDs: Set<String> {
        guard currentIndex >= 0 else { return [] }
        return Set(flat.prefix(currentIndex + 1).map { $0.node.id })
    }

    private var currentNodeID: String? {
        guard currentIndex >= 0, currentIndex < flat.count else { return nil }
        return flat[currentIndex].node.id
    }

    private var filesCounted: Int {
        guard currentIndex >= 0 else { return 0 }
        return flat.prefix(currentIndex + 1).filter { !$0.node.isFolder }.count
    }

    var body: some View {
        VStack(spacing: 14) {
            statsRow
            treeColumn
            controls
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .task(id: isPlaying) {
            guard isPlaying else { return }
            while !Task.isCancelled && isPlaying {
                try? await Task.sleep(for: stepDuration)
                if !isPlaying { break }
                if currentIndex < lastIndex {
                    stepForward()
                } else {
                    isPlaying = false
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatChip(label: "Files counted", value: "\(filesCounted)", icon: "doc.fill", tint: .green)
            StatChip(label: "Step", value: "\(max(currentIndex + 1, 0)) of \(totalSteps)", icon: "arrow.right.circle.fill", tint: accent)
        }
    }

    private var treeColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(flat.enumerated()), id: \.offset) { _, row in
                TreeRow(
                    node: row.node,
                    depth: row.depth,
                    state: rowState(for: row.node.id),
                    accent: accent
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .animation(.spring(response: 0.4, dampingFraction: 0.78), value: currentIndex)
    }

    private func rowState(for id: String) -> TreeRow.RowState {
        if id == currentNodeID { return .current }
        if visitedIDs.contains(id) { return .visited }
        return .pending
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button { reset() } label: { Image(systemName: "arrow.counterclockwise") }
                .buttonStyle(.bordered)
                .disabled(currentIndex < 0 && !isPlaying)
            Spacer()
            Button { stepBack() } label: { Image(systemName: "chevron.left") }
                .buttonStyle(.bordered)
                .disabled(currentIndex < 0)
            Button { togglePlay() } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
            Button { stepForward() } label: { Image(systemName: "chevron.right") }
                .buttonStyle(.bordered)
                .disabled(currentIndex >= lastIndex)
            Spacer()
            Color.clear.frame(width: 44, height: 1)
        }
    }

    private func reset() {
        isPlaying = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentIndex = -1
        }
    }

    private func stepForward() {
        guard currentIndex < lastIndex else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            currentIndex += 1
        }
    }

    private func stepBack() {
        guard currentIndex >= 0 else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            currentIndex -= 1
        }
    }

    private func togglePlay() {
        if currentIndex >= lastIndex { currentIndex = -1 }
        isPlaying.toggle()
    }
}

private struct TreeRow: View {
    enum RowState { case pending, current, visited }

    let node: FolderNode
    let depth: Int
    let state: RowState
    let accent: Color

    var body: some View {
        HStack(spacing: 8) {
            Color.clear.frame(width: CGFloat(depth) * 18, height: 1)

            Image(systemName: node.isFolder ? "folder.fill" : "doc.fill")
                .foregroundStyle(iconColor)
                .frame(width: 22, height: 22)
                .background(Circle().fill(iconBg))

            Text(node.name)
                .font(.subheadline.weight(state == .pending ? .regular : .semibold))
                .foregroundStyle(textColor)
                .lineLimit(1)

            Spacer(minLength: 4)

            if let size = node.size {
                Text(size)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            trailingIcon
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground)
        .overlay(rowBorder)
        .scaleEffect(state == .current ? 1.02 : 1)
    }

    @ViewBuilder
    private var trailingIcon: some View {
        switch state {
        case .current:
            Image(systemName: "eye.fill")
                .font(.caption)
                .foregroundStyle(accent)
        case .visited:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .pending:
            EmptyView()
        }
    }

    private var iconColor: Color {
        switch state {
        case .current: accent
        case .visited: .green
        case .pending: node.isFolder ? Color.orange.opacity(0.8) : .secondary
        }
    }

    private var iconBg: Color {
        switch state {
        case .current: accent.opacity(0.16)
        case .visited: .green.opacity(0.16)
        case .pending: Color.secondary.opacity(0.08)
        }
    }

    private var textColor: Color {
        switch state {
        case .current: .primary
        case .visited: .primary
        case .pending: .secondary
        }
    }

    @ViewBuilder
    private var rowBackground: some View {
        switch state {
        case .current:
            RoundedRectangle(cornerRadius: 8)
                .fill(accent.opacity(0.10))
        case .visited:
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.06))
        case .pending:
            Color.clear
        }
    }

    @ViewBuilder
    private var rowBorder: some View {
        switch state {
        case .current:
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(accent.opacity(0.45), lineWidth: 1.5)
        case .visited:
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.green.opacity(0.25), lineWidth: 1)
        case .pending:
            EmptyView()
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
