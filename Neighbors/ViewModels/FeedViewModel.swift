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
    
    /// Отфильтрованные посты (результат поиска)
    private(set) var filteredPosts: [Post] = []
    
    /// Флаг активного поиска
    private(set) var isSearching: Bool = false
    
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
    
    /// Получить пост по индексу (учитывает режим поиска)
    /// - Parameter index: Индекс в массиве
    /// - Returns: Post или nil
    func post(at index: Int) -> Post? {
        let source = isSearching ? filteredPosts : posts
        guard index >= 0 && index < source.count else {
            return nil
        }
        return source[index]
    }
    
    /// Количество постов (учитывает режим поиска)
    var numberOfPosts: Int {
        return isSearching ? filteredPosts.count : posts.count
    }
    
    /// Обновить пост в списке
        /// - Parameter updatedPost: Обновлённый пост
        func updatePost(_ updatedPost: Post) {
            if let index = posts.firstIndex(where: { $0.id == updatedPost.id }) {
                posts[index] = updatedPost
                onPostsUpdated?(posts)
            }
        }
    
    // MARK: - Search (суб-процесс H)
    
    /// H3: Фильтрация постов по поисковому запросу
    /// Ищет совпадения в заголовке, тексте и имени автора
    /// - Parameter query: Поисковый запрос
    func filterPosts(query: String) {
        // H2.3: Пустой запрос — показываем все посты
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            isSearching = false
            filteredPosts = []
            onPostsUpdated?(posts)
            return
        }
        
        isSearching = true
        
        // H2.2: Приведение к нижнему регистру для case-insensitive поиска
        let lowercasedQuery = query.lowercased()
        
        // H3.1-H3.4: Поиск по заголовку, тексту и автору
        filteredPosts = posts.filter { post in
            post.title.lowercased().contains(lowercasedQuery) ||
            post.content.lowercased().contains(lowercasedQuery) ||
            post.authorNickname.lowercased().contains(lowercasedQuery)
        }
        
        onPostsUpdated?(filteredPosts)
    }
    
    /// Отмена поиска — возврат к полному списку
    func cancelSearch() {
        isSearching = false
        filteredPosts = []
        onPostsUpdated?(posts)
    }
    
}
