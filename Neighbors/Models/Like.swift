// Models/Like.swift

import Foundation
import FirebaseFirestore

/// Модель лайка (для поста или комментария)
struct Like {
    let id: String
    let userId: String
    let targetId: String
    let targetType: LikeTargetType
    let createdAt: Date
    
    /// Тип объекта который лайкнули
    enum LikeTargetType: String {
        case post = "post"
        case comment = "comment"
    }
    
    /// Инициализация из словаря Firestore
    init?(dictionary: [String: Any], id: String) {
        guard let userId = dictionary["userId"] as? String,
              let targetId = dictionary["targetId"] as? String,
              let targetTypeString = dictionary["targetType"] as? String,
              let targetType = LikeTargetType(rawValue: targetTypeString),
              let createdAtTimestamp = dictionary["createdAt"] as? Timestamp else {
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.targetId = targetId
        self.targetType = targetType
        self.createdAt = createdAtTimestamp.dateValue()
    }
    
    /// Инициализация для создания нового лайка
    init(id: String = UUID().uuidString,
         userId: String,
         targetId: String,
         targetType: LikeTargetType) {
        self.id = id
        self.userId = userId
        self.targetId = targetId
        self.targetType = targetType
        self.createdAt = Date()
    }
    
    /// Преобразование в словарь для сохранения в Firestore
    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "targetId": targetId,
            "targetType": targetType.rawValue,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}
