// ViewModels/AuthViewModel.swift

import Foundation

/// Состояния процесса авторизации
enum AuthState {
    case idle           // Ожидание действий пользователя
    case loading        // Процесс выполнения (регистрация/вход)
    case success        // Успешная авторизация
    case error(AppError) // Ошибка (валидация или Firebase)
}

/// ViewModel для экрана авторизации
class AuthViewModel {
    
    // MARK: - Properties
    
    /// Callback для обновления UI при изменении состояния
    var onStateChanged: ((AuthState) -> Void)?
    
    private let authService = FirebaseAuthService.shared
    private let userService = FirestoreUserService.shared
    
    private(set) var state: AuthState = .idle {
        didSet {
            onStateChanged?(state)
        }
    }
    
    // MARK: - Validation
    
    /// Валидация email
    /// - Parameter email: Email для проверки
    /// - Returns: Сообщение об ошибке или nil если валиден
    func validateEmail(_ email: String) -> String? {
        guard !email.isEmpty else {
            return "Please enter your email"
        }

        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        guard emailPredicate.evaluate(with: email) else {
            return "Please enter a valid email"
        }

        return nil
    }

    /// Валидация пароля
    /// - Parameter password: Пароль для проверки
    /// - Returns: Сообщение об ошибке или nil если валиден
    func validatePassword(_ password: String) -> String? {
        guard !password.isEmpty else {
            return "Please enter your password"
        }

        guard password.count >= 6 else {
            return "Password must be at least 6 characters"
        }

        return nil
    }

    /// Валидация nickname
    /// - Parameter nickname: Nickname для проверки
    /// - Returns: Сообщение об ошибке или nil если валиден
    func validateNickname(_ nickname: String) -> String? {
        guard !nickname.isEmpty else {
            return "Please enter a nickname"
        }

        guard nickname.count >= 2 else {
            return "Nickname must be at least 2 characters"
        }

        guard nickname.count <= 20 else {
            return "Nickname cannot exceed 20 characters"
        }

        return nil
    }
    
    // MARK: - Actions
    
    /// Регистрация нового пользователя
    /// - Parameters:
    ///   - email: Email
    ///   - password: Пароль
    ///   - nickname: Nickname
    func register(email: String, password: String, nickname: String) {
        // Валидация всех полей
        if let emailError = validateEmail(email) {
            state = .error(.validation(emailError))
            return
        }

        if let passwordError = validatePassword(password) {
            state = .error(.validation(passwordError))
            return
        }

        if let nicknameError = validateNickname(nickname) {
            state = .error(.validation(nicknameError))
            return
        }

        state = .loading

        // A1.5: Создание аккаунта в Firebase Authentication
        authService.register(email: email, password: password) { [weak self] result in
            switch result {
            case .success(let uid):
                // A1.6: Сохранение данных пользователя в Firestore
                let user = User(uid: uid, email: email, nickname: nickname)
                self?.createUserInFirestore(user)

            case .failure(let error):
                self?.state = .error(AppError.from(error))
            }
        }
    }
    
    /// Вход существующего пользователя
    /// - Parameters:
    ///   - email: Email
    ///   - password: Пароль
    func signIn(email: String, password: String) {
        // Валидация полей
        if let emailError = validateEmail(email) {
            state = .error(.validation(emailError))
            return
        }

        if let passwordError = validatePassword(password) {
            state = .error(.validation(passwordError))
            return
        }

        state = .loading

        // A2.4: Вход через Firebase Authentication
        authService.signIn(email: email, password: password) { [weak self] result in
            switch result {
            case .success(let uid):
                // A2.5: Загрузка данных пользователя из Firestore
                self?.fetchUserFromFirestore(uid: uid)

            case .failure(let error):
                self?.state = .error(AppError.from(error))
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Создание пользователя в Firestore
    private func createUserInFirestore(_ user: User) {
        userService.createUser(user) { [weak self] result in
            switch result {
            case .success:
                // A1.7: Успешная регистрация
                self?.state = .success

            case .failure(let error):
                self?.state = .error(AppError.from(error))
            }
        }
    }

    /// Загрузка пользователя из Firestore
    private func fetchUserFromFirestore(uid: String) {
        userService.fetchUser(uid: uid) { [weak self] result in
            switch result {
            case .success:
                // A2.6: Успешный вход
                self?.state = .success

            case .failure(let error):
                self?.state = .error(AppError.from(error))
            }
        }
    }
}
