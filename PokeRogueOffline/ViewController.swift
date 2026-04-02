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

        server["/(.*)"] = { request in
            var relativePath = request.params.first?.value ?? ""
            if relativePath.isEmpty {
                relativePath = "index.html"
            }

            let filePath = webDir.appendingPathComponent(relativePath).path

            guard FileManager.default.fileExists(atPath: filePath),
                  let data = FileManager.default.contents(atPath: filePath) else {
                return HttpResponse.notFound
            }

            let ext = (relativePath as NSString).pathExtension.lowercased()
            let mime: String
            switch ext {
            case "js": mime = "application/javascript"
            case "css": mime = "text/css"
            case "html": mime = "text/html"
            case "png": mime = "image/png"
            case "jpg", "jpeg": mime = "image/jpeg"
            case "json": mime = "application/json"
            case "wav": mime = "audio/wav"
            case "mp3": mime = "audio/mpeg"
            case "ogg": mime = "audio/ogg"
            case "woff2": mime = "font/woff2"
            case "woff": mime = "font/woff"
            case "ttf": mime = "font/ttf"
            case "webmanifest": mime = "application/manifest+json"
            default: mime = "application/octet-stream"
            }

            return HttpResponse.raw(200, "OK", ["Content-Type": mime], { writer in
                try writer.write(data)
            })
        }

        do {
            try server.start(8080, forceIPv4: true)
        } catch {
            showError("Server failed to start: \(error.localizedDescription)")
        }
    }

    func loadGame() {
        if let url = URL(string: "http://localhost:8080/") {
            webView.load(URLRequest(url: url))
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

    override var prefersStatusBarHidden: Bool { return true }
    override var prefersHomeIndicatorAutoHidden: Bool { return true }

    deinit { server?.stop() }
}