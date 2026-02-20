// ViewControllers/PostDetailViewController.swift

import UIKit
import FirebaseAuth

/// Экран детального просмотра поста с комментариями
class PostDetailViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // Post Header
    private let postHeaderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarView: AvatarView = {
        let view = AvatarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // ========== ПОСЛЕ contentLabel ==========
    
    private let imagesScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let imagesStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var imagesScrollViewHeightConstraint: NSLayoutConstraint!
    
    // Видео превью
    private let videoContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let videoThumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let videoPlayButton: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "play.circle.fill")
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var videoContainerHeightConstraint: NSLayoutConstraint!
    
    /// URL видео для открытия в Safari
    private var videoURL: String?

    
    private let likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.tintColor = .systemRed
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let likeCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let commentCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Comments
    private let commentsTableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.isScrollEnabled = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let emptyCommentsLabel: UILabel = {
        let label = UILabel()
        label.text = "No comments yet.\nBe the first to comment!"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    
    
    
    private var tableViewHeightConstraint: NSLayoutConstraint!
    
    private let commentInputView: CommentInputView = {
        let view = CommentInputView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Properties
    
    private var viewModel: PostDetailViewModel
    
    /// Callback для обновления ленты постов при удалении поста
    var onPostDeleted: (() -> Void)?
    
    /// Callback для обновления поста в ленте при редактировании
    var onPostUpdated: ((Post) -> Void)?
    
    // MARK: - Initialization
    
    init(post: Post) {
        self.viewModel = PostDetailViewModel(post: post)
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
            setupBindings()
            configurePostHeader()
            
            // Загрузка текущего пользователя, затем настройка navigation bar
            viewModel.loadCurrentUser { [weak self] in
                DispatchQueue.main.async {
                    self?.setupNavigationBar()
                }
            }
            
            // Загрузка комментариев
            viewModel.loadComments()
        }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        // Post header
        postHeaderView.addSubview(avatarView)
        postHeaderView.addSubview(titleLabel)
        postHeaderView.addSubview(authorLabel)
        postHeaderView.addSubview(dateLabel)
        postHeaderView.addSubview(contentLabel)
        postHeaderView.addSubview(likeButton)
        postHeaderView.addSubview(likeCountLabel)
        postHeaderView.addSubview(commentCountLabel)
        postHeaderView.addSubview(imagesScrollView)
        imagesScrollView.addSubview(imagesStackView)
        postHeaderView.addSubview(videoContainerView)
        videoContainerView.addSubview(videoThumbnailImageView)
        videoContainerView.addSubview(videoPlayButton)
        contentStackView.addArrangedSubview(postHeaderView)
        contentStackView.addArrangedSubview(separatorView)
        contentStackView.addArrangedSubview(commentsTableView)
        contentStackView.addArrangedSubview(emptyCommentsLabel)
        
        view.addSubview(commentInputView)
        view.addSubview(activityIndicator)
        
        likeButton.addTarget(self, action: #selector(postLikeButtonTapped), for: .touchUpInside)
        
        // Tap на автора — открытие профиля
        let authorTap = UITapGestureRecognizer(target: self, action: #selector(authorTapped))
        authorLabel.isUserInteractionEnabled = true
        authorLabel.addGestureRecognizer(authorTap)
        
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(authorTapped))
        avatarView.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(avatarTap)
        
        tableViewHeightConstraint = commentsTableView.heightAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: commentInputView.topAnchor),
            
            // Content Stack
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Post Header Elements
            
            // Avatar
            avatarView.topAnchor.constraint(equalTo: postHeaderView.topAnchor, constant: 16),
            avatarView.leadingAnchor.constraint(equalTo: postHeaderView.leadingAnchor, constant: 16),
            avatarView.widthAnchor.constraint(equalToConstant: 48),
            avatarView.heightAnchor.constraint(equalToConstant: 48),
            
            // Title (сдвигаем вправо и выравниваем с аватаром)
            titleLabel.topAnchor.constraint(equalTo: postHeaderView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: postHeaderView.trailingAnchor, constant: -16),
            
            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            authorLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            
            dateLabel.centerYAnchor.constraint(equalTo: authorLabel.centerYAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: authorLabel.trailingAnchor, constant: 8),
            
            contentLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 16),
            contentLabel.leadingAnchor.constraint(equalTo: postHeaderView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: postHeaderView.trailingAnchor, constant: -16),
            

            
            /// Images Gallery — горизонтальная прокрутка фотографий
            imagesScrollView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 16),
            imagesScrollView.leadingAnchor.constraint(equalTo: postHeaderView.leadingAnchor),
            imagesScrollView.trailingAnchor.constraint(equalTo: postHeaderView.trailingAnchor),

            imagesStackView.topAnchor.constraint(equalTo: imagesScrollView.topAnchor),
            imagesStackView.leadingAnchor.constraint(equalTo: imagesScrollView.leadingAnchor, constant: 16),
            imagesStackView.trailingAnchor.constraint(equalTo: imagesScrollView.trailingAnchor, constant: -16),
            imagesStackView.bottomAnchor.constraint(equalTo: imagesScrollView.bottomAnchor),
            imagesStackView.heightAnchor.constraint(equalTo: imagesScrollView.heightAnchor),

            
            // Видео превью — под галереей фото
            videoContainerView.topAnchor.constraint(equalTo: imagesScrollView.bottomAnchor, constant: 12),
            videoContainerView.leadingAnchor.constraint(equalTo: postHeaderView.leadingAnchor, constant: 16),
            videoContainerView.trailingAnchor.constraint(equalTo: postHeaderView.trailingAnchor, constant: -16),
            
            videoThumbnailImageView.topAnchor.constraint(equalTo: videoContainerView.topAnchor),
            videoThumbnailImageView.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor),
            videoThumbnailImageView.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor),
            videoThumbnailImageView.bottomAnchor.constraint(equalTo: videoContainerView.bottomAnchor),
            
            videoPlayButton.centerXAnchor.constraint(equalTo: videoContainerView.centerXAnchor),
            videoPlayButton.centerYAnchor.constraint(equalTo: videoContainerView.centerYAnchor),
            videoPlayButton.widthAnchor.constraint(equalToConstant: 60),
            videoPlayButton.heightAnchor.constraint(equalToConstant: 60),
            
            // Кнопка лайка — привязана к низу видео
            likeButton.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: 16),
            
            likeButton.leadingAnchor.constraint(equalTo: postHeaderView.leadingAnchor, constant: 16),
            likeButton.widthAnchor.constraint(equalToConstant: 28),
            likeButton.heightAnchor.constraint(equalToConstant: 28),
            likeButton.bottomAnchor.constraint(equalTo: postHeaderView.bottomAnchor, constant: -16),
            
            likeCountLabel.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor),
            likeCountLabel.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 4),
            
            commentCountLabel.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor),
            commentCountLabel.leadingAnchor.constraint(equalTo: likeCountLabel.trailingAnchor, constant: 16),
            
            // Separator
            separatorView.heightAnchor.constraint(equalToConstant: 8),
            
            // Comments TableView
            tableViewHeightConstraint,
            
            // Empty Comments Label
            emptyCommentsLabel.heightAnchor.constraint(equalToConstant: 80),
            
            
            // Comment Input
            commentInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            commentInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            commentInputView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            commentInputView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: commentsTableView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: commentsTableView.topAnchor, constant: 20)
        ])
        // Начальная высота галереи — 0 (обновится в loadPostImages)
        imagesScrollViewHeightConstraint = imagesScrollView.heightAnchor.constraint(equalToConstant: 0)
        imagesScrollViewHeightConstraint.isActive = true
        
        // Начальная высота видео — 0 (обновится в loadVideoPreview)
        videoContainerHeightConstraint = videoContainerView.heightAnchor.constraint(equalToConstant: 0)
        videoContainerHeightConstraint.isActive = true
        
        // Tap на видео — открытие в Safari
        let videoTap = UITapGestureRecognizer(target: self, action: #selector(videoThumbnailTapped))
        videoContainerView.addGestureRecognizer(videoTap)
    }
    
    private func setupTableView() {
        commentsTableView.delegate = self
        commentsTableView.dataSource = self
        commentsTableView.register(CommentTableViewCell.self, forCellReuseIdentifier: CommentTableViewCell.identifier)
    }
    
    private func setupBindings() {
        viewModel.onStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.handleStateChange(state)
            }
        }
        
        viewModel.onCommentsUpdated = { [weak self] _ in
            DispatchQueue.main.async {
                self?.commentsTableView.reloadData()
                self?.updateTableViewHeight()
            }
        }
        
        viewModel.onPostUpdated = { [weak self] post in
            DispatchQueue.main.async {
                self?.updatePostCounts(post)
            }
        }
        
        commentInputView.onSendTapped = { [weak self] text in
            self?.createComment(text)
        }
    }
    
    private func setupNavigationBar() {
        title = "Post"
        
        // Кнопка меню (только для автора/админа)
        if viewModel.canManagePost() {
            let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(menuButtonTapped))
            navigationItem.rightBarButtonItem = menuButton
        }
    }
    
    private func configurePostHeader() {
        let post = viewModel.post
        avatarView.configure(with: post.authorNickname, fontSize: 20)
        titleLabel.text = post.title
        authorLabel.text = post.authorNickname
        dateLabel.text = post.formattedDate()
        contentLabel.text = post.content
        updatePostCounts(post)
        updatePostLikeButton()
        
        // Загружаем изображения
        loadPostImages(post.images)
        
        // Загружаем видео превью
        loadVideoPreview(post.videoLinks.first)
    }
    

    
    private func loadPostImages(_ imageURLs: [String]) {
        // Очищаем предыдущие изображения
        imagesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        guard !imageURLs.isEmpty else {
            // Нет изображений — скрываем галерею
            imagesScrollViewHeightConstraint.constant = 0
            return
        }
        
        // Высота галереи = ширина экрана * 0.6
        let imageHeight = view.bounds.width * 0.6
        imagesScrollViewHeightConstraint.constant = imageHeight
        
        // Ширина каждого изображения
        let imageWidth = view.bounds.width - 32
        
        // Создаём ImageView для каждого URL
        for urlString in imageURLs {
            guard URL(string: urlString) != nil else { continue }
            
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 8
            imageView.backgroundColor = .systemGray6
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: imageWidth).isActive = true
            
            imagesStackView.addArrangedSubview(imageView)
            
            // Загружаем изображение с кэшированием
            ImageCacheService.shared.loadImage(from: urlString) { image in
                imageView.image = image
            }
        }
    }
    
    // MARK: - Видео превью
    
    /// Загружает превью видео и показывает его
    private func loadVideoPreview(_ videoURLString: String?) {
        guard let urlString = videoURLString,
              let info = VideoLinkService.shared.parseVideoURL(urlString) else {
            // Нет видео — скрываем контейнер
            videoContainerHeightConstraint.constant = 0
            videoURL = nil
            return
        }
        
        // Сохраняем URL для открытия
        videoURL = urlString
        
        // Высота превью
        videoContainerHeightConstraint.constant = view.bounds.width * 0.5
        
        // Загружаем превью в зависимости от платформы
        if info.platform == .youtube {
            ImageCacheService.shared.loadImage(from: info.thumbnailURL) { [weak self] image in
                self?.videoThumbnailImageView.image = image
            }
        } else {
            VideoLinkService.shared.fetchVimeoThumbnail(videoId: info.videoId) { [weak self] thumbnailURL in
                guard let thumbnailURL = thumbnailURL else { return }
                ImageCacheService.shared.loadImage(from: thumbnailURL) { image in
                    self?.videoThumbnailImageView.image = image
                }
            }
        }
    }
    
    /// Открытие видео в Safari
    @objc private func videoThumbnailTapped() {
        guard let urlString = videoURL, let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
 
    private func updatePostCounts(_ post: Post) {
            likeCountLabel.text = "\(post.likesCount)"
            commentCountLabel.text = "💬 \(post.commentsCount)"
            
            // Уведомляем FeedViewController об изменении счётчиков
            onPostUpdated?(post)
        }
    
    
    
    private func updatePostLikeButton() {
        let isLiked = viewModel.isLiked(targetId: viewModel.post.id)
        let imageName = isLiked ? "heart.fill" : "heart"
        likeButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    private func updateTableViewHeight() {
        commentsTableView.layoutIfNeeded()
        tableViewHeightConstraint.constant = commentsTableView.contentSize.height
        
        // Показать/скрыть пустое состояние
        let hasComments = viewModel.numberOfComments > 0
        commentsTableView.isHidden = !hasComments
        emptyCommentsLabel.isHidden = hasComments
    }
    
    
    
    // MARK: - Actions
    
    
    @objc private func postLikeButtonTapped() {
        // Определяем лайкнуто ли сейчас
        let wasLiked = viewModel.isLiked(targetId: viewModel.post.id)
        
        // Анимируем кнопку
        if wasLiked {
            likeButton.animateUnlike()
        } else {
            likeButton.animateLike()
        }
        
        viewModel.toggleLike(targetId: viewModel.post.id, targetType: .post) { [weak self] result in
            DispatchQueue.main.async {
                if case .success = result {
                    self?.updatePostLikeButton()
                }
            }
        }
    }
        // ========== КОНЕЦ ==========
    
    
    
    @objc private func menuButtonTapped() {
        let alert = UIAlertController(title: "Post Options", message: nil, preferredStyle: .actionSheet)
        
        // Опция Edit (только для автора или админа)
        alert.addAction(UIAlertAction(title: "Edit Post", style: .default) { [weak self] _ in
            self?.editPost()
        })
        
        // Опция Delete
        alert.addAction(UIAlertAction(title: "Delete Post", style: .destructive) { [weak self] _ in
            self?.confirmDeletePost()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func editPost() {
            // Создаём экран редактирования поста
            let createPostVC = CreatePostViewController()
            createPostVC.setPostToEdit(viewModel.post)
            
            // Устанавливаем callback для обновления после редактирования
            createPostVC.onPostUpdated = { [weak self] updatedPost in
                guard let self = self else { return }
                
                // Обновляем локальный пост
                self.viewModel.post = updatedPost
                self.configurePostHeader()
                
                // Уведомляем FeedViewController об изменениях
                self.onPostUpdated?(updatedPost)
            }
            
            // Оборачиваем в NavigationController
            let navigationController = UINavigationController(rootViewController: createPostVC)
            
            // Показываем модально
            present(navigationController, animated: true)
        }
    
    
    
    
    private func confirmDeletePost() {
        let alert = UIAlertController(
            title: "Delete Post?",
            message: "This will delete the post and all its comments. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deletePost()
        })
        
        present(alert, animated: true)
    }
    
    private func deletePost() {
        viewModel.deletePost { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.onPostDeleted?()
                    self?.navigationController?.popViewController(animated: true)
                    
                case .failure(let error):
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to delete post: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
    private func createComment(_ text: String) {
        viewModel.createComment(content: text) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.commentInputView.clearInput()
                    
                case .failure(let error):
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to post comment: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
    @objc private func authorTapped() {
        let post = viewModel.post
        let isOwn = post.authorId == FirebaseAuthService.shared.currentUser?.uid
        let profileVC = ProfileViewController(userId: post.authorId, isOwnProfile: isOwn)
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    // MARK: - State Handling
    
    private func handleStateChange(_ state: PostDetailState) {
        switch state {
        case .idle:
            activityIndicator.stopAnimating()
            
        case .loadingComments:
            activityIndicator.startAnimating()
            
        case .commentsLoaded:
            activityIndicator.stopAnimating()
            
        case .error(let message):
            activityIndicator.stopAnimating()
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource

extension PostDetailViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfComments
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentTableViewCell.identifier, for: indexPath) as? CommentTableViewCell,
              let comment = viewModel.comment(at: indexPath.row) else {
            return UITableViewCell()
        }
        
        let isLiked = viewModel.isLiked(targetId: comment.id)
        cell.configure(with: comment, isLiked: isLiked)
        
        cell.onLikeTapped = { [weak self] in
            self?.viewModel.toggleLike(targetId: comment.id, targetType: .comment) { result in
                DispatchQueue.main.async {
                    if case .success = result {
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
                }
            }
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension PostDetailViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let comment = viewModel.comment(at: indexPath.row) else { return nil }
        
        var actions: [UIContextualAction] = []
        
        // Delete action (автор поста, автор комментария, админ)
        if viewModel.canManageComment(comment) {
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
                self?.deleteComment(comment, at: indexPath)
                completion(true)
            }
            actions.append(deleteAction)
        }
        
        // Edit action (только автор комментария или админ)
        if viewModel.canEditComment(comment) {
            let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
                self?.editComment(comment)
                completion(true)
            }
            editAction.backgroundColor = .systemBlue
            actions.append(editAction)
        }
        
        return actions.isEmpty ? nil : UISwipeActionsConfiguration(actions: actions)
    }
    
    private func editComment(_ comment: Comment) {
        let alert = UIAlertController(title: "Edit Comment", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = comment.content
            textField.placeholder = "Comment text"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let newContent = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newContent.isEmpty else { return }
            
            self?.viewModel.editComment(comment, newContent: newContent) { result in
                DispatchQueue.main.async {
                    if case .failure(let error) = result {
                        let errorAlert = UIAlertController(
                            title: "Error",
                            message: "Failed to edit comment: \(error.localizedDescription)",
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(errorAlert, animated: true)
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func deleteComment(_ comment: Comment, at indexPath: IndexPath) {
        viewModel.deleteComment(comment) { [weak self] result in
            DispatchQueue.main.async {
                if case .failure(let error) = result {
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to delete comment: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
}
