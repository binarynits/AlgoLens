import Foundation
import SwiftData

@Model
final class UserProgress {
    @Attribute(.unique) var lessonID: String
    var completedAt: Date

    init(lessonID: String, completedAt: Date = .now) {
        self.lessonID = lessonID
        self.completedAt = completedAt
    }
}
