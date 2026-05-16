import SwiftUI

struct PracticeSection: View {
    let lesson: Lesson
    let onAllAnswered: () -> Void

    @State private var index: Int = 0
    @State private var selectedChoiceID: String? = nil
    @State private var revealed: Bool = false

    var body: some View {
        let problem = lesson.problems[index]
        let total = lesson.problems.count

        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(problem.kind.headline)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(lesson.pattern.accent)
                Spacer()
                Text("Question \(index + 1) of \(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(problem.prompt)
                .font(.body.weight(.medium))
                .lineSpacing(4)

            VStack(spacing: 10) {
                ForEach(problem.choices) { choice in
                    ChoiceButton(
                        choice: choice,
                        state: state(for: choice),
                        accent: lesson.pattern.accent
                    ) {
                        selectedChoiceID = choice.id
                        revealed = true
                    }
                    .disabled(revealed && !isCurrentSelection(choice))
                }
            }

            if revealed {
                explanationCard(for: problem)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                Button {
                    goNext(total: total)
                } label: {
                    Text(index + 1 == total ? "Continue" : "Next question")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.borderedProminent)
                .tint(lesson.pattern.accent)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: revealed)
        .animation(.easeInOut(duration: 0.2), value: index)
    }

    private func state(for choice: Choice) -> ChoiceButton.State {
        guard revealed else { return .idle }
        if choice.isCorrect { return .correct }
        if choice.id == selectedChoiceID { return .wrong }
        return .dimmed
    }

    private func isCurrentSelection(_ choice: Choice) -> Bool {
        choice.id == selectedChoiceID
    }

    private func goNext(total: Int) {
        if index + 1 < total {
            index += 1
            selectedChoiceID = nil
            revealed = false
        } else {
            onAllAnswered()
        }
    }

    private func explanationCard(for problem: Problem) -> some View {
        let chosen = problem.choices.first { $0.id == selectedChoiceID }
        let isCorrect = chosen?.isCorrect ?? false

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "info.circle.fill")
                Text(isCorrect ? "Nice — that's the one." : "Close. Here's the why.")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isCorrect ? .green : .orange)

            Text(problem.explanation)
                .font(.subheadline)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct ChoiceButton: View {
    let choice: Choice
    let state: State
    let accent: Color
    let action: () -> Void

    enum State {
        case idle, correct, wrong, dimmed
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundStyle(iconColor)

                Text(choice.text)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(background, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .opacity(state == .dimmed ? 0.5 : 1)
    }

    private var iconName: String {
        switch state {
        case .idle, .dimmed: "circle"
        case .correct: "checkmark.circle.fill"
        case .wrong: "xmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch state {
        case .idle, .dimmed: .secondary
        case .correct: .green
        case .wrong: .red
        }
    }

    private var background: AnyShapeStyle {
        switch state {
        case .correct: AnyShapeStyle(Color.green.opacity(0.12))
        case .wrong: AnyShapeStyle(Color.red.opacity(0.12))
        default: AnyShapeStyle(.regularMaterial)
        }
    }

    private var borderColor: Color {
        switch state {
        case .correct: .green.opacity(0.5)
        case .wrong: .red.opacity(0.5)
        default: .clear
        }
    }
}

private extension ProblemKind {
    var headline: String {
        switch self {
        case .predictNextStep: "PREDICT THE NEXT STEP"
        case .multipleChoiceLogic: "PICK THE RIGHT REASONING"
        }
    }
}
