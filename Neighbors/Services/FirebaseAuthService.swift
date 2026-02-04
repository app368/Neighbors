// Services/FirebaseAuthService.swift

import Foundation
import FirebaseAuth

/// Сервис для работы с Firebase Authentication
class FirebaseAuthService {
    
    static let shared = FirebaseAuthService()
    private init() {}
    
    /// Получение текущего пользователя Firebase
    var currentUser: FirebaseAuth.User? {
        return Auth.auth().currentUser
    }
    
    /// Регистрация нового пользователя
    /// - Parameters:
    ///   - email: Email пользователя
    ///   - password: Пароль
    ///   - completion: Callback с результатом (UID или ошибка)
    func register(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let uid = authResult?.user.uid else {
                let error = NSError(domain: "AuthError", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "Не удалось получить UID пользователя"])
                completion(.failure(error))
                return
            }
            
            completion(.success(uid))
        }
    }
    
    /// Вход существующего пользователя
    /// - Parameters:
    ///   - email: Email пользователя
    ///   - password: Пароль
    ///   - completion: Callback с результатом (UID или ошибка)
    func signIn(email: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let uid = authResult?.user.uid else {
                let error = NSError(domain: "AuthError", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "Не удалось получить UID пользователя"])
                completion(.failure(error))
                return
            }
            
            completion(.success(uid))
        }
    }
    
    /// Выход из системы
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    /// Проверка наличия активной сессии
    func isUserLoggedIn() -> Bool {
        return currentUser != nil
    }
}
