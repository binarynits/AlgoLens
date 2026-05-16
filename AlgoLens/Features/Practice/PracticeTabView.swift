import SwiftUI

struct PracticeTabView: View {
    @State private var currentIndex: Int = 0
    @State private var solvedPuzzleIDs: Set<String> = []
    @State private var streak: Int = 0
    @State private var xp: Int = 0
    @State private var selectedCompany: Company? = nil

    private var filteredPuzzles: [PracticePuzzle] {
        if let company = selectedCompany {
            return PracticeLibrary.all.filter { $0.companies.contains(company) }
        }
        return PracticeLibrary.all
    }

    private var currentPuzzle: PracticePuzzle? {
        let puzzles = filteredPuzzles
        guard !puzzles.isEmpty else { return nil }
        return puzzles[currentIndex % puzzles.count]
    }

    private let backgroundColor = Color(red: 0.07, green: 0.07, blue: 0.09)

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()
                VStack(spacing: 0) {
                    companyChipRow
                    statusBar
                    if let puzzle = currentPuzzle {
                        currentPuzzleView(puzzle: puzzle)
                    } else {
                        emptyState
                    }
                }
            }
            .navigationTitle("Practice")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func currentPuzzleView(puzzle: PracticePuzzle) -> some View {
        switch puzzle {
        case let .fillIn(p):
            FillInPuzzleView(puzzle: p) { wasCorrect in
                handleAdvance(wasCorrect: wasCorrect)
            }
            .id(puzzle.id)
        case let .sortLines(p):
            SortPuzzleView(puzzle: p) { wasCorrect in
                handleAdvance(wasCorrect: wasCorrect)
            }
            .id(puzzle.id)
        case let .bugHunt(p):
            BugHuntPuzzleView(puzzle: p) { wasCorrect in
                handleAdvance(wasCorrect: wasCorrect)
            }
            .id(puzzle.id)
        }
    }

    private var companyChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CompanyChip(
                    company: nil,
                    count: PracticeLibrary.all.count,
                    isSelected: selectedCompany == nil
                ) {
                    select(company: nil)
                }
                ForEach(Company.allCases) { company in
                    let count = PracticeLibrary.all.filter { $0.companies.contains(company) }.count
                    CompanyChip(
                        company: company,
                        count: count,
                        isSelected: selectedCompany == company
                    ) {
                        select(company: company)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .padding(.top, 6)
    }

    private func select(company: Company?) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
            selectedCompany = company
            currentIndex = 0
        }
    }

    @ViewBuilder
    private var statusBar: some View {
        if let puzzle = currentPuzzle {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(puzzle.kindLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))
                    Text(puzzle.kindHint)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer(minLength: 8)
                HStack(spacing: 6) {
                    if streak > 0 {
                        StreakChip(streak: streak)
                            .transition(.scale.combined(with: .opacity))
                    }
                    XPChip(xp: xp)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: streak)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.4))
            Text("No puzzles tagged here yet")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))
            Text("More \(selectedCompany?.displayName ?? "") questions are on the way. Tap 'All' to keep going.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button {
                select(company: nil)
            } label: {
                Text("Show all puzzles")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleAdvance(wasCorrect: Bool) {
        guard let puzzle = currentPuzzle else { return }
        if wasCorrect {
            solvedPuzzleIDs.insert(puzzle.id)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                streak += 1
                xp += 10
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                streak = 0
            }
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentIndex = (currentIndex + 1) % max(filteredPuzzles.count, 1)
        }
    }
}

private struct CompanyChip: View {
    let company: Company?
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .monospacedDigit()
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.08),
                                in: Capsule())
            }
            .foregroundStyle(isSelected ? Color.white : tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? tint : Color.white.opacity(0.06))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : tint.opacity(0.45), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isSelected)
    }

    private var label: String {
        company?.shortName ?? "All"
    }

    private var tint: Color {
        company?.accent ?? Color(red: 0.62, green: 0.62, blue: 0.68)
    }
}

private struct StreakChip: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.caption)
                .foregroundStyle(.orange)
            Text("\(streak)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.orange)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(streak)))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.18), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }
}

private struct XPChip: View {
    let xp: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
            Text("\(xp) XP")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.92))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(xp)))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.06), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }
}

#Preview {
    PracticeTabView()
}
