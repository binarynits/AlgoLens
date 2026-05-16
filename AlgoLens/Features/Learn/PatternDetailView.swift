import SwiftUI
import SwiftData

struct PatternDetailView: View {
    let pattern: AlgorithmPattern

    @Query private var progress: [UserProgress]

    var body: some View {
        let lessons = LessonLibrary.lessons(for: pattern)
        let completedIDs = Set(progress.map(\.lessonID))

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero

                if lessons.isEmpty {
                    comingSoon
                } else {
                    VStack(spacing: 12) {
                        ForEach(lessons) { lesson in
                            NavigationLink(value: lesson) {
                                LessonRow(
                                    lesson: lesson,
                                    isCompleted: completedIDs.contains(lesson.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .navigationTitle(pattern.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: pattern.systemIcon)
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(pattern.accent.gradient, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(pattern.title)
                        .font(.title2.weight(.bold))
                    Text(pattern.tagline)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 4)
    }

    private var comingSoon: some View {
        VStack(spacing: 8) {
            Image(systemName: "hourglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Lessons coming soon")
                .font(.headline)
            Text("Sliding Window is the first path with full content. The rest are on the way.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct LessonRow: View {
    let lesson: Lesson
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: isCompleted ? "checkmark.seal.fill" : "play.circle.fill")
                .font(.title)
                .foregroundStyle(isCompleted ? .green : lesson.pattern.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                Text(lesson.scenario)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
