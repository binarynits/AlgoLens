import Foundation

enum LessonLibrary {
    static let all: [Lesson] = [
        arrayTrackLookup,
        arrayRecentlyPlayed,
        hashMapDuplicatePayments,
        twoPointersGiftCard,
        stackUndoSystem,
        treesFolderCount,
        graphsSocialDistance,
        slidingWindowFraud,
        mergeIntervalsCalendar
    ]

    static func lessons(for pattern: AlgorithmPattern) -> [Lesson] {
        all.filter { $0.pattern == pattern }
    }

    static let twoPointersGiftCard = Lesson(
        id: "tp.gift-card-pair",
        pattern: .twoPointers,
        title: "Spending a Gift Card on Exactly Two Items",
        scenario: "You have a $50 gift card and a sorted price list. Find two items whose prices sum to exactly $50 — no change owed, no overpay.",
        story: """
        Brute force: check every pair. For 1,000 items that's half a million pair-checks. Most of them you never had to look at.

        Two pointers exploits the sorted order. Place one finger on the cheapest item and one on the priciest. Their sum is your current guess.

        If the sum is too low, slide the left pointer right — you need a more expensive item on that side.
        If the sum is too high, slide the right pointer left — you need a cheaper item on that side.
        If they match, you've found the pair.

        Each step eliminates an entire range of pairs without ever looking at them. The two pointers walk toward each other, meeting in the middle — at most n steps total. O(n).

        This only works because the list is sorted. Sorting costs O(n log n) up front, but if your data is already sorted (price lists, time-stamped logs, leaderboards) you skip the cost entirely.
        """,
        realWorldUses: [
            "Pair / triplet sums — find values that meet a target",
            "Reverse a string or array in place",
            "Remove duplicates from a sorted array, in O(1) extra space",
            "Palindrome checks — first vs. last, walking inward",
            "Slow + fast pointer — cycle detection, finding the middle of a linked list"
        ],
        visualizer: .twoPointersPairSum(
            prices: [5, 9, 14, 22, 27, 33, 41, 50, 62],
            target: 50,
            unit: "$"
        ),
        problems: [
            Problem(
                id: "tp.gift-card-pair.q1",
                kind: .predictNextStep,
                prompt: "L points to $14, R points to $33. Target is $50. What's the next move?",
                choices: [
                    Choice(id: "a", text: "Move L right — the sum is 47, still under 50.", isCorrect: true),
                    Choice(id: "b", text: "Move R left — the sum is over 50.", isCorrect: false),
                    Choice(id: "c", text: "Done — sum equals 50.", isCorrect: false),
                    Choice(id: "d", text: "Stop — there's no pair that works.", isCorrect: false)
                ],
                explanation: "$14 + $33 = $47, which is less than $50. The only way to grow the sum is to swap one side for something pricier. Since L is on the cheaper end and the list is sorted, stepping L right gives us a bigger value there."
            ),
            Problem(
                id: "tp.gift-card-pair.q2",
                kind: .multipleChoiceLogic,
                prompt: "Why does the two-pointers approach require the list to be sorted?",
                choices: [
                    Choice(id: "a", text: "Sorted lists are faster to read from memory.", isCorrect: false),
                    Choice(id: "b", text: "Deciding which pointer to move depends on knowing that one direction has bigger values and the other has smaller — only true when sorted.", isCorrect: true),
                    Choice(id: "c", text: "Two pointers can only be used on sorted arrays — it's a language restriction.", isCorrect: false),
                    Choice(id: "d", text: "Sorting hashes the values so lookups become O(1).", isCorrect: false)
                ],
                explanation: "Order is what makes the decision rule sound. 'Sum too low → step L right' only helps if 'right of L' means 'bigger'. Without sort, moving a pointer doesn't reliably grow or shrink the sum, and you lose the ability to skip pairs."
            )
        ],
        interview: InterviewExplanation(
            whyItWorks: "On a sorted list, the current sum at (L, R) tells you which direction has any hope of fixing it. Too small → only bigger values can help → step L forward. Too big → only smaller values can help → step R back. Every step retires a whole range of pairs without examining them.",
            timeComplexity: "O(n) once sorted. The two pointers each cross the array at most once, so total work is bounded by n.",
            spaceComplexity: "O(1) — two index variables.",
            versusBruteForce: "Brute force checks every pair — O(n²). At n = 1,000 that's about 500K pair-checks. Two pointers finishes in n steps. If you also have to sort, that's O(n log n) up front — still cheaper than n² as soon as n gets non-trivial.",
            swiftSnippet: """
            func findPair(_ prices: [Int], summingTo target: Int) -> (Int, Int)? {
                var left = 0
                var right = prices.count - 1

                while left < right {
                    let sum = prices[left] + prices[right]
                    if sum == target { return (left, right) }
                    if sum < target {
                        left += 1
                    } else {
                        right -= 1
                    }
                }
                return nil
            }

            // Caller is responsible for sort order:
            //   let sorted = prices.sorted()         // O(n log n) once
            //   let pair = findPair(sorted, summingTo: 50)   // O(n) per query
            """
        )
    )

