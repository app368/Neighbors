// Services/FirestorePostService.swift

import Foundation
import FirebaseFirestore

/// Сервис для работы с коллекцией posts в Firestore
class FirestorePostService {
    
    static let shared = FirestorePostService()
    private init() {}
    
    private let db = Firestore.firestore()
    private let postsCollection = "posts"
    
    /// Создание нового поста
    /// - Parameters:
    ///   - post: Модель поста
    ///   - completion: Callback с результатом (успех или ошибка)
    func createPost(_ post: Post, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(postsCollection)
            .document(post.id)
            .setData(post.toDictionary()) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    /// Загрузка всех постов (с сортировкой по дате создания)
    /// - Parameter completion: Callback с результатом (массив постов или ошибка)
    func fetchPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        db.collection(postsCollection)
            .order(by: "createdAt", descending: true) // Новые посты сверху
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                // Парсинг документов в модели Post
                let posts = documents.compactMap { document -> Post? in
                    return Post(dictionary: document.data(), id: document.documentID)
                }
                
                completion(.success(posts))
            }
    }
    
    /// Загрузка поста по ID
    /// - Parameters:
    ///   - postId: ID поста
    ///   - completion: Callback с результатом (Post или ошибка)
    func fetchPost(postId: String, completion: @escaping (Result<Post, Error>) -> Void) {
        db.collection(postsCollection)
            .document(postId)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = snapshot?.data(),
                      let post = Post(dictionary: data, id: postId) else {
                    let error = NSError(domain: "FirestoreError", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "Failed to parse post data"])
                    completion(.failure(error))
                    return
                }
                
                completion(.success(post))
            }
    }
    
    /// Обновление поста
    /// - Parameters:
    ///   - postId: ID поста
    ///   - fields: Поля для обновления
    ///   - completion: Callback с результатом
    func updatePost(postId: String, fields: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        var updatedFields = fields
        updatedFields["updatedAt"] = Timestamp(date: Date())
        
        db.collection(postsCollection)
            .document(postId)
            .updateData(updatedFields) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    /// Удаление поста
    /// - Parameters:
    ///   - postId: ID поста
    ///   - completion: Callback с результатом
    func deletePost(postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(postsCollection)
            .document(postId)
            .delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    /// Увеличение счётчика лайков
    /// - Parameters:
    ///   - postId: ID поста
    ///   - completion: Callback с результатом
    func incrementLikesCount(postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(postsCollection)
            .document(postId)
            .updateData([
                "likesCount": FieldValue.increment(Int64(1)),
                "updatedAt": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    /// Уменьшение счётчика лайков
    /// - Parameters:
    ///   - postId: ID поста
    ///   - completion: Callback с результатом
    func decrementLikesCount(postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(postsCollection)
            .document(postId)
            .updateData([
                "likesCount": FieldValue.increment(Int64(-1)),
                "updatedAt": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    /// Увеличение счётчика комментариев
    /// - Parameters:
    ///   - postId: ID поста
    ///   - completion: Callback с результатом
    func incrementCommentsCount(postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(postsCollection)
            .document(postId)
            .updateData([
                "commentsCount": FieldValue.increment(Int64(1)),
                "updatedAt": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    /// Уменьшение счётчика комментариев
    /// - Parameters:
    ///   - postId: ID поста
    ///   - completion: Callback с результатом
    func decrementCommentsCount(postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(postsCollection)
            .document(postId)
            .updateData([
                "commentsCount": FieldValue.increment(Int64(-1)),
                "updatedAt": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
}
