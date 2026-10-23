import AppKit
import WebKit

// A minimal private window that hosts Telegram Web and stays out of screen
// captures / screen sharing. The window is owned by this process, so we can
// set NSWindow.sharingType = .none on it — the same supported API GhostLayer
// uses. This does NOT touch Rambox or any other app's windows.
final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate {
    private var window: NSWindow!
    private var webView: WKWebView!
    private var toggleItem: NSMenuItem?
    private var captureHidden = true   // start invisible to capture

    private let homeURL = URL(string: "https://web.telegram.org/k/")!
    private let telegramHosts = ["web.telegram.org", "telegram.org"]

    func applicationDidFinishLaunching(_ notification: Notification) {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()   // persistent: keeps you logged in
        config.mediaTypesRequiringUserActionForPlayback = []

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1040, height: 740),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false)
        window.title = "Telegram — Private"
        window.contentView = webView
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 1040, height: 740))   // default size
        window.center()
        // Remember size + position across launches (drag to resize once, it sticks).
        window.setFrameAutosaveName("GhostTGMainWindow")

        setupMenu()
        applyCaptureHidden()

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        webView.load(URLRequest(url: homeURL))
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    // MARK: - Capture visibility

    private func applyCaptureHidden() {
        // .none   -> excluded from screenshots / recording / screen sharing
        // .readOnly -> normal, visible to capture
        window.sharingType = captureHidden ? .none : .readOnly
        // Checkmark in the menu shows current state, keeping the title clean.
        toggleItem?.state = captureHidden ? .on : .off
    }

    @objc private func toggleCapture() {
        captureHidden.toggle()
        applyCaptureHidden()
    }

    // MARK: - Links

    // Keep Telegram inside the window; open other links in the default browser.
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url,
           let host = url.host,
           !telegramHosts.contains(where: { host == $0 || host.hasSuffix("." + $0) }) {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    // target=_blank links -> open externally instead of a dead popup
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url { NSWorkspace.shared.open(url) }
        return nil
    }

    // MARK: - Menu (so Cmd+C / Cmd+V and the toggle work)

    private func setupMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        let toggle = appMenu.addItem(withTitle: "Hidden from screen capture",
                                     action: #selector(toggleCapture), keyEquivalent: "p")
        toggle.keyEquivalentModifierMask = [.command, .shift]
        toggle.target = self
        toggle.state = captureHidden ? .on : .off
        toggleItem = toggle
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editItem.submenu = editMenu
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: Selector(("cut:")), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: Selector(("copy:")), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: Selector(("paste:")), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: Selector(("selectAll:")), keyEquivalent: "a")

        NSApp.mainMenu = mainMenu
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
