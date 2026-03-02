// Services/FirestoreCommentService.swift

import Foundation
import FirebaseFirestore

/// Сервис для работы с коллекцией comments в Firestore
class FirestoreCommentService {
    
    static let shared = FirestoreCommentService()
    private init() {}
    
    private let db = Firestore.firestore()
    private let commentsCollection = "comments"
    
    /// Создание нового комментария
    /// - Parameters:
    ///   - comment: Модель комментария
    ///   - completion: Callback с результатом
    func createComment(_ comment: Comment, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(commentsCollection)
            .document(comment.id)
            .setData(comment.toDictionary()) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    /// Загрузка комментариев для конкретного поста
    /// - Parameters:
    ///   - postId: ID поста
    ///   - completion: Callback с результатом (массив комментариев или ошибка)
    func fetchComments(forPostId postId: String, completion: @escaping (Result<[Comment], Error>) -> Void) {
        db.collection(commentsCollection)
            .whereField("postId", isEqualTo: postId)
            .order(by: "createdAt", descending: false) // Старые комментарии сверху
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                // Парсинг документов в модели Comment
                let comments = documents.compactMap { document -> Comment? in
                    return Comment(dictionary: document.data(), id: document.documentID)
                }
                
                completion(.success(comments))
            }
    }
    
    /// Обновление комментария
    /// - Parameters:
    ///   - commentId: ID комментария
    ///   - fields: Поля для обновления
    ///   - completion: Callback с результатом
    func updateComment(commentId: String, fields: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        var updatedFields = fields
        updatedFields["updatedAt"] = Timestamp(date: Date())
        
        db.collection(commentsCollection)
            .document(commentId)
            .updateData(updatedFields) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    /// Удаление комментария
    /// - Parameters:
    ///   - commentId: ID комментария
    ///   - completion: Callback с результатом
    func deleteComment(commentId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(commentsCollection)
            .document(commentId)
            .delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    /// Удаление всех комментариев для конкретного поста
    /// - Parameters:
    ///   - postId: ID поста
    ///   - completion: Callback с результатом
    func deleteAllComments(forPostId postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Сначала загружаем все комментарии поста
        fetchComments(forPostId: postId) { [weak self] result in
            switch result {
            case .success(let comments):
                // Если нет комментариев - завершаем успешно
                guard !comments.isEmpty else {
                    completion(.success(()))
                    return
                }
                
                // Удаляем каждый комментарий
                let syncQueue = DispatchQueue(label: "com.neighbors.deleteAllComments")
                let group = DispatchGroup()
                var errors: [Error] = []

                for comment in comments {
                    group.enter()
                    self?.deleteComment(commentId: comment.id) { deleteResult in
                        if case .failure(let error) = deleteResult {
                            syncQueue.sync { errors.append(error) }
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    let firstError = syncQueue.sync { errors.first }
                    if let error = firstError {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Подсчёт количества комментариев пользователя
    /// - Parameters:
    ///   - authorId: UID автора комментариев
    ///   - completion: Callback с количеством
    func fetchCommentsCount(forAuthorId authorId: String, completion: @escaping (Int) -> Void) {
        db.collection(commentsCollection)
            .whereField("authorId", isEqualTo: authorId)
            .getDocuments { snapshot, _ in
                completion(snapshot?.documents.count ?? 0)
            }
    }
    
}
