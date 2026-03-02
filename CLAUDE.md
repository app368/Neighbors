# Neighbors — Резюме проекта для продолжения работы

## О проекте

**Neighbors** — iOS-приложение для социальной сети малого сообщества (соседей). Позволяет публиковать посты с текстом, изображениями и видео-ссылками, комментировать, ставить лайки, просматривать профили пользователей.

---

## Технический стек

- **Язык:** Swift
- **UI-фреймворк:** UIKit
- **Backend:** Firebase (Auth + Firestore + Storage)
- **Архитектурный подход:** BPN (Business Process Notation)
- **Архитектурный паттерн:** MVVM (Model–View–ViewModel)
- **Минимальная версия iOS:** стандартная (определена при создании проекта)
- **Git:** GitHub, ветвление по feature-веткам, актуальная ветка — `develop`

---

## Структура проекта

```
Neighbors/
├── Models/
│   ├── User.swift
│   ├── Post.swift
│   ├── Comment.swift
│   ├── Like.swift
│   └── AppError.swift
├── Services/
│   ├── FirebaseAuthService.swift
│   ├── FirestorePostService.swift
│   ├── FirestoreCommentService.swift
│   ├── FirestoreLikeService.swift
│   ├── FirebaseStorageService.swift
│   ├── ImageCacheService.swift
│   └── ErrorPresenter.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── FeedViewModel.swift
│   └── PostDetailViewModel.swift
├── ViewControllers/
│   ├── AuthViewController.swift
│   ├── FeedViewController.swift
│   ├── CreatePostViewController.swift
│   ├── PostDetailViewController.swift
│   ├── ProfileViewController.swift
│   ├── CommentInputView.swift
│   ├── CommentTableViewCell.swift
│   ├── PostTableViewCell.swift
│   ├── PhotoCell.swift
│   └── AvatarView.swift
├── AppDelegate.swift
├── SceneDelegate.swift
├── Info.plist
└── GoogleService-Info.plist
```

---

## Реализованные суб-процессы (BPN)

| # | Суб-процесс | Описание | Статус |
|---|-------------|----------|--------|
| A | Аутентификация | Регистрация, вход, выход, Firebase Auth, модель User с ролями (admin/user) | ✅ |
| B | Лента постов (Feed) | UITableView, pull-to-refresh, пустое состояние, переход в детальный пост | ✅ |
| C | Создание поста | Валидация полей (заголовок, текст), публикация в Firestore | ✅ |
| D | Детальный пост | Просмотр, комментарии (CRUD), лайки с анимацией, редактирование и удаление поста, права доступа (автор + админ) | ✅ |
| E | Изображения в постах | До 3 фото, PHPicker, загрузка в Firebase Storage, галерея в карточке, превью в ленте, кэширование (ImageCacheService с NSCache), поддержка при редактировании | ✅ |
| F | Видео-ссылки | YouTube + Vimeo, превью с кнопкой ▶, открытие в Safari, иконка 🎬 в ленте | ✅ |
| G | Профиль пользователя | Статистика (посты, комментарии, лайки), список постов пользователя, редактирование (никнейм, локация), logout, переход из поста и комментария | ✅ |
| H | Поиск в ленте | UISearchController в navigation bar, локальная фильтрация по заголовку + тексту + автору, real-time при вводе | ✅ |
| I | Оптимизация | Пагинация ленты (по 20 постов), prefetching (UITableViewDataSourcePrefetching), footer spinner | ✅ |
| J | Обработка ошибок | AppError enum (маппинг Firebase → понятные сообщения), ErrorPresenter (extension UIViewController), кнопка Retry в ленте | ✅ |

---

## Визуальные улучшения (реализованы)

- **Аватары** — круглые, с инициалами пользователя, цвет генерируется на основе nickname (улучшенный хеш для равномерного распределения цветов)
- **Анимация лайков**
- **Пустые состояния** для ленты и комментариев
- **Админ-бейдж** — эмодзи 🛡 рядом с никнеймом для admin-роли
- **Динамические иконки** — медиа-индикаторы в ячейках ленты (📷 для фото, 🎬 для видео)

---

## Ключевые архитектурные решения

1. **UIKit** (не SwiftUI) — осознанный выбор для данного проекта
2. **Аватары без фото** — только цветные кружки с инициалами, без загрузки фото профиля
3. **Видео-ссылки** — не встроенный плеер, а открытие YouTube/Vimeo в Safari
4. **Локальный поиск** — фильтрация загруженных постов на клиенте (Firestore не поддерживает full-text search)
5. **Firestore persistence** — включён по умолчанию, обеспечивает базовый офлайн-режим без дополнительной реализации
6. **Единая обработка ошибок** — AppError + ErrorPresenter вместо разрозненных alert'ов

---

## Git-состояние

- **Актуальная ветка:** `develop`
- Все реализованные задачи смержены в develop
- Стиль коммитов: conventional commits (`feat:`, `fix:`)
- Feature-ветки создаются для каждой задачи и мержатся после тестирования

---

## Рабочий процесс

- **Методология:** BPN — декомпозиция задачи пользователя на суб-процессы, проектирование схемы, затем кодирование
- **Код:** комментарии на русском, UI-тексты на английском
- **Тестирование:** после каждого суб-процесса, с конкретной обратной связью
- **Коммуникация:** Джастин — постановщик задач, Claude — senior-разработчик/архитектор

---

## История чатов проекта

| Чат | Содержание |
|-----|-----------|
| **Neighbors1 — Beginning** | Создание проекта с нуля: настройка GitHub и Firebase, аутентификация (A), лента постов (B), создание постов (C), детальный пост с комментариями и лайками (D), начало работы с изображениями (E), аватары пользователей |
| **Neighbors2 — Continue** | Доработка изображений (E), видео-ссылки (F), профиль пользователя (G), исправление распределения цветов аватаров |
| **Neighbors3 — Search&Optimization** | Поиск в ленте постов (H) — UISearchController, локальная фильтрация по заголовку + тексту + автору. Пагинация и prefetching (I) — загрузка по 20 постов, footer spinner. Обработка ошибок (J) — AppError enum, ErrorPresenter, Retry в ленте. Обсуждение локализации (решено не делать — только один язык), обсуждение push-уведомлений. Решено не делать, нет необходимости |
| **Neighbors3+ — Polishing** | Глубокий рефакторинг обработки ошибок — интеграция AppError/ErrorPresenter во все контроллеры (State enums переведены с `error(String)` на `error(AppError)`), удаление дублирующего маппинга из AuthViewModel. Мониторинг сети — NWPathMonitor для мгновенной обратной связи при офлайне, timeout-механизмы для Firebase-операций при нестабильном соединении. UI polish: динамические иконки лайков и комментариев (filled при count > 0, outlined при 0), исправление клавиатуры в PostDetail (CommentInputView перекрывался клавиатурой), унификация поведения после создания поста (всегда показывать PostDetail, независимо от наличия медиа). Админ-бейджи — эмодзи 🛡 рядом с никнеймом для admin-роли, добавление поля `authorIsAdmin` в модели Post и Comment, обновление PostTableViewCell, CommentTableViewCell и PostDetailViewController |
