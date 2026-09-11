import SwiftUI

/// Loads an image stored via `MediaStoring` off the main thread and renders
/// it once ready, falling back to a placeholder if the file is missing.
struct RTStoredImage<Placeholder: View>: View {
    let path: String?
    @ViewBuilder var placeholder: () -> Placeholder

    @Environment(AppContainer.self) private var container
    @State private var uiImage: UIImage?
    @State private var loadedPath: String?

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder()
            }
        }
        .task(id: path) {
            await load()
        }
    }

    private func load() async {
        guard let path, path != loadedPath || uiImage == nil else {
            if path == nil { uiImage = nil }
            return
        }
        let mediaStore = container.mediaStore
        let image = await Task.detached(priority: .utility) { () -> UIImage? in
            guard let data = mediaStore.loadData(atRelativePath: path) else { return nil }
            return UIImage(data: data)
        }.value
        loadedPath = path
        uiImage = image
    }
}
