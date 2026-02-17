// ViewControllers/PostTableViewCell.swift

import UIKit

/// Ячейка для отображения поста в списке
class PostTableViewCell: UITableViewCell {
    
    // MARK: - Identifier
    
    static let identifier = "PostTableViewCell"
    
    // MARK: - UI Elements
    
    private let avatarView: AvatarView = {
        let view = AvatarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
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
    
    private let contentPreviewLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let likesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let commentsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // === Превью изображения в ленте ===
    
    private let previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()
    
    private var statsTopToPreviewConstraint: NSLayoutConstraint!
    private var statsTopToContentConstraint: NSLayoutConstraint!
    private var previewHeightConstraint: NSLayoutConstraint!
    
    
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
        contentView.addSubview(titleLabel)
        contentView.addSubview(authorLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(contentPreviewLabel)
        contentView.addSubview(statsStackView)
        contentView.addSubview(previewImageView)

        
        statsStackView.addArrangedSubview(likesLabel)
        statsStackView.addArrangedSubview(commentsLabel)

        
        // Constraint, который привязывает stats к превью (когда фото есть)
        statsTopToPreviewConstraint = statsStackView.topAnchor.constraint(equalTo: previewImageView.bottomAnchor, constant: 8)

        // Constraint, который привязывает stats к тексту (когда фото нет)
        statsTopToContentConstraint = statsStackView.topAnchor.constraint(equalTo: contentPreviewLabel.bottomAnchor, constant: 8)

        // Высота превью
        previewHeightConstraint = previewImageView.heightAnchor.constraint(equalToConstant: 180)

        NSLayoutConstraint.activate([
            // Avatar
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: avatarView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Author
            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            authorLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            
            // Date
            dateLabel.centerYAnchor.constraint(equalTo: authorLabel.centerYAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Content Preview
            contentPreviewLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 8),
            contentPreviewLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            contentPreviewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Preview Image — под текстом
            previewImageView.topAnchor.constraint(equalTo: contentPreviewLabel.bottomAnchor, constant: 8),
            previewImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            previewImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            previewHeightConstraint,
            
            // Stats — bottom привяжется динамически
            statsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])

        // По умолчанию — без фото
        statsTopToContentConstraint.isActive = true
    }
    
    // MARK: - Configuration
    
    /// Настройка ячейки данными поста
    /// - Parameter post: Модель поста
    func configure(with post: Post) {
        avatarView.configure(with: post.authorNickname, fontSize: 18)
        titleLabel.text = post.title
        authorLabel.text = post.authorNickname
        dateLabel.text = post.formattedDate()
        contentPreviewLabel.text = post.getContentPreview(maxLength: 100)
        likesLabel.text = "❤️ \(post.likesCount)"
        commentsLabel.text = "💬 \(post.commentsCount)"
        
        // Превью первого изображения
        if let firstImageURL = post.images.first, let url = URL(string: firstImageURL) {
            previewImageView.isHidden = false
            previewImageView.image = nil
            previewHeightConstraint.constant = 180
            
            // Переключаем constraints: stats привязан к превью
            statsTopToContentConstraint.isActive = false
            statsTopToPreviewConstraint.isActive = true
            
            // Загружаем изображение с кэшированием
            ImageCacheService.shared.loadImage(from: firstImageURL) { [weak self] image in
                self?.previewImageView.image = image
            }
        } else {
            // Нет изображений — скрываем превью
            previewImageView.isHidden = true
            previewHeightConstraint.constant = 0
            
            // Переключаем constraints: stats привязан к тексту
            statsTopToPreviewConstraint.isActive = false
            statsTopToContentConstraint.isActive = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        previewImageView.image = nil
        previewImageView.isHidden = true
        previewHeightConstraint.constant = 0
        statsTopToPreviewConstraint.isActive = false
        statsTopToContentConstraint.isActive = true
    }

}
