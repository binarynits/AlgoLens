import Foundation

enum CompanyTags {
    /// Maps inner puzzle id (FillInPuzzle.id / SortPuzzle.id / BugHuntPuzzle.id)
    /// to the set of companies that commonly ask questions in that shape.
    static let tags: [String: Set<Company>] = [
        // Fill-in puzzles
        "fill.arr.track-lookup": [.apple, .amazon],
        "fill.hm.duplicate-counter": [.google, .meta, .amazon],
        "fill.sw.max-window-sum": [.google, .meta, .amazon, .apple],

        // Sort puzzles
        "sort.sum-list": [.apple, .microsoft],
        "sort.find-max": [.google, .apple, .amazon, .microsoft],

        // Bug-hunt puzzles
        "bug.find-index": [.google, .meta, .amazon, .microsoft],
        "bug.average": [.apple, .microsoft]
    ]
}