    static let hashMapDuplicatePayments = Lesson(
        id: "hm.duplicate-payments",
        pattern: .hashMaps,
        title: "Catching Duplicate Payments Before They Charge Twice",
        scenario: "You're on the payments team. The same transaction can hit your service more than once — retries, network blips, a user tapping Pay twice. Charging twice is a bug. You need a fast 'have I seen this ID?' check, even as the stream grows.",
        story: """
        Imagine a stream of payments rushing through your service. Each carries a unique transaction ID — except when the same payment arrives twice. The network dropped your acknowledgement and the client retried. The user double-tapped Pay. Either way, charge them twice and you've got an angry customer and a refund ticket.

        The naive fix: keep a list of every ID you've already processed. For each new payment, scan the list. With ten payments, instant. With ten million, every check walks through up to ten million entries. The work climbs quadratically.

        The HashMap fix: store seen IDs in a hash-based structure (Swift's `Set` or `Dictionary`). 'Have I seen TXN-A?' takes the same time whether the set has ten items or ten million.

        How? The set computes a small 'hash' — a number — from each ID. That number maps directly to a slot in an internal array. Adding an item: hash and write. Looking one up: hash and read. One small calculation, one slot access. The number of items already stored doesn't enter the equation.

        The trade is memory. You hold every unique ID in the set. For millions of payments, that's megabytes. Almost always worth it: a million-element scan takes milliseconds, a hash lookup takes nanoseconds. You're trading bytes you have for time you don't.
        """,
        realWorldUses: [
            "Idempotency keys — every serious payment API (Stripe, Square) catches retries this way",
            "Username and email uniqueness at signup",
            "Web crawlers — 'have I already visited this URL?'",
            "Caching and memoization — 'have I already computed this?'",
            "Deduplicating event streams in analytics"
        ],
        visualizer: .duplicateDetection(
            stream: [
                PaymentEvent(id: "e1", txnID: "TXN-A", amount: "$42"),
                PaymentEvent(id: "e2", txnID: "TXN-B", amount: "$15"),
                PaymentEvent(id: "e3", txnID: "TXN-C", amount: "$128"),
                PaymentEvent(id: "e4", txnID: "TXN-A", amount: "$42"),
                PaymentEvent(id: "e5", txnID: "TXN-D", amount: "$7"),
                PaymentEvent(id: "e6", txnID: "TXN-B", amount: "$15"),
                PaymentEvent(id: "e7", txnID: "TXN-E", amount: "$230"),
                PaymentEvent(id: "e8", txnID: "TXN-A", amount: "$42"),
                PaymentEvent(id: "e9", txnID: "TXN-F", amount: "$19"),
                PaymentEvent(id: "e10", txnID: "TXN-G", amount: "$4")
            ]
        ),
        problems: [
            Problem(
                id: "hm.duplicate-payments.q1",
                kind: .predictNextStep,
                prompt: "Your seen-set has 1,000,000 entries. A new payment arrives. How many of those entries does the set look at to decide if it's a duplicate?",
                choices: [
                    Choice(id: "a", text: "About 1,000 — it uses binary search.", isCorrect: false),
                    Choice(id: "b", text: "Up to 1,000,000 — it scans the whole set.", isCorrect: false),
                    Choice(id: "c", text: "1 — it hashes the ID to a slot, then checks that slot.", isCorrect: true),
                    Choice(id: "d", text: "The 100 most recent — they're cached for fast checking.", isCorrect: false)
                ],
                explanation: "Hash-based sets compute a slot directly from the value, then look at that one slot. The number of items already stored doesn't affect lookup cost on average. That's the whole reason you'd pay the memory price for a hash set."
            ),
            Problem(
                id: "hm.duplicate-payments.q2",
                kind: .multipleChoiceLogic,
                prompt: "What's the trade-off you accept when reaching for a HashSet (or HashMap) instead of scanning a list?",
                choices: [
                    Choice(id: "a", text: "HashSets are slower to insert but faster to read back.", isCorrect: false),
                    Choice(id: "b", text: "Extra memory to store every unique value, in exchange for O(1) average lookup and insert.", isCorrect: true),
                    Choice(id: "c", text: "HashSets only work for integer values.", isCorrect: false),
                    Choice(id: "d", text: "The values are kept sorted, which makes iteration slow.", isCorrect: false)
                ],
                explanation: "A HashSet keeps a copy of every unique value — that's the memory cost. In return, you stop paying O(n) per lookup. For 'have I seen this?' streams, the trade is almost always a win: bytes are cheap, time isn't."
            )
        ],
        interview: InterviewExplanation(
            whyItWorks: "A hash set computes a fixed-size hash from each value, and that hash maps directly to a slot in an internal array. Insert is hash-and-write; lookup is hash-and-read. The work per operation doesn't grow with the set's size — same cost for 10 items or 10 million. Dictionaries (HashMaps) are the same trick with a value attached to each key.",
            timeComplexity: "Insert: O(1) average. Lookup: O(1) average. Worst case O(n) for pathological inputs that hash to the same slot.",
            spaceComplexity: "O(n) — one slot per unique value.",
            versusBruteForce: "Brute force scans the list for every check — O(n) per call, O(n²) for n checks against each other. A hash set collapses that to O(1) and O(n). At 1M payments that's ~1M ops vs. ~1 trillion. The difference between 'instant' and 'never finishes'.",
            swiftSnippet: """
            struct Payment {
                let txnID: String
                let amount: Int
            }

            func processStream(_ events: [Payment]) -> Int {
                var seen: Set<String> = []
                var duplicates = 0

                for event in events {
                    if seen.contains(event.txnID) {
                        duplicates += 1
                        continue
                    }
                    seen.insert(event.txnID)
                    // process(event)
                }
                return duplicates
            }

            // Swift Set<T> and Dictionary<K, V>:
            //   .contains, .insert, [key] lookup: O(1) average
            //   One hash, one slot read. Independent of size.
            """
        )
    )

