import Foundation

class LivecamWallpaperUpdaterService: NSObject, LivecamWallpaperUpdaterServiceProtocol {
    func installNewVersion(_ path: String, tmpDir: String, pwd: String, withReply reply: @escaping (String) -> Void) {
        NSLog("Started new version installation...")

        _ = syncShell("mkdir /tmp/LivecamWallpaper") // make sure that directory exist
        let res = syncShell("/usr/bin/hdiutil attach \(path) -mountpoint /tmp/LivecamWallpaper -noverify -nobrowse -noautoopen") // mount the dmg

        NSLog("DMG is mounted")

        if res.contains("is busy") { // dmg can be busy, if yes, unmount it and mount again
            print("DMG is busy, remounting")

            _ = syncShell("/usr/bin/hdiutil detach \(tmpDir)/LivecamWallpaper")
            _ = syncShell("/usr/bin/hdiutil attach \(path) -mountpoint /tmp/LivecamWallpaper -noverify -nobrowse -noautoopen")
        }

        _ = syncShell("cp -rf /tmp/LivecamWallpaper/LivecamWallpaper.app/Contents/Resources/Scripts/updater.sh \(tmpDir)/updater.sh")

        NSLog("Script is copied to $TMPDIR/updater.sh")

        let dmg = path.replacingOccurrences(of: "file://", with: "")

        asyncShell("sh \(tmpDir)/updater.sh --app \(pwd) --dmg \(dmg) >>$TMPDIR/log &") // run updater script in in background

        NSLog("Run updater.sh with app: \(pwd) and dmg: \(dmg)")
        reply("OK")
    }
}
