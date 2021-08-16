import SwiftUI
import Cocoa

class UpdateWindow: NSWindow, NSWindowDelegate {
    private let viewController: UpdateViewController = UpdateViewController()
    init() {
        let width = NSScreen.main!.frame.width
        let height = NSScreen.main!.frame.height
        super.init(
            contentRect: NSRect(
                x: width - self.viewController.view.frame.width,
                y: height - self.viewController.view.frame.height,
                width: self.viewController.view.frame.width,
                height: self.viewController.view.frame.height
            ),
            styleMask: [.closable, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )

        self.contentViewController = self.viewController
        self.animationBehavior = .default
        self.collectionBehavior = .transient
        self.titlebarAppearsTransparent = true
        self.appearance = NSAppearance(named: .darkAqua)
        self.center()
        self.setIsVisible(false)

        let windowController = NSWindowController()
        windowController.window = self
        windowController.loadWindow()
    }

    public func open(_ version: Version) {
        if !self.isVisible {
            self.setIsVisible(true)
            self.makeKeyAndOrderFront(nil)
        }
        self.viewController.open(version)
    }
}

private class UpdateView: NSView {
    private var version: Version?
    private var path: String = ""

    override init(frame: NSRect) {
        super.init(frame: CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height: frame.height))
        self.wantsLayer = true

        let sidebar = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        sidebar.material = .sidebar
        sidebar.blendingMode = .behindWindow
        sidebar.state = .active

        self.addSubview(sidebar)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func noUpdates() {
        let view: NSView = NSView(frame: NSRect(x: 10, y: 10, width: self.frame.width - 20, height: self.frame.height - 20))

        let title: NSTextView = NSTextView(frame: NSRect(x: 0, y: ((view.frame.height - 18)/2), width: view.frame.width, height: 40))
        title.font = NSFont.systemFont(ofSize: 14)
        title.backgroundColor = .clear
        title.alignment = .center
        title.string = "The latest version of LivecamWallpaper is installed"

        let button: NSButton = NSButton(frame: NSRect(x: 0, y: 0, width: view.frame.width, height: 26))
        button.title = "Close"
        button.bezelStyle = .rounded
        button.action = #selector(self.close)
        button.target = self

        view.addSubview(button)
        view.addSubview(title)
        self.addSubview(view)
    }

    public func newVersion(_ version: Version) {
        self.version = version
        let view: NSView = NSView(frame: NSRect(x: 10, y: 10, width: self.frame.width - 20, height: self.frame.height - 20 - 26))

        let title: NSTextView = NSTextView(frame: NSRect(x: 0, y: view.frame.height - 20, width: view.frame.width, height: 18))
        title.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        title.alignment = .center
        title.backgroundColor = .clear
        title.string = "New version available"

        let currentVersionString = "Current version: \(version.current)"
        let currentVersionWidth = currentVersionString.widthOfString(usingFont: .systemFont(ofSize: 13, weight: .light))
        let currentVersion: NSTextView = NSTextView(frame: NSRect(
            x: (view.frame.width-currentVersionWidth)/2,
            y: title.frame.origin.y - 40,
            width: currentVersionWidth,
            height: 16
        ))
        currentVersion.string = currentVersionString
        currentVersion.backgroundColor = .clear

        let latestVersionString = "Latest version: \(version.latest)"
        let latestVersionWidth = latestVersionString.widthOfString(usingFont: .systemFont(ofSize: 13, weight: .light))
        let latestVersion: NSTextView = NSTextView(frame: NSRect(
        x: (view.frame.width-currentVersionWidth)/2,
            y: currentVersion.frame.origin.y - 22,
            width: latestVersionWidth,
            height: 16
        ))
        latestVersion.string = latestVersionString
        latestVersion.backgroundColor = .clear

        let closeButton: NSButton = NSButton(frame: NSRect(x: 0, y: 0, width: view.frame.width/2, height: 26))
        closeButton.title = "Close"
        closeButton.bezelStyle = .rounded
        closeButton.action = #selector(self.close)
        closeButton.target = self

        let downloadButton: NSButton = NSButton(frame: NSRect(x: view.frame.width/2, y: 0, width: view.frame.width/2, height: 26))
        downloadButton.title = "Download"
        downloadButton.bezelStyle = .rounded
        downloadButton.action = #selector(self.download)
        downloadButton.target = self

        view.addSubview(title)
        view.addSubview(currentVersion)
        view.addSubview(latestVersion)
        view.addSubview(closeButton)
        view.addSubview(downloadButton)
        self.addSubview(view)
    }

    @objc private func close(_ sender: Any) {
        self.window?.close()
    }

    public func clear() {
        self.subviews.filter { !($0 is NSVisualEffectView) }.forEach { $0.removeFromSuperview() }
    }

    @objc private func download(_ sender: Any) {
        guard let urlString = self.version?.url, let url = URL(string: urlString) else {
            return
        }

        self.clear()

        let view: NSView = NSView(frame: NSRect(x: 10, y: 10, width: self.frame.width - 20, height: self.frame.height - 20 - 26))

        let title: NSTextView = NSTextView(frame: NSRect(x: 0, y: view.frame.height - 28, width: view.frame.width, height: 18))
        title.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        title.alignment = .center
        title.string = "Downloading..."
        title.backgroundColor = .clear

        let progressBar: NSProgressIndicator = NSProgressIndicator()
        progressBar.frame = NSRect(x: 20, y: 64, width: view.frame.width - 40, height: 22)
        progressBar.minValue = 0
        progressBar.maxValue = 1
        progressBar.isIndeterminate = false

        let state: NSTextView = NSTextView(frame: NSRect(x: 0, y: 48, width: view.frame.width, height: 18))
        state.font = NSFont.systemFont(ofSize: 12, weight: .light)
        state.alignment = .center
        state.textColor = .secondaryLabelColor
        state.string = "0%"
        state.backgroundColor = .clear

        let closeButton: NSButton = NSButton(frame: NSRect(x: 0, y: 0, width: view.frame.width, height: 26))
        closeButton.title = "Cancel"
        closeButton.bezelStyle = .rounded
        closeButton.action = #selector(self.close)
        closeButton.target = self

        let installButton: NSButton = NSButton(frame: NSRect(x: view.frame.width/2, y: 0, width: view.frame.width/2, height: 26))
        installButton.title = "Install"
        installButton.bezelStyle = .rounded
        installButton.action = #selector(self.install)
        installButton.target = self
        installButton.isHidden = true

        updater.download(url, progressHandler: { progress in
            DispatchQueue.main.async {
                progressBar.doubleValue = progress.fractionCompleted
                state.string = "\(Int(progress.fractionCompleted*100))%"
            }
        }, doneHandler: { path in
            self.path = path
            DispatchQueue.main.async {
                closeButton.setFrameSize(NSSize(width: view.frame.width/2, height: closeButton.frame.height))
                installButton.isHidden = false
            }
        })

        view.addSubview(title)
        view.addSubview(progressBar)
        view.addSubview(state)
        view.addSubview(closeButton)
        view.addSubview(installButton)
        self.addSubview(view)
    }

    @objc private func install(_ sender: Any) {
        updater.install(path: self.path)

    }
}

private class UpdateViewController: NSViewController {
    private var update: UpdateView

    public init() {
        self.update = UpdateView(frame: NSRect(x: 0, y: 0, width: 280, height: 176))
        super.init(nibName: nil, bundle: nil)
        self.view = self.update
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func open(_ version: Version) {
        self.update.clear()

        if version.isNewVersion {
            self.update.newVersion(version)
            return
        }
        self.update.noUpdates()
    }
}
