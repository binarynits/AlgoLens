import SwiftUI

struct LaunchGate<Content: View>: View {
    @ViewBuilder var content: () -> Content

    @State private var isSplashing = true

    var body: some View {
        ZStack {
            content()

            if isSplashing {
                SplashView { dismissSplash() }
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
    }

    private func dismissSplash() {
        withAnimation(.easeInOut(duration: 0.45)) {
            isSplashing = false
        }
    }
}

private struct SplashView: View {
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var circleIn = false
    @State private var bracketsIn = false
    @State private var pupilIn = false
    @State private var textIn = false

    private let brandTop = Color(red: 0.49, green: 0.47, blue: 0.93)
    private let brandBottom = Color(red: 0.39, green: 0.38, blue: 0.86)
    private let pupil = Color(red: 0.34, green: 0.32, blue: 0.84)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [brandTop, brandBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                LensMark(
                    circleIn: circleIn,
                    bracketsIn: bracketsIn,
                    pupilIn: pupilIn,
                    pupilColor: pupil
                )
                .frame(width: 144, height: 144)

                VStack(spacing: 8) {
                    Text("AlgoLens")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Patterns, not problems.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .opacity(textIn ? 1 : 0)
                .offset(y: textIn ? 0 : 12)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onFinish() }
        .task { await runAnimation() }
    }

    private func runAnimation() async {
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.3)) {
                circleIn = true; bracketsIn = true; pupilIn = true; textIn = true
            }
            try? await Task.sleep(for: .seconds(1.4))
            onFinish()
            return
        }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) { circleIn = true }
        try? await Task.sleep(for: .milliseconds(120))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) { bracketsIn = true }
        try? await Task.sleep(for: .milliseconds(160))
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { pupilIn = true }
        try? await Task.sleep(for: .milliseconds(140))
        withAnimation(.easeOut(duration: 0.45)) { textIn = true }
        try? await Task.sleep(for: .milliseconds(1100))
        onFinish()
    }
}

private enum BracketCorner {
    case topLeading, topTrailing, bottomLeading, bottomTrailing

    var alignment: Alignment {
        switch self {
        case .topLeading: .topLeading
        case .topTrailing: .topTrailing
        case .bottomLeading: .bottomLeading
        case .bottomTrailing: .bottomTrailing
        }
    }

    func entryOffset(_ d: CGFloat) -> CGSize {
        switch self {
        case .topLeading: CGSize(width: -d, height: -d)
        case .topTrailing: CGSize(width: d, height: -d)
        case .bottomLeading: CGSize(width: -d, height: d)
        case .bottomTrailing: CGSize(width: d, height: d)
        }
    }
}

private struct LensMark: View {
    let circleIn: Bool
    let bracketsIn: Bool
    let pupilIn: Bool
    let pupilColor: Color

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let bracketLen = size * 0.34
            let bracketThickness = size * 0.10
            let bracketCorner = size * 0.06
            let circleSize = size * 0.62
            let pupilSize = circleSize * 0.42
            let highlightSize = pupilSize * 0.32

            ZStack {
                bracketView(.topLeading, length: bracketLen, thickness: bracketThickness, corner: bracketCorner)
                bracketView(.topTrailing, length: bracketLen, thickness: bracketThickness, corner: bracketCorner)
                bracketView(.bottomLeading, length: bracketLen, thickness: bracketThickness, corner: bracketCorner)
                bracketView(.bottomTrailing, length: bracketLen, thickness: bracketThickness, corner: bracketCorner)

                Circle()
                    .fill(.white)
                    .frame(width: circleSize, height: circleSize)
                    .scaleEffect(circleIn ? 1 : 0.35)
                    .opacity(circleIn ? 1 : 0)

                ZStack(alignment: .topLeading) {
                    Circle()
                        .fill(pupilColor)
                        .frame(width: pupilSize, height: pupilSize)
                    Circle()
                        .fill(.white.opacity(0.32))
                        .frame(width: highlightSize, height: highlightSize)
                        .offset(x: pupilSize * 0.16, y: pupilSize * 0.14)
                }
                .scaleEffect(pupilIn ? 1 : 0.2)
                .opacity(pupilIn ? 1 : 0)
            }
            .frame(width: size, height: size)
        }
    }

    private func bracketView(
        _ corner: BracketCorner,
        length: CGFloat,
        thickness: CGFloat,
        corner cornerRadius: CGFloat
    ) -> some View {
        let entry = corner.entryOffset(10)
        return Bracket(length: length, thickness: thickness, cornerRadius: cornerRadius, corner: corner)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: corner.alignment)
            .opacity(bracketsIn ? 1 : 0)
            .offset(bracketsIn ? .zero : entry)
    }
}

private struct Bracket: View {
    let length: CGFloat
    let thickness: CGFloat
    let cornerRadius: CGFloat
    let corner: BracketCorner

    var body: some View {
        ZStack(alignment: corner.alignment) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .frame(width: length, height: thickness)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .frame(width: thickness, height: length)
        }
        .frame(width: length, height: length, alignment: corner.alignment)
    }
}
