import SwiftUI

enum AlgorithmPattern: String, CaseIterable, Identifiable, Hashable, Sendable {
    case arrays
    case hashMaps
    case twoPointers
    case slidingWindow
    case stackQueue
    case trees
    case graphs
    case mergeIntervals

    var id: String { rawValue }

    var title: String {
        switch self {
        case .arrays: "Arrays"
        case .hashMaps: "HashMaps"
        case .twoPointers: "Two Pointers"
        case .slidingWindow: "Sliding Window"
        case .stackQueue: "Stack & Queue"
        case .trees: "Trees"
        case .graphs: "Graph Basics"
        case .mergeIntervals: "Merge Intervals"
        }
    }

    var tagline: String {
        switch self {
        case .arrays: "The foundation everything else builds on."
        case .hashMaps: "Trade memory for speed. Look things up in O(1)."
        case .twoPointers: "Two indices, one array, half the work."
        case .slidingWindow: "Reuse work as the window moves forward."
        case .stackQueue: "Last-in-first-out. First-in-first-out. Pick your order."
        case .trees: "Hierarchies — files, comments, org charts."
        case .graphs: "Connections — friends, routes, dependencies."
        case .mergeIntervals: "Collapse overlapping ranges into clean blocks."
        }
    }

    var systemIcon: String {
        switch self {
        case .arrays: "square.grid.3x1.below.line.grid.1x2"
        case .hashMaps: "tablecells"
        case .twoPointers: "arrow.left.and.right"
        case .slidingWindow: "rectangle.split.3x1"
        case .stackQueue: "square.stack.3d.up"
        case .trees: "point.3.connected.trianglepath.dotted"
        case .graphs: "point.3.filled.connected.trianglepath.dotted"
        case .mergeIntervals: "calendar.badge.clock"
        }
    }

    var accent: Color {
        switch self {
        case .arrays: .blue
        case .hashMaps: .purple
        case .twoPointers: .teal
        case .slidingWindow: .orange
        case .stackQueue: .pink
        case .trees: .green
        case .graphs: .indigo
        case .mergeIntervals: .cyan
        }
    }
}
