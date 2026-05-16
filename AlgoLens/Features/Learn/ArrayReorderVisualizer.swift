import SwiftUI

struct ArrayReorderVisualizer: View {
    let items: [ReorderItem]
    let moves: [ReorderMove]
    let accent: Color

    @State private var order: [ReorderItem]
    @State private var playCount: Int = 0
    @State private var displayedShifts: Int = 0
    @State private var totalShifts: Int = 0
    @State private var lastMoveCaption: String? = nil
    @State private var aboutToShift: Set<String> = []
    @State private var justPlayedID: String? = nil
    @State private var isAnimating: Bool = false
    @State private var suggestionIndex: Int = 0

    init(items: [ReorderItem], moves: [ReorderMove], accent: Color) {
        self.items = items
        self.moves = moves
        self.accent = accent
        self._order = State(initialValue: items)
    }

    var body: some View {
        VStack(spacing: 14) {
            statsRow
            songList
            caption
            controls
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatBadge(label: "Plays", value: "\(playCount)", icon: "play.fill", tint: accent)
            StatBadge(label: "Total shifts", value: "\(displayedShifts)", icon: "arrow.up.arrow.down", tint: .green)
        }
    }

    private var songList: some View {
        VStack(spacing: 6) {
            ForEach(order) { item in
                SongRow(
                    item: item,
                    isAboutToShift: aboutToShift.contains(item.id),
                    isJustPlayed: justPlayedID == item.id,
                    accent: accent
                ) {
                    play(item)
                }
                .disabled(isAnimating)
            }
        }
    }

    @ViewBuilder
    private var caption: some View {
        if let text = lastMoveCaption {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .transition(.opacity)
        } else {
            HStack {
                Image(systemName: "hand.tap")
                    .foregroundStyle(.secondary)
                Text("Tap any song to play it. Watch the cost climb.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button { playSuggestion() } label: {
                Label(suggestionTitle, systemImage: "wand.and.stars")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .buttonStyle(.bordered)
            .tint(accent)
            .disabled(isAnimating || moves.isEmpty)

            Spacer()

            Button { reset() } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .disabled(isAnimating || (playCount == 0 && totalShifts == 0))
        }
    }

    private var suggestionTitle: String {
        guard !moves.isEmpty else { return "No suggestions" }
        let move = moves[suggestionIndex % moves.count]
        if let target = items.first(where: { $0.id == move.itemID }) {
            return "Try playing '\(target.title)'"
        }
        return "Try a play"
    }

    private func play(_ item: ReorderItem) {
        guard !isAnimating else { return }
        guard let idx = order.firstIndex(where: { $0.id == item.id }) else { return }
        let shifts = idx
        let willShift = Set(order.prefix(idx).map { $0.id })

        isAnimating = true

        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.2)) {
                aboutToShift = willShift
                justPlayedID = item.id
                lastMoveCaption = nil
            }
            try? await Task.sleep(for: .milliseconds(220))

            playCount += 1
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                let it = order.remove(at: idx)
                order.insert(it, at: 0)
            }

            if shifts > 0 {
                for i in 1...shifts {
                    try? await Task.sleep(for: .milliseconds(70))
                    withAnimation(.easeOut(duration: 0.18)) {
                        displayedShifts = totalShifts + i
                    }
                }
            }
            totalShifts += shifts
            displayedShifts = totalShifts

            withAnimation(.easeOut(duration: 0.25)) {
                lastMoveCaption = "Played '\(item.title)' — \(shifts) shift\(shifts == 1 ? "" : "s")"
            }
            try? await Task.sleep(for: .milliseconds(280))
            withAnimation(.easeOut(duration: 0.3)) {
                aboutToShift = []
                justPlayedID = nil
            }
            isAnimating = false
        }
    }

    private func playSuggestion() {
        guard !moves.isEmpty else { return }
        let move = moves[suggestionIndex % moves.count]
        suggestionIndex += 1
        guard let item = order.first(where: { $0.id == move.itemID }) else { return }
        play(item)
    }

    private func reset() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
            order = items
            playCount = 0
            displayedShifts = 0
            totalShifts = 0
            lastMoveCaption = nil
            aboutToShift = []
            justPlayedID = nil
            suggestionIndex = 0
        }
    }
}

private struct SongRow: View {
    let item: ReorderItem
    let isAboutToShift: Bool
    let isJustPlayed: Bool
    let accent: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                albumTile

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(item.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                trailingIcon
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .scaleEffect(isJustPlayed ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var trailingIcon: some View {
        if isJustPlayed {
            Image(systemName: "play.circle.fill")
                .font(.callout)
                .foregroundStyle(accent)
                .transition(.scale.combined(with: .opacity))
        } else if isAboutToShift {
            Image(systemName: "arrow.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(.orange)
        }
    }

    private var rowBackground: AnyShapeStyle {
        if isJustPlayed { return AnyShapeStyle(accent.opacity(0.18)) }
        if isAboutToShift { return AnyShapeStyle(Color.orange.opacity(0.10)) }
        return AnyShapeStyle(Color.secondary.opacity(0.08))
    }

    private var borderColor: Color {
        if isJustPlayed { return accent.opacity(0.5) }
        if isAboutToShift { return .orange.opacity(0.4) }
        return .clear
    }

    private var albumTile: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(tileColor.gradient)
            .frame(width: 40, height: 40)
            .overlay(
                Text(String(item.title.prefix(1)))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            )
    }

    private var tileColor: Color {
        var hash: UInt64 = 5381
        for c in item.id.unicodeScalars {
            hash = (hash &* 33) &+ UInt64(c.value)
        }
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.72)
    }
}

private struct StatBadge: View {
    let label: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(Circle().fill(tint.opacity(0.15)))
            VStack(alignment: .leading, spacing: 0) {
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: 0))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
