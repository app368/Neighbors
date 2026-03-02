// SceneDelegate.swift

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
              options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)

        // A3: Проверка активной сессии Firebase
        let rootViewController: UIViewController

        if FirebaseAuthService.shared.isUserLoggedIn() {
            // A3.2: Есть активная сессия → показываем ленту постов
            rootViewController = createFeedViewController()
        } else {
            // A3.3: Нет сессии → показываем экран авторизации
            rootViewController = AuthViewController()
        }

        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
    }

    /// Создание экрана ленты постов с навигацией
    private func createFeedViewController() -> UIViewController {
        let feedVC = FeedViewController()
        let navigationController = UINavigationController(rootViewController: feedVC)
        return navigationController
    }
}
