import SwiftUI

struct MergeIntervalsVisualizer: View {
    let inputIntervals: [Interval]
    let accent: Color

    private let sortedIntervals: [Interval]

    init(intervals: [Interval], accent: Color) {
        self.inputIntervals = intervals
        self.sortedIntervals = intervals.sorted { $0.start < $1.start }
        self.accent = accent
    }

    @State private var currentStep: Int = -1
    @State private var isPlaying: Bool = false

    private let stepDuration: Duration = .milliseconds(1100)
    private let trackHeight: CGFloat = 30

    private struct MergedBlock: Identifiable, Hashable {
        let id: String
        var start: Double
        var end: Double
        var components: [String]
    }

    private var totalSteps: Int { sortedIntervals.count }
    private var lastIndex: Int { totalSteps - 1 }

    private var timeMin: Double {
        sortedIntervals.map(\.start).min() ?? 9
    }
    private var timeMax: Double {
        sortedIntervals.map(\.end).max() ?? 17
    }

    private func mergedBlocks(through step: Int) -> [MergedBlock] {
        guard step >= 0 else { return [] }
        var result: [MergedBlock] = []
        for i in 0...min(step, lastIndex) {
            let input = sortedIntervals[i]
            if var last = result.last, input.start <= last.end {
                last.end = max(last.end, input.end)
                last.components.append(input.id)
                result[result.count - 1] = last
            } else {
                result.append(MergedBlock(id: input.id, start: input.start, end: input.end, components: [input.id]))
            }
        }
        return result
    }

    private var currentBlocks: [MergedBlock] { mergedBlocks(through: currentStep) }

    private var processedIDs: Set<String> {
        guard currentStep >= 0 else { return [] }
        return Set(sortedIntervals.prefix(currentStep + 1).map { $0.id })
    }

    private var currentInputID: String? {
        guard currentStep >= 0, currentStep < sortedIntervals.count else { return nil }
        return sortedIntervals[currentStep].id
    }

