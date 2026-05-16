import Foundation

struct BugHuntPuzzle: Identifiable, Hashable, Sendable {
    let id: String
    let pattern: AlgorithmPattern
    let title: String
    let prompt: String
    let lines: [BugHuntLine]
    let buggyLineID: String
    let fixedLine: String
    let explanation: String
}

struct BugHuntLine: Identifiable, Hashable, Sendable {
    let id: String
    let code: String
}