    static let stackUndoSystem = Lesson(
        id: "sq.undo-system",
        pattern: .stackQueue,
        title: "Cmd+Z Lives on a Stack",
        scenario: "You're building the undo button for a drawing app. The user expects Cmd+Z to take back the very last thing they did — not the first stroke they drew an hour ago. That's the contract a Stack delivers for free.",
        story: """
        Every action the user takes — a brushstroke, a color change, a drag — gets pushed onto a stack as it happens. The freshest action is always on top.

        Cmd+Z pops the top off. That's the most recent action, the one they meant. Pop again and you get the next most recent. Pop until empty and you've undone everything.

        The whole pattern: last in, first out. The newest thing is always the most accessible.

        The same shape shows up everywhere. The browser back button is a stack of pages. The call stack inside your CPU is a stack of function calls — that's literally what 'stack overflow' means. Even parenthesis matching in a compiler uses a stack to remember which open paren you saw last.

        Compare it to a Queue (first in, first out) — like a coffee shop line. First in line, first served. That's the right structure for printer jobs, customer tickets, breadth-first search — anywhere fairness matters. But for undo? You'd undo the first stroke from an hour ago, not the one they just drew. Wrong order entirely.

        Pick the data structure that gives you the order you need. Stack for 'most recent first.' Queue for 'oldest first.'
        """,
        realWorldUses: [
            "Undo and redo in any editor — text, drawing, design tools",
            "Browser back button — pages stack as you navigate forward",
            "The CPU's call stack — every function call pushes, every return pops",
            "Parenthesis and bracket matching in compilers and linters",
            "Depth-first search and tree traversal — explore deep before wide",
            "Recursive-descent parsers — grammar rules nest on a stack"
        ],
        visualizer: .stackOperations(actions: [
            StackAction(id: "line", label: "Draw line", systemIcon: "pencil.line"),
            StackAction(id: "rect", label: "Add shape", systemIcon: "square.dashed"),
            StackAction(id: "color", label: "Change color", systemIcon: "paintpalette.fill"),
            StackAction(id: "erase", label: "Erase mark", systemIcon: "eraser.fill")
        ]),
        problems: [
            Problem(
                id: "sq.undo-system.q1",
                kind: .predictNextStep,
                prompt: "The stack from bottom to top is [Draw, Move, Resize]. The user hits Cmd+Z. What gets undone?",
                choices: [
                    Choice(id: "a", text: "Resize — it's the top of the stack, the most recent action.", isCorrect: true),
                    Choice(id: "b", text: "Draw — it's the oldest, undo starts at the bottom.", isCorrect: false),
                    Choice(id: "c", text: "Move — it's in the middle, somehow.", isCorrect: false),
                    Choice(id: "d", text: "Nothing — Cmd+Z needs at least 4 items on the stack.", isCorrect: false)
                ],
                explanation: "Stack means last in, first out. Pop always removes the top — the most recently pushed item. Resize was the last thing pushed, so it's the first thing popped. The 'undo' contract is just 'pop the stack.'"
            ),
            Problem(
                id: "sq.undo-system.q2",
                kind: .multipleChoiceLogic,
                prompt: "Why is Stack the right structure for undo — and not a Queue?",
                choices: [
                    Choice(id: "a", text: "Stacks are faster than queues at insertion.", isCorrect: false),
                    Choice(id: "b", text: "Stacks return the most recent action first, which is exactly what users expect from undo.", isCorrect: true),
                    Choice(id: "c", text: "Queues don't have an undo operation in any language.", isCorrect: false),
                    Choice(id: "d", text: "Stacks automatically sort their contents.", isCorrect: false)
                ],
                explanation: "Stack = last in, first out. Queue = first in, first out. Undo wants 'the last thing I did, not the first.' That's a Stack. Queues are right for fairness (oldest first); Stacks are right for recency."
            )
        ],
        interview: InterviewExplanation(
            whyItWorks: "A Stack only adds and removes at one end — the top. Push goes on top, pop comes off the top. That single rule guarantees the most recent push is the first to come out: last in, first out. For undo, that contract is exactly what users want.",
            timeComplexity: "Push, pop, and peek are all O(1). No scanning is ever required — the top is always one read away.",
            spaceComplexity: "O(n) for n items in the stack — one slot per stored item.",
            versusBruteForce: "You could simulate undo with a plain array and a manual cursor, but it gets fiddly when redo enters the picture. A pair of stacks (undo stack + redo stack) handles undo/redo cleanly: pop from undo, push to redo, and vice versa. Each operation stays O(1).",
            swiftSnippet: """
            struct UndoSystem<Action> {
                private var stack: [Action] = []

                mutating func push(_ action: Action) {
                    stack.append(action)        // O(1)
                }

                mutating func undo() -> Action? {
                    return stack.popLast()      // O(1)
                }

                var peek: Action? {
                    return stack.last           // O(1)
                }

                var depth: Int { stack.count }
            }

            // In Swift, [Element] gives you O(1) append and popLast for free.
            // That's why most "stacks" in production code are just arrays.
            """
        )
    )

