import Foundation
import os.log

extension AppDelegate {
    internal func parseArguments() {
        let args = CommandLine.arguments

        if let mountIndex = args.firstIndex(of: "--mount-path") {
            if args.indices.contains(mountIndex+1) {
                let mountPath = args[mountIndex+1]
                asyncShell("/usr/bin/hdiutil detach \(mountPath)")
                asyncShell("/bin/rm -rf \(mountPath)")

                os_log(.debug, log: log, "DMG was unmounted and mountPath deleted")
            }
        }

        if let dmgIndex = args.firstIndex(of: "--dmg-path") {
            if args.indices.contains(dmgIndex+1) {
                asyncShell("/bin/rm -rf \(args[dmgIndex+1])")

                os_log(.debug, log: log, "DMG was deleted")
            }
        }
    }
}
