// Models/Post.swift

import Foundation
import FirebaseFirestore

/// Модель поста в ленте
struct Post {
    let id: String
    var title: String
    var content: String
    let authorId: String
    let authorNickname: String
    let images: [String]
    let videoLinks: [String]
    var likesCount: Int
    var commentsCount: Int
    let createdAt: Date
    var updatedAt: Date
    
    /// Инициализация из словаря Firestore
    init?(dictionary: [String: Any], id: String) {
        guard let title = dictionary["title"] as? String,
              let content = dictionary["content"] as? String,
              let authorId = dictionary["authorId"] as? String,
              let authorNickname = dictionary["authorNickname"] as? String,
              let images = dictionary["images"] as? [String],
              let videoLinks = dictionary["videoLinks"] as? [String],
              let likesCount = dictionary["likesCount"] as? Int,
              let commentsCount = dictionary["commentsCount"] as? Int,
              let createdAtTimestamp = dictionary["createdAt"] as? Timestamp,
              let updatedAtTimestamp = dictionary["updatedAt"] as? Timestamp else {
            return nil
        }
        
        self.id = id
        self.title = title
        self.content = content
        self.authorId = authorId
        self.authorNickname = authorNickname
        self.images = images
        self.videoLinks = videoLinks
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.createdAt = createdAtTimestamp.dateValue()
        self.updatedAt = updatedAtTimestamp.dateValue()
    }
    
    /// Инициализация для создания нового поста
    init(id: String = UUID().uuidString,
         title: String,
         content: String,
         authorId: String,
         authorNickname: String,
         images: [String] = [],
         videoLinks: [String] = [],
         likesCount: Int = 0,
         commentsCount: Int = 0) {
        self.id = id
        self.title = title
        self.content = content
        self.authorId = authorId
        self.authorNickname = authorNickname
        self.images = images
        self.videoLinks = videoLinks
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Преобразование в словарь для сохранения в Firestore
    func toDictionary() -> [String: Any] {
        return [
            "title": title,
            "content": content,
            "authorId": authorId,
            "authorNickname": authorNickname,
            "images": images,
            "videoLinks": videoLinks,
            "likesCount": likesCount,
            "commentsCount": commentsCount,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
    
    /// Получить превью контента (первые 100 символов)
    func getContentPreview(maxLength: Int = 100) -> String {
        if content.count <= maxLength {
            return content
        }
        let index = content.index(content.startIndex, offsetBy: maxLength)
        return String(content[..<index]) + "..."
    }
    
    /// Форматированная дата создания
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: createdAt)
    }
}
