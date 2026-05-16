import SwiftUI
import SwiftData

struct LessonView: View {
    let lesson: Lesson

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var progress: [UserProgress]

    @State private var step: LessonStep = .story

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 4)

            ScrollView {
                Group {
                    switch step {
                    case .story:
                        StorySection(lesson: lesson)
                    case .visualizer:
                        VisualizerSection(lesson: lesson)
                    case .practice:
                        PracticeSection(lesson: lesson) {
                            advance()
                        }
                    case .interview:
                        InterviewSection(lesson: lesson)
                    case .done:
                        CompletionSection(lesson: lesson)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }

            footerButton
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.bar)
        }
        .navigationTitle(lesson.pattern.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(LessonStep.allOrdered, id: \.self) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? lesson.pattern.accent : Color.secondary.opacity(0.25))
                    .frame(height: 4)
            }
        }
    }

    @ViewBuilder
    private var footerButton: some View {
        switch step {
        case .practice:
            EmptyView()
        case .done:
            Button {
                markComplete()
                dismiss()
            } label: {
                Text("Finish")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 32)
            }
            .buttonStyle(.borderedProminent)
            .tint(lesson.pattern.accent)
        default:
            Button {
                advance()
            } label: {
                Text(step.continueLabel)
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 32)
            }
            .buttonStyle(.borderedProminent)
            .tint(lesson.pattern.accent)
        }
    }

    private func advance() {
        if let next = step.next {
            withAnimation { step = next }
        }
    }

    private func markComplete() {
        if !progress.contains(where: { $0.lessonID == lesson.id }) {
            modelContext.insert(UserProgress(lessonID: lesson.id))
            try? modelContext.save()
        }
    }
}

enum LessonStep: Int, Hashable, CaseIterable {
    case story = 0
    case visualizer
    case practice
    case interview
    case done

    static let allOrdered: [LessonStep] = allCases

    var next: LessonStep? {
        LessonStep(rawValue: rawValue + 1)
    }

    var continueLabel: String {
        switch self {
        case .story: "Show me the visualizer"
        case .visualizer: "Try a problem"
        case .practice: "Continue"
        case .interview: "Wrap up"
        case .done: "Finish"
        }
    }
}

private struct StorySection: View {
    let lesson: Lesson

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(lesson.title)
                .font(.title2.weight(.bold))

            Text(lesson.scenario)
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)

            Text(lesson.story)
                .font(.body)
                .lineSpacing(4)

            VStack(alignment: .leading, spacing: 10) {
                Text("Where you'll see this in real systems")
                    .font(.subheadline.weight(.semibold))
                ForEach(lesson.realWorldUses, id: \.self) { use in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(lesson.pattern.accent)
                            .padding(.top, 6)
                        Text(use)
                            .font(.subheadline)
                    }
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct VisualizerSection: View {
    let lesson: Lesson

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(headline)
                .font(.title3.weight(.semibold))
            Text(subheadline)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            switch lesson.visualizer {
            case let .slidingWindow(values, windowSize, unit):
                SlidingWindowVisualizer(
                    values: values,
                    windowSize: windowSize,
                    unit: unit,
                    accent: lesson.pattern.accent
                )
            case let .arrayReorder(items, moves):
                ArrayReorderVisualizer(
                    items: items,
                    moves: moves,
                    accent: lesson.pattern.accent
                )
            case let .directAccess(items, queries):
                DirectAccessVisualizer(
                    items: items,
                    queries: queries,
                    accent: lesson.pattern.accent
                )
            case let .duplicateDetection(stream):
                DuplicateDetectionVisualizer(
                    stream: stream,
                    accent: lesson.pattern.accent
                )
            case let .twoPointersPairSum(prices, target, unit):
                TwoPointersVisualizer(
                    prices: prices,
                    target: target,
                    unit: unit,
                    accent: lesson.pattern.accent
                )
            case let .stackOperations(actions):
                StackVisualizer(
                    actions: actions,
                    accent: lesson.pattern.accent
                )
            case let .folderTreeDFS(root):
                FolderTreeVisualizer(
                    root: root,
                    accent: lesson.pattern.accent
                )
            case let .graphBFS(nodes, edges, startID, targetID):
                GraphBFSVisualizer(
                    nodes: nodes,
                    edges: edges,
                    startID: startID,
                    targetID: targetID,
                    accent: lesson.pattern.accent
                )
            case let .mergeIntervals(intervals):
                MergeIntervalsVisualizer(
                    intervals: intervals,
                    accent: lesson.pattern.accent
                )
            }
        }
    }

    private var headline: String {
        switch lesson.visualizer {
        case .slidingWindow: "Watch the window slide"
        case .arrayReorder: "Watch the shifts add up"
        case .directAccess: "Jump straight to any track"
        case .duplicateDetection: "Catch the duplicate before it charges twice"
        case .twoPointersPairSum: "Two pointers walking toward each other"
        case .stackOperations: "Push some actions, then Undo to pop them"
        case .folderTreeDFS: "Walk the folder tree, counting as you go"
        case .graphBFS: "Spread out level by level — BFS finds the shortest path"
        case .mergeIntervals: "Sort once, then sweep left to right"
        }
    }

    private var subheadline: String {
        switch lesson.visualizer {
        case .slidingWindow:
            "Each step adds the new value on the right and drops the one on the left. Watch the running sum update in O(1)."
        case .arrayReorder:
            "Each play moves one song to the top. Count how many other songs have to slide down to make room."
        case .directAccess:
            "Step through each lookup. No matter which track you pick — first, middle, or last — it's one step."
        case .duplicateDetection:
            "Step the stream forward. Each ID either lands a new chip in the set, or flashes one that's already there."
        case .twoPointersPairSum:
            "Step through. The sum tells you which pointer to move. The list shrinks toward the answer."
        case .stackOperations:
            "Push actions in any order. Hit Undo and watch only the top come off — that's the LIFO contract."
        case .folderTreeDFS:
            "Pre-order DFS: visit the folder, then dive into each child. Every file counts; every folder routes deeper."
        case .graphBFS:
            "BFS from the start node fans out one ring at a time. The first time it reaches the target is the shortest path."
        case .mergeIntervals:
            "Top track is your raw calendar. Each step pulls in the next meeting — overlap extends the current block; a gap starts a new one."
        }
    }
}

private struct InterviewSection: View {
    let lesson: Lesson

    var body: some View {
        let interview = lesson.interview

        VStack(alignment: .leading, spacing: 20) {
            Text("How to explain it in an interview")
                .font(.title3.weight(.semibold))

            Text(interview.whyItWorks)
                .font(.body)
                .lineSpacing(4)

            HStack(spacing: 12) {
                ComplexityChip(label: "Time", value: interview.timeComplexity)
                ComplexityChip(label: "Space", value: interview.spaceComplexity)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Vs. brute force")
                    .font(.subheadline.weight(.semibold))
                Text(interview.versusBruteForce)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            CodeBlock(code: interview.swiftSnippet)
        }
    }
}

private struct ComplexityChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.weight(.medium))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct CompletionSection: View {
    let lesson: Lesson

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(lesson.pattern.accent)
                .padding(.top, 24)

            Text("You learned a pattern.")
                .font(.title2.weight(.bold))

            Text("\(lesson.pattern.title) — you can now spot it the next time you see a problem with overlapping windows of work.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
    }
}
