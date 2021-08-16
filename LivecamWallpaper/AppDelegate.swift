import Bugsnag
import Cocoa
import Defaults
import SwiftUI
import os.log

var log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "LivecamWallpaper")

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var menu: NSMenu!
    var window: NSWindow!
    var isError = false

    var refreshTimer: Timer?

    func applicationDidFinishLaunching(_: Notification) {
        Bugsnag.start()
        if MyApp.isFirstLaunch {
            openPreferences()
        }
        setup()
    }

    func changeWallpaper(savedUrl: URL) {
        do {
            for nsScreen in NSScreen.screens {
                try NSWorkspace.shared.setDesktopImageURL(savedUrl, for: nsScreen, options: [:])
            }
            clearFolder()
            clearError()
            refreshMenu()
        } catch {
            setError(message: error.localizedDescription)
        }
    }

    func downloadImage(url: URL) {
        URLSession.shared.downloadTask(with: url) { urlOrNil, _, _ in
            guard let fileURL = urlOrNil else { return }
            do {

                let documentsURL = try
                    FileManager.default.url(for: .documentDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: false)

                let dataPath = documentsURL.appendingPathComponent("wallpaper")
                if !FileManager.default.fileExists(atPath: dataPath.path) {
                    do {
                        try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        print(error.localizedDescription)
                    }
                }

                let savedURL = dataPath.appendingPathComponent(String(NSDate().timeIntervalSince1970))
                try FileManager.default.moveItem(at: fileURL, to: savedURL)

                self.changeWallpaper(savedUrl: savedURL)
            } catch {
                self.setError(message: error.localizedDescription)
            }
        }.resume()
    }

    func changeWallpaper(livecamURL: URL) {
        SkapingController.shared.fetchImage(livecamURL: livecamURL) { error in
            guard error == nil else {
                self.setError(message: error!)
                return
            }
            NSLog("Wallpaper updated")
        }
    }

    @objc func refreshWallpaper() {
        if Defaults[.livecamUrl] != "" {
            let url = URL(string: Defaults[.livecamUrl])!
            self.changeWallpaper(livecamURL: url)
        } else {
            NSLog("Error: Url is missing")
            setError(message: "Url is missing")
        }
    }

    func clearFolder() {
        let fileManager = FileManager.default
        let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let wallpaperDir = documentsUrl.appendingPathComponent("wallpaper")
        guard var filePaths = try?
                fileManager.contentsOfDirectory(at: wallpaperDir, includingPropertiesForKeys: nil, options: [])
        else { return }
        filePaths.sort {
            $0.absoluteString < $1.absoluteString
        }
        if filePaths.count > 1 {
            for key in 0...filePaths.count - 2 {
                try? fileManager.removeItem(at: filePaths[key])
            }
        }
    }

    func setError(message: String) {
        self.displayError(message: "Error: \(message.wrapped(atLength: 36))")
        isError = true
        refreshMenu()
    }

    func clearError() {
        menu.item(at: 0)?.isHidden = true
        menu.item(at: 1)?.isHidden = true
            isError = false
    }

    func displayError(message: String) {
        menu.item(at: 0)?.attributedTitle = NSAttributedString(string: message)
            menu.item(at: 0)?.isHidden = false
            menu.item(at: 1)?.isHidden = false
    }

    func refreshMenu() {
        menu.item(at: 2)?.title = Defaults[.livecamUrl].truncating(to: 30)
        menu.item(at: 3)?.title = Defaults[.livecamTitle].truncating(to: 30)
        menu.item(at: 2)?.isHidden = false
        menu.item(at: 3)?.isHidden = false
        menu.item(at: 4)?.isHidden = false

        if  Defaults[.livecamUrl] == "" {
            menu.item(at: 2)?.isHidden = true
            menu.item(at: 3)?.isHidden = true
        }

        if  Defaults[.livecamTitle] == "" {
            menu.item(at: 3)?.isHidden = true
        }

        if menu.item(at: 2)?.isHidden == true && menu.item(at: 3)?.isHidden == true {
            menu.item(at: 4)?.isHidden = true
        }
    }

    func resetInterval() {
        refreshTimer?.invalidate()
        refreshTimer =
            Timer.scheduledTimer(
                timeInterval: Double(Defaults[.refreshInterval] * 60),
                target: self,
                selector: #selector(refreshWallpaper),
                userInfo: nil,
                repeats: true
            )
        refreshTimer?.fire()
    }

    func setupMenu() {
        let errorMenu = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        errorMenu.isHidden = true
        menu.addItem(errorMenu)
        menu.addItem(.separator())

        menu.item(at: 1)?.isHidden = true

        let menuUrl = NSMenuItem(title: "\(Defaults[.livecamUrl])".truncating(to: 30), action: nil, keyEquivalent: "")
        menuUrl.isEnabled = false

        let menuTitle =
            NSMenuItem(title: "\(Defaults[.livecamTitle])".truncating(to: 30), action: nil, keyEquivalent: "")
        menuTitle.isEnabled = false

        if Defaults[.livecamUrl] == "" && Defaults[.livecamTitle] == "" {
            menuUrl.isHidden = true
            menuTitle.isHidden = true
        }

        menu.addItem(menuUrl)
        menu.addItem(menuTitle)
        menu.addItem(.separator())

        let menuVersion =
            NSMenuItem(
                title: "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown")",
                action: nil, keyEquivalent: ""
            )
        menuVersion.isEnabled = false
        menu.addItem(menuVersion)

        menu.addItem(withTitle: "Preferences", action: #selector(openPreferences), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(terminate), keyEquivalent: "q")
    }

    func setup() {
        menu = NSMenu()
        setupMenu()
        statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        statusBarItem.menu = menu

        if let statusBarButton = statusBarItem.button {
            statusBarButton.image = NSImage(named: "StatusIcon")
        }
    }

    @objc func openPreferences() {
        NSLog("Open preferences window")
        NSApp.setActivationPolicy(.regular)
        let contentView = PreferencesView()
        if window != nil {
            window.close()
        }
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 570),
            styleMask: [.closable, .titled],
            backing: .buffered,
            defer: false
        )

        NotificationCenter.default.addObserver(
            self, selector: #selector(AppDelegate.windowClosed), name: NSWindow.willCloseNotification, object: nil
        )

        window.title = "LivecamWallpaper Preferences"
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)

        NSApplication.shared.activate(ignoringOtherApps: true)

        let controller = NSWindowController(window: window)
        controller.showWindow(self)
        window.center()
        window.orderFrontRegardless()
    }

    @objc
    func windowClosed(notification: NSNotification) {
        let window = notification.object as? NSWindow
        if let windowTitle = window?.title {
            if windowTitle == "LivecamWallpaper Preferences" {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    @objc func terminate() {
        NSLog("Quit Application")
        NSApp.terminate(self)
    }
}
