import Foundation

class LivecamWallpaperUpdaterServiceDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        let exportedObject = LivecamWallpaperUpdaterService()
        newConnection.exportedInterface = NSXPCInterface(with: LivecamWallpaperUpdaterServiceProtocol.self)
        newConnection.exportedObject = exportedObject
        newConnection.resume()
        return true
    }
}
