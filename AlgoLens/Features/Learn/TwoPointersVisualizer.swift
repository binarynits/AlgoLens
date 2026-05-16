import SwiftUI

struct TwoPointersVisualizer: View {
    let prices: [Int]
    let target: Int
    let unit: String
    let accent: Color

    @State private var step: Int = 0
    @State private var isPlaying: Bool = false

    private let autoStepDuration: Duration = .milliseconds(1100)

    private struct Snapshot {
        let left: Int
        let right: Int
        let actionLabel: String
        let isFound: Bool
        let isExhausted: Bool
    }

    private var trajectory: [Snapshot] {
        var result: [Snapshot] = []
        var l = 0
        var r = max(prices.count - 1, 0)
        result.append(Snapshot(left: l, right: r, actionLabel: "Place L at the cheapest, R at the priciest.", isFound: false, isExhausted: false))
        while l < r {
            let sum = prices[l] + prices[r]
            if sum == target {
                result.append(Snapshot(left: l, right: r, actionLabel: "sum equals target — pair found.", isFound: true, isExhausted: false))
                return result
            }
            if sum < target {
                let prevSum = sum
                l += 1
                result.append(Snapshot(left: l, right: r, actionLabel: "sum \(unit)\(prevSum) < \(unit)\(target) — step L right.", isFound: false, isExhausted: false))
            } else {
                let prevSum = sum
                r -= 1
                result.append(Snapshot(left: l, right: r, actionLabel: "sum \(unit)\(prevSum) > \(unit)\(target) — step R left.", isFound: false, isExhausted: false))
            }
        }
        result.append(Snapshot(left: l, right: r, actionLabel: "Pointers met — no pair sums to \(unit)\(target).", isFound: false, isExhausted: true))
        return result
    }

    private var lastStep: Int { max(trajectory.count - 1, 0) }
    private var current: Snapshot { trajectory[min(step, lastStep)] }
    private var currentSum: Int {
        let s = current
        guard s.left < s.right || s.isFound else { return 0 }
        return prices[s.left] + prices[s.right]
    }

    var body: some View {
        VStack(spacing: 14) {
            topRow
            priceRow
            sumPanel
            controls
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .task(id: isPlaying) {
            guard isPlaying else { return }
            while !Task.isCancelled && isPlaying {
                try? await Task.sleep(for: autoStepDuration)
                if !isPlaying { break }
                if step < lastStep && !current.isFound {
                    stepForward()
                } else {
                    isPlaying = false
                }
            }
        }
    }

    private var topRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TARGET")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text("\(unit)\(target)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(accent)
                    .monospacedDigit()
            }
            Spacer()
            Text("Step \(step) of \(lastStep)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var priceRow: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 4
            let totalSpacing = CGFloat(prices.count - 1) * spacing
            let boxWidth = (geo.size.width - totalSpacing) / CGFloat(prices.count)
            let boxHeight: CGFloat = 48

            VStack(spacing: 6) {
                HStack(spacing: spacing) {
                    ForEach(Array(prices.enumerated()), id: \.offset) { index, value in
                        PriceCell(
                            label: "\(unit)\(value)",
                            isLeft: index == current.left && !isOut(index),
                            isRight: index == current.right && !isOut(index),
                            isFound: current.isFound && (index == current.left || index == current.right),
                            isOut: isOut(index),
                            accent: accent
                        )
                        .frame(width: boxWidth, height: boxHeight)
                    }
                }

                HStack(spacing: spacing) {
                    ForEach(prices.indices, id: \.self) { index in
                        Group {
                            if index == current.left && !isOut(index) {
                                PointerBadge(letter: "L", tint: accent)
                            } else if index == current.right && !isOut(index) {
                                PointerBadge(letter: "R", tint: accent)
                            } else {
                                Color.clear
                            }
                        }
                        .frame(width: boxWidth, height: 22)
                        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: current.left)
                        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: current.right)
                    }
                }
            }
        }
        .frame(height: 76)
    }

    private func isOut(_ index: Int) -> Bool {
        current.isExhausted && index != current.left && index != current.right
    }

    private var sumPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if current.isFound {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                } else if current.isExhausted {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                } else {
                    sumComparisonIcon
                }
                Text(sumLine)
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                Spacer(minLength: 0)
            }

            Text(current.actionLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private var sumLine: String {
        guard !current.isExhausted else { return "—" }
        let s = current
        let sum = prices[s.left] + prices[s.right]
        let cmp: String
        if sum == target { cmp = "=" }
        else if sum < target { cmp = "<" }
        else { cmp = ">" }
        return "\(unit)\(prices[s.left]) + \(unit)\(prices[s.right]) = \(unit)\(sum)  \(cmp)  \(unit)\(target)"
    }

    @ViewBuilder
    private var sumComparisonIcon: some View {
        let sum = currentSum
        if sum < target {
            Image(systemName: "arrow.up").foregroundStyle(.orange)
        } else if sum > target {
            Image(systemName: "arrow.down").foregroundStyle(.orange)
        } else {
            Image(systemName: "checkmark").foregroundStyle(.green)
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
            .disabled(current.isFound || current.isExhausted ? false : false)

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
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { step = 0 }
    }

    private func stepForward() {
        guard step < lastStep else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) { step += 1 }
    }

    private func stepBack() {
        guard step > 0 else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) { step -= 1 }
    }

    private func togglePlay() {
        if step >= lastStep { step = 0 }
        isPlaying.toggle()
    }
}

private struct PriceCell: View {
    let label: String
    let isLeft: Bool
    let isRight: Bool
    let isFound: Bool
    let isOut: Bool
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(fillStyle)
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(borderColor, lineWidth: 1.5)
            Text(label)
                .font(.system(.callout, design: .rounded).weight(.semibold))
                .foregroundStyle(textColor)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.horizontal, 2)
        }
        .opacity(isOut ? 0.35 : 1)
    }

    private var fillStyle: AnyShapeStyle {
        if isFound { return AnyShapeStyle(Color.green.opacity(0.20)) }
        if isLeft || isRight { return AnyShapeStyle(accent.opacity(0.18)) }
        return AnyShapeStyle(Color.secondary.opacity(0.10))
    }

    private var borderColor: Color {
        if isFound { return .green.opacity(0.6) }
        if isLeft || isRight { return accent.opacity(0.55) }
        return .clear
    }

    private var textColor: Color {
        if isFound { return .green }
        if isLeft || isRight { return accent }
        return .secondary
    }
}

private struct PointerBadge: View {
    let letter: String
    let tint: Color

    var body: some View {
        VStack(spacing: 1) {
            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: 9))
                .foregroundStyle(tint)
            Text(letter)
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
        }
    }
}
