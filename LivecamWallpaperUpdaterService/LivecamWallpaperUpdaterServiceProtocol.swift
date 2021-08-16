import Foundation

@objc public protocol LivecamWallpaperUpdaterServiceProtocol {
    func installNewVersion(_ path: String, tmpDir: String, pwd: String, withReply reply: @escaping (String) -> Void)
}
