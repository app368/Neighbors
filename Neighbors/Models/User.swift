// Models/User.swift

import Foundation
import FirebaseFirestore

/// Модель пользователя приложения
struct User {
    let uid: String
    let email: String
    let nickname: String
    let isAdmin: Bool
    let createdAt: Date
    
    /// Инициализация из словаря Firestore
    init?(dictionary: [String: Any], uid: String) {
        guard let email = dictionary["email"] as? String,
              let nickname = dictionary["nickname"] as? String,
              let isAdmin = dictionary["isAdmin"] as? Bool,
              let timestamp = dictionary["createdAt"] as? Timestamp else {
            return nil
        }
        
        self.uid = uid
        self.email = email
        self.nickname = nickname
        self.isAdmin = isAdmin
        self.createdAt = timestamp.dateValue()
    }
    
    /// Инициализация для создания нового пользователя
    init(uid: String, email: String, nickname: String, isAdmin: Bool = false) {
        self.uid = uid
        self.email = email
        self.nickname = nickname
        self.isAdmin = isAdmin
        self.createdAt = Date()
    }
    
    /// Преобразование в словарь для сохранения в Firestore
    func toDictionary() -> [String: Any] {
        return [
            "email": email,
            "nickname": nickname,
            "isAdmin": isAdmin,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}
