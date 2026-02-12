// Models/UIButton+Animation.swift

import UIKit

extension UIButton {
    
    /// Анимация "сердцебиение" для кнопки лайка
    func animateLike() {
        // Создаём анимацию scale
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 6, options: .allowUserInteraction, animations: {
                self.transform = .identity
            })
        }
    }
    
    /// Анимация для анлайка (небольшое сжатие)
    func animateUnlike() {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.transform = .identity
            })
        }
    }
}
