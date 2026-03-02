// Models/AppError.swift

import Foundation

/// J2: Единая модель ошибок приложения
/// Маппинг технических ошибок Firebase в понятные пользователю сообщения
enum AppError {
    
    // MARK: - Категории ошибок
    
    /// Ошибки сети
    case network
    
    /// Ошибки авторизации
    case emailAlreadyInUse
    case invalidCredentials
    case wrongPassword
    case userNotFound
    case weakPassword
    case tooManyRequests
    case userDisabled
    
    /// Ошибки Firestore
    case permissionDenied
    case notFound
    case unavailable
    case dataCorrupted
    
    /// Ошибки Storage
    case uploadFailed
    case quotaExceeded
    case fileTooLarge
    
    /// Ошибки валидации полей формы (email, пароль, nickname)
    case validation(String)

    /// Неизвестная ошибка
    case unknown(String)
    
    // MARK: - Сообщение для пользователя
    
    /// Понятное пользователю описание ошибки
    var userMessage: String {
        switch self {
        // Сеть
        case .network:
            return "No internet connection. Please check your network and try again."
            
        // Авторизация
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .invalidCredentials:
            return "Invalid email or password."
        case .wrongPassword:
            return "Incorrect password."
        case .userNotFound:
            return "Account not found. Please check your email or register."
        case .weakPassword:
            return "Password is too weak. Use at least 6 characters."
        case .tooManyRequests:
            return "Too many attempts. Please try again later."
        case .userDisabled:
            return "This account has been disabled."
            
        // Firestore
        case .permissionDenied:
            return "You don't have permission to perform this action."
        case .notFound:
            return "The requested data was not found."
        case .unavailable:
            return "Service is temporarily unavailable. Please try again later."
        case .dataCorrupted:
            return "Data error. Please try again."
            
        // Storage
        case .uploadFailed:
            return "Failed to upload file. Please try again."
        case .quotaExceeded:
            return "Storage limit exceeded."
        case .fileTooLarge:
            return "File is too large to upload."
            
        // Валидация формы — сообщение передаётся как есть
        case .validation(let message):
            return message

        // Неизвестная
        case .unknown(let message):
            return "Something went wrong: \(message)"
        }
    }
    
    // MARK: - Можно ли повторить действие
    
    /// Показывает, имеет ли смысл кнопка "Повторить" для данного типа ошибки
    var isRetryable: Bool {
        switch self {
        case .network, .unavailable, .uploadFailed:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Фабричный метод из Error
    
    /// J2.2-J2.4: Маппинг системных ошибок в AppError
    /// - Parameter error: Исходная ошибка (Firebase или системная)
    /// - Returns: AppError с понятным сообщением
    static func from(_ error: Error) -> AppError {
        let nsError = error as NSError
        
        // Firebase Auth ошибки (домен FIRAuthErrorDomain, коды 17xxx)
        switch nsError.code {
        case 17007:
            return .emailAlreadyInUse
        case 17008, 17011:
            return .invalidCredentials
        case 17009:
            return .wrongPassword
        case 17005:
            return .userDisabled
        case 17010:
            return .tooManyRequests
        case 17026:
            return .weakPassword
        case 17020:
            return .network
        case 17004, 17999: // ERROR_INVALID_CREDENTIAL, malformed/expired credential
            return .invalidCredentials
        default:
            break
        }
        
        // Firestore ошибки (коды GRPCStatus)
        switch nsError.code {
        case 7:  // PERMISSION_DENIED
            return .permissionDenied
        case 5:  // NOT_FOUND
            return .notFound
        case 14: // UNAVAILABLE
            return .unavailable
        default:
            break
        }
        
        // Ошибки сети (NSURLErrorDomain)
        if nsError.domain == NSURLErrorDomain {
            return .network
        }
        
        // Firebase Storage ошибки
        if nsError.domain.contains("FIRStorageErrorDomain") || nsError.domain.contains("StorageError") {
            switch nsError.code {
            case -13010: // objectNotFound
                return .notFound
            case -13000: // unknown
                return .uploadFailed
            case -13013: // quotaExceeded
                return .quotaExceeded
            default:
                return .uploadFailed
            }
        }
        
        return .unknown(error.localizedDescription)
    }
}
