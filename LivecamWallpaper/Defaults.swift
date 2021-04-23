import Defaults

extension Defaults.Keys {
    static let livecamUrl = Key<String>("livecamUrl", default: "")
    static let livecamTitle = Key<String>("livecamTitle", default: "")
    static let refreshInterval = Key<Int>("refreshInterval", default: 10)
}
