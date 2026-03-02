// ViewControllers/ProfileViewController.swift

import UIKit

/// Экран профиля пользователя
class ProfileViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Аватар — цветные инициалы
    private let avatarView: AvatarView = {
        let view = AvatarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Никнейм пользователя
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// Локация (опционально)
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// Дата регистрации
    private let registrationDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// Контейнер статистики
    private let statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let postsStatView = ProfileStatView(title: "Posts")
    private let likesStatView = ProfileStatView(title: "Likes")
    private let commentsStatView = ProfileStatView(title: "Comments")
    
    /// Разделитель
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Заголовок секции постов
    private let postsHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "Posts"
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// Таблица постов пользователя
    private let postsTableView: UITableView = {
        let tableView = UITableView()
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    /// Пустое состояние
    private let emptyPostsLabel: UILabel = {
        let label = UILabel()
        label.text = "No posts yet"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private var postsTableViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    
    /// UID пользователя для отображения
    private let userId: String
    
    /// Флаг: свой профиль или чужой
    private let isOwnProfile: Bool
    
    /// Данные пользователя
    private var user: User?
    
    /// Посты пользователя
    private var userPosts: [Post] = []
    
    // MARK: - Initialization
    
    /// - Parameters:
    ///   - userId: UID пользователя
    ///   - isOwnProfile: true если это профиль текущего пользователя
    init(userId: String, isOwnProfile: Bool) {
        self.userId = userId
        self.isOwnProfile = isOwnProfile
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        loadUserData()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Profile"
        
        // Кнопка редактирования (только для своего профиля)
        if isOwnProfile {
            let editButton = UIBarButtonItem(
                image: UIImage(systemName: "gearshape"),
                style: .plain,
                target: self,
                action: #selector(editProfileTapped)
            )
            navigationItem.rightBarButtonItem = editButton
        }
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(avatarView)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(locationLabel)
        contentView.addSubview(registrationDateLabel)
        contentView.addSubview(statsStackView)
        contentView.addSubview(separatorView)
        contentView.addSubview(postsHeaderLabel)
        contentView.addSubview(postsTableView)
        contentView.addSubview(emptyPostsLabel)
        contentView.addSubview(activityIndicator)
        
        statsStackView.addArrangedSubview(postsStatView)
        statsStackView.addArrangedSubview(likesStatView)
        statsStackView.addArrangedSubview(commentsStatView)
        
        postsTableViewHeightConstraint = postsTableView.heightAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Аватар
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            avatarView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 80),
            avatarView.heightAnchor.constraint(equalToConstant: 80),
            
            // Никнейм
            nicknameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 12),
            nicknameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nicknameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Локация
            locationLabel.topAnchor.constraint(equalTo: nicknameLabel.bottomAnchor, constant: 4),
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            locationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Дата регистрации
            registrationDateLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 4),
            registrationDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            registrationDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Статистика
            statsStackView.topAnchor.constraint(equalTo: registrationDateLabel.bottomAnchor, constant: 20),
            statsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            statsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            
            // Разделитель
            separatorView.topAnchor.constraint(equalTo: statsStackView.bottomAnchor, constant: 20),
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            
            // Заголовок постов
            postsHeaderLabel.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 16),
            postsHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            // Таблица постов
            postsTableView.topAnchor.constraint(equalTo: postsHeaderLabel.bottomAnchor, constant: 8),
            postsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            postsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            postsTableViewHeightConstraint,
            postsTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // Пустое состояние
            emptyPostsLabel.topAnchor.constraint(equalTo: postsHeaderLabel.bottomAnchor, constant: 24),
            emptyPostsLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // Индикатор загрузки
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: postsHeaderLabel.bottomAnchor, constant: 24)
        ])
    }
    
    private func setupTableView() {
        postsTableView.delegate = self
        postsTableView.dataSource = self
        postsTableView.register(PostTableViewCell.self, forCellReuseIdentifier: PostTableViewCell.identifier)
    }
    
    // MARK: - Загрузка данных
    
    private func loadUserData() {
        activityIndicator.startAnimating()
        
        // Загружаем данные пользователя
        FirestoreUserService.shared.fetchUser(uid: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.user = user
                    self?.configureProfile(user)
                    self?.loadUserPosts()
                    self?.loadStats()
                    
                case .failure(let error):
                    self?.activityIndicator.stopAnimating()
                    self?.presentError(error)
                }
            }
        }
    }
    
    /// Заполняем UI данными пользователя
    private func configureProfile(_ user: User) {
        avatarView.configure(with: user.nickname, fontSize: 32)
        
        if user.isAdmin {
            nicknameLabel.text = user.nickname + " 🛡️"
        } else {
            nicknameLabel.text = user.nickname
        }
        registrationDateLabel.text = "Member since \(user.formattedRegistrationDate())"
        
        // Локация — показываем только если заполнена
        if user.location.isEmpty {
            locationLabel.isHidden = true
        } else {
            locationLabel.isHidden = false
            locationLabel.text = "📍 \(user.location)"
        }
    }
    
    /// Загружаем посты пользователя и обновляем статистику постов/лайков
    private func loadUserPosts() {
        // Используем fetchUserPosts — не затрагивает курсор пагинации ленты
        FirestorePostService.shared.fetchUserPosts(authorId: userId) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()

                switch result {
                case .success(let posts):
                    self.userPosts = posts
                    self.postsTableView.reloadData()
                    self.updatePostsTableViewHeight()

                    // Статистика постов и лайков — из уже загруженных данных (без второго запроса)
                    let totalLikes = posts.reduce(0) { $0 + $1.likesCount }
                    self.postsStatView.setValue(posts.count)
                    self.likesStatView.setValue(totalLikes)

                case .failure(let error):
                    self.presentError(error)
                }
            }
        }
    }

    /// Загружаем статистику комментариев
    private func loadStats() {
        // Посты и лайки обновляются в loadUserPosts()
        // Количество комментариев — через отдельный запрос
        FirestoreCommentService.shared.fetchCommentsCount(forAuthorId: userId) { [weak self] count in
            DispatchQueue.main.async {
                self?.commentsStatView.setValue(count)
            }
        }
    }
    
    /// Обновляем высоту таблицы постов
    private func updatePostsTableViewHeight() {
        postsTableView.layoutIfNeeded()
        postsTableViewHeightConstraint.constant = postsTableView.contentSize.height
        
        let hasPosts = !userPosts.isEmpty
        postsTableView.isHidden = !hasPosts
        emptyPostsLabel.isHidden = hasPosts
    }
    
    // MARK: - Actions
    
    @objc private func editProfileTapped() {
        let alert = UIAlertController(title: "Profile Settings", message: nil, preferredStyle: .actionSheet)
        
        // Изменить никнейм
        alert.addAction(UIAlertAction(title: "Change Nickname", style: .default) { [weak self] _ in
            self?.showChangeNicknameAlert()
        })
        
        // Изменить локацию
        alert.addAction(UIAlertAction(title: "Change Location", style: .default) { [weak self] _ in
            self?.showChangeLocationAlert()
        })
        
        // Logout
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showChangeNicknameAlert() {
        let alert = UIAlertController(title: "Change Nickname", message: nil, preferredStyle: .alert)
        
        alert.addTextField { [weak self] textField in
            textField.text = self?.user?.nickname
            textField.placeholder = "New nickname"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let newNickname = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newNickname.isEmpty,
                  let self = self else { return }
            
            self.updateUserField("nickname", value: newNickname) {
                self.user?.nickname = newNickname
                
                if self.user?.isAdmin == true {
                    self.nicknameLabel.text = newNickname + " 🛡️"
                } else {
                    self.nicknameLabel.text = newNickname
                }
                
                self.avatarView.configure(with: newNickname, fontSize: 32)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showChangeLocationAlert() {
        let alert = UIAlertController(title: "Change Location", message: "e.g. Apt 12, Building B", preferredStyle: .alert)
        
        alert.addTextField { [weak self] textField in
            textField.text = self?.user?.location
            textField.placeholder = "Your location (optional)"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let self = self else { return }
            let newLocation = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            self.updateUserField("location", value: newLocation) {
                self.user?.location = newLocation
                if newLocation.isEmpty {
                    self.locationLabel.isHidden = true
                } else {
                    self.locationLabel.isHidden = false
                    self.locationLabel.text = "📍 \(newLocation)"
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    /// Обновляет одно поле пользователя в Firestore
    private func updateUserField(_ field: String, value: Any, onSuccess: @escaping () -> Void) {
        FirestoreUserService.shared.updateUser(uid: userId, fields: [field: value]) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    onSuccess()
                case .failure(let error):
                    self?.presentError(error)
                }
            }
        }
    }
    
    private func performLogout() {
        do {
            try FirebaseAuthService.shared.signOut()
            if let window = view.window {
                window.rootViewController = AuthViewController()
            }
        } catch {
            presentError(error)
        }
    }
    
}

// MARK: - UITableViewDataSource

extension ProfileViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostTableViewCell.identifier, for: indexPath) as? PostTableViewCell else {
            return UITableViewCell()
        }
        
        let post = userPosts[indexPath.row]
        cell.configure(with: post)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ProfileViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let post = userPosts[indexPath.row]
        let detailVC = PostDetailViewController(post: post)
        
        detailVC.onPostDeleted = { [weak self] in
            self?.loadUserPosts()
        }
        
        detailVC.onPostUpdated = { [weak self] _ in
            self?.loadUserPosts()
        }
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
