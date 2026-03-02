// ViewModels/PostDetailViewModel.swift

import Foundation
import FirebaseAuth

/// Состояния экрана детального поста
enum PostDetailState {
    case idle
    case loadingComments
    case commentsLoaded
    case error(String)
}

/// ViewModel для экрана детального поста
class PostDetailViewModel {
    
    // MARK: - Properties
    
    /// Callback для обновления UI при изменении состояния
    var onStateChanged: ((PostDetailState) -> Void)?
    
    /// Callback для обновления комментариев
    var onCommentsUpdated: (([Comment]) -> Void)?
    
    /// Callback для обновления поста
    var onPostUpdated: ((Post) -> Void)?
    
    private let commentService = FirestoreCommentService.shared
    private let likeService = FirestoreLikeService.shared
    private let postService = FirestorePostService.shared
    private let authService = FirebaseAuthService.shared
    private let userService = FirestoreUserService.shared
    
    var post: Post
    private(set) var comments: [Comment] = []
    private(set) var state: PostDetailState = .idle {
        didSet {
            onStateChanged?(state)
        }
    }
    
    /// Словарь лайков: targetId -> Like
    private(set) var userLikes: [String: Like] = [:]
    
    /// Текущий пользователь
    private var currentUser: User?
    
    // MARK: - Initialization
    
    init(post: Post) {
        self.post = post
        loadCurrentUser()
    }
    
    // MARK: - User Management
    
    /// Загрузка данных текущего пользователя
    /// Загрузка данных текущего пользователя
        func loadCurrentUser(completion: (() -> Void)? = nil) {
            guard let uid = authService.currentUser?.uid else {
                completion?()
                return
            }
            
            userService.fetchUser(uid: uid) { [weak self] result in
                if case .success(let user) = result {
                    self?.currentUser = user
                }
                completion?()
            }
        }
    
    /// Проверка прав доступа (автор поста или админ)
    func canManagePost() -> Bool {
            
            guard let currentUser = currentUser else {
                return false
            }
            
            let result = currentUser.uid == post.authorId || currentUser.isAdmin
            
            return result
        }
    
    /// Проверка прав на удаление/редактирование комментария
    /// - Parameter comment: Комментарий для проверки
    /// - Returns: true если может управлять
    func canManageComment(_ comment: Comment) -> Bool {
        guard let currentUser = currentUser else { return false }
        // Автор поста, автор комментария или админ
        return currentUser.uid == post.authorId ||
               currentUser.uid == comment.authorId ||
               currentUser.isAdmin
    }
    
    /// Проверка может ли редактировать комментарий
    /// - Parameter comment: Комментарий для проверки
    /// - Returns: true если может редактировать
    func canEditComment(_ comment: Comment) -> Bool {
        guard let currentUser = currentUser else { return false }
        // Только автор комментария или админ
        return currentUser.uid == comment.authorId || currentUser.isAdmin
    }
    
    // MARK: - Comments Management
    
    /// Загрузка комментариев для поста
    func loadComments() {
        state = .loadingComments
        
        commentService.fetchComments(forPostId: post.id) { [weak self] result in
            switch result {
            case .success(let fetchedComments):
                self?.comments = fetchedComments
                self?.loadUserLikes()
                self?.state = .commentsLoaded
                self?.onCommentsUpdated?(fetchedComments)
                
            case .failure(let error):
                self?.state = .error("Failed to load comments: \(error.localizedDescription)")
            }
        }
    }
    
