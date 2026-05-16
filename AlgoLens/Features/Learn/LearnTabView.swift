import SwiftUI

struct LearnTabView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    LazyVStack(spacing: 12) {
                        ForEach(AlgorithmPattern.allCases) { pattern in
                            NavigationLink(value: pattern) {
                                PatternCard(pattern: pattern)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationTitle("Learn")
            .navigationDestination(for: AlgorithmPattern.self) { pattern in
                PatternDetailView(pattern: pattern)
            }
            .navigationDestination(for: Lesson.self) { lesson in
                LessonView(lesson: lesson)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Patterns, not problems.")
                .font(.title2.weight(.semibold))
            Text("Each path teaches one way of thinking — through stories from real software systems.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }
}

private struct PatternCard: View {
    let pattern: AlgorithmPattern

    var body: some View {
        let lessonCount = LessonLibrary.lessons(for: pattern).count

        HStack(spacing: 16) {
            Image(systemName: pattern.systemIcon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(pattern.accent.gradient, in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.title)
                    .font(.headline)
                Text(pattern.tagline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(lessonCount)")
                    .font(.headline.monospacedDigit())
                Text(lessonCount == 1 ? "lesson" : "lessons")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .opacity(lessonCount == 0 ? 0.55 : 1)
    }
}

#Preview {
    LearnTabView()
}
