// Services/VideoLinkService.swift

import Foundation

/// Поддерживаемые видео-платформы
enum VideoPlatform {
    case youtube
    case vimeo
}

/// Результат парсинга видео-ссылки
struct VideoLinkInfo {
    let platform: VideoPlatform
    let videoId: String
    let originalURL: String
    let thumbnailURL: String
}

/// Сервис для валидации и парсинга видео-ссылок (YouTube, Vimeo)
class VideoLinkService {
    
    static let shared = VideoLinkService()
    private init() {}
    
    // MARK: - Основной метод
    
    /// Парсит URL и возвращает информацию о видео, или nil если ссылка невалидна
    func parseVideoURL(_ urlString: String) -> VideoLinkInfo? {
        // Убираем пробелы по краям
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let url = URL(string: trimmed) else { return nil }
        
        // Пробуем YouTube
        if let youtubeId = extractYouTubeId(from: url) {
            return VideoLinkInfo(
                platform: .youtube,
                videoId: youtubeId,
                originalURL: trimmed,
                thumbnailURL: "https://img.youtube.com/vi/\(youtubeId)/hqdefault.jpg"
            )
        }
        
        // Пробуем Vimeo
        if let vimeoId = extractVimeoId(from: url) {
            return VideoLinkInfo(
                platform: .vimeo,
                videoId: vimeoId,
                originalURL: trimmed,
                // Для Vimeo превью загружается отдельно через oEmbed
                thumbnailURL: ""
            )
        }
        
        return nil
    }
    
    // MARK: - YouTube
    
    /// Извлекает videoId из разных форматов YouTube-ссылок
    /// Поддерживает:
    /// - https://www.youtube.com/watch?v=VIDEO_ID
    /// - https://youtu.be/VIDEO_ID
    /// - https://www.youtube.com/embed/VIDEO_ID
    /// - https://m.youtube.com/watch?v=VIDEO_ID
    private func extractYouTubeId(from url: URL) -> String? {
        let host = url.host?.lowercased() ?? ""
        
        // Формат: youtu.be/VIDEO_ID
        if host == "youtu.be" {
            let id = url.pathComponents.dropFirst().first
            return id?.isEmpty == false ? id : nil
        }
        
        // Формат: youtube.com/watch?v=VIDEO_ID
        if host.contains("youtube.com") {
            // Через query parameter v=
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let videoId = components.queryItems?.first(where: { $0.name == "v" })?.value,
               !videoId.isEmpty {
                return videoId
            }
            
            // Формат: youtube.com/embed/VIDEO_ID
            if url.pathComponents.count >= 3 && url.pathComponents[1] == "embed" {
                return url.pathComponents[2]
            }
        }
        
        return nil
    }
    
    // MARK: - Vimeo
    
    /// Извлекает videoId из Vimeo-ссылок
    /// Поддерживает:
    /// - https://vimeo.com/VIDEO_ID
    /// - https://player.vimeo.com/video/VIDEO_ID
    private func extractVimeoId(from url: URL) -> String? {
        let host = url.host?.lowercased() ?? ""
        
        guard host.contains("vimeo.com") else { return nil }
        
        // Формат: vimeo.com/VIDEO_ID (числовой ID)
        if host == "vimeo.com" || host == "www.vimeo.com" {
            if let lastComponent = url.pathComponents.last,
               lastComponent.allSatisfy({ $0.isNumber }),
               !lastComponent.isEmpty {
                return lastComponent
            }
        }
        
        // Формат: player.vimeo.com/video/VIDEO_ID
        if host == "player.vimeo.com" && url.pathComponents.count >= 3 && url.pathComponents[1] == "video" {
            return url.pathComponents[2]
        }
        
        return nil
    }
    
    // MARK: - Загрузка превью Vimeo
    
    /// Загружает URL превью для Vimeo через oEmbed API
    func fetchVimeoThumbnail(videoId: String, completion: @escaping (String?) -> Void) {
        let oEmbedURL = "https://vimeo.com/api/oembed.json?url=https://vimeo.com/\(videoId)"
        
        guard let url = URL(string: oEmbedURL) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let thumbnailURL = json["thumbnail_url"] as? String else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { completion(thumbnailURL) }
        }.resume()
    }
}
