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
    private func generateColor(from string: String) -> UIColor {
        // Используем хэш строки для генерации цвета
        var hash = 0
        for char in string.unicodeScalars {
            hash = Int(char.value) + ((hash << 5) - hash)
        }
        
        // Генерируем hue из хэша (0.0 - 1.0)
        let hue = CGFloat(abs(hash) % 360) / 360.0
        
        // Используем высокую насыщенность и среднюю яркость для приятных цветов
        return UIColor(hue: hue, saturation: 0.6, brightness: 0.8, alpha: 1.0)
    }
}
