// ViewModels/FeedViewModel.swift

import Foundation

/// Состояния ленты постов
enum FeedState {
    case idle           // Начальное состояние
    case loading        // Загрузка постов
    case loaded         // Посты загружены
    case error(String)  // Ошибка загрузки
    case empty          // Нет постов
}

/// ViewModel для экрана ленты постов
class FeedViewModel {
    
    // MARK: - Properties
    
    /// Callback для обновления UI при изменении состояния
    var onStateChanged: ((FeedState) -> Void)?
    
    /// Callback для обновления списка постов
    var onPostsUpdated: (([Post]) -> Void)?
    
    private let postService = FirestorePostService.shared
    
    private(set) var state: FeedState = .idle {
        didSet {
            onStateChanged?(state)
        }
    }
    
    private(set) var posts: [Post] = [] {
        didSet {
            onPostsUpdated?(posts)
        }
    }
    
    // MARK: - Actions
    
    /// Загрузка постов из Firestore
    func loadPosts() {
        state = .loading
        
        postService.fetchPosts { [weak self] result in
            switch result {
            case .success(let fetchedPosts):
                self?.posts = fetchedPosts
                
                if fetchedPosts.isEmpty {
                    self?.state = .empty
                } else {
                    self?.state = .loaded
                }
                
            case .failure(let error):
                self?.state = .error(error.localizedDescription)
            }
        }
    }
    
    /// Обновление ленты (pull-to-refresh)
    func refreshPosts(completion: @escaping () -> Void) {
        postService.fetchPosts { [weak self] result in
            switch result {
            case .success(let fetchedPosts):
                self?.posts = fetchedPosts
                
                if fetchedPosts.isEmpty {
                    self?.state = .empty
                } else {
                    self?.state = .loaded
                }
                
            case .failure(let error):
                self?.state = .error(error.localizedDescription)
            }
            
            completion()
        }
    }
    
    /// Получить пост по индексу
    /// - Parameter index: Индекс в массиве posts
    /// - Returns: Post или nil
    func post(at index: Int) -> Post? {
        guard index >= 0 && index < posts.count else {
            return nil
        }
        return posts[index]
    }
    
    /// Количество постов
    var numberOfPosts: Int {
        return posts.count
    }
}
