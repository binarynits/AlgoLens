import Foundation

struct FillInPuzzle: Identifiable, Hashable, Sendable {
    let id: String
    let pattern: AlgorithmPattern
    let title: String
    let prompt: String
    let codeLines: [[CodeSegment]]
    let tokens: [CodeToken]
    let explanation: String

    var blankIDs: [String] {
        codeLines.flatMap { line in
            line.compactMap { seg in
                if case let .blank(id, _) = seg { return id }
                return nil
            }
        }
    }

    func correctText(for blankID: String) -> String? {
        for line in codeLines {
            for seg in line {
                if case let .blank(id, text) = seg, id == blankID {
                    return text
                }
            }
        }
        return nil
    }
}

enum CodeSegment: Hashable, Sendable {
    case text(String)
    case blank(id: String, correctText: String)
}

struct CodeToken: Identifiable, Hashable, Sendable {
    let id: String
    let text: String
}
