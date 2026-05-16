import SwiftUI

struct DuplicateDetectionVisualizer: View {
    let stream: [PaymentEvent]
    let accent: Color

    @State private var step: Int = 0
    @State private var flashTxnID: String? = nil
    @State private var newlyAddedTxnID: String? = nil
    @State private var isPlaying: Bool = false

    private let autoStepDuration: Duration = .milliseconds(1100)

    private var lastStep: Int { stream.count }

    private func seenSet(at k: Int) -> [String] {
        var seen: [String] = []
        for i in 0..<min(k, stream.count) {
            let txn = stream[i].txnID
            if !seen.contains(txn) { seen.append(txn) }
        }
        return seen
    }

    private var seenNow: [String] { seenSet(at: step) }

    private var currentEvent: PaymentEvent? {
        guard step > 0, step <= stream.count else { return nil }
        return stream[step - 1]
    }

    private var currentStatus: EventStatus {
        guard let event = currentEvent else { return .pending }
        let prior = seenSet(at: step - 1)
        return prior.contains(event.txnID) ? .duplicate : .new
    }

    private var processedCount: Int {
        guard step > 0 else { return 0 }
        var count = 0
        var seen: Set<String> = []
        for i in 0..<step {
            if !seen.contains(stream[i].txnID) {
                seen.insert(stream[i].txnID)
                count += 1
            }
        }
        return count
    }

    private var duplicateCount: Int { step - processedCount }

    enum EventStatus { case pending, new, duplicate }

    var body: some View {
        VStack(spacing: 14) {
            statsRow
            setPanel
            currentEventCard
            controls
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .task(id: isPlaying) {
            guard isPlaying else { return }
            while !Task.isCancelled && isPlaying {
                try? await Task.sleep(for: autoStepDuration)
                if !isPlaying { break }
                if step < lastStep {
                    advance()
                } else {
                    isPlaying = false
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatBadge(label: "Processed", value: "\(processedCount)", icon: "checkmark.seal.fill", tint: .green)
            StatBadge(label: "Duplicates", value: "\(duplicateCount)", icon: "exclamationmark.triangle.fill", tint: .orange)
        }
    }

    private var setPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "tray.full.fill")
                    .foregroundStyle(accent)
                Text("Seen set — \(seenNow.count) entries")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("O(1) lookup")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accent.opacity(0.15), in: Capsule())
                    .foregroundStyle(accent)
            }

            if seenNow.isEmpty {
                Text("Empty so far — tap → to start the stream.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(seenNow, id: \.self) { id in
                        SeenChip(
                            txnID: id,
                            isFlashing: id == flashTxnID,
                            isNewlyAdded: id == newlyAddedTxnID,
                            accent: accent
                        )
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.45, dampingFraction: 0.7), value: seenNow)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    private var currentEventCard: some View {
        let event = currentEvent
        let status = currentStatus

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(.secondary)
                Text(headerLabel(for: event, status: status))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(step == 0 ? "Step 0" : "Step \(step) of \(stream.count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }

            if let event {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.txnID)
                            .font(.system(.body, design: .monospaced).weight(.bold))
                        Text(event.amount)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusPill(status: status)
                }
                .padding(12)
                .background(statusBackground(status), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(statusBorder(status), lineWidth: 1.5)
                )
                .id(step)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
            } else {
                Text("Press → and the first payment lands. Then we'll ask the set: have we seen it?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: step)
    }

    private func headerLabel(for event: PaymentEvent?, status: EventStatus) -> String {
        guard event != nil else { return "Ready" }
        switch status {
        case .new: return "Now checking — new!"
        case .duplicate: return "Now checking — duplicate caught"
        case .pending: return "Now checking..."
        }
    }

    private func statusBackground(_ status: EventStatus) -> AnyShapeStyle {
        switch status {
        case .new: AnyShapeStyle(Color.green.opacity(0.14))
        case .duplicate: AnyShapeStyle(Color.orange.opacity(0.14))
        case .pending: AnyShapeStyle(Color.secondary.opacity(0.08))
        }
    }

    private func statusBorder(_ status: EventStatus) -> Color {
        switch status {
        case .new: .green.opacity(0.5)
        case .duplicate: .orange.opacity(0.6)
        case .pending: .clear
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button { reset() } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .disabled(step == 0 && !isPlaying)

            Spacer()

            Button { stepBack() } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(step == 0)

            Button { togglePlay() } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)

            Button { stepForward() } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
            .disabled(step >= lastStep)

            Spacer()

            Color.clear.frame(width: 44, height: 1)
        }
    }

    private func reset() {
        isPlaying = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            step = 0
            flashTxnID = nil
            newlyAddedTxnID = nil
        }
    }

    private func stepForward() { advance() }

    private func stepBack() {
        guard step > 0 else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            step -= 1
            flashTxnID = nil
            newlyAddedTxnID = nil
        }
    }

    private func togglePlay() {
        if step >= lastStep { step = 0 }
        isPlaying.toggle()
    }

    private func advance() {
        guard step < lastStep else { return }
        let nextEvent = stream[step]
        let prior = seenSet(at: step)
        let isDup = prior.contains(nextEvent.txnID)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            step += 1
        }

        if isDup {
            flashTxnID = nextEvent.txnID
            newlyAddedTxnID = nil
        } else {
            newlyAddedTxnID = nextEvent.txnID
            flashTxnID = nil
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(750))
            withAnimation(.easeOut(duration: 0.35)) {
                flashTxnID = nil
                newlyAddedTxnID = nil
            }
        }
    }
}

private struct SeenChip: View {
    let txnID: String
    let isFlashing: Bool
    let isNewlyAdded: Bool
    let accent: Color

    var body: some View {
        Text(txnID)
            .font(.caption.monospaced().weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(foreground)
            .background(background, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .scaleEffect(isFlashing ? 1.1 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isFlashing)
    }

    private var background: AnyShapeStyle {
        if isFlashing { return AnyShapeStyle(Color.orange.opacity(0.25)) }
        if isNewlyAdded { return AnyShapeStyle(accent.opacity(0.20)) }
        return AnyShapeStyle(Color.secondary.opacity(0.14))
    }

    private var borderColor: Color {
        if isFlashing { return .orange.opacity(0.75) }
        if isNewlyAdded { return accent.opacity(0.55) }
        return .clear
    }

    private var foreground: Color {
        if isFlashing { return .orange }
        if isNewlyAdded { return accent }
        return .primary
    }
}

private struct StatusPill: View {
    let status: DuplicateDetectionVisualizer.EventStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(label)
        }
        .font(.caption.weight(.bold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(.white)
        .background(color, in: Capsule())
    }

    private var icon: String {
        switch status {
        case .new: "plus.circle.fill"
        case .duplicate: "exclamationmark.triangle.fill"
        case .pending: "questionmark.circle.fill"
        }
    }

    private var label: String {
        switch status {
        case .new: "NEW"
        case .duplicate: "DUPLICATE"
        case .pending: "..."
        }
    }

    private var color: Color {
        switch status {
        case .new: .green
        case .duplicate: .orange
        case .pending: .secondary
        }
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

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                maxLineWidth = max(maxLineWidth, x - spacing)
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        maxLineWidth = max(maxLineWidth, x - spacing)
        return CGSize(width: maxLineWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
