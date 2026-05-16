import SwiftUI

struct SlidingWindowVisualizer: View {
    let values: [Int]
    let windowSize: Int
    let unit: String
    let accent: Color

    @State private var windowStart: Int = 0
    @State private var isPlaying: Bool = false

    private let spacing: CGFloat = 6
    private let boxHeight: CGFloat = 56
    private let stepDuration: Duration = .milliseconds(900)

    private var k: Int { windowSize }
    private var n: Int { values.count }
    private var lastStart: Int { max(0, n - k) }
    private var totalSteps: Int { lastStart + 1 }

    private var currentSum: Int {
        guard windowStart + k <= n else { return 0 }
        return values[windowStart..<(windowStart + k)].reduce(0, +)
    }

    private var maxSumSoFar: Int {
        (0...windowStart).map { start in
            values[start..<(start + k)].reduce(0, +)
        }.max() ?? 0
    }

    var body: some View {
        VStack(spacing: 20) {
            arrayRow
            readouts
            deltaExplanation
            controls
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .task(id: isPlaying) {
            guard isPlaying else { return }
            while !Task.isCancelled && isPlaying {
                try? await Task.sleep(for: stepDuration)
                if !isPlaying { break }
                if windowStart < lastStart {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        windowStart += 1
                    }
                } else {
                    isPlaying = false
                }
            }
        }
    }

    private var arrayRow: some View {
        GeometryReader { geo in
            let totalSpacing = CGFloat(n - 1) * spacing
            let boxWidth = (geo.size.width - totalSpacing) / CGFloat(n)
            let windowWidth = CGFloat(k) * boxWidth + CGFloat(k - 1) * spacing
            let xOffset = CGFloat(windowStart) * (boxWidth + spacing)

            ZStack(alignment: .leading) {
                HStack(spacing: spacing) {
                    ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                        ValueBox(
                            text: "\(unit)\(value)",
                            isInWindow: isInWindow(index),
                            accent: accent
                        )
                        .frame(width: boxWidth, height: boxHeight)
                    }
                }

                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(accent, lineWidth: 3)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accent.opacity(0.10))
                    )
                    .frame(width: windowWidth, height: boxHeight + 8)
                    .offset(x: xOffset, y: -4)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: boxHeight + 8)
    }

    private var readouts: some View {
        HStack(spacing: 12) {
            ReadoutChip(label: "Window sum", value: "\(unit)\(currentSum)", tint: accent)
            ReadoutChip(label: "Max so far", value: "\(unit)\(maxSumSoFar)", tint: .green)
        }
    }

    private var deltaExplanation: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Step \(windowStart + 1) of \(totalSteps)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(stepFormula)
                .font(.system(.subheadline, design: .monospaced))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stepFormula: String {
        if windowStart == 0 {
            let parts = values.prefix(k).map { "\(unit)\($0)" }.joined(separator: " + ")
            return "sum = \(parts) = \(unit)\(currentSum)"
        } else {
            let entering = values[windowStart + k - 1]
            let leaving = values[windowStart - 1]
            let prevSum = currentSum - entering + leaving
            return "sum = \(unit)\(prevSum) + \(unit)\(entering) − \(unit)\(leaving) = \(unit)\(currentSum)"
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button { reset() } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .disabled(windowStart == 0 && !isPlaying)

            Spacer()

            Button { stepBack() } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(windowStart == 0)

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
            .disabled(windowStart >= lastStart)

            Spacer()

            Color.clear.frame(width: 44, height: 1)
        }
    }

    private func isInWindow(_ index: Int) -> Bool {
        index >= windowStart && index < windowStart + k
    }

    private func reset() {
        isPlaying = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            windowStart = 0
        }
    }

    private func stepForward() {
        guard windowStart < lastStart else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            windowStart += 1
        }
    }

    private func stepBack() {
        guard windowStart > 0 else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            windowStart -= 1
        }
    }

    private func togglePlay() {
        if windowStart >= lastStart {
            windowStart = 0
        }
        isPlaying.toggle()
    }
}

private struct ValueBox: View {
    let text: String
    let isInWindow: Bool
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(isInWindow ? accent.opacity(0.18) : Color.secondary.opacity(0.10))

            Text(text)
                .font(.system(.callout, design: .rounded).weight(.semibold))
                .foregroundStyle(isInWindow ? accent : .secondary)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.horizontal, 4)
        }
    }
}

private struct ReadoutChip: View {
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)
                .monospacedDigit()
                .contentTransition(.numericText(value: 0))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
