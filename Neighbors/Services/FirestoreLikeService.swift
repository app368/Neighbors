// Services/FirestoreLikeService.swift

import Foundation
import FirebaseFirestore

/// Сервис для работы с коллекцией likes в Firestore
class FirestoreLikeService {
    
    static let shared = FirestoreLikeService()
    private init() {}
    
    private let db = Firestore.firestore()
    private let likesCollection = "likes"
    
    /// Добавить лайк
    /// - Parameters:
    ///   - like: Модель лайка
    ///   - completion: Callback с результатом
    func addLike(_ like: Like, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(likesCollection)
            .document(like.id)
            .setData(like.toDictionary()) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    /// Удалить лайк
    /// - Parameters:
    ///   - likeId: ID лайка
    ///   - completion: Callback с результатом
    func removeLike(likeId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(likesCollection)
            .document(likeId)
            .delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    /// Проверить существует ли лайк от пользователя на объект
    /// - Parameters:
    ///   - userId: ID пользователя
    ///   - targetId: ID объекта (пост или комментарий)
    ///   - completion: Callback с результатом (Like если есть, nil если нет)
    func fetchLike(userId: String, targetId: String, completion: @escaping (Result<Like?, Error>) -> Void) {
        db.collection(likesCollection)
            .whereField("userId", isEqualTo: userId)
            .whereField("targetId", isEqualTo: targetId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    completion(.success(nil))
                    return
                }
                
                let like = Like(dictionary: document.data(), id: document.documentID)
                completion(.success(like))
            }
    }
    
    /// Загрузить все лайки пользователя для списка объектов
    /// - Parameters:
    ///   - userId: ID пользователя
    ///   - targetIds: Массив ID объектов
    ///   - completion: Callback с результатом (словарь targetId -> Like)
    /// Лимит Firestore для оператора `in` в запросах
    private static let firestoreInLimit = 30

    func fetchLikes(userId: String, targetIds: [String], completion: @escaping (Result<[String: Like], Error>) -> Void) {
        guard !targetIds.isEmpty else {
            completion(.success([:]))
            return
        }

        // Разбиваем targetIds на чанки по firestoreInLimit (лимит Firestore для `in`)
        let chunks = stride(from: 0, to: targetIds.count, by: Self.firestoreInLimit).map {
            Array(targetIds[$0..<min($0 + Self.firestoreInLimit, targetIds.count)])
        }

        let syncQueue = DispatchQueue(label: "com.neighbors.fetchLikes")
        let group = DispatchGroup()
        var allLikes: [String: Like] = [:]
        var fetchError: Error?

        for chunk in chunks {
            group.enter()
            db.collection(likesCollection)
                .whereField("userId", isEqualTo: userId)
                .whereField("targetId", in: chunk)
                .getDocuments { snapshot, error in
                    syncQueue.sync {
                        if let error = error {
                            fetchError = error
                        } else if let documents = snapshot?.documents {
                            for document in documents {
                                if let like = Like(dictionary: document.data(), id: document.documentID) {
                                    allLikes[like.targetId] = like
                                }
                            }
                        }
                    }
                    group.leave()
                }
        }

        group.notify(queue: .main) {
            let result = syncQueue.sync { () -> Result<[String: Like], Error> in
                if let error = fetchError {
                    return .failure(error)
                }
                return .success(allLikes)
            }
            completion(result)
        }
    }
    
    /// Удалить все лайки для конкретного объекта (пост или комментарий)
    /// - Parameters:
    ///   - targetId: ID объекта
    ///   - completion: Callback с результатом
    func deleteAllLikes(forTargetId targetId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(likesCollection)
            .whereField("targetId", isEqualTo: targetId)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion(.success(()))
                    return
                }
                
                // Удаляем каждый лайк
                let syncQueue = DispatchQueue(label: "com.neighbors.deleteAllLikes")
                let group = DispatchGroup()
                var errors: [Error] = []

                for document in documents {
                    group.enter()
                    self?.removeLike(likeId: document.documentID) { deleteResult in
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
            }
    }
}
