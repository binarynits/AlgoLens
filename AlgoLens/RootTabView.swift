import SwiftUI
import SwiftData

struct RootTabView: View {
    var body: some View {
        TabView {
            LearnTabView()
                .tabItem { Label("Learn", systemImage: "book.fill") }

            PracticeTabView()
                .tabItem { Label("Practice", systemImage: "pencil.and.list.clipboard") }

            ProgressTabView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: UserProgress.self, inMemory: true)
}
