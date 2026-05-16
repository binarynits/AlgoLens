import SwiftUI
import SwiftData

@main
struct AlgoLensApp: App {
    var sharedModelContainer: ModelContainer = AlgoLensApp.makeContainer()

    var body: some Scene {
        WindowGroup {
            LaunchGate {
                RootTabView()
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([UserProgress.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Pre-launch schema drift (e.g. leftover Item store from the template).
            // Wipe the store and rebuild rather than crash.
            wipeStore(at: configuration.url)
            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                // Last resort: in-memory store so the UI still renders.
                let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try! ModelContainer(for: schema, configurations: [memory])
            }
        }
    }

    private static func wipeStore(at url: URL) {
        let fm = FileManager.default
        let base = url.deletingPathExtension()
        let suffixes = ["", "-shm", "-wal"]
        let extensions = ["sqlite", "store"]
        for ext in extensions {
            for suffix in suffixes {
                let candidate = base.appendingPathExtension(ext + suffix)
                try? fm.removeItem(at: candidate)
            }
        }
        try? fm.removeItem(at: url)
    }
}
