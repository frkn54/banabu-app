import UIKit
import Capacitor
import UserNotifications
import Network
import WebKit

// Banabu iOS — native katman (App Store 4.2 için): push izni + ağ izleme + markalı offline ekranı.
// CI'da her build'de generated AppDelegate'in ÜZERİNE kopyalanır (native/AppDelegate.swift).
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let netMonitor = NWPathMonitor()
    private var offlineVC: OfflineViewController?
    private var isOffline = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 1) Push bildirim izni (native — kullanıcıya açılışta izin sorulur)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async { application.registerForRemoteNotifications() }
            }
        }
        // 2) Ağ izleme → bağlantı yokken markalı offline ekranı (tarayıcı hatası/beyaz ekran YOK)
        netMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let offline = (path.status != .satisfied)
                guard let self = self, offline != self.isOffline else { return }
                self.isOffline = offline
                if offline { self.showOfflineScreen() } else { self.hideOfflineScreen() }
            }
        }
        netMonitor.start(queue: DispatchQueue.global(qos: .background))
        // GECICI GORSEL TEST — offline ekranini dogrula (sonra kaldirilacak)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { self.showOfflineScreen() }
        return true
    }

    private func topViewController() -> UIViewController? {
        var top = window?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }

    private func showOfflineScreen() {
        guard offlineVC == nil, let top = topViewController() else { return }
        let vc = OfflineViewController()
        vc.modalPresentationStyle = .fullScreen
        offlineVC = vc
        top.present(vc, animated: false, completion: nil)
    }

    private func hideOfflineScreen() {
        guard let vc = offlineVC else { return }
        offlineVC = nil
        vc.dismiss(animated: true) { [weak self] in
            if let bridge = self?.window?.rootViewController as? CAPBridgeViewController {
                bridge.webView?.reload()
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
    func applicationWillTerminate(_ application: UIApplication) {}

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return ApplicationDelegateProxy.shared.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }
}

// Markalı offline ekranı — bundle'daki offline.html'i gösterir (www/offline.html cap sync ile public/'e kopyalanır).
class OfflineViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let webView = WKWebView(frame: view.bounds)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.isOpaque = true
        webView.scrollView.isScrollEnabled = false
        view.addSubview(webView)
        if let url = Bundle.main.url(forResource: "offline", withExtension: "html", subdirectory: "public") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            let label = UILabel(frame: view.bounds)
            label.text = "İnternet bağlantısı yok"
            label.textColor = .black
            label.textAlignment = .center
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(label)
        }
    }
}
