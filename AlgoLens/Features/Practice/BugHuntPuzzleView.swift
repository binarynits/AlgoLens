import SwiftUI

struct BugHuntPuzzleView: View {
    let puzzle: BugHuntPuzzle
    let onAdvance: (Bool) -> Void

    private let palette: Palette = .dark
    private let codeTheme: CodeTheme = .dark

    @State private var hasFound: Bool = false
    @State private var wrongAttempts: Int = 0
    @State private var shakeTriggers: [String: Int] = [:]
    @State private var lastWrongID: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                editorPanel
                if hasFound {
                    fixCard
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    explanationCard
                        .transition(.opacity)
                } else {
                    hintCard
                }
                if hasFound {
                    actionRow
                }
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
            Image(systemName: "ladybug.fill")
                .font(.caption2.weight(.bold))
            Text("FIND THE BUG")
                .font(.caption2.weight(.bold))
                .tracking(0.8)
        }
        .foregroundStyle(.red)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.red.opacity(0.18), in: Capsule())
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
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(puzzle.lines.enumerated()), id: \.element.id) { idx, line in
                        lineRow(idx: idx, line: line)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
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
            if wrongAttempts > 0 && !hasFound {
                Text("Wrong taps: \(wrongAttempts)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func lineRow(idx: Int, line: BugHuntLine) -> some View {
        let isBuggy = hasFound && line.id == puzzle.buggyLineID
        return Button {
            handleTap(line)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(idx + 1)")
                    .foregroundStyle(codeTheme.text.opacity(isBuggy ? 0.65 : 0.30))
                    .frame(width: 18, alignment: .trailing)
                    .monospacedDigit()
                Text(AttributedString.swiftHighlighted(line.code, theme: codeTheme))
                    .fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: 8)
                if isBuggy {
                    Image(systemName: "ladybug.fill")
                        .font(.callout)
                        .foregroundStyle(.green)
                }
            }
            .font(.system(.footnote, design: .monospaced))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground(line: line))
            .overlay(rowBorder(line: line))
        }
        .buttonStyle(.plain)
        .disabled(hasFound)
        .keyframeAnimator(initialValue: 0.0, trigger: shakeTriggers[line.id] ?? 0) { content, value in
            content.offset(x: value)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(-8, duration: 0.06)
                LinearKeyframe(8, duration: 0.06)
                LinearKeyframe(-6, duration: 0.06)
                LinearKeyframe(6, duration: 0.06)
                LinearKeyframe(-3, duration: 0.06)
                LinearKeyframe(0, duration: 0.06)
            }
        }
    }

    private func rowBackground(line: BugHuntLine) -> some View {
        let isBuggy = hasFound && line.id == puzzle.buggyLineID
        return RoundedRectangle(cornerRadius: 8)
            .fill(isBuggy ? Color.green.opacity(0.18) : Color.clear)
    }

    @ViewBuilder
    private func rowBorder(line: BugHuntLine) -> some View {
        let isBuggy = hasFound && line.id == puzzle.buggyLineID
        if isBuggy {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.green.opacity(0.55), lineWidth: 1.5)
        }
    }

    private func handleTap(_ line: BugHuntLine) {
        guard !hasFound else { return }
        if line.id == puzzle.buggyLineID {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                hasFound = true
            }
        } else {
            wrongAttempts += 1
            lastWrongID = line.id
            shakeTriggers[line.id, default: 0] += 1
        }
    }

    private var hintCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.callout)
                .foregroundStyle(.cyan)
            Text("Read each line. Tap the one that doesn't do what the title promises.")
                .font(.caption)
                .foregroundStyle(palette.muted)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(palette.border, lineWidth: 1)
        )
    }

    private var fixCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("Caught the bug!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.heading)
                Spacer(minLength: 0)
                if wrongAttempts > 0 {
                    Text("after \(wrongAttempts) wrong \(wrongAttempts == 1 ? "tap" : "taps")")
                        .font(.caption2)
                        .foregroundStyle(palette.muted)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("THE FIX")
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(palette.muted)
                Text(AttributedString.swiftHighlighted(puzzle.fixedLine, theme: codeTheme))
                    .font(.system(.footnote, design: .monospaced))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(codeTheme.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.green.opacity(0.45), lineWidth: 1)
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

    private var actionRow: some View {
        Button { onAdvance(wrongAttempts == 0) } label: {
            Text("Next puzzle")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 30)
        }
        .buttonStyle(.borderedProminent)
        .tint(puzzle.pattern.accent)
    }
}
