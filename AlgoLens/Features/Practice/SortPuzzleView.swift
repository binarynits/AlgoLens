import SwiftUI

struct SortPuzzleView: View {
    let puzzle: SortPuzzle
    let onAdvance: (Bool) -> Void

    private let palette: Palette = .dark
    private let codeTheme: CodeTheme = .dark

    @State private var currentOrder: [SortLine]
    @State private var pickedID: String? = nil
    @State private var hasChecked: Bool = false
    @State private var revealedSolution: Bool = false

    init(puzzle: SortPuzzle, onAdvance: @escaping (Bool) -> Void) {
        self.puzzle = puzzle
        self.onAdvance = onAdvance
        var lines = puzzle.lines
        var rng = SeededRandomNumberGenerator(seed: puzzle.id)
        lines.shuffle(using: &rng)
        // Guarantee non-identity shuffle for small N.
        if zip(lines, puzzle.lines).allSatisfy({ $0.id == $1.id }), lines.count >= 2 {
            lines.swapAt(0, lines.count - 1)
        }
        self._currentOrder = State(initialValue: lines)
    }

    private var allCorrect: Bool {
        zip(currentOrder, puzzle.lines).allSatisfy { $0.id == $1.id }
    }

    private var solutionCode: String {
        puzzle.lines.map(\.code).joined(separator: "\n")
    }

    private var showSolution: Bool {
        hasChecked && (allCorrect || revealedSolution)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                editorPanel
                if hasChecked {
                    resultBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                    explanationCard
                        .transition(.opacity)
                    if showSolution {
                        CodeBlock(code: solutionCode)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if !allCorrect {
                        revealSolutionButton
                    }
                }
                actionRow
            }
            .padding(20)
            .padding(.bottom, 12)
        }
        .background(palette.background.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                kindPill
                patternPill
            }
            Text(puzzle.title)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(palette.heading)
            Text(puzzle.prompt)
                .font(.subheadline)
                .foregroundStyle(palette.muted)
        }
    }

    private var kindPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.up.arrow.down.square.fill")
                .font(.caption2.weight(.bold))
            Text("SORT THE CODE")
                .font(.caption2.weight(.bold))
                .tracking(0.8)
        }
        .foregroundStyle(.cyan)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.cyan.opacity(0.18), in: Capsule())
    }

    private var patternPill: some View {
        HStack(spacing: 4) {
            Image(systemName: puzzle.pattern.systemIcon)
                .font(.caption2.weight(.bold))
            Text(puzzle.pattern.title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.6)
        }
        .foregroundStyle(puzzle.pattern.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(puzzle.pattern.accent.opacity(0.18), in: Capsule())
    }

    private var editorPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            chrome
            Divider().overlay(Color.white.opacity(0.06))
            body_
        }
        .background(codeTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var chrome: some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.caption)
                .foregroundStyle(codeTheme.text.opacity(0.55))
            Text("Swift")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(codeTheme.text)
            Spacer(minLength: 0)
            if let pickedID, let line = currentOrder.first(where: { $0.id == pickedID }) {
                Text("Picked: line \((currentOrder.firstIndex(of: line) ?? 0) + 1)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.cyan)
            } else if !hasChecked {
                Text("Tap a line to pick it up")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(codeTheme.text.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var body_: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(currentOrder.enumerated()), id: \.element.id) { idx, line in
                LineCard(
                    line: line,
                    position: idx + 1,
                    state: state(for: line),
                    accent: puzzle.pattern.accent,
                    codeTheme: codeTheme
                ) {
                    handleTap(line)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: currentOrder)
    }

    private func state(for line: SortLine) -> LineCard.State {
        if hasChecked {
            let correctIdx = puzzle.lines.firstIndex(where: { $0.id == line.id }) ?? -1
            let currentIdx = currentOrder.firstIndex(of: line) ?? -2
            return correctIdx == currentIdx ? .correct : .wrong
        }
        return pickedID == line.id ? .picked : .idle
    }

    private func handleTap(_ line: SortLine) {
        guard !hasChecked else { return }
        if let pickedID, pickedID != line.id {
            // swap
            guard let from = currentOrder.firstIndex(where: { $0.id == pickedID }),
                  let to = currentOrder.firstIndex(of: line) else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                currentOrder.swapAt(from, to)
                self.pickedID = nil
            }
        } else if pickedID == line.id {
            withAnimation(.easeOut(duration: 0.18)) { pickedID = nil }
        } else {
            withAnimation(.easeOut(duration: 0.18)) { pickedID = line.id }
        }
    }

    @ViewBuilder
    private var resultBanner: some View {
        let correct = allCorrect
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((correct ? Color.green : Color.orange).opacity(0.22))
                    .frame(width: 36, height: 36)
                Image(systemName: correct ? "checkmark" : "exclamationmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(correct ? .green : .orange)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(correct ? "Perfect order!" : "Some lines are out of place.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.heading)
                Text(correct
                     ? "Every line is in the right spot."
                     : "Red lines aren't where they should be.")
                    .font(.caption)
                    .foregroundStyle(palette.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder((correct ? Color.green : Color.orange).opacity(0.45), lineWidth: 1)
        )
    }

    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                Text("Why")
                    .font(.caption.weight(.bold))
                    .tracking(0.4)
            }
            .foregroundStyle(palette.muted)
            Text(puzzle.explanation)
                .font(.subheadline)
                .foregroundStyle(palette.heading)
                .lineSpacing(3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(palette.border, lineWidth: 1)
        )
    }

    private var revealSolutionButton: some View {
        Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                revealedSolution = true
            }
        } label: {
            Label("Reveal solution", systemImage: "eye.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .tint(puzzle.pattern.accent)
    }

    @ViewBuilder
    private var actionRow: some View {
        if hasChecked {
            if allCorrect || revealedSolution {
                Button { onAdvance(allCorrect) } label: {
                    Text("Next puzzle")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 30)
                }
                .buttonStyle(.borderedProminent)
                .tint(puzzle.pattern.accent)
            } else {
                HStack(spacing: 10) {
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                            hasChecked = false
                        }
                    } label: {
                        Text("Try again")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 30)
                    }
                    .buttonStyle(.bordered)
                    .tint(puzzle.pattern.accent)
                    Button { onAdvance(false) } label: {
                        Text("Skip ahead")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 30)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(puzzle.pattern.accent)
                }
            }
        } else {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                    hasChecked = true
                    pickedID = nil
                }
            } label: {
                Text("Check order")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 30)
            }
            .buttonStyle(.borderedProminent)
            .tint(puzzle.pattern.accent)
        }
    }
}

