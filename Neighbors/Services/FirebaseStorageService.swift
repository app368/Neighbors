// Services/FirebaseStorageService.swift

import Foundation
import FirebaseStorage
import UIKit

/// Сервис для работы с Firebase Storage
class FirebaseStorageService {
    
    static let shared = FirebaseStorageService()
    private init() {}
    
    private let storage = Storage.storage()
    
    /// Загрузить изображение в Storage
    /// - Parameters:
    ///   - image: UIImage для загрузки
    ///   - postId: ID поста
    ///   - completion: Callback с URL изображения или ошибкой
    func uploadPostImage(_ image: UIImage, postId: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Сжимаем изображение до разумного размера
        guard let imageData = compressImage(image) else {
            let error = NSError(domain: "ImageError", code: -1,
                               userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
            completion(.failure(error))
            return
        }
        
        // Генерируем уникальное имя файла
        let imageId = UUID().uuidString
        let imagePath = "post_images/\(postId)/\(imageId).jpg"
        
        // Создаём ссылку на Storage
        let storageRef = storage.reference().child(imagePath)
        
        // Метаданные
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Загружаем
        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Получаем downloadURL
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url?.absoluteString else {
                    let error = NSError(domain: "StorageError", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])
                    completion(.failure(error))
                    return
                }
                
                completion(.success(downloadURL))
            }
        }
    }
    
    /// Загрузить несколько изображений
    /// - Parameters:
    ///   - images: Массив UIImage
    ///   - postId: ID поста
    ///   - completion: Callback с массивом URL или ошибкой
    func uploadPostImages(_ images: [UIImage], postId: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let syncQueue = DispatchQueue(label: "com.neighbors.uploadPostImages")
        var uploadedURLs: [String?] = Array(repeating: nil, count: images.count)
        let group = DispatchGroup()
        var uploadError: Error?

        for (index, image) in images.enumerated() {
            group.enter()
            uploadPostImage(image, postId: postId) { result in
                syncQueue.sync {
                    switch result {
                    case .success(let url):
                        uploadedURLs[index] = url
                    case .failure(let error):
                        uploadError = error
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let finalError = syncQueue.sync { uploadError }
            if let error = finalError {
                completion(.failure(error))
            } else {
                let urls = syncQueue.sync { uploadedURLs.compactMap { $0 } }
                completion(.success(urls))
            }
        }
    }
    
    /// Удалить изображения поста
    /// - Parameters:
    ///   - imageURLs: Массив URL изображений
    ///   - completion: Callback с результатом
    func deletePostImages(_ imageURLs: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        guard !imageURLs.isEmpty else {
            completion(.success(()))
            return
        }

        let syncQueue = DispatchQueue(label: "com.neighbors.deletePostImages")
        let group = DispatchGroup()
        var deleteError: Error?

        for urlString in imageURLs {
            group.enter()

            // Создаём ссылку из URL
            let storageRef = storage.reference(forURL: urlString)

            storageRef.delete { error in
                if let error = error {
                    syncQueue.sync { deleteError = error }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let finalError = syncQueue.sync { deleteError }
            if let error = finalError {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /// Сжатие изображения до разумного размера
    /// - Parameter image: Исходное изображение
    /// - Returns: Сжатые данные JPEG
    private func compressImage(_ image: UIImage) -> Data? {
        // Максимальная ширина/высота
        let maxDimension: CGFloat = 1200
        
        var newSize = image.size
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let ratio = image.size.width / image.size.height
            if ratio > 1 {
                // Горизонтальное
                newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
            } else {
                // Вертикальное
                newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
            }
        }
        
        // Ресайз если нужно
        let resizedImage: UIImage
        if newSize != image.size {
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            resizedImage = image
        }
        
        // Сжимаем до JPEG с качеством 0.7
        return resizedImage.jpegData(compressionQuality: 0.7)
    }
}
