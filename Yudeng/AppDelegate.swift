import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    static let 灯 = 引擎()
    static let 车 = 骑手.共享

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        w.backgroundColor = 色.夜

        if UserDefaults.standard.bool(forKey: "看过引导") {
            进主界面(w)
        } else {
            let 导 = 引导控制器()
            导.看完 = { [weak self, weak w] in
                UserDefaults.standard.set(true, forKey: "看过引导")
                guard let self, let w else { return }
                self.进主界面(w)
            }
            w.rootViewController = 导
        }

        window = w
        w.makeKeyAndVisible()
        return true
    }

    private func 进主界面(_ w: UIWindow) {
        w.rootViewController = 主控制器()
    }
}
