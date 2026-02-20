// ViewControllers/AvatarView.swift

import UIKit

/// Круглый аватар с инициалами пользователя
class AvatarView: UIView {
    
    // MARK: - UI Elements
    
    private let initialsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        layer.masksToBounds = true
        
        addSubview(initialsLabel)
        
        NSLayoutConstraint.activate([
            initialsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Делаем круглым
        layer.cornerRadius = bounds.width / 2
    }
    
    // MARK: - Configuration
    
    /// Настроить аватар для пользователя
    /// - Parameters:
    ///   - nickname: Nickname пользователя
    ///   - size: Размер шрифта для инициалов (по умолчанию 16)
    func configure(with nickname: String, fontSize: CGFloat = 16) {
        // Получить первую букву
        let initial = String(nickname.prefix(1)).uppercased()
        initialsLabel.text = initial
        initialsLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        
        // Сгенерировать цвет на основе nickname
        backgroundColor = generateColor(from: nickname)
    }
    
    /// Генерация консистентного цвета на основе строки
    /// - Parameter string: Строка для генерации цвета
    /// - Returns: UIColor
    /// Генерация консистентного цвета на основе строки
        /// - Parameter string: Строка для генерации цвета
        /// - Returns: UIColor
    private func generateColor(from string: String) -> UIColor {
        // Используем DJB2 хеш для лучшего распределения
        var hash: UInt64 = 5381
        for char in string.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ UInt64(char.value)
        }
        
        // Набор приятных цветов для аватаров
        let colors: [UIColor] = [
            UIColor(hue: 0.0,  saturation: 0.6, brightness: 0.8, alpha: 1.0),  // Красный
            UIColor(hue: 0.05, saturation: 0.6, brightness: 0.8, alpha: 1.0),  // Оранжевый
            UIColor(hue: 0.12, saturation: 0.6, brightness: 0.8, alpha: 1.0),  // Жёлто-оранжевый
            UIColor(hue: 0.22, saturation: 0.6, brightness: 0.7, alpha: 1.0),  // Зелёный
            UIColor(hue: 0.35, saturation: 0.6, brightness: 0.7, alpha: 1.0),  // Бирюзовый
            UIColor(hue: 0.5,  saturation: 0.6, brightness: 0.7, alpha: 1.0),  // Голубой
            UIColor(hue: 0.58, saturation: 0.6, brightness: 0.8, alpha: 1.0),  // Синий
            UIColor(hue: 0.7,  saturation: 0.5, brightness: 0.8, alpha: 1.0),  // Фиолетовый
            UIColor(hue: 0.8,  saturation: 0.5, brightness: 0.8, alpha: 1.0),  // Пурпурный
            UIColor(hue: 0.9,  saturation: 0.5, brightness: 0.8, alpha: 1.0),  // Розовый
        ]
        
        let index = Int(hash % UInt64(colors.count))
        return colors[index]
    }
}
