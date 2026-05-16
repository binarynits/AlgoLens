import Foundation

struct Lesson: Identifiable, Hashable, Sendable {
    let id: String
    let pattern: AlgorithmPattern
    let title: String
    let scenario: String
    let story: String
    let realWorldUses: [String]
    let visualizer: LessonVisualizer
    let problems: [Problem]
    let interview: InterviewExplanation
}

enum LessonVisualizer: Hashable, Sendable {
    case slidingWindow(values: [Int], windowSize: Int, unit: String)
    case arrayReorder(items: [ReorderItem], moves: [ReorderMove])
    case directAccess(items: [DirectAccessItem], queries: [DirectAccessQuery])
    case duplicateDetection(stream: [PaymentEvent])
    case twoPointersPairSum(prices: [Int], target: Int, unit: String)
    case stackOperations(actions: [StackAction])
    case folderTreeDFS(root: FolderNode)
    case graphBFS(nodes: [GraphNode], edges: [GraphEdge], startID: String, targetID: String)
    case mergeIntervals(intervals: [Interval])
}

struct Interval: Identifiable, Hashable, Sendable {
    let id: String
    let start: Double
    let end: Double
    let label: String
}

struct FolderNode: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let isFolder: Bool
    let size: String?
    let children: [FolderNode]
}

struct GraphNode: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let x: Double
    let y: Double
}

struct GraphEdge: Hashable, Sendable {
    let from: String
    let to: String
}

struct StackAction: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let systemIcon: String
}

struct PaymentEvent: Identifiable, Hashable, Sendable {
    let id: String
    let txnID: String
    let amount: String
}

struct DirectAccessItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
}

struct DirectAccessQuery: Identifiable, Hashable, Sendable {
    let id: String
    let index: Int
    let label: String
}

struct ReorderItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
}

struct ReorderMove: Hashable, Sendable {
    let itemID: String
    let label: String
}

struct Problem: Identifiable, Hashable, Sendable {
    let id: String
    let kind: ProblemKind
    let prompt: String
    let choices: [Choice]
    let explanation: String
}

enum ProblemKind: String, Hashable, Sendable {
    case predictNextStep
    case multipleChoiceLogic
}

struct Choice: Identifiable, Hashable, Sendable {
    let id: String
    let text: String
    let isCorrect: Bool
}

struct InterviewExplanation: Hashable, Sendable {
    let whyItWorks: String
    let timeComplexity: String
    let spaceComplexity: String
    let versusBruteForce: String
    let swiftSnippet: String
}
