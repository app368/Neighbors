// ViewControllers/CommentTableViewCell.swift

import UIKit

/// Ячейка для отображения комментария
class CommentTableViewCell: UITableViewCell {
    
    // MARK: - Identifier
    
    static let identifier = "CommentTableViewCell"
    
    // MARK: - UI Elements
    
    private let avatarView: AvatarView = {
        let view = AvatarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
        
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
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
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.tintColor = .systemRed
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let likeCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    
    var onLikeTapped: (() -> Void)?
    
    var onAuthorTapped: (() -> Void)?
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.addSubview(avatarView)
        contentView.addSubview(authorLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(likeButton)
        contentView.addSubview(likeCountLabel)
        
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        
        // Tap на автора — переход в профиль
        let authorTap = UITapGestureRecognizer(target: self, action: #selector(authorLabelTapped))
        authorLabel.isUserInteractionEnabled = true
        authorLabel.addGestureRecognizer(authorTap)
        
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(authorLabelTapped))
        avatarView.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(avatarTap)
        
        NSLayoutConstraint.activate([
            
            // Avatar
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.widthAnchor.constraint(equalToConstant: 32),
            avatarView.heightAnchor.constraint(equalToConstant: 32),
            
            // Author (Сдвигаем вправо от аватара)
            authorLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            authorLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
            
            // Date
            dateLabel.centerYAnchor.constraint(equalTo: authorLabel.centerYAnchor),
            dateLabel.leadingAnchor.constraint(equalTo: authorLabel.trailingAnchor, constant: 8),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            // Content (сдвигаем вниз и выравниваем с аватаром)
            contentLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 6),
            contentLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Like Button
            likeButton.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 8),
            likeButton.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
            
            
            likeButton.widthAnchor.constraint(equalToConstant: 24),
            likeButton.heightAnchor.constraint(equalToConstant: 24),
            likeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            // Like Count
            likeCountLabel.centerYAnchor.constraint(equalTo: likeButton.centerYAnchor),
            likeCountLabel.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 4)
        ])
    }
    
    // MARK: - Configuration
    
    /// Настройка ячейки данными комментария
    /// - Parameters:
    ///   - comment: Модель комментария
    ///   - isLiked: Залайкан ли комментарий текущим пользователем
    func configure(with comment: Comment, isLiked: Bool) {
        avatarView.configure(with: comment.authorNickname, fontSize: 14)
        authorLabel.text = comment.authorNickname
        dateLabel.text = comment.formattedDate()
        contentLabel.text = comment.content
        likeCountLabel.text = "\(comment.likesCount)"
        
        // Обновить состояние кнопки лайка
        updateLikeButton(isLiked: isLiked)
    }
    
    /// Обновить кнопку лайка
    /// - Parameter isLiked: Залайкан или нет
    func updateLikeButton(isLiked: Bool) {
        let imageName = isLiked ? "heart.fill" : "heart"
        likeButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    // MARK: - Actions
    
    @objc private func likeButtonTapped() {
        // Анимируем кнопку (определяем состояние по изображению)
        if likeButton.currentImage == UIImage(systemName: "heart.fill") {
            likeButton.animateUnlike()
        } else {
            likeButton.animateLike()
        }
        
        onLikeTapped?()
    }
    
    @objc private func authorLabelTapped() {
        onAuthorTapped?()
    }

}
