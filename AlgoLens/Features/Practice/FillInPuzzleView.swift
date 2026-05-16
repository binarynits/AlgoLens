import SwiftUI

struct FillInPuzzleView: View {
    let puzzle: FillInPuzzle
    let onAdvance: (Bool) -> Void

    @State private var placements: [String: String] = [:]
    @State private var pickedTokenID: String? = nil
    @State private var hasChecked: Bool = false
    @State private var revealedSolution: Bool = false

    private let palette: Palette = .dark
    private let codeTheme: CodeTheme = .dark

    private var blanks: [String] { puzzle.blankIDs }

    private var solutionCode: String {
        puzzle.codeLines.map { line in
            line.map { seg in
                switch seg {
                case let .text(s): return s
                case let .blank(_, correctText): return correctText
                }
            }.joined()
        }.joined(separator: "\n")
    }

    private var showSolution: Bool {
        hasChecked && (allCorrect || revealedSolution)
    }

    private var allFilled: Bool {
        blanks.allSatisfy { placements[$0] != nil }
    }

    private var usedTokenIDs: Set<String> {
        Set(placements.values)
    }

    private var allCorrect: Bool {
        blanks.allSatisfy(isCorrect)
    }

    private var pickedToken: CodeToken? {
        guard let id = pickedTokenID else { return nil }
        return puzzle.tokens.first { $0.id == id }
    }

    private func isCorrect(_ blankID: String) -> Bool {
        guard let tokenID = placements[blankID],
              let token = puzzle.tokens.first(where: { $0.id == tokenID }),
              let expected = puzzle.correctText(for: blankID) else { return false }
        return token.text == expected
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                editorPanel
                if hasChecked {
                    resultBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                tokenBank
                if hasChecked {
                    explanationCard
                        .transition(.opacity)
                    if showSolution {
                        CodeBlock(code: solutionCode)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if !allCorrect {
                        revealSolutionButton
                            .transition(.opacity)
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
            HStack(spacing: 6) {
                Image(systemName: puzzle.pattern.systemIcon)
                    .font(.caption.weight(.semibold))
                Text(puzzle.pattern.title.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
            }
            .foregroundStyle(puzzle.pattern.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(puzzle.pattern.accent.opacity(0.18), in: Capsule())

            Text(puzzle.title)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(palette.heading)

            Text(puzzle.prompt)
                .font(.subheadline)
                .foregroundStyle(palette.muted)
        }
    }

    private var editorPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            editorChrome
            Divider().overlay(Color.white.opacity(0.06))
            editorBody
        }
        .background(codeTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var editorChrome: some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.caption)
                .foregroundStyle(codeTheme.text.opacity(0.55))
            Text("Swift")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(codeTheme.text)
            Spacer(minLength: 0)
            Text("\(placedCount)/\(blanks.count) filled")
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(codeTheme.text.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var placedCount: Int {
        blanks.filter { placements[$0] != nil }.count
    }

    private var editorBody: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(puzzle.codeLines.enumerated()), id: \.offset) { lineIdx, line in
                    HStack(alignment: .center, spacing: 12) {
                        Text("\(lineIdx + 1)")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(codeTheme.text.opacity(0.30))
                            .frame(width: 18, alignment: .trailing)
                            .monospacedDigit()
                        HStack(alignment: .center, spacing: 0) {
                            ForEach(Array(line.enumerated()), id: \.offset) { _, seg in
                                segmentView(seg)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
    }

    @ViewBuilder
    private func segmentView(_ seg: CodeSegment) -> some View {
        switch seg {
        case let .text(text):
            Text(AttributedString.swiftHighlighted(text, theme: codeTheme))
                .font(.system(.callout, design: .monospaced).weight(.medium))
        case let .blank(id, _):
            BlankSlot(
                placedText: placedToken(for: id)?.text,
                state: blankState(for: id),
                accent: puzzle.pattern.accent,
                isDropTarget: pickedTokenID != nil && placements[id] == nil && !hasChecked,
                mutedColor: codeTheme.text.opacity(0.55)
            ) {
                handleBlankTap(id)
            }
        }
    }

    private func placedToken(for blankID: String) -> CodeToken? {
        guard let tokenID = placements[blankID] else { return nil }
        return puzzle.tokens.first { $0.id == tokenID }
    }

    private func blankState(for id: String) -> BlankSlot.SlotState {
        if !hasChecked { return placements[id] == nil ? .empty : .filled }
        return isCorrect(id) ? .correct : .wrong
    }

    private func handleBlankTap(_ id: String) {
        guard !hasChecked else { return }
        if let tokenID = pickedTokenID {
            // Place the picked token here (replaces anything that was already there).
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                placements[id] = tokenID
                pickedTokenID = nil
            }
        } else if placements[id] != nil {
            // No token picked, but this blank is filled — clear it so the token returns to the bank.
            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                placements[id] = nil
            }
        }
        // else: empty blank, nothing picked — nothing to do.
    }

    private var tokenBank: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "tray")
                    .font(.caption2)
                Text(bankHeadline)
                    .font(.caption.weight(.bold))
                    .tracking(0.4)
                    .contentTransition(.opacity)
            }
            .foregroundStyle(pickedTokenID != nil ? puzzle.pattern.accent : palette.muted)
            .animation(.easeOut(duration: 0.2), value: pickedTokenID)

            FillFlow(spacing: 8) {
                ForEach(puzzle.tokens) { token in
                    TokenPill(
                        token: token,
                        isUsed: usedTokenIDs.contains(token.id),
                        isPicked: pickedTokenID == token.id,
                        accent: puzzle.pattern.accent,
                        palette: palette,
                        codeTheme: codeTheme
                    ) {
                        handleTokenTap(token)
                    }
                    .disabled(usedTokenIDs.contains(token.id) || hasChecked)
                }
            }
        }
    }

    private var bankHeadline: String {
        if let picked = pickedToken {
            return "Now tap a blank to drop '\(picked.text)'"
        }
        return "Tokens — tap one to pick it up"
    }

    private func handleTokenTap(_ token: CodeToken) {
        guard !hasChecked else { return }
        guard !usedTokenIDs.contains(token.id) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            if pickedTokenID == token.id {
                pickedTokenID = nil
            } else {
                pickedTokenID = token.id
            }
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
                Text(correct ? "Nailed it." : "Not quite.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.heading)
                Text(correct
                     ? "Every blank matches."
                     : "Red blanks didn't match — the explanation below shows why.")
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
                    Button { tryAgain() } label: {
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
                    pickedTokenID = nil
                }
            } label: {
                Text("Check answer")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 30)
            }
            .buttonStyle(.borderedProminent)
            .tint(puzzle.pattern.accent)
            .disabled(!allFilled)
        }
    }

    private func tryAgain() {
        let wrong = blanks.filter { !isCorrect($0) }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            hasChecked = false
            revealedSolution = false
            for id in wrong { placements[id] = nil }
            pickedTokenID = nil
        }
    }
}

