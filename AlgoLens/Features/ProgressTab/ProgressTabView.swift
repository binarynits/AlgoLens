import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Query(sort: \UserProgress.completedAt, order: .reverse) private var progress: [UserProgress]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    streakCard
                    calendarStrip
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

    // MARK: - Streak

    private struct StreakInfo {
        let current: Int
        let longest: Int
        let isAtRisk: Bool
    }

    private var streakInfo: StreakInfo {
        let calendar = Calendar.current
        let days = Set(progress.map { calendar.startOfDay(for: $0.completedAt) })
        guard !days.isEmpty else {
            return StreakInfo(current: 0, longest: 0, isAtRisk: false)
        }

        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        var current = 0
        var isAtRisk = false
        var cursor: Date

        if days.contains(today) {
            cursor = today
        } else if days.contains(yesterday) {
            cursor = yesterday
            isAtRisk = true
        } else {
            return StreakInfo(current: 0,
                              longest: longestStreak(days: days, calendar: calendar),
                              isAtRisk: false)
        }

        while days.contains(cursor) {
            current += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }

        return StreakInfo(
            current: current,
            longest: max(current, longestStreak(days: days, calendar: calendar)),
            isAtRisk: isAtRisk
        )
    }

    private func longestStreak(days: Set<Date>, calendar: Calendar) -> Int {
        let sorted = days.sorted()
        guard !sorted.isEmpty else { return 0 }
        var longest = 1
        var current = 1
        for i in 1..<sorted.count {
            let diff = calendar.dateComponents([.day], from: sorted[i - 1], to: sorted[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    private var streakCard: some View {
        let info = streakInfo
        let active = info.current > 0
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(active ? Color.orange.opacity(0.20) : Color.secondary.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: active ? "flame.fill" : "flame")
                    .font(.system(size: 30))
                    .foregroundStyle(active ? .orange : .secondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(info.current)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(info.current)))
                    Text(info.current == 1 ? "day" : "days")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Text(streakSubtitle(info))
                    .font(.caption)
                    .foregroundStyle(info.isAtRisk ? .orange : .secondary)
            }
            Spacer(minLength: 0)
            if info.longest > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("BEST")
                        .font(.caption2.weight(.bold))
                        .tracking(0.6)
                        .foregroundStyle(.secondary)
                    Text("\(info.longest)")
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func streakSubtitle(_ info: StreakInfo) -> String {
        if info.current == 0 {
            return "Finish a lesson to start a streak"
        }
        if info.isAtRisk {
            return "Finish a lesson today to keep it"
        }
        return "Keep it going"
    }

    // MARK: - 14-day calendar strip

    private struct DayActivity: Identifiable {
        let id: Date
        let date: Date
        let count: Int
        let isToday: Bool
    }

    private var recentActivity: [DayActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let counts = Dictionary(grouping: progress) { calendar.startOfDay(for: $0.completedAt) }
            .mapValues { $0.count }
        return (0..<14).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            return DayActivity(
                id: date,
                date: date,
                count: counts[date] ?? 0,
                isToday: offset == 0
            )
        }
    }

    private var calendarStrip: some View {
        let activity = recentActivity
        let todayLabel = activity.last.map { $0.date.formatted(.dateTime.month(.abbreviated).day()) } ?? ""
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PAST 14 DAYS")
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Today: \(todayLabel)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                ForEach(activity) { day in
                    DayCell(day: day)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private struct DayCell: View {
        let day: DayActivity

        var body: some View {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(fill)
                        .frame(width: 22, height: 22)
                    if day.count > 0 {
                        Text("\(day.count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                    }
                }
                .overlay {
                    if day.isToday {
                        Circle()
                            .strokeBorder(.primary, lineWidth: 1.5)
                            .padding(-3)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }

        private var fill: Color {
            day.count > 0 ? .orange : Color.secondary.opacity(0.15)
        }
    }

    // MARK: - Stats + completed list

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
