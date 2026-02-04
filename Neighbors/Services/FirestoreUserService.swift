// Services/FirestoreUserService.swift

import Foundation
import FirebaseFirestore

/// Сервис для работы с коллекцией users в Firestore
class FirestoreUserService {
    
    static let shared = FirestoreUserService()
    private init() {}
    
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    
    /// Создание документа пользователя в Firestore
    /// - Parameters:
    ///   - user: Модель пользователя
    ///   - completion: Callback с результатом (успех или ошибка)
    func createUser(_ user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(usersCollection)
            .document(user.uid)
            .setData(user.toDictionary()) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    /// Загрузка данных пользователя из Firestore
    /// - Parameters:
    ///   - uid: UID пользователя
    ///   - completion: Callback с результатом (User или ошибка)
    func fetchUser(uid: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection(usersCollection)
            .document(uid)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = snapshot?.data(),
                      let user = User(dictionary: data, uid: uid) else {
                    let error = NSError(domain: "FirestoreError", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "Не удалось распарсить данные пользователя"])
                    completion(.failure(error))
                    return
                }
                
                completion(.success(user))
            }
    }
    
    /// Обновление данных пользователя
    /// - Parameters:
    ///   - uid: UID пользователя
    ///   - fields: Поля для обновления
    ///   - completion: Callback с результатом
    func updateUser(uid: String, fields: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(usersCollection)
            .document(uid)
            .updateData(fields) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
}