    static let treesFolderCount = Lesson(
        id: "tr.folder-count",
        pattern: .trees,
        title: "How Many Files in This Folder, Really?",
        scenario: "You're building Finder's 'Calculating size…' indicator. To show how much storage a folder uses, you have to look inside it — and inside every subfolder, and inside those. A tree gives you exactly that, with one simple rule: a folder is a list of children, each of which might be another folder.",
        story: """
        A folder hierarchy is a tree. Every node is either a file (a leaf) or a folder (a node with children). The top folder is the root.

        To count every file inside a folder, you visit the folder, then visit each of its children, then each of theirs, and so on. That's a tree traversal.

        Two natural orderings:
        - Depth-first (DFS): go all the way down one branch before coming back up. Pre-order: visit, then recurse into each child.
        - Breadth-first (BFS): visit every node at depth 1, then every node at depth 2, and so on. Uses a queue.

        For counting files both visit every node, so they give the same count. The difference matters when the question changes. 'Find the closest match' wants BFS (shallower hits first). 'Walk a path' wants DFS (the call stack remembers where you are).

        Trees are everywhere in software: the DOM in a web page, comment threads on Reddit, the AST your compiler builds from source, JSON data, even this app's navigation stack.

        The recursion writes itself because the data is recursive: a folder's file count is the sum of each child's file count. The shape of your function matches the shape of your data.
        """,
        realWorldUses: [
            "File systems — folders within folders",
            "DOM trees — every element nests inside another",
            "Comment threads on Reddit, Hacker News, YouTube",
            "AST (abstract syntax tree) — how a compiler reads your code",
            "Decision trees in machine learning",
            "Auto-complete tries — special trees for word prefixes"
        ],
        visualizer: .folderTreeDFS(
            root: FolderNode(
                id: "root",
                name: "Projects",
                isFolder: true,
                size: nil,
                children: [
                    FolderNode(id: "photos", name: "Photos", isFolder: true, size: nil, children: [
                        FolderNode(id: "vacation", name: "vacation.jpg", isFolder: false, size: "2.3 MB", children: []),
                        FolderNode(id: "wedding", name: "wedding.jpg", isFolder: false, size: "4.1 MB", children: [])
                    ]),
                    FolderNode(id: "docs", name: "Docs", isFolder: true, size: nil, children: [
                        FolderNode(id: "resume", name: "resume.pdf", isFolder: false, size: "180 KB", children: []),
                        FolderNode(id: "archive", name: "Archive", isFolder: true, size: nil, children: [
                            FolderNode(id: "old", name: "old.txt", isFolder: false, size: "12 KB", children: [])
                        ])
                    ]),
                    FolderNode(id: "readme", name: "README.md", isFolder: false, size: "2 KB", children: [])
                ]
            )
        ),
        problems: [
            Problem(
                id: "tr.folder-count.q1",
                kind: .predictNextStep,
                prompt: "DFS just visited 'Photos' (a folder with two image files inside). What's the next node DFS visits?",
                choices: [
                    Choice(id: "a", text: "vacation.jpg — the first child of Photos.", isCorrect: true),
                    Choice(id: "b", text: "Docs — the next sibling folder, jumping past the kids.", isCorrect: false),
                    Choice(id: "c", text: "Projects — back up to the root.", isCorrect: false),
                    Choice(id: "d", text: "old.txt — the deepest file in the tree.", isCorrect: false)
                ],
                explanation: "Pre-order DFS visits a node, then dives into its children one at a time. After Photos, the first thing DFS does is descend into Photos's children. The first child is vacation.jpg — that's next."
            ),
            Problem(
                id: "tr.folder-count.q2",
                kind: .multipleChoiceLogic,
                prompt: "Why do tree algorithms feel like they 'naturally' use recursion?",
                choices: [
                    Choice(id: "a", text: "Recursion is faster than loops for trees.", isCorrect: false),
                    Choice(id: "b", text: "Each child node is itself a smaller tree of the same shape, so the recursive structure of the data matches the recursive structure of the function.", isCorrect: true),
                    Choice(id: "c", text: "Trees are too big for loops to handle.", isCorrect: false),
                    Choice(id: "d", text: "Swift's compiler requires recursion for tree types.", isCorrect: false)
                ],
                explanation: "A tree is defined recursively — a node is either a leaf, or a node whose children are themselves trees. Any operation you can run on the whole tree, you can also run on each subtree. That's why `count(tree) = sum(count(child) for each child)` writes itself."
            )
        ],
        interview: InterviewExplanation(
            whyItWorks: "Trees are recursive data: every node is either a leaf or a node whose children are themselves trees. Any operation on the whole tree can be expressed as the same operation on each subtree, combined. That's why tree algorithms look like 'do something here, then call yourself on each child.'",
            timeComplexity: "O(n) — every node is visited exactly once during a full traversal.",
            spaceComplexity: "O(h) for the call stack, where h is the height of the tree. A balanced tree of n nodes has h = O(log n). A degenerate (one-sided) tree can have h = O(n).",
            versusBruteForce: "There's no real 'brute force' for tree traversal — you have to touch each node. The choice is the order: DFS uses the call stack and is great for follow-the-path problems. BFS uses an explicit queue and is great for 'shallowest match first.' Pick the order that matches your question.",
            swiftSnippet: """
            struct FolderNode {
                let name: String
                let isFolder: Bool
                let children: [FolderNode]
            }

            func countFiles(in node: FolderNode) -> Int {
                if !node.isFolder { return 1 }
                return node.children.reduce(0) { running, child in
                    running + countFiles(in: child)
                }
            }

            // The recursion mirrors the data: a folder's file count is
            // the sum of each child's file count. Tree + recursion = match.
            """
        )
    )