private struct BlankSlot: View {
    enum SlotState { case empty, filled, correct, wrong }

    let placedText: String?
    let state: SlotState
    let accent: Color
    let isDropTarget: Bool
    let mutedColor: Color
    let onTap: () -> Void

    @State private var pulse: Bool = false

    var body: some View {
        Button(action: onTap) {
            Text(displayText)
                .font(.system(.callout, design: .monospaced).weight(.semibold))
                .foregroundStyle(foreground)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .frame(minWidth: 56)
                .background(background, in: RoundedRectangle(cornerRadius: 7))
                .overlay(border)
                .scaleEffect(isDropTarget && state == .empty ? (pulse ? 1.05 : 1.0) : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.78), value: state)
        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: pulse)
        .onChange(of: isDropTarget) { _, newValue in
            if newValue && state == .empty {
                pulse = true
            } else {
                pulse = false
            }
        }
        .onAppear {
            if isDropTarget && state == .empty {
                pulse = true
            }
        }
    }

    private var displayText: String {
        placedText ?? "_____"
    }

    private var foreground: Color {
        switch state {
        case .empty: isDropTarget ? accent : mutedColor
        case .filled, .correct, .wrong: .white
        }
    }

    private var background: AnyShapeStyle {
        switch state {
        case .empty: isDropTarget
            ? AnyShapeStyle(accent.opacity(0.15))
            : AnyShapeStyle(Color.white.opacity(0.04))
        case .filled: AnyShapeStyle(accent)
        case .correct: AnyShapeStyle(Color.green)
        case .wrong: AnyShapeStyle(Color.red)
        }
    }

    @ViewBuilder
    private var border: some View {
        if state == .empty {
            RoundedRectangle(cornerRadius: 7)
                .strokeBorder(
                    isDropTarget ? accent : mutedColor.opacity(0.55),
                    style: StrokeStyle(lineWidth: isDropTarget ? 2 : 1.5, dash: [4, 3])
                )
        }
    }
}

private struct TokenPill: View {
    let token: CodeToken
    let isUsed: Bool
    let isPicked: Bool
    let accent: Color
    let palette: Palette
    let codeTheme: CodeTheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(AttributedString.swiftHighlighted(token.text, theme: codeTheme))
                .font(.system(.callout, design: .monospaced).weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(background, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(borderColor, lineWidth: isPicked ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
        .opacity(isUsed ? 0.32 : 1)
        .scaleEffect(scaleAmount)
        .shadow(color: isPicked ? accent.opacity(0.45) : .clear, radius: 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isPicked)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isUsed)
    }

    private var background: Color {
        isPicked ? accent.opacity(0.20) : palette.surface
    }

    private var borderColor: Color {
        isPicked ? accent : palette.border
    }

    private var scaleAmount: CGFloat {
        if isUsed { return 0.92 }
        if isPicked { return 1.06 }
        return 1.0
    }
}

struct Palette: Sendable {
    let background: Color
    let surface: Color
    let border: Color
    let heading: Color
    let muted: Color

    static let dark = Palette(
        background: Color(red: 0.07, green: 0.07, blue: 0.09),
        surface: Color(red: 0.13, green: 0.13, blue: 0.16),
        border: Color.white.opacity(0.08),
        heading: Color(red: 0.95, green: 0.94, blue: 0.92),
        muted: Color(red: 0.62, green: 0.62, blue: 0.65)
    )
}

private struct FillFlow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxLine: CGFloat = 0

        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                maxLine = max(maxLine, x - spacing)
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        maxLine = max(maxLine, x - spacing)
        return CGSize(width: maxLine, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
