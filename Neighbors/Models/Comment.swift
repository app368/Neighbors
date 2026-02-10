// Models/Comment.swift

import Foundation
import FirebaseFirestore

/// Модель комментария к посту
struct Comment {
    let id: String
    let postId: String
    let content: String
    let authorId: String
    let authorNickname: String
    let images: [String]
    let videoLinks: [String]
    var likesCount: Int
    let createdAt: Date
    let updatedAt: Date
    
    /// Инициализация из словаря Firestore
    init?(dictionary: [String: Any], id: String) {
        guard let postId = dictionary["postId"] as? String,
              let content = dictionary["content"] as? String,
              let authorId = dictionary["authorId"] as? String,
              let authorNickname = dictionary["authorNickname"] as? String,
              let images = dictionary["images"] as? [String],
              let videoLinks = dictionary["videoLinks"] as? [String],
              let likesCount = dictionary["likesCount"] as? Int,
              let createdAtTimestamp = dictionary["createdAt"] as? Timestamp,
              let updatedAtTimestamp = dictionary["updatedAt"] as? Timestamp else {
            return nil
        }
        
        self.id = id
        self.postId = postId
        self.content = content
        self.authorId = authorId
        self.authorNickname = authorNickname
        self.images = images
        self.videoLinks = videoLinks
        self.likesCount = likesCount
        self.createdAt = createdAtTimestamp.dateValue()
        self.updatedAt = updatedAtTimestamp.dateValue()
    }
    
    /// Инициализация для создания нового комментария
    init(id: String = UUID().uuidString,
         postId: String,
         content: String,
         authorId: String,
         authorNickname: String,
         images: [String] = [],
         videoLinks: [String] = [],
         likesCount: Int = 0) {
        self.id = id
        self.postId = postId
        self.content = content
        self.authorId = authorId
        self.authorNickname = authorNickname
        self.images = images
        self.videoLinks = videoLinks
        self.likesCount = likesCount
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// Преобразование в словарь для сохранения в Firestore
    func toDictionary() -> [String: Any] {
        return [
            "postId": postId,
            "content": content,
            "authorId": authorId,
            "authorNickname": authorNickname,
            "images": images,
            "videoLinks": videoLinks,
            "likesCount": likesCount,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
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
