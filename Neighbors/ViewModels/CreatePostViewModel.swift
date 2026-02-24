// ViewModels/CreatePostViewModel.swift

import Foundation
import FirebaseAuth

enum CreatePostState {
    case idle              // Ожидание ввода
    case publishing        // Процесс публикации
    case success(Post)     // Успешная публикация — передаём созданный пост
    case error(String)     // Ошибка
}

/// ViewModel для экрана создания поста
class CreatePostViewModel {
    
    // MARK: - Properties
    
    /// Callback для обновления UI при изменении состояния
    var onStateChanged: ((CreatePostState) -> Void)?
    
    private let postService = FirestorePostService.shared
    private let userService = FirestoreUserService.shared
    private let authService = FirebaseAuthService.shared
    
    private(set) var state: CreatePostState = .idle {
        didSet {
            onStateChanged?(state)
        }
    }
    
    // MARK: - Validation
    
    /// Валидация заголовка поста
    /// - Parameter title: Заголовок для проверки
    /// - Returns: Сообщение об ошибке или nil если валиден
    func validateTitle(_ title: String) -> String? {
        guard !title.isEmpty else {
            return "Please enter a title"
        }
        
        guard title.count >= 3 else {
            return "Title must be at least 3 characters"
        }
        
        guard title.count <= 100 else {
            return "Title cannot exceed 100 characters"
        }
        
        return nil
    }
    
    /// Валидация текста поста
    /// - Parameter content: Текст для проверки
    /// - Returns: Сообщение об ошибке или nil если валиден
    func validateContent(_ content: String) -> String? {
        guard !content.isEmpty else {
            return "Please enter post content"
        }
        
        guard content.count >= 10 else {
            return "Content must be at least 10 characters"
        }
        
        return nil
    }
    
    // MARK: - Actions
    
    /// Создание и публикация поста
    /// - Parameters:
    ///   - title: Заголовок поста
    ///   - content: Текст поста
    func createPost(title: String, content: String) {
        // Валидация всех полей
        if let titleError = validateTitle(title) {
            state = .error(titleError)
            return
        }
        
        if let contentError = validateContent(content) {
            state = .error(contentError)
            return
        }
        
        state = .publishing
        
        // Получение текущего пользователя
        guard let currentUser = authService.currentUser else {
            state = .error("User not authenticated")
            return
        }
        
        // Загрузка данных пользователя из Firestore
        userService.fetchUser(uid: currentUser.uid) { [weak self] result in
            switch result {
            case .success(let user):
                // Создание объекта Post
                let post = Post(
                    title: title,
                    content: content,
                    authorId: user.uid,
                    authorNickname: user.nickname
                )
                
                // Сохранение в Firestore
                self?.savePost(post)
                
            case .failure(let error):
                self?.state = .error("Failed to get user data: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Сохранение поста в Firestore
    private func savePost(_ post: Post) {
        postService.createPost(post) { [weak self] result in
            switch result {
            case .success:
                self?.state = .success(post)
                
            case .failure(let error):
                self?.state = .error("Failed to publish post: \(error.localizedDescription)")
            }
        }
    }
}
