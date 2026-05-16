import SwiftUI

struct StackVisualizer: View {
    let actions: [StackAction]
    let accent: Color

    @State private var stack: [StackItem] = []
    @State private var totalPushes: Int = 0
    @State private var totalPops: Int = 0

    private struct StackItem: Identifiable, Hashable {
        let id: UUID
        let action: StackAction
    }

    var body: some View {
        VStack(spacing: 14) {
            statsRow
            stackColumn
            pushSection
            HStack(spacing: 8) {
                popButton
                resetButton
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatChip(label: "Stack size", value: "\(stack.count)", icon: "square.stack.3d.up.fill", tint: accent)
            StatChip(label: "Pushes", value: "\(totalPushes)", icon: "plus.circle.fill", tint: .green)
            StatChip(label: "Pops", value: "\(totalPops)", icon: "minus.circle.fill", tint: .orange)
        }
    }

    private var stackColumn: some View {
        VStack(spacing: 6) {
            if stack.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "tray")
                        .foregroundStyle(.secondary)
                    Text("Stack is empty. Push an action to start.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(Array(stack.reversed().enumerated()), id: \.element.id) { idx, item in
                    StackCard(
                        action: item.action,
                        tint: tint(for: item.action),
                        isTop: idx == 0
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
            }
        }
        .frame(minHeight: 72)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.78), value: stack)
    }

    private var pushSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PUSH AN ACTION")
                .font(.caption2.weight(.bold))
                .tracking(0.6)
                .foregroundStyle(.secondary)

            let columns = [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ]
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(actions) { action in
                    PushButton(action: action, tint: tint(for: action)) {
                        push(action)
                    }
                }
            }
        }
    }

    private var popButton: some View {
        Button { pop() } label: {
            Label("Undo (Pop)", systemImage: "arrow.uturn.backward")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.borderedProminent)
        .tint(accent)
        .disabled(stack.isEmpty)
    }

    private var resetButton: some View {
        Button { reset() } label: {
            Image(systemName: "arrow.counterclockwise")
                .font(.subheadline.weight(.semibold))
                .frame(width: 40, height: 32)
        }
        .buttonStyle(.bordered)
        .disabled(stack.isEmpty && totalPushes == 0)
    }

    private func push(_ action: StackAction) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            stack.append(StackItem(id: UUID(), action: action))
            totalPushes += 1
        }
    }

    private func pop() {
        guard !stack.isEmpty else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
            stack.removeLast()
            totalPops += 1
        }
    }

    private func reset() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            stack.removeAll()
            totalPushes = 0
            totalPops = 0
        }
    }

    private func tint(for action: StackAction) -> Color {
        switch action.id {
        case "line": return .blue
        case "rect": return .orange
        case "color": return .purple
        case "erase": return .teal
        default: return .gray
        }
    }
}

private struct StackCard: View {
    let action: StackAction
    let tint: Color
    let isTop: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: action.systemIcon)
                .font(.callout)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(Circle().fill(tint.opacity(0.16)))

            Text(action.label)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Spacer(minLength: 0)

            if isTop {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left")
                        .font(.caption2.weight(.bold))
                    Text("TOP")
                        .font(.caption2.weight(.bold))
                        .tracking(0.6)
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.15), in: Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(tint.opacity(isTop ? 0.55 : 0.25), lineWidth: isTop ? 1.5 : 1)
        )
    }
}

private struct PushButton: View {
    let action: StackAction
    let tint: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: action.systemIcon)
                    .foregroundStyle(tint)
                Text(action.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(tint.opacity(0.30), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct StatChip: View {
    let label: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.caption)
            VStack(alignment: .leading, spacing: 0) {
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: 0))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}
