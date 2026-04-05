import Foundation
import SwiftUI
import UIKit
import Combine

@MainActor
final class ImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?

    private static let cache = NSCache<NSURL, UIImage>()

    func load(from url: URL?) async {
        guard let url else {
            image = nil
            return
        }

        let cacheKey = url as NSURL
        if let cached = Self.cache.object(forKey: cacheKey) {
            image = cached
            return
        }

        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            request.timeoutInterval = 20

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let loadedImage = UIImage(data: data) else {
                image = nil
                return
            }

            Self.cache.setObject(loadedImage, forKey: cacheKey)
            image = loadedImage
        } catch {
            image = nil
        }
    }
}

struct CachedRemoteImage<Placeholder: View>: View {
    let url: URL?
    let contentMode: ContentMode
    private let placeholder: () -> Placeholder

    @StateObject private var loader = ImageLoader()

    init(
        url: URL?,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loader.load(from: url)
        }
    }
}
