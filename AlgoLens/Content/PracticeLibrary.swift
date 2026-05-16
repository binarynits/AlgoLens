import Foundation

enum PracticeLibrary {
    /// Interleaves the puzzle types so the player gets variety as they advance.
    static let all: [PracticePuzzle] = {
        var result: [PracticePuzzle] = []
        let fills = FillInLibrary.all.map(PracticePuzzle.fillIn)
        let sorts = SortLibrary.all.map(PracticePuzzle.sortLines)
        let bugs = BugHuntLibrary.all.map(PracticePuzzle.bugHunt)
        let stride = max(fills.count, max(sorts.count, bugs.count))
        for i in 0..<stride {
            if i < fills.count { result.append(fills[i]) }
            if i < sorts.count { result.append(sorts[i]) }
            if i < bugs.count { result.append(bugs[i]) }
        }
        return result
    }()
}
