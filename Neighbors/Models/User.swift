// Models/User.swift

import Foundation
import FirebaseFirestore

/// Модель пользователя приложения
struct User {
    let uid: String
    let email: String
    var nickname: String
    let isAdmin: Bool
    var location: String
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
        self.location = dictionary["location"] as? String ?? ""
        self.createdAt = timestamp.dateValue()
    }
    
    /// Инициализация для создания нового пользователя
    init(uid: String, email: String, nickname: String, isAdmin: Bool = false, location: String = "") {
        self.uid = uid
        self.email = email
        self.nickname = nickname
        self.isAdmin = isAdmin
        self.location = location
        self.createdAt = Date()
    }
    
    /// Преобразование в словарь для сохранения в Firestore
    func toDictionary() -> [String: Any] {
        return [
            "email": email,
            "nickname": nickname,
            "isAdmin": isAdmin,
            "location": location,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
    
    /// Кэшированный форматтер для даты регистрации
    private static let registrationDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Форматированная дата регистрации
    func formattedRegistrationDate() -> String {
        return User.registrationDateFormatter.string(from: createdAt)
    }
}