    var body: some View {
        VStack(spacing: 14) {
            statsRow
            inputSection
            mergedSection
            actionCard
            controls
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .task(id: isPlaying) {
            guard isPlaying else { return }
            while !Task.isCancelled && isPlaying {
                try? await Task.sleep(for: stepDuration)
                if !isPlaying { break }
                if currentStep < lastIndex {
                    stepForward()
                } else {
                    isPlaying = false
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatChip(label: "Processed", value: "\(max(currentStep + 1, 0)) of \(totalSteps)", icon: "checkmark.circle.fill", tint: accent)
            StatChip(label: "Merged blocks", value: "\(currentBlocks.count)", icon: "rectangle.compress.vertical", tint: .green)
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("INPUT MEETINGS")
                .font(.caption2.weight(.bold)).tracking(0.6)
                .foregroundStyle(.secondary)
            timelineTrack(bars: inputBars())
            timeAxis
        }
    }

    private var mergedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MERGED BUSY BLOCKS")
                .font(.caption2.weight(.bold)).tracking(0.6)
                .foregroundStyle(.secondary)
            timelineTrack(bars: mergedBars())
        }
    }

    private func inputBars() -> [BarSpec] {
        sortedIntervals.map { interval in
            BarSpec(
                id: "input." + interval.id,
                start: interval.start,
                end: interval.end,
                label: interval.label,
                color: interval.id == currentInputID
                    ? accent
                    : (processedIDs.contains(interval.id) ? Color.secondary.opacity(0.55) : accent.opacity(0.55)),
                isCurrent: interval.id == currentInputID,
                isProcessed: processedIDs.contains(interval.id) && interval.id != currentInputID
            )
        }
    }

    private func mergedBars() -> [BarSpec] {
        currentBlocks.map { block in
            BarSpec(
                id: "merged." + block.id,
                start: block.start,
                end: block.end,
                label: timeRangeLabel(block.start, block.end),
                color: .green,
                isCurrent: false,
                isProcessed: false
            )
        }
    }

    private func timelineTrack(bars: [BarSpec]) -> some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let span = max(timeMax - timeMin, 0.001)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.10))
                    .frame(height: trackHeight)
                ForEach(bars) { bar in
                    let x = ((bar.start - timeMin) / span) * totalWidth
                    let w = max(((bar.end - bar.start) / span) * totalWidth, 14)
                    BarView(spec: bar, height: trackHeight - 6)
                        .frame(width: w)
                        .offset(x: x, y: 3)
                }
            }
        }
        .frame(height: trackHeight)
        .animation(.spring(response: 0.5, dampingFraction: 0.78), value: bars.map(\.id))
        .animation(.spring(response: 0.5, dampingFraction: 0.78), value: bars.map(\.end))
    }

    private var timeAxis: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let span = max(timeMax - timeMin, 0.001)
            let ticks = axisTicks()
            ZStack(alignment: .topLeading) {
                ForEach(ticks, id: \.self) { t in
                    let x = ((t - timeMin) / span) * totalWidth
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 1, height: 4)
                        Text(hourLabel(t))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .offset(x: x - 8, y: 0)
                }
            }
        }
        .frame(height: 18)
    }

    private func axisTicks() -> [Double] {
        let span = timeMax - timeMin
        let stride = span <= 6 ? 1.0 : 2.0
        var result: [Double] = []
        var t = ceil(timeMin)
        while t <= floor(timeMax) {
            result.append(t)
            t += stride
        }
        return result
    }

    private func hourLabel(_ t: Double) -> String {
        let hour = Int(t)
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return "\(displayHour)\(hour < 12 ? "a" : "p")"
    }

    private func timeRangeLabel(_ start: Double, _ end: Double) -> String {
        "\(hourMinute(start))–\(hourMinute(end))"
    }

    private func hourMinute(_ t: Double) -> String {
        let hour = Int(t)
        let minutes = Int(round((t - Double(hour)) * 60))
        return String(format: "%d:%02d", hour, minutes)
    }

    @ViewBuilder
    private var actionCard: some View {
        HStack(spacing: 8) {
            Image(systemName: actionIcon)
                .foregroundStyle(actionTint)
            Text(actionDescription)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    private var actionDescription: String {
        guard currentStep >= 0 else {
            return "Tap → and we'll walk through merging the meetings, left to right."
        }
        let input = sortedIntervals[currentStep]
        let priorBlocks = mergedBlocks(through: currentStep - 1)
        if let last = priorBlocks.last, input.start <= last.end {
            let newEnd = max(last.end, input.end)
            return "\(input.label) (\(timeRangeLabel(input.start, input.end))) overlaps — extend block to \(hourMinute(newEnd))."
        }
        return "\(input.label) (\(timeRangeLabel(input.start, input.end))) opens a new block — gap before it."
    }

    private var actionIcon: String {
        guard currentStep >= 0 else { return "play.circle" }
        let input = sortedIntervals[currentStep]
        let priorBlocks = mergedBlocks(through: currentStep - 1)
        if let last = priorBlocks.last, input.start <= last.end {
            return "arrow.left.and.right.righttriangle.left.righttriangle.right.fill"
        }
        return "rectangle.badge.plus"
    }

    private var actionTint: Color {
        guard currentStep >= 0 else { return .secondary }
        let input = sortedIntervals[currentStep]
        let priorBlocks = mergedBlocks(through: currentStep - 1)
        if let last = priorBlocks.last, input.start <= last.end {
            return accent
        }
        return .green
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
                .disabled(currentStep >= lastIndex)
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
        guard currentStep < lastIndex else { return }
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
        if currentStep >= lastIndex { currentStep = -1 }
        isPlaying.toggle()
    }
}

private struct BarView: View {
    let spec: BarSpec
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(spec.color)
            .frame(height: height)
            .overlay(
                Text(spec.label)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(spec.isCurrent ? Color.white : .clear, lineWidth: 2)
            )
            .scaleEffect(y: spec.isCurrent ? 1.15 : 1.0, anchor: .center)
            .opacity(spec.isProcessed ? 0.55 : 1.0)
            .shadow(color: spec.isCurrent ? spec.color.opacity(0.6) : .clear, radius: 6)
    }
}

private typealias BarSpec = MergeIntervalsVisualizer.BarSpec

extension MergeIntervalsVisualizer {
    struct BarSpec: Identifiable {
        let id: String
        let start: Double
        let end: Double
        let label: String
        let color: Color
        let isCurrent: Bool
        let isProcessed: Bool
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
