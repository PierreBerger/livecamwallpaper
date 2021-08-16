import Defaults
import SwiftUI
import os.log

let updater = Updater()
private let updateWindow: UpdateWindow = UpdateWindow()

struct PreferencesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ServicesSection()
            Divider()
            SettingsSection()
            Divider()
            PreferencesSection()
            Divider()
            UpdateSection()
        }
        .padding()
    }
}

struct ServicesSection: View {
    var services = ["Skaping"]
    @State var selectedService = "Skaping"

    var body: some View {
        Text("Livecam services").font(.headline).bold()
        Picker("Service :", selection: $selectedService) {
            ForEach(services, id: \.self) {
                Text($0)
            }
        }.frame(width: 150, alignment: .leading)
    }
}

struct SettingsSection: View {
    @Default(.livecamUrl) var livecamUrl
    @State var text = Defaults[.livecamUrl]

    var body: some View {
        Text("Settings").font(.headline).bold()
        HStack {
            Text("Livecam Url :")
            TextField("https://www.skaping.com/grenoble/col-de-porte", text: $text)
            Button("Update", action: {
                NSLog("Update click")
                livecamUrl = text
                AppDelegate.shared.resetInterval()
            })
        }
    }
}

struct PreferencesSection: View {
    var refreshTimes = [10, 20, 30, 60]
    @Default(.refreshInterval) var refreshInterval

    var body: some View {
        HStack {
            Text("Refresh interval :")
            Picker("", selection: $refreshInterval) {
                ForEach(refreshTimes, id: \.self) {
                    Text("\($0)")
                }
            }.frame(width: 70)
            Text("minutes")
                .padding(.leading, 4)
        }
    }
}

struct UpdateSection: View {
    var body: some View {
        VStack(alignment: .center) {
            Image(nsImage: NSImage(named: "AppIcon")!).resizable().frame(width: 120.0, height: 120.0)
            Text("LivecamWallpaper").font(.system(size: 20)).bold()
            Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)")
                .foregroundColor(.gray)
            Button("Check for update", action: {
                update()
            })
        }.frame(width: 700, alignment: .center)
    }
}

func update() {
    updater.check { result, error in
        if error != nil {
            os_log(.error, log: log, "error updater.check(): %s", "\(error!.localizedDescription)")
            return
        }

        guard error == nil, let version: Version = result else {
            os_log(.error, log: log, "download error(): %s", "\(error!.localizedDescription)")
            return
        }

        DispatchQueue.main.async(execute: {
            updateWindow.open(version)
            return
        })
    }

}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
