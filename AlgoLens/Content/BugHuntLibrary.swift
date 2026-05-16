import Foundation

enum BugHuntLibrary {
    static let all: [BugHuntPuzzle] = [
        findIndexComparison,
        averageArithmetic
    ]

    static let findIndexComparison = BugHuntPuzzle(
        id: "bug.find-index",
        pattern: .arrays,
        title: "Where's the bug?",
        prompt: "This function should return the index of the first item that matches a target. Right now it returns the wrong thing. Tap the line you think is broken.",
        lines: [
            BugHuntLine(id: "l1", code: "func findIndex(_ items: [Int], _ target: Int) -> Int {"),
            BugHuntLine(id: "l2", code: "    for i in 0..<items.count {"),
            BugHuntLine(id: "l3", code: "        if items[i] != target {"),
            BugHuntLine(id: "l4", code: "            return i"),
            BugHuntLine(id: "l5", code: "        }"),
            BugHuntLine(id: "l6", code: "    }"),
            BugHuntLine(id: "l7", code: "    return -1"),
            BugHuntLine(id: "l8", code: "}")
        ],
        buggyLineID: "l3",
        fixedLine: "        if items[i] == target {",
        explanation: "The condition was looking for items that DON'T match the target. Flip != to == and the function returns the first matching index."
    )

    static let averageArithmetic = BugHuntPuzzle(
        id: "bug.average",
        pattern: .arrays,
        title: "The average is way off",
        prompt: "Tester says this 'average' returns weird numbers. The loop builds the sum correctly. One line at the end is wrong. Find it.",
        lines: [
            BugHuntLine(id: "l1", code: "func average(_ numbers: [Int]) -> Int {"),
            BugHuntLine(id: "l2", code: "    var sum = 0"),
            BugHuntLine(id: "l3", code: "    for n in numbers {"),
            BugHuntLine(id: "l4", code: "        sum += n"),
            BugHuntLine(id: "l5", code: "    }"),
            BugHuntLine(id: "l6", code: "    return sum - numbers.count"),
            BugHuntLine(id: "l7", code: "}")
        ],
        buggyLineID: "l6",
        fixedLine: "    return sum / numbers.count",
        explanation: "Average = sum divided by count, not sum minus count. Swap the minus for a slash and the function returns a proper average."
    )
}
