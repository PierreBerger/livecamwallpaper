import SwiftUI
import Defaults

struct PreferencesView: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ServicesSection()
            Divider()
            SettingsSection()
            Divider()
            PreferencesSection()
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
            Button(action: {
                NSLog("Update click")
                livecamUrl = text
                AppDelegate.shared.resetInterval()
            }) {
                Text("Update")
            }
        }
    }
}

struct PreferencesSection: View {
    var refreshTimes = [10, 20, 30, 60]
    @Default(.refreshInterval) var refreshInterval
  

    var body: some View {
       
        HStack{
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

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
