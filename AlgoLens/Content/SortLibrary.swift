import Foundation

enum SortLibrary {
    static let all: [SortPuzzle] = [
        sumList,
        findMax
    ]

    static let sumList = SortPuzzle(
        id: "sort.sum-list",
        pattern: .arrays,
        title: "Add up every number in a list",
        prompt: "These five lines compute a total. They got shuffled. Tap two lines to swap them until the order makes sense.",
        lines: [
            SortLine(id: "decl", code: "var total = 0"),
            SortLine(id: "for", code: "for number in numbers {"),
            SortLine(id: "add", code: "    total += number"),
            SortLine(id: "close", code: "}"),
            SortLine(id: "return", code: "return total")
        ],
        explanation: "You start with zero. Then you walk through every number, adding each one to your running total. When the loop ends, the total holds the sum. Setup → loop → return."
    )

    static let findMax = SortPuzzle(
        id: "sort.find-max",
        pattern: .arrays,
        title: "Find the biggest number",
        prompt: "Six lines that find the maximum value in a list. Put them in the order they should run.",
        lines: [
            SortLine(id: "init", code: "var maxValue = numbers[0]"),
            SortLine(id: "for", code: "for n in numbers {"),
            SortLine(id: "if", code: "    if n > maxValue {"),
            SortLine(id: "assign", code: "        maxValue = n"),
            SortLine(id: "close-if", code: "    }"),
            SortLine(id: "close-for", code: "}"),
            SortLine(id: "return", code: "return maxValue")
        ],
        explanation: "Seed the max with the first item, then walk the rest. Each time you see something bigger, update your record. When the loop's done, you've seen them all — maxValue holds the winner."
    )
}