private struct LineCard: View {
    enum State { case idle, picked, correct, wrong }

    let line: SortLine
    let position: Int
    let state: State
    let accent: Color
    let codeTheme: CodeTheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(position)")
                    .font(.system(.footnote, design: .monospaced).weight(.bold))
                    .foregroundStyle(numberColor)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(numberBg))

                Text(AttributedString.swiftHighlighted(line.code, theme: codeTheme))
                    .font(.system(.callout, design: .monospaced).weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                if state == .picked {
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                } else if state == .correct {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else if state == .wrong {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(borderColor, lineWidth: 1.5)
            )
            .scaleEffect(state == .picked ? 1.03 : 1)
            .shadow(color: state == .picked ? .cyan.opacity(0.4) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: state)
    }

    private var numberColor: Color {
        switch state {
        case .picked: .cyan
        case .correct: .green
        case .wrong: .orange
        case .idle: codeTheme.text.opacity(0.6)
        }
    }

    private var numberBg: Color {
        switch state {
        case .picked: .cyan.opacity(0.20)
        case .correct: .green.opacity(0.20)
        case .wrong: .orange.opacity(0.20)
        case .idle: .white.opacity(0.05)
        }
    }

    private var background: Color {
        switch state {
        case .picked: .cyan.opacity(0.10)
        case .correct: .green.opacity(0.10)
        case .wrong: .orange.opacity(0.10)
        case .idle: .white.opacity(0.03)
        }
    }

    private var borderColor: Color {
        switch state {
        case .picked: .cyan.opacity(0.55)
        case .correct: .green.opacity(0.45)
        case .wrong: .orange.opacity(0.45)
        case .idle: .clear
        }
    }
}

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: String) {
        var hash: UInt64 = 5381
        for c in seed.unicodeScalars {
            hash = (hash &* 33) &+ UInt64(c.value)
        }
        self.state = hash == 0 ? 1 : hash
    }

    mutating func next() -> UInt64 {
        state &*= 6364136223846793005
        state &+= 1442695040888963407
        return state
    }
}
