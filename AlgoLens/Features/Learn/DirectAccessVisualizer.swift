import SwiftUI

struct DirectAccessVisualizer: View {
    let items: [DirectAccessItem]
    let queries: [DirectAccessQuery]
    let accent: Color

    @State private var queryIndex: Int = 0

    private var currentQuery: DirectAccessQuery? {
        guard queryIndex > 0, queryIndex <= queries.count else { return nil }
        return queries[queryIndex - 1]
    }

    private var totalSteps: Int { queries.count + 1 }
    private var lastStep: Int { queries.count }
    private var highlightedItemIndex: Int? { currentQuery?.index }

    var body: some View {
        VStack(spacing: 16) {
            promptRow
            list
            statsRow
            controls
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var promptRow: some View {
        HStack(spacing: 8) {
            Image(systemName: currentQuery == nil ? "list.number" : "scope")
                .foregroundStyle(currentQuery == nil ? .secondary : accent)
            Text(currentQuery?.label ?? "The album — track 0 through \(items.count - 1)")
                .font(.subheadline.weight(.medium))
            Spacer(minLength: 0)
        }
    }

    private var list: some View {
        VStack(spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                Row(
                    index: index,
                    title: item.title,
                    isHighlighted: index == highlightedItemIndex,
                    accent: accent
                )
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: queryIndex)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            ReadoutChip(
                label: "Direct access",
                value: "1 step",
                tint: accent,
                emphasis: currentQuery != nil
            )
            ReadoutChip(
                label: "Linear scan would be",
                value: linearScanText,
                tint: .secondary,
                emphasis: false
            )
        }
    }

    private var linearScanText: String {
        if let q = currentQuery {
            return "\(q.index + 1) step\(q.index == 0 ? "" : "s")"
        } else {
            return "—"
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button { reset() } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .disabled(queryIndex == 0)

            Spacer()

            Button { stepBack() } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(queryIndex == 0)

            Button { stepForward() } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
            .disabled(queryIndex >= lastStep)

            Spacer()

            Color.clear.frame(width: 44, height: 1)
        }
    }

    private func reset() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            queryIndex = 0
        }
    }

    private func stepForward() {
        guard queryIndex < lastStep else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            queryIndex += 1
        }
    }

    private func stepBack() {
        guard queryIndex > 0 else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            queryIndex -= 1
        }
    }
}

private struct Row: View {
    let index: Int
    let title: String
    let isHighlighted: Bool
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            Text("\(index)")
                .font(.subheadline.monospacedDigit().weight(.bold))
                .foregroundStyle(isHighlighted ? .white : .secondary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isHighlighted ? accent : Color.secondary.opacity(0.15))
                )

            Text(title)
                .font(.subheadline.weight(isHighlighted ? .semibold : .regular))
                .foregroundStyle(isHighlighted ? .primary : .secondary)

            Spacer(minLength: 0)

            if isHighlighted {
                Image(systemName: "arrow.left")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accent)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHighlighted ? accent.opacity(0.14) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isHighlighted ? accent.opacity(0.45) : .clear, lineWidth: 1)
        )
    }
}

private struct ReadoutChip: View {
    let label: String
    let value: String
    let tint: Color
    let emphasis: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(emphasis ? tint : .secondary)
                .monospacedDigit()
                .contentTransition(.numericText(value: 0))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
