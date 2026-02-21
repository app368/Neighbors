// Services/ErrorPresenter.swift

import UIKit

/// J1: Единый сервис отображения ошибок пользователю
/// Расширение UIViewController — вызов из любого экрана
extension UIViewController {
    
    /// J1.1: Показать ошибку с кнопкой OK
    /// - Parameter error: Ошибка приложения
    func presentError(_ error: AppError) {
        let alert = UIAlertController(
            title: "Error",
            message: error.userMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    /// J1.2: Показать ошибку с кнопкой "Повторить" (если ошибка retryable)
    /// - Parameters:
    ///   - error: Ошибка приложения
    ///   - retryAction: Действие при нажатии "Повторить"
    func presentRetryError(_ error: AppError, retryAction: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "Error",
            message: error.userMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        // Кнопка "Повторить" только для retryable ошибок
        if error.isRetryable {
            alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
                retryAction()
            })
        }
        
        present(alert, animated: true)
    }
    
    /// Удобный метод: принимает обычный Error, конвертирует в AppError
    /// - Parameter error: Системная ошибка
    func presentError(_ error: Error) {
        presentError(AppError.from(error))
    }
    
    /// Удобный метод: принимает обычный Error + retry
    /// - Parameters:
    ///   - error: Системная ошибка
    ///   - retryAction: Действие при нажатии "Повторить"
    func presentRetryError(_ error: Error, retryAction: @escaping () -> Void) {
        presentRetryError(AppError.from(error), retryAction: retryAction)
    }
}
