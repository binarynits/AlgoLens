import SwiftUI

enum Company: String, CaseIterable, Identifiable, Hashable, Sendable {
    case google
    case meta
    case apple
    case amazon
    case microsoft

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .google: "Google"
        case .meta: "Meta"
        case .apple: "Apple"
        case .amazon: "Amazon"
        case .microsoft: "Microsoft"
        }
    }

    var shortName: String {
        switch self {
        case .google: "Google"
        case .meta: "Meta"
        case .apple: "Apple"
        case .amazon: "Amazon"
        case .microsoft: "MS"
        }
    }

    var accent: Color {
        switch self {
        case .google: Color(red: 0.26, green: 0.52, blue: 0.96)
        case .meta: Color(red: 0.03, green: 0.40, blue: 1.00)
        case .apple: Color(red: 0.62, green: 0.62, blue: 0.66)
        case .amazon: Color(red: 1.00, green: 0.60, blue: 0.00)
        case .microsoft: Color(red: 0.00, green: 0.74, blue: 0.83)
        }
    }
}
