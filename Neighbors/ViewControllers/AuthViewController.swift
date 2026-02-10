// ViewControllers/AuthViewController.swift

import UIKit

/// Экран авторизации (вход/регистрация)
class AuthViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let logoLabel: UILabel = {
        let label = UILabel()
        label.text = "Соседи"
        label.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "Добро пожаловать в сообщество"
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let modeSegmentedControl: UISegmentedControl = {
        let items = ["Вход", "Регистрация"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let emailErrorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Пароль"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let passwordErrorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let nicknameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Nickname"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let nicknameErrorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Войти", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
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
    
    private let viewModel = AuthViewModel()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupActions()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Добавление элементов на экран
        view.addSubview(logoLabel)
        view.addSubview(welcomeLabel)
        view.addSubview(modeSegmentedControl)
        view.addSubview(emailTextField)
        view.addSubview(emailErrorLabel)
        view.addSubview(passwordTextField)
        view.addSubview(passwordErrorLabel)
        view.addSubview(nicknameTextField)
        view.addSubview(nicknameErrorLabel)
        view.addSubview(actionButton)
        view.addSubview(activityIndicator)
        
        // Изначально скрываем поле nickname (режим входа)
        nicknameTextField.isHidden = true
        nicknameErrorLabel.isHidden = true
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Logo
            logoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            logoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Welcome
            welcomeLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 8),
            welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Segmented Control
            modeSegmentedControl.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 40),
            modeSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            modeSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            // Email
            emailTextField.topAnchor.constraint(equalTo: modeSegmentedControl.bottomAnchor, constant: 32),
            emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            emailTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Email Error
            emailErrorLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 4),
            emailErrorLabel.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            emailErrorLabel.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            
            // Password
            passwordTextField.topAnchor.constraint(equalTo: emailErrorLabel.bottomAnchor, constant: 8),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Password Error
            passwordErrorLabel.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 4),
            passwordErrorLabel.leadingAnchor.constraint(equalTo: passwordTextField.leadingAnchor),
            passwordErrorLabel.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor),
            
            // Nickname
            nicknameTextField.topAnchor.constraint(equalTo: passwordErrorLabel.bottomAnchor, constant: 8),
            nicknameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            nicknameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            nicknameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Nickname Error
            nicknameErrorLabel.topAnchor.constraint(equalTo: nicknameTextField.bottomAnchor, constant: 4),
            nicknameErrorLabel.leadingAnchor.constraint(equalTo: nicknameTextField.leadingAnchor),
            nicknameErrorLabel.trailingAnchor.constraint(equalTo: nicknameTextField.trailingAnchor),
            
            // Action Button
            actionButton.topAnchor.constraint(equalTo: nicknameErrorLabel.bottomAnchor, constant: 32),
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            actionButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        // Подписка на изменения состояния ViewModel
        viewModel.onStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.handleStateChange(state)
            }
        }
    }
    
    private func setupActions() {
        // Действие при смене режима (Вход/Регистрация)
        modeSegmentedControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        
        // Действие при нажатии на кнопку
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        
        // Скрытие клавиатуры при тапе вне текстовых полей
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    
    @objc private func modeChanged() {
        let isRegistrationMode = modeSegmentedControl.selectedSegmentIndex == 1
        
        // Показать/скрыть поле nickname
        nicknameTextField.isHidden = !isRegistrationMode
        nicknameErrorLabel.isHidden = true
        
        // Изменить текст кнопки
        actionButton.setTitle(isRegistrationMode ? "Зарегистрироваться" : "Войти", for: .normal)
        
        // Очистить ошибки
        clearErrors()
    }
    
    @objc private func actionButtonTapped() {
        clearErrors()
        
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        
        if modeSegmentedControl.selectedSegmentIndex == 1 {
            // Режим регистрации
            let nickname = nicknameTextField.text ?? ""
            viewModel.register(email: email, password: password, nickname: nickname)
        } else {
            // Режим входа
            viewModel.signIn(email: email, password: password)
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - State Handling
    
    private func handleStateChange(_ state: AuthState) {
        switch state {
        case .idle:
            actionButton.isEnabled = true
            activityIndicator.stopAnimating()
            
        case .loading:
            actionButton.isEnabled = false
            activityIndicator.startAnimating()
            
        case .success:
            actionButton.isEnabled = true
            activityIndicator.stopAnimating()
            // Переход в основное приложение
            navigateToMainApp()
            
        case .error(let message):
            actionButton.isEnabled = true
            activityIndicator.stopAnimating()
            showError(message)
        }
    }
    
    private func showError(_ message: String) {
        // Проверяем, относится ли ошибка к конкретному полю
        if message.contains("email") || message.contains("Email") {
            emailErrorLabel.text = message
            emailErrorLabel.isHidden = false
        } else if message.contains("пароль") || message.contains("Пароль") {
            passwordErrorLabel.text = message
            passwordErrorLabel.isHidden = false
        } else if message.contains("nickname") || message.contains("Nickname") {
            nicknameErrorLabel.text = message
            nicknameErrorLabel.isHidden = false
        } else {
            // Показываем общую ошибку через UIAlertController
            let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    private func clearErrors() {
        emailErrorLabel.isHidden = true
        passwordErrorLabel.isHidden = true
        nicknameErrorLabel.isHidden = true
    }
    
    private func navigateToMainApp() {
        // Создаём NavigationController с FeedViewController
        let feedVC = FeedViewController()
        let navigationController = UINavigationController(rootViewController: feedVC)
        
        // Меняем rootViewController окна
        if let window = view.window {
            window.rootViewController = navigationController
            
            // Анимация перехода (опционально)
            UIView.transition(with: window,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: nil,
                              completion: nil)
        }
    }
    
}
    
    
    
    
    
 // MARK: - Old
//    private func navigateToMainApp() {
//        // TODO: Позже заменим на переход к ленте постов
//        // Пока просто показываем заглушку
//        let alert = UIAlertController(title: "Успешно!",
//                                     message: "Вы успешно вошли в систему",
//                                     preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }

