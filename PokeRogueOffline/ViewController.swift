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
        
        let errorScript = WKUserScript(
            source: """
            window.onerror = function(msg, url, line, col, err) {
                document.body.innerHTML = '<pre style="color:white;background:black;padding:20px;font-size:12px;">ERROR: ' + msg + '\\nURL: ' + url + '\\nLine: ' + line + '\\n\\n' + (err ? err.stack : '') + '</pre>';
                return true;
            };
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        webView.configuration.userContentController.addUserScript(errorScript)
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

        server["/(.*)"] = { request in
            let relativePath = request.params.first?.value ?? ""
            let filePath = webDir.appendingPathComponent(relativePath).path

            if FileManager.default.fileExists(atPath: filePath) {
                if let data = FileManager.default.contents(atPath: filePath) {
                    // Determine MIME type
                    let ext = (relativePath as NSString).pathExtension.lowercased()
                    let mime: String
                    switch ext {
                    case "js": mime = "application/javascript"
                    case "css": mime = "text/css"
                    case "html": mime = "text/html"
                    case "png": mime = "image/png"
                    case "jpg", "jpeg": mime = "image/jpeg"
                    case "json": mime = "application/json"
                    case "wav", "mp3", "ogg": mime = "audio/\(ext)"
                    case "woff2": mime = "font/woff2"
                    default: mime = "application/octet-stream"
                    }
                    return HttpResponse.raw(200, "OK", ["Content-Type": mime], { writer in
                        try writer.write(data)
                    })
                }
            }
            return HttpResponse.notFound
        }
        do {
            try server.start(8080, forceIPv4: true)
        } catch {
            showError("Server failed to start: \(error.localizedDescription)")
        }
    }

    func loadGame() {
        if let url = URL(string: "http://localhost:8080/assets/index.js") {
            let request = URLRequest(url: url)
            webView.load(request)
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