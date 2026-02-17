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
    
    /// Загрузить изображение с кэшированием
    /// - Parameters:
    ///   - urlString: URL изображения
    ///   - completion: Callback с изображением (nil если ошибка)
    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        // Проверяем кэш
        if let cached = cache.object(forKey: urlString as NSString) {
            completion(cached)
            return
        }
        
        // Если уже загружается — добавляем callback в очередь
        if activeDownloads[urlString] != nil {
            activeDownloads[urlString]?.append(completion)
            return
        }
        
        // Начинаем новую загрузку
        activeDownloads[urlString] = [completion]
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            activeDownloads.removeValue(forKey: urlString)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            let image = data.flatMap { UIImage(data: $0) }
            
            // Сохраняем в кэш
            if let image = image {
                self?.cache.setObject(image, forKey: urlString as NSString)
            }
            
            DispatchQueue.main.async {
                // Вызываем все ожидающие callbacks
                let callbacks = self?.activeDownloads.removeValue(forKey: urlString) ?? []
                callbacks.forEach { $0(image) }
            }
        }.resume()
    }
}
