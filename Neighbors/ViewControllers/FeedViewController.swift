// ViewControllers/FeedViewController.swift

import UIKit

/// Экран ленты постов
class FeedViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        return tableView
    }()
    
    private let refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        return refreshControl
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No posts yet.\nBe the first to create one!"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Properties
    
    private let viewModel = FeedViewModel()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupBindings()
        setupNavigationBar()
        
        // Загрузка постов при первом открытии
        viewModel.loadPosts()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            // TableView
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Empty State Label
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: PostTableViewCell.identifier)
        
        // Pull-to-refresh
        refreshControl.addTarget(self, action: #selector(refreshPosts), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupBindings() {
        // Подписка на изменения состояния
        viewModel.onStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.handleStateChange(state)
            }
        }
        
        // Подписка на обновление постов
        viewModel.onPostsUpdated = { [weak self] _ in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    private func setupNavigationBar() {
        title = "Feed"
        
        // Кнопка создания поста
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createPostTapped))
        navigationItem.rightBarButtonItem = addButton
        
        // Кнопка профиля/выхода (временно)
        let profileButton = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutTapped))
        navigationItem.leftBarButtonItem = profileButton
    }
    
    // MARK: - Actions
    
    @objc private func refreshPosts() {
        viewModel.refreshPosts { [weak self] in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
            }
        }
    }
    
    
    @objc private func createPostTapped() {
            // Создаём экран создания поста
            let createPostVC = CreatePostViewController()
            
            // Устанавливаем callback для обновления ленты после создания поста
            createPostVC.onPostCreated = { [weak self] in
                self?.viewModel.loadPosts()
            }
            
            // Оборачиваем в NavigationController для показа navigation bar
            let navigationController = UINavigationController(rootViewController: createPostVC)
            
            // Показываем модально
            present(navigationController, animated: true)
        }
    
    
    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "Logout",
                                     message: "Are you sure you want to logout?",
                                     preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        
        present(alert, animated: true)
    }
    
    private func performLogout() {
        do {
            try FirebaseAuthService.shared.signOut()
            
            // Переход на экран авторизации
            if let window = view.window {
                window.rootViewController = AuthViewController()
            }
        } catch {
            let alert = UIAlertController(title: "Error",
                                         message: "Failed to logout: \(error.localizedDescription)",
                                         preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    // MARK: - State Handling
    
    private func handleStateChange(_ state: FeedState) {
        switch state {
        case .idle:
            activityIndicator.stopAnimating()
            emptyStateLabel.isHidden = true
            tableView.isHidden = false
            
        case .loading:
            activityIndicator.startAnimating()
            emptyStateLabel.isHidden = true
            tableView.isHidden = true
            
        case .loaded:
            activityIndicator.stopAnimating()
            emptyStateLabel.isHidden = true
            tableView.isHidden = false
            
        case .empty:
            activityIndicator.stopAnimating()
            emptyStateLabel.isHidden = false
            tableView.isHidden = true
            
        case .error(let message):
            activityIndicator.stopAnimating()
            emptyStateLabel.isHidden = true
            tableView.isHidden = false
            
            // Показать ошибку
            let alert = UIAlertController(title: "Error",
                                         message: message,
                                         preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource

extension FeedViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfPosts
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostTableViewCell.identifier, for: indexPath) as? PostTableViewCell,
              let post = viewModel.post(at: indexPath.row) else {
            return UITableViewCell()
        }
        
        cell.configure(with: post)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension FeedViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // TODO: Переход к детальному посту (суб-процесс D)
        guard let post = viewModel.post(at: indexPath.row) else { return }
        
        let alert = UIAlertController(title: post.title,
                                     message: "Post detail view will be implemented in the next step",
                                     preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
