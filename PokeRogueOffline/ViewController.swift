import UIKit
import WebKit
import Swifter

class ViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    var server: HttpServer!

    override func viewDidLoad() {
        super.viewDidLoad()

        startLocalServer()

        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        view.addSubview(webView)

        loadGame()
    }

    func startLocalServer() {
        guard let webDir = Bundle.main.resourceURL?.appendingPathComponent("web") else {
            print("Could not find web directory")
            return
        }

        server = HttpServer()
        server["/(.+)"] = shareFilesFromDirectory(webDir.path)
        server["/"] = { _ in
            let indexPath = webDir.appendingPathComponent("index.html").path
            if let content = try? String(contentsOfFile: indexPath, encoding: .utf8) {
                return HttpResponse.ok(.html(content))
            }
            return HttpResponse.notFound
        }

        do {
            try server.start(8080, forceIPv4: true)
            print("Server started on port 8080")
        } catch {
            print("Server failed to start: \(error)")
        }
    }

    func loadGame() {
        if let url = URL(string: "http://localhost:8080/") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    func showError(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.frame = view.bounds
        view.backgroundColor = .black
        view.addSubview(label)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    deinit {
        server?.stop()
    }
}