    static let graphsSocialDistance = Lesson(
        id: "gr.social-distance",
        pattern: .graphs,
        title: "Are You Connected to a Stranger?",
        scenario: "You're building 'mutual friends' on a social app. Given the user and someone they don't know, how many degrees of friendship separate them — and what's the shortest connection? That's a graph search problem.",
        story: """
        A social network is a graph. Every person is a node. Every friendship is an edge connecting two people. Unlike a tree, a graph has no root — it's a web. Two people might be connected through many paths, or not at all.

        To find the shortest connection between A and Z, you do a breadth-first search:
        1. Start at A. Mark it 'seen.'
        2. Visit all of A's friends. Mark them seen.
        3. Visit all THEIR unseen friends.
        4. Keep going level by level until you find Z, or run out.

        The first time BFS reaches Z is the shortest path. That guarantee is what makes BFS the go-to answer for 'degrees of separation.'

        Two gotchas to watch for:
        - Cycles. Graphs loop. If you don't track who you've seen, you'll go around forever. A simple Set of visited nodes prevents that.
        - Direction. Some edges are one-way (Twitter follows). Some are mutual (Facebook friendships). Read the problem carefully.

        Graphs power so much: Google Maps (cities + roads), web search (pages + links), package managers (libraries + dependencies), recommendation engines (users + products), even garbage collectors (objects + references).
        """,
        realWorldUses: [
            "Social networks — mutual friends, friends-of-friends, degrees of separation",
            "Navigation apps — shortest path between two locations",
            "Web crawlers — discover pages by following links",
            "Recommendation systems — 'people who liked X also liked Y'",
            "Package dependency resolution — npm, pip, Swift Package Manager",
            "Garbage collectors — find which objects are still reachable"
        ],
        visualizer: .graphBFS(
            nodes: [
                GraphNode(id: "alex", name: "Alex", x: 0.5, y: 0.10),
                GraphNode(id: "sam", name: "Sam", x: 0.18, y: 0.34),
                GraphNode(id: "jordan", name: "Jordan", x: 0.82, y: 0.34),
                GraphNode(id: "riley", name: "Riley", x: 0.28, y: 0.66),
                GraphNode(id: "pat", name: "Pat", x: 0.72, y: 0.66),
                GraphNode(id: "casey", name: "Casey", x: 0.5, y: 0.92)
            ],
            edges: [
                GraphEdge(from: "alex", to: "sam"),
                GraphEdge(from: "alex", to: "jordan"),
                GraphEdge(from: "sam", to: "riley"),
                GraphEdge(from: "jordan", to: "pat"),
                GraphEdge(from: "riley", to: "pat"),
                GraphEdge(from: "riley", to: "casey")
            ],
            startID: "alex",
            targetID: "casey"
        ),
        problems: [
            Problem(
                id: "gr.social-distance.q1",
                kind: .predictNextStep,
                prompt: "BFS has finished visiting everyone at depth 2 (friends-of-friends). The target still isn't found. What does BFS visit next?",
                choices: [
                    Choice(id: "a", text: "Depth 3 — friends-of-friends-of-friends, the next outer ring.", isCorrect: true),
                    Choice(id: "b", text: "Anyone, in any order — BFS picks randomly after depth 2.", isCorrect: false),
                    Choice(id: "c", text: "Nobody — if the target isn't in 2 hops, BFS gives up.", isCorrect: false),
                    Choice(id: "d", text: "Depth 1 again — to re-check connections.", isCorrect: false)
                ],
                explanation: "BFS expands outward one ring at a time. Once every depth-2 node has been visited, the queue holds their unseen neighbors — which are exactly the depth-3 nodes. BFS keeps going until it finds the target or exhausts the connected component."
            ),
            Problem(
                id: "gr.social-distance.q2",
                kind: .multipleChoiceLogic,
                prompt: "Why does BFS need to track which nodes it has already visited?",
                choices: [
                    Choice(id: "a", text: "Tracking visits makes BFS faster on large graphs but isn't required for correctness.", isCorrect: false),
                    Choice(id: "b", text: "To avoid revisiting nodes through cycles — without the seen set, BFS can loop forever.", isCorrect: true),
                    Choice(id: "c", text: "So BFS knows the path back to the start.", isCorrect: false),
                    Choice(id: "d", text: "Because graphs are inherently slow to read.", isCorrect: false)
                ],
                explanation: "Graphs can have cycles. If A is friends with B and B is friends with A, you'd enqueue B from A, then A from B, then B again, forever. A Set of visited nodes lets BFS skip anything it's already enqueued and guarantees each node is processed at most once."
            )
        ],
        interview: InterviewExplanation(
            whyItWorks: "BFS uses a queue. The start node goes in; you dequeue, then enqueue all unseen neighbors. Because nodes come out in the order they went in, BFS visits every level fully before stepping to the next level. That's why the first time it reaches the target, the path is the shortest in the unweighted case.",
            timeComplexity: "O(V + E) — every vertex and every edge is examined at most once. On a sparse friend graph, that's effectively linear in the reachable part.",
            spaceComplexity: "O(V) — the visited set plus the queue are both bounded by the number of nodes.",
            versusBruteForce: "DFS would also find a path, but not necessarily the shortest one — you might dive deep down a branch and find a long route to the target before backtracking. BFS guarantees shortest path on an unweighted graph. For weighted edges (different costs per hop), upgrade to Dijkstra — same idea, but a priority queue replaces the plain queue.",
            swiftSnippet: """
            func degreesBetween(
                _ start: String,
                and target: String,
                in friends: [String: Set<String>]
            ) -> Int? {
                var queue: [(person: String, depth: Int)] = [(start, 0)]
                var seen: Set<String> = [start]

                while !queue.isEmpty {
                    let (person, depth) = queue.removeFirst()
                    if person == target { return depth }
                    for friend in friends[person] ?? [] where !seen.contains(friend) {
                        seen.insert(friend)
                        queue.append((friend, depth + 1))
                    }
                }
                return nil   // not connected
            }

            // BFS guarantees: the first time we see `target`,
            // we've reached it via the shortest path.
            """
        )
    )

