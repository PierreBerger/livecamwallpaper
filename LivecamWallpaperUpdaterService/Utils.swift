import Foundation

public func asyncShell(_ args: String) {
    let task = Process()
    let pipe = Pipe()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", args]
    task.standardOutput = pipe
    task.launch()
}

public func syncShell(_ args: String) -> String {
    let task = Process()
    let pipe = Pipe()
    task.standardOutput = pipe
//    task.standardError = pipe
    task.arguments = ["-c", args]
    task.launchPath = "/bin/sh"
    task.launch()
    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()

    let output = String(data: data, encoding: .utf8)!
    return output
}