    /// Создание нового комментария
    /// - Parameters:
    ///   - content: Текст комментария
    ///   - completion: Callback с результатом
    func createComment(content: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = currentUser else {
            completion(.failure(NSError(domain: "AuthError", code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let comment = Comment(
            postId: post.id,
            content: content,
            authorId: currentUser.uid,
            authorNickname: currentUser.nickname,
            authorIsAdmin: currentUser.isAdmin
        )
        
        commentService.createComment(comment) { [weak self] result in
            switch result {
            case .success:
                // Увеличить счётчик комментариев в посте
                self?.incrementPostCommentsCount {
                    self?.loadComments()
                    completion(.success(()))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Редактирование комментария
    /// - Parameters:
    ///   - comment: Комментарий для редактирования
    ///   - newContent: Новый текст
    ///   - completion: Callback с результатом
    func editComment(_ comment: Comment, newContent: String, completion: @escaping (Result<Void, Error>) -> Void) {
        commentService.updateComment(commentId: comment.id, fields: ["content": newContent]) { [weak self] result in
            switch result {
            case .success:
                self?.loadComments()
                completion(.success(()))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Удаление комментария
    /// - Parameters:
    ///   - comment: Комментарий для удаления
    ///   - completion: Callback с результатом
    func deleteComment(_ comment: Comment, completion: @escaping (Result<Void, Error>) -> Void) {
        let commentId = comment.id

        // Удалить все лайки комментария (best effort — продолжаем даже при ошибке)
        likeService.deleteAllLikes(forTargetId: commentId) { [weak self] _ in
            guard let self else {
                completion(.failure(NSError(domain: "PostDetail", code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "Operation cancelled"])))
                return
            }

            // Удалить сам комментарий
            self.commentService.deleteComment(commentId: commentId) { [weak self] result in
                switch result {
                case .success:
                    guard let self else {
                        completion(.success(()))
                        return
                    }
                    // Уменьшить счётчик комментариев в посте
                    self.decrementPostCommentsCount {
                        self.loadComments()
                        completion(.success(()))
                    }

                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Post Management
    
    /// Удаление поста (вместе со всеми комментариями и лайками)
    /// - Parameter completion: Callback с результатом
    func deletePost(completion: @escaping (Result<Void, Error>) -> Void) {
        let postId = post.id

        // Удалить все комментарии поста (best effort — продолжаем даже при ошибке)
        commentService.deleteAllComments(forPostId: postId) { [weak self] _ in
            guard let self else {
                completion(.failure(NSError(domain: "PostDetail", code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "Operation cancelled"])))
                return
            }

            // Удалить все лайки поста (best effort)
            self.likeService.deleteAllLikes(forTargetId: postId) { [weak self] _ in
                guard let self else {
                    completion(.failure(NSError(domain: "PostDetail", code: -1,
                                                userInfo: [NSLocalizedDescriptionKey: "Operation cancelled"])))
                    return
                }

                // Удалить сам пост
                self.postService.deletePost(postId: postId, completion: completion)
            }
        }
    }
    
    // MARK: - Likes Management
    
    /// Загрузка лайков текущего пользователя
    private func loadUserLikes() {
        guard let currentUserId = authService.currentUser?.uid else { return }
        
        // Собираем все ID (пост + комментарии)
        var targetIds = [post.id]
        targetIds.append(contentsOf: comments.map { $0.id })
        
        likeService.fetchLikes(userId: currentUserId, targetIds: targetIds) { [weak self] result in
            if case .success(let likes) = result {
                self?.userLikes = likes
                self?.onCommentsUpdated?(self?.comments ?? [])
            }
        }
    }
    
    /// Проверка залайкан ли объект
    /// - Parameter targetId: ID объекта (пост или комментарий)
    /// - Returns: true если залайкан
    func isLiked(targetId: String) -> Bool {
        return userLikes[targetId] != nil
    }
    
    /// Переключить лайк на объект
    /// - Parameters:
    ///   - targetId: ID объекта
    ///   - targetType: Тип объекта (пост или комментарий)
    ///   - completion: Callback с результатом
    func toggleLike(targetId: String, targetType: Like.LikeTargetType, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserId = authService.currentUser?.uid else {
            completion(.failure(NSError(domain: "AuthError", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        if let existingLike = userLikes[targetId] {
            // Уже лайкнуто - удаляем лайк
            likeService.removeLike(likeId: existingLike.id) { [weak self] result in
                switch result {
                case .success:
                    self?.userLikes.removeValue(forKey: targetId)
                    self?.decrementLikesCount(targetId: targetId, targetType: targetType)
                    completion(.success(()))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            // Ещё не лайкнуто - добавляем лайк
            let like = Like(userId: currentUserId, targetId: targetId, targetType: targetType)
            
            likeService.addLike(like) { [weak self] result in
                switch result {
                case .success:
                    self?.userLikes[targetId] = like
                    self?.incrementLikesCount(targetId: targetId, targetType: targetType)
                    completion(.success(()))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Counter Updates
    
    /// Увеличить счётчик лайков
    private func incrementLikesCount(targetId: String, targetType: Like.LikeTargetType) {
        if targetType == .post && targetId == post.id {
            postService.incrementLikesCount(postId: targetId) { [weak self] _ in
                guard let self else { return }
                self.post.likesCount += 1
                self.onPostUpdated?(self.post)
            }
        } else if targetType == .comment {
            if let index = comments.firstIndex(where: { $0.id == targetId }) {
                comments[index].likesCount += 1
                onCommentsUpdated?(comments)
            }
        }
    }
    
    /// Уменьшить счётчик лайков
    private func decrementLikesCount(targetId: String, targetType: Like.LikeTargetType) {
        if targetType == .post && targetId == post.id {
            postService.decrementLikesCount(postId: targetId) { [weak self] _ in
                guard let self else { return }
                self.post.likesCount -= 1
                self.onPostUpdated?(self.post)
            }
        } else if targetType == .comment {
            if let index = comments.firstIndex(where: { $0.id == targetId }) {
                comments[index].likesCount -= 1
                onCommentsUpdated?(comments)
            }
        }
    }
    
    /// Увеличить счётчик комментариев поста
    private func incrementPostCommentsCount(completion: @escaping () -> Void) {
        postService.incrementCommentsCount(postId: post.id) { [weak self] _ in
            guard let self else { return }
            self.post.commentsCount += 1
            self.onPostUpdated?(self.post)
            completion()
        }
    }
    
    /// Уменьшить счётчик комментариев поста
    private func decrementPostCommentsCount(completion: @escaping () -> Void) {
        postService.decrementCommentsCount(postId: post.id) { [weak self] _ in
            guard let self else { return }
            self.post.commentsCount -= 1
            self.onPostUpdated?(self.post)
            completion()
        }
    }
    
    // MARK: - Helpers
    
    /// Количество комментариев
    var numberOfComments: Int {
        return comments.count
    }
    
    /// Получить комментарий по индексу
    func comment(at index: Int) -> Comment? {
        guard index >= 0 && index < comments.count else { return nil }
        return comments[index]
    }
}
