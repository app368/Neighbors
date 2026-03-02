// Models/DateFormatter+Extensions.swift

import Foundation

extension Date {

    /// Кэшированный форматтер для дат (создание DateFormatter дорогостоящая операция)
    private static let relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    /// Форматирование даты как относительное время
    /// - Returns: Строка типа "Just now", "5m", "2h", "Yesterday", "Feb 9"
    func relativeTimeString() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)

        if let day = components.day, day >= 2 {
            // Больше 2 дней - показываем дату
            return Date.relativeDateFormatter.string(from: self)
        } else if let day = components.day, day >= 1 {
            // Вчера
            return "Yesterday"
        } else if let hour = components.hour, hour >= 1 {
            // Часы назад
            return "\(hour)h"
        } else if let minute = components.minute, minute >= 1 {
            // Минуты назад
            return "\(minute)m"
        } else {
            // Только что
            return "Just now"
        }
    }
}
