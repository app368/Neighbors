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
    let authorIsAdmin: Bool
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
        
        // Обратная совместимость: старые комментарии без этого поля получают false
        let authorIsAdmin = dictionary["authorIsAdmin"] as? Bool ?? false
        
        self.id = id
        self.postId = postId
        self.content = content
        self.authorId = authorId
        self.authorNickname = authorNickname
        self.authorIsAdmin = authorIsAdmin
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
         authorIsAdmin: Bool = false,
         images: [String] = [],
         videoLinks: [String] = [],
         likesCount: Int = 0) {
        self.id = id
        self.postId = postId
        self.content = content
        self.authorId = authorId
        self.authorNickname = authorNickname
        self.authorIsAdmin = authorIsAdmin
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
            "authorIsAdmin": authorIsAdmin,
            "images": images,
            "videoLinks": videoLinks,
            "likesCount": likesCount,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
    }
    
    // Форматированная дата создания (относительное время)
    func formattedDate() -> String {
        return createdAt.relativeTimeString()
    }
}