    static let mergeIntervalsCalendar = Lesson(
        id: "mi.calendar-merge",
        pattern: .mergeIntervals,
        title: "Finding Free Time on Your Calendar",
        scenario: "You're building a 'find me a 30-minute slot' feature for a calendar app. To know when the user is free, you first need to know when they're busy — and when two meetings overlap or run back-to-back, they form one solid block of busy time.",
        story: """
        Your calendar is a list of meeting ranges. [9:00–10:30], [10:00–11:00], [13:00–14:30]. Notice the first two overlap — to the user they look like one solid busy block from 9:00 to 11:00, not two separate ones with a sliver of gap in between.

        Merge Intervals turns a list of possibly-overlapping ranges into a list of clean, non-overlapping ranges. The trick is two-part:

        1. Sort by start time. Now any two intervals that could overlap have to be adjacent in the list — there's no way for two intervals to overlap if a third interval starts somewhere between them.
        2. Walk left to right, keeping a 'current merged' block. For each new interval:
           - If it overlaps the current block (its start ≤ current end), extend the current end to max(current end, new end).
           - Otherwise the gap means a clean break. Save the current block and start a new one from this interval.
        3. After the loop, save whatever you were building.

        One pass through sorted data. O(n log n) total — dominated by the sort. The merging pass itself is O(n).

        The same shape shows up anywhere ranges might overlap: meeting calendars, CPU time slices, log session windows, even merging insurance coverage periods. The work is always the same — collapse a messy list of ranges into a clean one.
        """,
        realWorldUses: [
            "Calendar apps — finding free time between meetings",
            "CPU and resource scheduling — collapsing busy time slices",
            "Log analytics — active user session windows",
            "Genomics — combining overlapping DNA sequence ranges",
            "Map regions and zoning — combining adjacent areas",
            "Billing and insurance — combining coverage periods that touch"
        ],
        visualizer: .mergeIntervals(intervals: [
            Interval(id: "standup", start: 9.0, end: 10.5, label: "Standup"),
            Interval(id: "design", start: 10.0, end: 11.0, label: "Design"),
            Interval(id: "lunch", start: 13.0, end: 14.5, label: "Lunch"),
            Interval(id: "review", start: 14.0, end: 15.0, label: "Review"),
            Interval(id: "wrap", start: 16.0, end: 17.0, label: "Wrap")
        ]),
        problems: [
            Problem(
                id: "mi.calendar-merge.q1",
                kind: .predictNextStep,
                prompt: "Current merged block is [9:00–11:00]. The next interval is [10:30–12:00]. What happens?",
                choices: [
                    Choice(id: "a", text: "Merge it in — extend the current block to [9:00–12:00] because 10:30 ≤ 11:00.", isCorrect: true),
                    Choice(id: "b", text: "Skip it — the new interval overlaps an existing one, so it's a duplicate.", isCorrect: false),
                    Choice(id: "c", text: "Start a new block — overlapping intervals always begin a new block.", isCorrect: false),
                    Choice(id: "d", text: "Throw an error — overlapping intervals aren't allowed.", isCorrect: false)
                ],
                explanation: "When the new interval's start (10:30) is ≤ the current block's end (11:00), they overlap. The fix is to extend the current end to max(11:00, 12:00) = 12:00. The merged block grows; no new block is started."
            ),
            Problem(
                id: "mi.calendar-merge.q2",
                kind: .multipleChoiceLogic,
                prompt: "Why does Merge Intervals sort by start time first?",
                choices: [
                    Choice(id: "a", text: "Because the final answer must be returned in sorted order.", isCorrect: false),
                    Choice(id: "b", text: "Sorting puts potentially-overlapping intervals next to each other so one left-to-right pass catches every overlap.", isCorrect: true),
                    Choice(id: "c", text: "Sorting drops the time complexity from O(n) to O(1).", isCorrect: false),
                    Choice(id: "d", text: "Intervals can't be compared without first being sorted.", isCorrect: false)
                ],
                explanation: "After sorting by start time, any overlap is between adjacent items in the list — no interval can 'hide' another in between. That's what lets one linear sweep with a single 'current' interval cover every possible merge."
            )
        ],
        interview: InterviewExplanation(
            whyItWorks: "Sort by start time, then sweep. Maintain a 'current merged' interval. For each new interval, either its start ≤ current end (overlap → extend current's end) or there's a gap (save current, start new). Because the input is sorted, the only intervals that could overlap with the new one are the chain you've already built — so checking just the latest merged block is sufficient.",
            timeComplexity: "O(n log n) — dominated by the sort. The merging sweep is O(n).",
            spaceComplexity: "O(n) for the output list. If you can mutate the sorted input in place, the merging itself is O(1) extra space.",
            versusBruteForce: "Brute force checks every pair O(n²) and may need multiple passes to fully merge transitive overlaps. Sort + single sweep is asymptotically better and far simpler to write — a 'current' variable and a results list, that's it.",
            swiftSnippet: """
            struct Interval {
                let start: Int
                let end: Int
            }

            func merge(_ intervals: [Interval]) -> [Interval] {
                guard !intervals.isEmpty else { return [] }
                let sorted = intervals.sorted { $0.start < $1.start }

                var merged: [Interval] = [sorted[0]]

                for next in sorted.dropFirst() {
                    let last = merged.last!
                    if next.start <= last.end {
                        // Overlap — extend the current merged interval's end.
                        merged[merged.count - 1] = Interval(
                            start: last.start,
                            end: max(last.end, next.end)
                        )
                    } else {
                        // Gap — start a new merged interval.
                        merged.append(next)
                    }
                }
                return merged
            }
            """
        )
    )

    static let slidingWindowFraud = Lesson(
        id: "sw.fraud-burst",
        pattern: .slidingWindow,
        title: "Spotting Fraud in a Stream of Transactions",
        scenario: "You're on the payments team. Cards transact thousands of times per second, and your job is to flag suspicious bursts of spend.",
        story: """
        A user's card normally averages $30 per swipe. Then in a 60-second window it racks up $4,000 across nine merchants. That's the pattern your fraud team wants surfaced — the highest total spent inside any rolling window of N transactions.

        The naive way: for every starting index, sum the next K values. That's O(n·k) — every window recomputes work the previous window already did.

        The Sliding Window insight: when the window slides forward by one, only two things change. One value enters at the front, one value leaves at the back. So the new sum = old sum + entering − leaving. Constant work per step. O(n) total.

        That's the whole pattern: reuse the work the previous window already did.
        """,
        realWorldUses: [
            "Rate limiting — max requests per minute per API key",
            "Streaming analytics — rolling averages and percentiles",
            "Fraud detection — bursts of unusual activity",
            "Session tracking — active users in the last N minutes"
        ],
        visualizer: .slidingWindow(
            values: [4, 2, 9, 7, 1, 6, 3, 8, 5],
            windowSize: 3,
            unit: "$"
        ),
        problems: [
            Problem(
                id: "sw.fraud-burst.q1",
                kind: .predictNextStep,
                prompt: "Window covers indices [2, 3, 4] with values [9, 7, 1] — current sum is 17. After the window slides one step right, what's the new sum?",
                choices: [
                    Choice(id: "a", text: "14  (subtract 9, add 6)", isCorrect: true),
                    Choice(id: "b", text: "23  (add 6 to 17)", isCorrect: false),
                    Choice(id: "c", text: "17  (no change)", isCorrect: false),
                    Choice(id: "d", text: "8   (recompute from scratch)", isCorrect: false)
                ],
                explanation: "Sliding the window right drops the leftmost value (9) and adds the next value on the right (6). New sum = 17 − 9 + 6 = 14. You don't recompute from scratch — that's the whole point."
            ),
            Problem(
                id: "sw.fraud-burst.q2",
                kind: .multipleChoiceLogic,
                prompt: "Why is the sliding window approach O(n) instead of O(n·k)?",
                choices: [
                    Choice(id: "a", text: "Because n is always smaller than k in practice.", isCorrect: false),
                    Choice(id: "b", text: "Because each element enters the window once and leaves once — constant work per slide.", isCorrect: true),
                    Choice(id: "c", text: "Because we skip every k-th element.", isCorrect: false),
                    Choice(id: "d", text: "Because we use a hash map to cache window sums.", isCorrect: false)
                ],
                explanation: "Every element gets added when it enters the window and subtracted when it leaves — that's two visits per element across the whole array. Total work scales with n, not n·k."
            )
        ],
        interview: InterviewExplanation(
            whyItWorks: "Adjacent windows share k−1 elements. Recomputing the full sum throws away that overlap. Sliding window keeps a running total and updates it in O(1) per step by adding the entering element and subtracting the leaving one.",
            timeComplexity: "O(n) — one pass through the array, constant work per element.",
            spaceComplexity: "O(1) — just the running sum and the running max.",
            versusBruteForce: "Brute force computes each window's sum independently in O(k), giving O(n·k) total. For a 1M-element stream with k=60, that's 60M ops vs 1M ops — a 60× speedup that gets larger as k grows.",
            swiftSnippet: """
            func maxWindowSum(_ values: [Int], windowSize k: Int) -> Int {
                guard values.count >= k else { return values.reduce(0, +) }
                var windowSum = values.prefix(k).reduce(0, +)
                var maxSum = windowSum
                for i in k..<values.count {
                    windowSum += values[i] - values[i - k]
                    maxSum = max(maxSum, windowSum)
                }
                return maxSum
            }
            """
        )
    )

