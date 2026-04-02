import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let config = WKWebViewConfiguration()

	config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
	config.preferences.setValue(true, forKey: "allowUniversalAccessFromFileURLs")

        // Allow local storage and session storage to persist
        config.websiteDataStore = WKWebsiteDataStore.default()

        // Allow audio to play without user interaction (for game sounds)
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

    func loadGame() {
        guard let webDir = Bundle.main.url(forResource: "web", withExtension: nil),
              let indexURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "web")
        else {
            showError("Could not find game files.")
            return
        }

        webView.loadFileURL(indexURL, allowingReadAccessTo: webDir)
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
}
