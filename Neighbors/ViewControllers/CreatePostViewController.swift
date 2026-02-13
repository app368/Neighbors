// ViewControllers/CreatePostViewController.swift

import UIKit
import FirebaseAuth

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
    
    // ========== ПОСЛЕ contentErrorLabel ==========
        
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
    
    // ========== КОНЕЦ ==========
    
    
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
    
    // ========== ПОСЛЕ onPostUpdated ==========
        
    /// Выбранные изображения
    private var selectedImages: [UIImage] = [] {
        didSet {
            updatePhotosButton()
            photosCollectionView.reloadData()
        }
    }
    
    private let maxImages = 3
    
    // ========== КОНЕЦ ==========
    
    
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupNavigationBar()
        setupTextFields()
        
        // Если редактируем пост - заполняем поля
        if let post = postToEdit {
            titleTextField.text = post.title
            contentTextView.text = post.content
            titleTextChanged() // Обновить счётчик символов
            textViewDidChange(contentTextView) // Скрыть placeholder
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
            
            // ========== После constraints для contentErrorLabel ==========
            
            // Add Photos Button
            addPhotosButton.topAnchor.constraint(equalTo: contentTextView.bottomAnchor, constant: 16),
            addPhotosButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addPhotosButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Photos Collection View
            photosCollectionView.topAnchor.constraint(equalTo: addPhotosButton.bottomAnchor, constant: 8),
            photosCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            photosCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            photosCollectionView.heightAnchor.constraint(equalToConstant: 100),
            
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
        
        // ========== ДОБАВЬ ЭТО ПЕРЕД ЗАКРЫВАЮЩЕЙ СКОБКОЙ ==========
        
        // Add Photos Button
        addPhotosButton.addTarget(self, action: #selector(addPhotosTapped), for: .touchUpInside)
        
        // Photos Collection View
        photosCollectionView.delegate = self
        photosCollectionView.dataSource = self
        photosCollectionView.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.identifier)
        photosCollectionView.isHidden = true
        
    } // ← вот эта закрывающая скобка метода
    
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
        
        // Если есть введённый текст - показываем предупреждение
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
            // Если поля пустые - просто закрываем
            dismiss(animated: true)
        }
    }
    
    // ========== ПОСЛЕ ИЗМЕНЕНИЯ ==========
    @objc private func publishTapped() {
        clearErrors()
        
        let title = titleTextField.text ?? ""
        let content = contentTextView.text ?? ""
        
        if let post = postToEdit {
            // Режим редактирования
            updatePost(post, title: title, content: content)
        } else {
            // Режим создания
            if selectedImages.isEmpty {
                // Без изображений - создаём как раньше
                viewModel.createPost(title: title, content: content)
            } else {
                // С изображениями - новый метод
                createPostWithImages(title: title, content: content, images: selectedImages)
            }
        }
    }
    // ========== КОНЕЦ ==========
    
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
            
            // Обновляем пост в Firestore
            FirestorePostService.shared.updatePost(
                postId: post.id,
                fields: ["title": title, "content": content]
            ) { [weak self] result in
                DispatchQueue.main.async {
                    self?.navigationItem.rightBarButtonItem?.isEnabled = true
                    self?.activityIndicator.stopAnimating()
                    
                    switch result {
                    case .success:
                        // Создаём обновлённый объект Post
                        var updatedPost = post
                        updatedPost.title = title
                        updatedPost.content = content
                        updatedPost.updatedAt = Date()
                        
                        // Вызываем callback
                        self?.onPostUpdated?(updatedPost)
                        
                        // Закрываем экран
                        self?.dismiss(animated: true)
                        
                    case .failure(let error):
                        let alert = UIAlertController(
                            title: "Error",
                            message: "Failed to update post: \(error.localizedDescription)",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(alert, animated: true)
                    }
                }
            }
        }
    
    
    // ========== ДОБАВЬ ПОСЛЕ метода updatePost() ==========
    
    private func createPostWithImages(title: String, content: String, images: [UIImage]) {
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
                    authorNickname: user.nickname
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
                                images: imageURLs
                            )
                            
                            // Сохраняем в Firestore
                            FirestorePostService.shared.createPost(post) { saveResult in
                                DispatchQueue.main.async {
                                    self?.navigationItem.rightBarButtonItem?.isEnabled = true
                                    self?.activityIndicator.stopAnimating()
                                    
                                    switch saveResult {
                                    case .success:
                                        self?.onPostCreated?()
                                        self?.dismiss(animated: true)
                                        
                                    case .failure(let error):
                                        self?.showError("Failed to create post: \(error.localizedDescription)")
                                    }
                                }
                            }
                            
                        case .failure(let error):
                            self?.navigationItem.rightBarButtonItem?.isEnabled = true
                            self?.activityIndicator.stopAnimating()
                            self?.showError("Failed to upload images: \(error.localizedDescription)")
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.navigationItem.rightBarButtonItem?.isEnabled = true
                    self?.activityIndicator.stopAnimating()
                    self?.showError("Failed to get user data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // ========== КОНЕЦ ==========
    
    
    
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
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
            
        case .success:
            navigationItem.rightBarButtonItem?.isEnabled = true
            activityIndicator.stopAnimating()
            
            // Вызываем callback для обновления ленты
            onPostCreated?()
            
            // Закрываем экран
            dismiss(animated: true)
            
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
    
    
    // MARK: - Public Methods
        
        /// Установить пост для редактирования
        /// - Parameter post: Пост который нужно отредактировать
        func setPostToEdit(_ post: Post) {
            self.postToEdit = post
        }
    
}

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
        guard selectedImages.count < maxImages else {
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
        
        // Добавляем фото если не превышен лимит
        if selectedImages.count < maxImages {
            selectedImages.append(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    private func updatePhotosButton() {
        addPhotosButton.setTitle("📷 Add Photos (\(selectedImages.count)/\(maxImages))", for: .normal)
        photosCollectionView.isHidden = selectedImages.isEmpty
    }
}

// MARK: - UICollectionViewDataSource

extension CreatePostViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.identifier, for: indexPath) as? PhotoCell else {
            return UICollectionViewCell()
        }
        
        let image = selectedImages[indexPath.item]
        cell.configure(with: image)
        
        cell.onDeleteTapped = { [weak self] in
            self?.selectedImages.remove(at: indexPath.item)
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension CreatePostViewController: UICollectionViewDelegate {
    // Пока пустой, может понадобиться позже
}