    static let arrayTrackLookup = Lesson(
        id: "arr.track-lookup",
        pattern: .arrays,
        title: "Jumping Straight to Track 7",
        scenario: "You're building a music player. The user knows the track number they want. The array lets you go straight there — no skipping through every track on the way.",
        story: """
        An array is a row of numbered boxes. The first box is index 0, the next is index 1, and so on. Each box holds one value.

        The thing that makes arrays special: you can reach any box directly. To get track 7, you don't visit tracks 0 through 6 first. You say "give me index 6" (arrays count from 0) and you're there. One step.

        That's called random access. It works because every box in an array is the same size and sits right next to the previous one. The runtime knows where the array starts in memory and how big each box is, so it does the math: "start + 6 × box-size" → that's where track 7 lives. One multiplication, one read.

        Compare that to walking the array one element at a time. For 1,000 tracks, asking by index is still one step. Walking can be up to 1,000.

        Random access is the property arrays are built around. When you know the position, an array gives you the value instantly.
        """,
        realWorldUses: [
            "Track lists, video chapter markers, page numbers",
            "Pixel grids — pixels[x][y] reads any single pixel directly",
            "Game tile maps — board[row][col]",
            "Lookup tables — month name from a month number",
            "Anywhere 'position' is meaningful and known"
        ],
        visualizer: .directAccess(
            items: [
                DirectAccessItem(id: "intro", title: "Intro"),
                DirectAccessItem(id: "verse-1", title: "Verse 1"),
                DirectAccessItem(id: "chorus-1", title: "Chorus"),
                DirectAccessItem(id: "verse-2", title: "Verse 2"),
                DirectAccessItem(id: "bridge", title: "Bridge"),
                DirectAccessItem(id: "solo", title: "Solo"),
                DirectAccessItem(id: "chorus-2", title: "Chorus (reprise)"),
                DirectAccessItem(id: "outro", title: "Outro")
            ],
            queries: [
                DirectAccessQuery(id: "q1", index: 0, label: "Play track 0 — the very first one"),
                DirectAccessQuery(id: "q2", index: 5, label: "Skip to track 5 — the Solo"),
                DirectAccessQuery(id: "q3", index: 7, label: "Jump to track 7 — the Outro")
            ]
        ),
        problems: [
            Problem(
                id: "arr.track-lookup.q1",
                kind: .predictNextStep,
                prompt: "Your album array has 100 tracks. You want track 73. How many tracks does the array touch to give you the answer?",
                choices: [
                    Choice(id: "a", text: "73 — it walks from track 0 forward.", isCorrect: false),
                    Choice(id: "b", text: "1 — it jumps straight to the slot at index 72.", isCorrect: true),
                    Choice(id: "c", text: "50 — it splits the array in half each time (binary search).", isCorrect: false),
                    Choice(id: "d", text: "100 — it scans the whole array.", isCorrect: false)
                ],
                explanation: "Arrays know where each slot lives in memory: start address + index × element size. Pulling track 73 (index 72) is one address calculation and one read. The size of the array doesn't matter — index lookup is always one step."
            ),
            Problem(
                id: "arr.track-lookup.q2",
                kind: .multipleChoiceLogic,
                prompt: "Why doesn't the array have to look at the elements *before* the one you ask for?",
                choices: [
                    Choice(id: "a", text: "It memorizes every element's position the first time you access it.", isCorrect: false),
                    Choice(id: "b", text: "Elements are stored in sorted order so it can binary search.", isCorrect: false),
                    Choice(id: "c", text: "Every element is the same size and packed next to the previous one, so the runtime can compute exactly where index i lives.", isCorrect: true),
                    Choice(id: "d", text: "Modern CPUs run array reads in parallel.", isCorrect: false)
                ],
                explanation: "Arrays are contiguous, fixed-size slots. With the start address and the slot size, the runtime jumps straight to any index by arithmetic — no scanning needed. That's what makes random access O(1)."
            )
        ],
        interview: InterviewExplanation(
            whyItWorks: "An array is a single contiguous block of memory holding equal-sized slots. To find element i, the runtime computes 'base address + i × slot size' and reads that location. One multiplication, one load — no scanning, no comparison, no walk.",
            timeComplexity: "Read or write by index: O(1). Independent of array size.",
            spaceComplexity: "O(n) — one slot per element.",
            versusBruteForce: "Without an array, finding the i-th item in a linked list means following i pointers, one at a time. That's O(i) — and for the last element of a 1M-item list, it's 1M pointer hops vs. one array read.",
            swiftSnippet: """
            let tracks = [
                "Intro", "Verse 1", "Chorus",
                "Verse 2", "Bridge", "Solo",
                "Chorus (reprise)", "Outro"
            ]

            // Index lookup is O(1) — same speed at index 0 or index 7.
            let solo = tracks[5]
            let outro = tracks[7]

            // The cost is in the subscript itself, not in how big tracks is.
            // tracks.count could be 8 or 8,000,000 — tracks[i] is one step.
            """
        )
    )

