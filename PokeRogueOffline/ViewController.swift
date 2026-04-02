import UIKit
import WebKit
import Swifter

class ViewController: UIViewController,	WKNavigationDelegate {
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
        webView.configuration.userContentController.add(self, name: "logger")
        let logScript = WKUserScript(
            source: """
            window.onerror = function(msg, url, line) {
                window.webkit.messageHandlers.logger.postMessage('ERROR: ' + msg + ' at ' + url + ':' + line);
            };
            console.log = function(msg) {
                window.webkit.messageHandlers.logger.postMessage('LOG: ' + msg);
            };
            """,
            injectionTime: .atDocumentStart,
                 forMainFrameOnly: false
        )
        webView.configuration.userContentController.addUserScript(logScript)
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
server["/test"] = { _ in
    return HttpResponse.ok(.text("Server is working"))
}
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
/** 
    func loadGame() {
        if let url = URL(string: "http://localhost:8080/") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    func loadGame() {
        if let url = URL(string: "http://localhost:8080/") {
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            showError("Failed to create URL")
        } 
    }
*/
func loadGame() {
    if let url = URL(string: "http://localhost:8080/test") {
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
extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("JS: \(message.body)")
    }
}
