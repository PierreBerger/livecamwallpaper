import Foundation

let delegate = LivecamWallpaperUpdaterServiceDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate
listener.resume()
