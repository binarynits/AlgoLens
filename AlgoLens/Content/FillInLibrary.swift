import Foundation

enum FillInLibrary {
    static let all: [FillInPuzzle] = [
        trackLookup,
        duplicateCounter,
        maxWindowSum
    ]

    static let trackLookup = FillInPuzzle(
        id: "fill.arr.track-lookup",
        pattern: .arrays,
        title: "Return a track by position",
        prompt: "Look up a track by its index in the album. Return nil for out-of-range positions.",
        codeLines: [
            [.text("func track(_ position: Int, of album: [String]) -> String? {")],
            [.text("    guard position >= 0 && position < album."), .blank(id: "b1", correctText: "count"), .text(" else {")],
            [.text("        return nil")],
            [.text("    }")],
            [.text("    return album["), .blank(id: "b2", correctText: "position"), .text("]")],
            [.text("}")]
        ],
        tokens: [
            CodeToken(id: "count", text: "count"),
            CodeToken(id: "length", text: "length"),
            CodeToken(id: "size", text: "size"),
            CodeToken(id: "position", text: "position"),
            CodeToken(id: "index", text: "index"),
            CodeToken(id: "n", text: "n")
        ],
        explanation: "album.count is the number of slots in the array — any position at or past it is out of range. The lookup album[position] reads that exact slot in O(1). That direct addressing is what arrays trade middle-insert cost for."
    )

    static let duplicateCounter = FillInPuzzle(
        id: "fill.hm.duplicate-counter",
        pattern: .hashMaps,
        title: "Count duplicate IDs in a stream",
        prompt: "Walk the stream once. Use a hash set to spot duplicates in O(1) per check.",
        codeLines: [
            [.text("func countDuplicates(_ ids: [String]) -> Int {")],
            [.text("    var seen: Set<String> = []")],
            [.text("    var duplicates = 0")],
            [.text("    for id in ids {")],
            [.text("        if seen."), .blank(id: "b1", correctText: "contains"), .text("(id) {")],
            [.text("            duplicates += 1")],
            [.text("        } else {")],
            [.text("            seen."), .blank(id: "b2", correctText: "insert"), .text("(id)")],
            [.text("        }")],
            [.text("    }")],
            [.text("    return duplicates")],
            [.text("}")]
        ],
        tokens: [
            CodeToken(id: "contains", text: "contains"),
            CodeToken(id: "insert", text: "insert"),
            CodeToken(id: "append", text: "append"),
            CodeToken(id: "add", text: "add"),
            CodeToken(id: "remove", text: "remove"),
            CodeToken(id: "has", text: "has"),
            CodeToken(id: "find", text: "find")
        ],
        explanation: "Set.contains is hash-and-read — O(1) on average regardless of set size. Set.insert is hash-and-write — also O(1). The whole pass runs in O(n) total instead of O(n²) for a linear-scan-per-check version."
    )

    static let maxWindowSum = FillInPuzzle(
        id: "fill.sw.max-window-sum",
        pattern: .slidingWindow,
        title: "Find the heaviest sliding window",
        prompt: "Slide a window of size k across the values. Maintain the running sum without recomputing it each step.",
        codeLines: [
            [.text("func maxWindowSum(_ values: [Int], k: Int) -> Int {")],
            [.text("    var sum = values.prefix(k).reduce(0, +)")],
            [.text("    var maxSum = sum")],
            [.text("    for i in "), .blank(id: "b1", correctText: "k"), .text("..<values.count {")],
            [.text("        sum += values[i] - values["), .blank(id: "b2", correctText: "i - k"), .text("]")],
            [.text("        maxSum = max(maxSum, "), .blank(id: "b3", correctText: "sum"), .text(")")],
            [.text("    }")],
            [.text("    return maxSum")],
            [.text("}")]
        ],
        tokens: [
            CodeToken(id: "k", text: "k"),
            CodeToken(id: "zero", text: "0"),
            CodeToken(id: "i", text: "i"),
            CodeToken(id: "i-k", text: "i - k"),
            CodeToken(id: "i+k", text: "i + k"),
            CodeToken(id: "k-i", text: "k - i"),
            CodeToken(id: "sum", text: "sum"),
            CodeToken(id: "windowSum", text: "windowSum"),
            CodeToken(id: "maxSum", text: "maxSum")
        ],
        explanation: "The loop starts at k because the first window covers 0..<k — sum is already correct for that. To slide one step right, add the new value values[i] and subtract values[i - k] (the one falling off the back). Then compare sum to the running max."
    )
}
