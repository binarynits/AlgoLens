import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Query(sort: \UserProgress.completedAt, order: .reverse) private var progress: [UserProgress]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statsRow

                    if progress.isEmpty {
                        emptyState
                    } else {
                        completedSection
                    }
                }
                .padding(20)
            }
            .navigationTitle("Progress")
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatTile(label: "Lessons", value: "\(progress.count)", icon: "checkmark.seal.fill", tint: .green)
            StatTile(label: "Patterns", value: "\(uniquePatternCount)", icon: "square.grid.2x2.fill", tint: .blue)
        }
    }

    private var uniquePatternCount: Int {
        let lessonsByID = Dictionary(uniqueKeysWithValues: LessonLibrary.all.map { ($0.id, $0) })
        let patterns = progress.compactMap { lessonsByID[$0.lessonID]?.pattern }
        return Set(patterns).count
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No lessons yet")
                .font(.headline)
            Text("Open the Learn tab and finish a lesson — it'll show up here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed lessons")
                .font(.subheadline.weight(.semibold))

            let lessonsByID = Dictionary(uniqueKeysWithValues: LessonLibrary.all.map { ($0.id, $0) })

            ForEach(progress) { entry in
                if let lesson = lessonsByID[entry.lessonID] {
                    HStack(spacing: 12) {
                        Image(systemName: lesson.pattern.systemIcon)
                            .frame(width: 36, height: 36)
                            .foregroundStyle(.white)
                            .background(lesson.pattern.accent.gradient, in: RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lesson.title)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(2)
                            Text(lesson.pattern.title + " · " + entry.completedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

private struct StatTile: View {
    let label: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(value)
                .font(.title.weight(.bold))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ProgressTabView()
        .modelContainer(for: UserProgress.self, inMemory: true)
}
