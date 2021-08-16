import Cocoa
import SystemConfiguration
import LivecamWallpaperUpdaterService

// see https://github.com/exelban/stats/blob/4351d25a222d00bfe8d74b5a169998c9aa6d4dfc/Kit/plugins/Updater.swift

public struct Version {
    public let current: String
    public let latest: String
    public let isNewVersion: Bool
    public let url: String

    public init(current: String, latest: String, isNewVersion: Bool, url: String) {
        self.current = current
        self.latest = latest
        self.isNewVersion = isNewVersion
        self.url = url
    }
}

public class Updater {
    public var latest: Version?
    private var observation: NSKeyValueObservation?

    private var url = "https://api.github.com/repos/pierreberger/livecamwallpaper/releases/latest"
    private let appName: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    private let currentVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

    public func check(completionHandler: @escaping (_ newVersion: Version?, _ error: Error?) -> Void) {
        getLastVersion { result, error in
            guard error == nil else {
                completionHandler(nil, error)
                return
            }

            let downloadURL: String = result![1]
            let lastVersion: String = result![0]
            let isNewVersion = self.currentVersion.compare(lastVersion, options: .numeric).rawValue == -1
            self.latest = Version(current: self.currentVersion, latest: lastVersion, isNewVersion: isNewVersion, url: downloadURL)
            completionHandler(self.latest, nil)
        }
    }

    private func getLastVersion(completionHandler: @escaping (_ result: [String]?, _ error: Error?) -> Void) {
        let url = URL(string: self.url)!
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }

            do {
                let response = try JSONSerialization.jsonObject(with: data, options: [])
                guard let jsonArray = response as? [String: Any] else {
                    completionHandler(nil, "parsing json")
                    return
                }

                let lastVersion = jsonArray["tag_name"] as? String

                guard let assets = jsonArray["assets"] as? [[String: Any]] else {
                    completionHandler(nil, "parsing assets")
                    return
                }

                if let asset = assets.first(where: {$0["name"] as! String == "\(self.appName).dmg"}) {
                    let downloadURL = asset["browser_download_url"] as? String
                    completionHandler([lastVersion!, downloadURL!], nil)
                }

            } catch {
                completionHandler(nil, error)
            }
        }.resume()
    }

    public func download(
        _ url: URL,
        progressHandler: @escaping (_ progress: Progress) -> Void = {_ in },
        doneHandler: @escaping (_ path: String) -> Void = {_ in }
    ) {

        let downloadTask = URLSession.shared.downloadTask(with: url) { urlOrNil, _, _ in
            guard let fileURL = urlOrNil else { return }
            NSLog(fileURL.debugDescription)
            do {
                let downloadsURL = try
                    FileManager.default.url(for: .documentDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: false)
                let updateFolder = downloadsURL.appendingPathComponent("updates")

                if !FileManager.default.fileExists(atPath: updateFolder.path) {
                    do {
                        try FileManager.default.createDirectory(atPath: updateFolder.path, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        print(error.localizedDescription)
                    }
                }

                let destinationURL = updateFolder.appendingPathComponent(url.lastPathComponent)

                self.copyFile(from: fileURL, to: destinationURL) { (path, error) in
                    if error != nil {
                        print("copy file error: \(error ?? "copy error")")
                        return
                    }

                    doneHandler(path)
                }
            } catch {
                print("file error: \(error)")
            }
        }

        self.observation = downloadTask.progress.observe(\.fractionCompleted) { progress, _ in
            progressHandler(progress)
        }

        downloadTask.resume()
    }

    private func copyFile(from: URL, to: URL, completionHandler: @escaping (_ path: String, _ error: Error?) -> Void) {
        var toPath = to
        let fileName = (URL(fileURLWithPath: to.absoluteString)).lastPathComponent
        let fileExt  = (URL(fileURLWithPath: to.absoluteString)).pathExtension
        var fileNameWithotSuffix: String!
        var newFileName: String!
        var counter = 0

        if fileName.hasSuffix(fileExt) {
            fileNameWithotSuffix = String(fileName.prefix(fileName.count - (fileExt.count+1)))
        }

        while toPath.checkFileExist() {
            counter += 1
            newFileName =  "\(fileNameWithotSuffix!)-\(counter).\(fileExt)"
            toPath = to.deletingLastPathComponent().appendingPathComponent(newFileName)
        }

        do {
            try FileManager.default.moveItem(at: from, to: toPath)
            completionHandler(toPath.absoluteString, nil)
        } catch {
            completionHandler("", error)
        }
    }

    public func install(path: String) {
        let pwd = Bundle.main.bundleURL.absoluteString
            .replacingOccurrences(of: "file://", with: "")
            .replacingOccurrences(of: "LivecamWallpaper.app", with: "")
            .replacingOccurrences(of: "//", with: "/")

        let connection = NSXPCConnection(serviceName: "fr.pierreberger.LivecamWallpaperUpdaterService")
        connection.remoteObjectInterface = NSXPCInterface(with: LivecamWallpaperUpdaterServiceProtocol.self)
        connection.resume()

        let service = connection.remoteObjectProxyWithErrorHandler { error in
            print("Received error:", error)
        } as? LivecamWallpaperUpdaterServiceProtocol

        service?.installNewVersion(
            path,
            tmpDir: NSTemporaryDirectory(),
            pwd: pwd
        ) { response in
            print("Response from XPC service:", response)
            guard response != "OK" else { exit(0) }
        }

    }
}
