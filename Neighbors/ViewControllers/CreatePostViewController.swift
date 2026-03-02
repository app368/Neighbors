// ViewControllers/CreatePostViewController.swift

import UIKit
import FirebaseAuth

// MARK: - ImageItem

/// Модель медиа-элемента поста: существующее фото (с URL из Firebase) или новое (только UIImage)
enum ImageItem {
    case existing(url: String, image: UIImage?)
    case new(image: UIImage)

    /// Изображение для отображения (nil пока идёт загрузка existing)
    var image: UIImage? {
        switch self {
        case .existing(_, let image): return image
        case .new(let image): return image
        }
    }
}

/// Экран создания нового поста
class CreatePostViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let titleTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Post title"
        textField.borderStyle = .roundedRect
        textField.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        textField.autocapitalizationType = .sentences
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let titleErrorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let titleCharCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.text = "0/100"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let contentTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.layer.cornerRadius = 8
        textView.autocapitalizationType = .sentences
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let contentPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "What's on your mind?"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .placeholderText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let contentErrorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let addPhotosButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("📷 Add Photos (0/3)", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.contentHorizontalAlignment = .left
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let photosCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumLineSpacing = 8
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let addVideoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🎬 Add Video (0/1)", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.contentHorizontalAlignment = .left
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    /// Превью добавленного видео
    private let videoPreviewView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let videoThumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    /// Кнопка ▶ поверх превью
    private let playIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "play.circle.fill")
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    /// Кнопка удаления видео
    private let deleteVideoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Properties
    
    private let viewModel = CreatePostViewModel()
    
    /// Callback для обновления ленты после создания поста
    var onPostCreated: (() -> Void)?

    /// Пост для редактирования (если nil - режим создания)
    private var postToEdit: Post?
    
    /// Callback для обновления поста после редактирования
    var onPostUpdated: ((Post) -> Void)?
    
    /// Медиа-элементы: существующие (URL + загруженный UIImage) и новые (только UIImage)
    private var imageItems: [ImageItem] = [] {
        didSet {
            updatePhotosButton()
            photosCollectionView.reloadData()
        }
    }

    /// Общее количество изображений
    private var totalImagesCount: Int {
        return imageItems.count
    }
    
    private let maxImages = 3
    
    /// Информация о добавленном видео
    private var videoInfo: VideoLinkInfo? {
        didSet {
            updateVideoButton()
            updateVideoPreview()
        }
    }
    
    /// URL видео при редактировании существующего поста
    private var existingVideoURL: String?
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupNavigationBar()
        setupTextFields()
        
        // Если редактируем пост — заполняем поля
        if let post = postToEdit {
            titleTextField.text = post.title
            contentTextView.text = post.content
            titleTextChanged()
            textViewDidChange(contentTextView)
            
            // Загружаем существующие изображения поста
            loadExistingImages()
            
            // Загружаем существующее видео
            if let videoURL = post.videoLinks.first {
                existingVideoURL = videoURL
                videoInfo = VideoLinkService.shared.parseVideoURL(videoURL)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Автоматически открываем клавиатуру для заголовка
        titleTextField.becomeFirstResponder()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleTextField)
        view.addSubview(titleErrorLabel)
        view.addSubview(titleCharCountLabel)
        view.addSubview(contentTextView)
        view.addSubview(contentPlaceholderLabel)
        view.addSubview(contentErrorLabel)
        view.addSubview(addPhotosButton)
        view.addSubview(photosCollectionView)
        view.addSubview(addVideoButton)
        view.addSubview(videoPreviewView)
        videoPreviewView.addSubview(videoThumbnailImageView)
        videoPreviewView.addSubview(playIconView)
        videoPreviewView.addSubview(deleteVideoButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            // Title TextField
            titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Title Char Count
            titleCharCountLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 4),
            titleCharCountLabel.trailingAnchor.constraint(equalTo: titleTextField.trailingAnchor),
            
            // Title Error
            titleErrorLabel.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 4),
            titleErrorLabel.leadingAnchor.constraint(equalTo: titleTextField.leadingAnchor),
            titleErrorLabel.trailingAnchor.constraint(equalTo: titleCharCountLabel.leadingAnchor, constant: -8),
            
            // Content TextView
            contentTextView.topAnchor.constraint(equalTo: titleCharCountLabel.bottomAnchor, constant: 16),
            contentTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contentTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            contentTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            
            // Content Placeholder
            contentPlaceholderLabel.topAnchor.constraint(equalTo: contentTextView.topAnchor, constant: 8),
            contentPlaceholderLabel.leadingAnchor.constraint(equalTo: contentTextView.leadingAnchor, constant: 5),
            
            // Content Error
            contentErrorLabel.topAnchor.constraint(equalTo: contentTextView.bottomAnchor, constant: 4),
            contentErrorLabel.leadingAnchor.constraint(equalTo: contentTextView.leadingAnchor),
            contentErrorLabel.trailingAnchor.constraint(equalTo: contentTextView.trailingAnchor),
            
            // Add Photos Button
            addPhotosButton.topAnchor.constraint(equalTo: contentTextView.bottomAnchor, constant: 16),
            addPhotosButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addPhotosButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Photos Collection View
            photosCollectionView.topAnchor.constraint(equalTo: addPhotosButton.bottomAnchor, constant: 8),
            photosCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            photosCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            photosCollectionView.heightAnchor.constraint(equalToConstant: 100),
            
            // Add Video Button
            addVideoButton.topAnchor.constraint(equalTo: photosCollectionView.bottomAnchor, constant: 12),
            addVideoButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addVideoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Video Preview
            videoPreviewView.topAnchor.constraint(equalTo: addVideoButton.bottomAnchor, constant: 8),
            videoPreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            videoPreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            videoPreviewView.heightAnchor.constraint(equalToConstant: 180),
            
            videoThumbnailImageView.topAnchor.constraint(equalTo: videoPreviewView.topAnchor),
            videoThumbnailImageView.leadingAnchor.constraint(equalTo: videoPreviewView.leadingAnchor),
            videoThumbnailImageView.trailingAnchor.constraint(equalTo: videoPreviewView.trailingAnchor),
            videoThumbnailImageView.bottomAnchor.constraint(equalTo: videoPreviewView.bottomAnchor),
            
            playIconView.centerXAnchor.constraint(equalTo: videoPreviewView.centerXAnchor),
            playIconView.centerYAnchor.constraint(equalTo: videoPreviewView.centerYAnchor),
            playIconView.widthAnchor.constraint(equalToConstant: 50),
            playIconView.heightAnchor.constraint(equalToConstant: 50),
            
            deleteVideoButton.topAnchor.constraint(equalTo: videoPreviewView.topAnchor, constant: 8),
            deleteVideoButton.trailingAnchor.constraint(equalTo: videoPreviewView.trailingAnchor, constant: -8),
            deleteVideoButton.widthAnchor.constraint(equalToConstant: 24),
            deleteVideoButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        // Подписка на изменения состояния
        viewModel.onStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.handleStateChange(state)
            }
        }
    }
    
    private func setupNavigationBar() {
        // Заголовок меняется в зависимости от режима
        title = postToEdit != nil ? "Edit Post" : "New Post"
        
        // Кнопка Cancel
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.leftBarButtonItem = cancelButton
        
        // Кнопка Publish/Save
        let saveButtonTitle = postToEdit != nil ? "Save" : "Publish"
        let publishButton = UIBarButtonItem(title: saveButtonTitle, style: .prominent, target: self, action: #selector(publishTapped))
        navigationItem.rightBarButtonItem = publishButton
    }
    
    private func setupTextFields() {
        titleTextField.addTarget(self, action: #selector(titleTextChanged), for: .editingChanged)
        contentTextView.delegate = self
        
        // Скрытие клавиатуры при тапе вне
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // Настройка кнопки добавления фото
        addPhotosButton.addTarget(self, action: #selector(addPhotosTapped), for: .touchUpInside)
        
        // Настройка коллекции фото
        photosCollectionView.delegate = self
        photosCollectionView.dataSource = self
        photosCollectionView.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.identifier)
        photosCollectionView.isHidden = true
        
        // Кнопка добавления видео
        addVideoButton.addTarget(self, action: #selector(addVideoTapped), for: .touchUpInside)
        deleteVideoButton.addTarget(self, action: #selector(deleteVideoTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func titleTextChanged() {
        let count = titleTextField.text?.count ?? 0
        titleCharCountLabel.text = "\(count)/100"
        
        // Изменить цвет если превышен лимит
        titleCharCountLabel.textColor = count > 100 ? .systemRed : .secondaryLabel
        
        // Очистить ошибку при вводе
        titleErrorLabel.isHidden = true
    }
    
    @objc private func cancelTapped() {
        let title = titleTextField.text ?? ""
        let content = contentTextView.text ?? ""
        
        // Если есть введённый текст — показываем предупреждение
        if !title.isEmpty || !content.isEmpty {
            let alert = UIAlertController(
                title: "Discard Post?",
                message: "Are you sure you want to discard this post?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
            alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
                self?.dismiss(animated: true)
            })
            
            present(alert, animated: true)
        } else {
            // Если поля пустые — просто закрываем
            dismiss(animated: true)
        }
    }
    
    @objc private func publishTapped() {
        clearErrors()
        
        let title = titleTextField.text ?? ""
        let content = contentTextView.text ?? ""
        
        if let post = postToEdit {
            // Режим редактирования
            updatePost(post, title: title, content: content)
        } else {
            // Режим создания — все items будут .new(image:)
            let videoLinks = videoInfo != nil ? [videoInfo!.originalURL] : []
            let newImages = imageItems.compactMap { item -> UIImage? in
                guard case .new(let image) = item else { return nil }
                return image
            }

            if newImages.isEmpty && videoLinks.isEmpty {
                // Без медиа — создаём как раньше
                viewModel.createPost(title: title, content: content)
            } else {
                // С медиа — метод с загрузкой
                createPostWithMedia(title: title, content: content, images: newImages, videoLinks: videoLinks)
            }
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Обновление поста (с поддержкой изображений)
    
    private func updatePost(_ post: Post, title: String, content: String) {
        // Валидация заголовка
        if let titleError = viewModel.validateTitle(title) {
            titleErrorLabel.text = titleError
            titleErrorLabel.isHidden = false
            return
        }
        
        // Валидация контента
        if let contentError = viewModel.validateContent(content) {
            contentErrorLabel.text = contentError
            contentErrorLabel.isHidden = false
            return
        }
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        activityIndicator.startAnimating()
        dismissKeyboard()

        // Извлекаем существующие URL и новые изображения из imageItems (порядок гарантирован)
        let existingURLs = imageItems.compactMap { item -> String? in
            guard case .existing(let url, _) = item else { return nil }
            return url
        }
        let newImages = imageItems.compactMap { item -> UIImage? in
            guard case .new(let image) = item else { return nil }
            return image
        }

        if newImages.isEmpty {
            // Нет новых фото — обновляем только текст и текущие URL
            let fields: [String: Any] = [
                "title": title,
                "content": content,
                "images": existingURLs,
                "videoLinks": videoInfo != nil ? [videoInfo!.originalURL] : []
            ]

            FirestorePostService.shared.updatePost(postId: post.id, fields: fields) { [weak self] result in
                DispatchQueue.main.async {
                    self?.navigationItem.rightBarButtonItem?.isEnabled = true
                    self?.activityIndicator.stopAnimating()

                    switch result {
                    case .success:
                        var updatedPost = post
                        updatedPost.title = title
                        updatedPost.content = content
                        updatedPost.images = existingURLs
                        updatedPost.updatedAt = Date()
                        self?.onPostUpdated?(updatedPost)
                        self?.dismiss(animated: true)

                    case .failure(let error):
                        self?.presentError(error)
                    }
                }
            }
        } else {
            // Есть новые фото — загружаем в Storage, потом обновляем пост
            FirebaseStorageService.shared.uploadPostImages(newImages, postId: post.id) { [weak self] uploadResult in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    switch uploadResult {
                    case .success(let newURLs):
                        // Объединяем существующие URL с новыми (существующие сохраняют порядок из imageItems)
                        let allImageURLs = existingURLs + newURLs

                        let fields: [String: Any] = [
                            "title": title,
                            "content": content,
                            "images": allImageURLs,
                            "videoLinks": self.videoInfo != nil ? [self.videoInfo!.originalURL] : []
                        ]

                        FirestorePostService.shared.updatePost(postId: post.id, fields: fields) { result in
                            DispatchQueue.main.async {
                                self.navigationItem.rightBarButtonItem?.isEnabled = true
                                self.activityIndicator.stopAnimating()

                                switch result {
                                case .success:
                                    var updatedPost = post
                                    updatedPost.title = title
                                    updatedPost.content = content
                                    updatedPost.images = allImageURLs
                                    updatedPost.updatedAt = Date()
                                    self.onPostUpdated?(updatedPost)
                                    self.dismiss(animated: true)

                                case .failure(let error):
                                    self.presentError(error)
                                }
                            }
                        }

                    case .failure(let error):
                        self.navigationItem.rightBarButtonItem?.isEnabled = true
                        self.activityIndicator.stopAnimating()
                        self.presentError(error)
                    }
                }
            }
        }
    }
    
    // MARK: - Создание поста с изображениями
    
    private func createPostWithMedia(title: String, content: String, images: [UIImage], videoLinks: [String] = []) {
        // Валидация
        if let titleError = viewModel.validateTitle(title) {
            titleErrorLabel.text = titleError
            titleErrorLabel.isHidden = false
            return
        }
        
        if let contentError = viewModel.validateContent(content) {
            contentErrorLabel.text = contentError
            contentErrorLabel.isHidden = false
            return
        }
        
        navigationItem.rightBarButtonItem?.isEnabled = false
        activityIndicator.startAnimating()
        dismissKeyboard()
        
        // Получаем текущего пользователя
        guard let currentUser = FirebaseAuthService.shared.currentUser else {
            showError("User not authenticated")
            return
        }
        
        // Загружаем данные пользователя
        FirestoreUserService.shared.fetchUser(uid: currentUser.uid) { [weak self] result in
            switch result {
            case .success(let user):
                // Создаём временный пост для получения ID
                let tempPost = Post(
                    title: title,
                    content: content,
                    authorId: user.uid,
                    authorNickname: user.nickname,
                    authorIsAdmin: user.isAdmin,
                    videoLinks: videoLinks
                )
                
                // Загружаем изображения в Storage
                FirebaseStorageService.shared.uploadPostImages(images, postId: tempPost.id) { uploadResult in
                    DispatchQueue.main.async {
                        switch uploadResult {
                        case .success(let imageURLs):
                            // Создаём пост с URL изображений
                            let post = Post(
                                id: tempPost.id,
                                title: title,
                                content: content,
                                authorId: user.uid,
                                authorNickname: user.nickname,
                                authorIsAdmin: user.isAdmin,
                                images: imageURLs,
                                videoLinks: videoLinks
                            )
                            
                            // Сохраняем в Firestore
                            FirestorePostService.shared.createPost(post) { saveResult in
                                DispatchQueue.main.async {
                                    self?.navigationItem.rightBarButtonItem?.isEnabled = true
                                    self?.activityIndicator.stopAnimating()
                                    
                                    switch saveResult {
                                    case .success:
                                        self?.onPostCreated?()
                                        self?.showPostDetail(post)
                                        
                                    case .failure(let error):
                                        self?.presentError(error)
                                    }
                                }
                            }
                            
                        case .failure(let error):
                            self?.navigationItem.rightBarButtonItem?.isEnabled = true
                            self?.activityIndicator.stopAnimating()
                            self?.presentError(error)
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.navigationItem.rightBarButtonItem?.isEnabled = true
                    self?.activityIndicator.stopAnimating()
                    self?.presentError(error)
                }
            }
        }
    }
    
    // MARK: - State Handling
    
    private func handleStateChange(_ state: CreatePostState) {
        switch state {
        case .idle:
            navigationItem.rightBarButtonItem?.isEnabled = true
            activityIndicator.stopAnimating()
            
        case .publishing:
            navigationItem.rightBarButtonItem?.isEnabled = false
            activityIndicator.startAnimating()
            dismissKeyboard()
            
        case .success(let post):
            navigationItem.rightBarButtonItem?.isEnabled = true
            activityIndicator.stopAnimating()
            
            // Обновляем ленту
            onPostCreated?()
            
            // Показываем карточку поста (как при создании с медиа)
            showPostDetail(post)
            
        case .error(let message):
            navigationItem.rightBarButtonItem?.isEnabled = true
            activityIndicator.stopAnimating()
            showError(message)
        }
    }
    
    private func showError(_ message: String) {
        // Проверяем к какому полю относится ошибка
        if message.contains("title") || message.contains("Title") {
            titleErrorLabel.text = message
            titleErrorLabel.isHidden = false
        } else if message.contains("content") || message.contains("Content") {
            contentErrorLabel.text = message
            contentErrorLabel.isHidden = false
        } else {
            // Общая ошибка через alert
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    private func clearErrors() {
        titleErrorLabel.isHidden = true
        contentErrorLabel.isHidden = true
    }
    
    // MARK: - Видео
    
    @objc private func addVideoTapped() {
        // Если видео уже добавлено — предлагаем заменить
        let title = videoInfo != nil ? "Replace Video" : "Add Video"
        
        let alert = UIAlertController(
            title: title,
            message: "Paste a YouTube or Vimeo link",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "https://youtube.com/watch?v=..."
            textField.keyboardType = .URL
            textField.autocapitalizationType = .none
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self, weak alert] _ in
            guard let urlString = alert?.textFields?.first?.text else { return }
            self?.processVideoURL(urlString)
        })
        
        present(alert, animated: true)
    }
    
    /// Валидация и обработка введённой ссылки
    private func processVideoURL(_ urlString: String) {
        guard let info = VideoLinkService.shared.parseVideoURL(urlString) else {
            showError("Invalid video link. Please use a YouTube or Vimeo URL.")
            return
        }
        
        existingVideoURL = nil
        videoInfo = info
    }
    
    @objc private func deleteVideoTapped() {
        existingVideoURL = nil
        videoInfo = nil
    }
    
    /// Обновляет текст кнопки Add Video
    private func updateVideoButton() {
        let count = videoInfo != nil ? 1 : 0
        addVideoButton.setTitle("🎬 Add Video (\(count)/1)", for: .normal)
    }
    
    /// Обновляет превью видео
    private func updateVideoPreview() {
        guard let info = videoInfo else {
            videoPreviewView.isHidden = true
            videoThumbnailImageView.image = nil
            return
        }
        
        videoPreviewView.isHidden = false
        
        if info.platform == .youtube {
            // YouTube — превью загружается напрямую по URL
            ImageCacheService.shared.loadImage(from: info.thumbnailURL) { [weak self] image in
                self?.videoThumbnailImageView.image = image
            }
        } else {
            // Vimeo — нужен запрос к oEmbed API
            VideoLinkService.shared.fetchVimeoThumbnail(videoId: info.videoId) { [weak self] thumbnailURL in
                guard let thumbnailURL = thumbnailURL else { return }
                ImageCacheService.shared.loadImage(from: thumbnailURL) { image in
                    self?.videoThumbnailImageView.image = image
                }
            }
        }
    }
    
    
    // MARK: - Загрузка существующих изображений

    /// Инициализирует imageItems из URL существующих фото, затем асинхронно подгружает изображения по индексу
    private func loadExistingImages() {
        guard let post = postToEdit, !post.images.isEmpty else { return }

        // Предзаполняем items с nil image — порядок гарантирован сразу
        imageItems = post.images.map { .existing(url: $0, image: nil) }
        photosCollectionView.isHidden = false

        // Асинхронно загружаем каждое изображение, обновляем конкретный item по индексу
        for (index, urlString) in post.images.enumerated() {
            ImageCacheService.shared.loadImage(from: urlString) { [weak self] image in
                guard let self = self, let image = image else { return }
                guard index < self.imageItems.count else { return }
                if case .existing(let url, _) = self.imageItems[index] {
                    self.imageItems[index] = .existing(url: url, image: image)
                }
            }
        }
    }
    
    /// Обновляет текст кнопки и видимость коллекции фото
    private func updatePhotosButton() {
        let total = totalImagesCount
        addPhotosButton.setTitle("📷 Add Photos (\(total)/\(maxImages))", for: .normal)
        photosCollectionView.isHidden = (total == 0)
    }
    
    /// Показать карточку поста после создания (заменяет экран создания)
        private func showPostDetail(_ post: Post) {
            let detailVC = PostDetailViewController(post: post)
            
            // При нажатии Done — закрываем модальное окно
            detailVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Done",
                style: .prominent,
                target: detailVC,
                action: #selector(UIViewController.dismissSelf)
            )
            
            // Заменяем текущий экран на карточку поста
            navigationController?.setViewControllers([detailVC], animated: true)
        }
    
    // MARK: - Public Methods
    
    /// Установить пост для редактирования
    /// - Parameter post: Пост который нужно отредактировать
    func setPostToEdit(_ post: Post) {
        self.postToEdit = post
    }
    
} // ← Закрывающая скобка класса

// MARK: - UITextViewDelegate

extension CreatePostViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        // Показать/скрыть placeholder
        contentPlaceholderLabel.isHidden = !textView.text.isEmpty
        
        // Очистить ошибку при вводе
        contentErrorLabel.isHidden = true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        contentPlaceholderLabel.isHidden = !textView.text.isEmpty
    }
}

// MARK: - Photo Picker

extension CreatePostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc private func addPhotosTapped() {
        // Проверяем лимит
        guard totalImagesCount < maxImages else {
            let alert = UIAlertController(
                title: "Maximum Photos",
                message: "You can add up to \(maxImages) photos per post",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Показываем picker
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else { return }

        // Добавляем новое фото если не превышен лимит
        if imageItems.count < maxImages {
            imageItems.append(.new(image: image))
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension CreatePostViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.identifier, for: indexPath) as? PhotoCell else {
            return UICollectionViewCell()
        }

        // Передаём изображение из item (nil — пока загружается existing)
        cell.configure(with: imageItems[indexPath.item].image)

        cell.onDeleteTapped = { [weak self] in
            guard let self = self else { return }
            // Удаление по актуальному индексу — enum несёт всю информацию об item
            self.imageItems.remove(at: indexPath.item)
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension CreatePostViewController: UICollectionViewDelegate {
    // Пока пустой, может понадобиться позже
}

// MARK: - UIViewController Extension

extension UIViewController {
    @objc func dismissSelf() {
        dismiss(animated: true)
    }
}
