// ViewControllers/CreatePostViewController.swift

import UIKit

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
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupNavigationBar()
        setupTextFields()
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
        title = "New Post"
        
        // Кнопка Cancel
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.leftBarButtonItem = cancelButton
        
        // Кнопка Publish
        let publishButton = UIBarButtonItem(title: "Publish", style: .done, target: self, action: #selector(publishTapped))
        navigationItem.rightBarButtonItem = publishButton
    }
    
    private func setupTextFields() {
        titleTextField.addTarget(self, action: #selector(titleTextChanged), for: .editingChanged)
        contentTextView.delegate = self
        
        // Скрытие клавиатуры при тапе вне
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
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
    
    @objc private func publishTapped() {
        clearErrors()
        
        let title = titleTextField.text ?? ""
        let content = contentTextView.text ?? ""
        
        viewModel.createPost(title: title, content: content)
    }
    
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
