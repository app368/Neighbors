// Services/ImageCacheService.swift

import UIKit

/// Сервис кэширования изображений в памяти
class ImageCacheService {
    
    static let shared = ImageCacheService()
    private init() {}

    /// Кэш изображений (ключ — URL строка)
    private let cache = NSCache<NSString, UIImage>()

    /// Активные загрузки — чтобы не загружать одно фото дважды
    private var activeDownloads: [String: [(UIImage?) -> Void]] = [:]

    /// Serial queue для синхронизации доступа к activeDownloads
    private let queue = DispatchQueue(label: "com.neighbors.ImageCacheService")

    /// Загрузить изображение с кэшированием
    /// - Parameters:
    ///   - urlString: URL изображения
    ///   - completion: Callback с изображением (nil если ошибка)
    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        // Проверяем кэш (NSCache потокобезопасен)
        if let cached = cache.object(forKey: urlString as NSString) {
            completion(cached)
            return
        }

        // Проверяем и обновляем activeDownloads атомарно
        let shouldStartDownload = queue.sync { () -> Bool in
            if activeDownloads[urlString] != nil {
                activeDownloads[urlString]?.append(completion)
                return false
            }
            activeDownloads[urlString] = [completion]
            return true
        }

        guard shouldStartDownload else { return }

        guard let url = URL(string: urlString) else {
            let callbacks = queue.sync { activeDownloads.removeValue(forKey: urlString) ?? [] }
            callbacks.forEach { $0(nil) }
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            let image = data.flatMap { UIImage(data: $0) }

            // Сохраняем в кэш (NSCache потокобезопасен)
            if let image = image {
                self?.cache.setObject(image, forKey: urlString as NSString)
            }

            let callbacks = self?.queue.sync { self?.activeDownloads.removeValue(forKey: urlString) ?? [] } ?? []
            DispatchQueue.main.async {
                callbacks.forEach { $0(image) }
            }
        }.resume()
    }
}
