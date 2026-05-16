import Foundation

enum PracticePuzzle: Hashable, Identifiable, Sendable {
    case fillIn(FillInPuzzle)
    case sortLines(SortPuzzle)
    case bugHunt(BugHuntPuzzle)

    var id: String {
        switch self {
        case let .fillIn(p): return "fill." + p.id
        case let .sortLines(p): return "sort." + p.id
        case let .bugHunt(p): return "bug." + p.id
        }
    }

    var pattern: AlgorithmPattern {
        switch self {
        case let .fillIn(p): return p.pattern
        case let .sortLines(p): return p.pattern
        case let .bugHunt(p): return p.pattern
        }
    }

    var kindLabel: String {
        switch self {
        case .fillIn: "Fill in the missing code"
        case .sortLines: "Sort the code into order"
        case .bugHunt: "Find the bug"
        }
    }

    var kindHint: String {
        switch self {
        case .fillIn: "Tap a blank, then tap a token."
        case .sortLines: "Tap two lines to swap their positions."
        case .bugHunt: "Tap the line you think is wrong."
        }
    }

    /// The inner puzzle id without the `fill.` / `sort.` / `bug.` wrapper prefix.
    var innerID: String {
        switch self {
        case let .fillIn(p): return p.id
        case let .sortLines(p): return p.id
        case let .bugHunt(p): return p.id
        }
    }

    var companies: Set<Company> {
        CompanyTags.tags[innerID] ?? []
    }
}
