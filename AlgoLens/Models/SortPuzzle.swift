import Foundation

struct SortPuzzle: Identifiable, Hashable, Sendable {
    let id: String
    let pattern: AlgorithmPattern
    let title: String
    let prompt: String
    /// Lines in their correct order. The view shuffles them deterministically by ID.
    let lines: [SortLine]
    let explanation: String
}

struct SortLine: Identifiable, Hashable, Sendable {
    let id: String
    let code: String
}
