import SwiftUI
import WebKit

/// Toont de meegebundelde web/index.html. Alles staat in de app zelf,
/// dus hij werkt ook zonder internet (alleen de lettertypes vallen dan terug).
struct WebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default() // onthoudt spelers en slokken-niveau

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.122, green: 0.302, blue: 0.227, alpha: 1)
        // De pagina regelt zelf de safe areas via env(safe-area-inset-*).
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = true

        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "web") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}
