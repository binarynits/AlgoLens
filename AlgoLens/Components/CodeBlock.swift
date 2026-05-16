import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct CodeBlock: View {
    let code: String
    var language: String = "Swift"

    @State private var didCopy = false

    private let theme: CodeTheme = .dark

    private var lines: [String] {
        code.components(separatedBy: "\n")
    }

    private var gutterWidth: CGFloat {
        let digits = String(max(lines.count, 1)).count
        return CGFloat(max(digits, 2)) * 8 + 4
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
                .overlay(Color.white.opacity(0.06))
            codeArea
        }
        .background(theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.caption)
                .foregroundStyle(theme.text.opacity(0.55))
            Text(language)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.text)
            Spacer(minLength: 0)
            Button(action: copy) {
                Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                    .font(.subheadline)
                    .foregroundStyle(didCopy ? Color.green : theme.text.opacity(0.70))
                    .frame(width: 32, height: 28)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(didCopy ? "Copied" : "Copy code")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var codeArea: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(lines.enumerated()), id: \.offset) { idx, line in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("\(idx + 1)")
                            .foregroundStyle(theme.text.opacity(0.28))
                            .frame(width: gutterWidth, alignment: .trailing)
                            .monospacedDigit()
                        Text(AttributedString.swiftHighlighted(line, theme: theme))
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .font(.system(.footnote, design: .monospaced))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
    }

    private func copy() {
        #if canImport(UIKit)
        UIPasteboard.general.string = code
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        #endif
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            didCopy = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            withAnimation(.easeOut(duration: 0.3)) { didCopy = false }
        }
    }
}

struct CodeTheme: Sendable {
    let background: Color
    let text: Color
    let keyword: Color
    let type: Color
    let function: Color
    let property: Color
    let number: Color
    let string: Color
    let comment: Color

    // Xcode-default-dark inspired palette.
    static let dark = CodeTheme(
        background: Color(red: 0.12, green: 0.12, blue: 0.14),
        text: Color(red: 0.93, green: 0.93, blue: 0.95),
        keyword: Color(red: 0.988, green: 0.373, blue: 0.639),   // pink / magenta
        type: Color(red: 0.816, green: 0.659, blue: 1.000),       // lavender
        function: Color(red: 0.404, green: 0.718, blue: 0.643),   // teal
        property: Color(red: 0.255, green: 0.631, blue: 0.753),   // blue-cyan
        number: Color(red: 0.816, green: 0.749, blue: 0.412),     // cream-yellow
        string: Color(red: 0.988, green: 0.416, blue: 0.365),     // red-orange
        comment: Color(red: 0.424, green: 0.475, blue: 0.525)     // muted grey-green
    )
}

extension AttributedString {
    static func swiftHighlighted(_ source: String, theme: CodeTheme) -> AttributedString {
        var attr = AttributedString(source)
        attr.foregroundColor = theme.text

        // Order matters: later patterns overwrite earlier ones where they overlap.
        // Lowest priority first; comments win over everything inside them.
        apply(&attr, in: source, pattern: #"\b[0-9]+(?:\.[0-9]+)?\b"#, color: theme.number)
        apply(&attr, in: source, pattern: #""(?:[^"\\]|\\.)*""#, color: theme.string)
        apply(&attr, in: source, pattern: #"\b[A-Z][A-Za-z0-9_]*\b"#, color: theme.type)
        applyGroup(&attr, in: source, pattern: #"\.([a-z_][A-Za-z0-9_]*)\b(?!\s*\()"#, group: 1, color: theme.property)
        applyGroup(&attr, in: source, pattern: #"\b([a-z_][A-Za-z0-9_]*)\b(?=\s*\()"#, group: 1, color: theme.function)
        apply(&attr, in: source, pattern: keywordsPattern, color: theme.keyword)
        apply(&attr, in: source, pattern: #"//[^\n]*"#, color: theme.comment)

        return attr
    }

    private static let keywordsPattern = #"\b(class|func|let|var|for|in|if|else|return|guard|while|do|struct|enum|case|import|init|self|static|true|false|nil|throws|throw|try|async|await|defer|where|extension|protocol|public|private|fileprivate|internal|open|switch|break|continue|repeat|as|is|inout|mutating|some|any|typealias|associatedtype|deinit|subscript|convenience|final|override|required|lazy|weak|unowned|@escaping|@autoclosure|@MainActor)\b"#

    private static func apply(_ attr: inout AttributedString, in source: String, pattern: String, color: Color) {
        applyGroup(&attr, in: source, pattern: pattern, group: 0, color: color)
    }

    private static func applyGroup(_ attr: inout AttributedString, in source: String, pattern: String, group: Int, color: Color) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let fullRange = NSRange(source.startIndex..<source.endIndex, in: source)
        regex.enumerateMatches(in: source, range: fullRange) { match, _, _ in
            guard let match else { return }
            guard group < match.numberOfRanges else { return }
            let nsRange = match.range(at: group)
            guard nsRange.location != NSNotFound else { return }
            guard let stringRange = Range(nsRange, in: source) else { return }
            guard let lower = AttributedString.Index(stringRange.lowerBound, within: attr),
                  let upper = AttributedString.Index(stringRange.upperBound, within: attr) else { return }
            attr[lower..<upper].foregroundColor = color
        }
    }
}