    static let arrayRecentlyPlayed = Lesson(
        id: "arr.recently-played",
        pattern: .arrays,
        title: "Bumping a Song to the Top of Recently Played",
        scenario: "You're building Apple Music's 'Recently Played' shelf. Every time the user plays a song, that song jumps to the top — and everything below it slides down by one slot.",
        story: """
        Recently Played feels effortless as a user: tap a song, it appears at the top of the list. Under the hood, it's two array operations stitched together.

        Find the song's current position. Remove it from that slot — every element after it shifts up by one. Insert it at index 0 — every element shifts back down. For a 50-song list, that's a few dozen memory moves per play. Microseconds. Totally fine.

        But the cost reveals what arrays are good at and bad at.

        Good: random access. `arr[1000]` is no slower than `arr[1]`. The runtime computes "base address + index × element size" and reads one location. Constant time, regardless of the index.

        Bad: inserting or removing in the middle. Every element on one side of the gap has to move.

        When you need fast inserts in the middle, you reach past arrays — to linked lists (no shifts, but no random access) or deques (O(1) at both ends). The pattern: arrays trade middle-insert cost for random-access speed. Pick the data structure that matches the operations you do most.
        """,
        realWorldUses: [
            "Recently Played / Recently Viewed lists",
            "Drag-to-reorder UI — todo apps, file managers, browser tabs",
            "Leaderboard updates after a score change",
            "Image and video frame buffers — random access by index",
            "The backing store under almost every other data structure"
        ],
        visualizer: .arrayReorder(
            items: [
                ReorderItem(id: "anti-hero", title: "Anti-Hero", subtitle: "Taylor Swift"),
                ReorderItem(id: "as-it-was", title: "As It Was", subtitle: "Harry Styles"),
                ReorderItem(id: "bad-habit", title: "Bad Habit", subtitle: "Steve Lacy"),
                ReorderItem(id: "flowers", title: "Flowers", subtitle: "Miley Cyrus"),
                ReorderItem(id: "levitating", title: "Levitating", subtitle: "Dua Lipa"),
                ReorderItem(id: "sunflower", title: "Sunflower", subtitle: "Post Malone"),
                ReorderItem(id: "watermelon-sugar", title: "Watermelon Sugar", subtitle: "Harry Styles")
            ],
            moves: [
                ReorderMove(itemID: "sunflower", label: "User plays 'Sunflower' (5 shifts)"),
                ReorderMove(itemID: "watermelon-sugar", label: "User plays 'Watermelon Sugar' (6 shifts)"),
                ReorderMove(itemID: "as-it-was", label: "User plays 'As It Was' (2 shifts)")
            ]
        ),
        problems: [
            Problem(
                id: "arr.recently-played.q1",
                kind: .predictNextStep,
                prompt: "Your array holds [A, B, C, D, E, F] in that order. The user plays 'E'. How many of the other songs have to shift positions?",
                choices: [
                    Choice(id: "a", text: "1  — only E moves", isCorrect: false),
                    Choice(id: "b", text: "4  — A, B, C, D each shift down by one", isCorrect: true),
                    Choice(id: "c", text: "5  — every other song shifts", isCorrect: false),
                    Choice(id: "d", text: "0  — arrays just rewrite the index in place", isCorrect: false)
                ],
                explanation: "E was at index 4. Pulling it out leaves a gap that A, B, C, D fill by sliding right. Then E goes in at index 0. The four songs that were in front of E each move down one slot — 4 shifts. F was already behind E and doesn't move."
            ),
            Problem(
                id: "arr.recently-played.q2",
                kind: .multipleChoiceLogic,
                prompt: "Why is reading `arr[1000]` just as fast as reading `arr[1]`?",
                choices: [
                    Choice(id: "a", text: "The CPU caches every array element, so any access is a cache hit.", isCorrect: false),
                    Choice(id: "b", text: "The array is internally sorted by access frequency.", isCorrect: false),
                    Choice(id: "c", text: "Arrays sit on contiguous memory — `arr[i]` is one multiplication (base + i × element size) and one read.", isCorrect: true),
                    Choice(id: "d", text: "The compiler unrolls the access into a tight loop.", isCorrect: false)
                ],
                explanation: "Arrays guarantee contiguous storage. Given the start address and the element size, the runtime can jump straight to any index in constant time. That O(1) random access is the property arrays trade *for* — and the reason middle-insert costs O(n)."
            )
        ],
        interview: InterviewExplanation(
            whyItWorks: "Arrays sit on a contiguous block of memory with elements of a fixed size. The runtime knows the start address and the element size, so `arr[i]` is a single multiplication and a single load — O(1) regardless of i. The cost lives on the other side: middle inserts and deletes have to shift every element on one side of the gap.",
            timeComplexity: "Random access O(1). Append at the end (amortized) O(1). Insert or remove in the middle O(n).",
            spaceComplexity: "O(n) — one slot per element, plus a little overhead for the dynamic-array growth strategy.",
            versusBruteForce: "Arrays aren't really compared against a brute-force approach — they're compared against other data structures. Linked list: O(1) middle insert, O(n) random access. Hash table: O(1) lookup by key, no order. Deque: O(1) at both ends but slower middle access. Pick the structure whose strengths match the operation you do most.",
            swiftSnippet: """
            var recentlyPlayed: [String] = [
                "Anti-Hero", "As It Was", "Bad Habit",
                "Flowers", "Levitating", "Sunflower"
            ]

            func play(_ song: String) {
                if let idx = recentlyPlayed.firstIndex(of: song) {
                    recentlyPlayed.remove(at: idx)    // O(n) — shifts everything after idx
                }
                recentlyPlayed.insert(song, at: 0)    // O(n) — shifts everything down by one
            }

            // Swift Array complexities:
            //   subscript get/set:  O(1)
            //   append:             O(1) amortized
            //   insert(at:) / remove(at:): O(n) when not at the end
            """
        )
    )
}
