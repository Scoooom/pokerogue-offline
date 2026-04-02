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
            showError("Could not find web directory")
            return
        }

        server = HttpServer()

        server["/"] = { _ in
            let indexPath = webDir.appendingPathComponent("index.html").path
            if let content = try? String(contentsOfFile: indexPath, encoding: .utf8) {
                return HttpResponse.ok(.html(content))
            }
            return HttpResponse.notFound
        }
        
        server["/debug"] = { _ in
            let contents = (try? FileManager.default.contentsOfDirectory(atPath: webDir.path)) ?? []
            return HttpResponse.ok(.text(contents.joined(separator: "\n")))
        }

        server["/(.*)"] = shareFilesFromDirectory(webDir.path)

        do {
            try server.start(8080, forceIPv4: true)
        } catch {
            showError("Server failed to start: \(error.localizedDescription)")
        }
    }

    func loadGame() {
        if let url = URL(string: "http://localhost:8080/debug") {
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            showError("Failed to create URL")
        }
    }

    func showError(_ message: String) {
        DispatchQueue.main.async {
            let label = UILabel()
            label.text = message
            label.textColor = .white
            label.textAlignment = .center
            label.numberOfLines = 0
            label.frame = self.view.bounds
            self.view.backgroundColor = .black
            self.view.addSubview(label)
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError("Failed to load: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError("Navigation failed: \(error.localizedDescription)")
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