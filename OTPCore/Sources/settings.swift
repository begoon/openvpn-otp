import Foundation

public let UserHome = FileManager.default.homeDirectoryForCurrentUser

public let SettingsFilename = UserHome.appendingPathComponent(".otpvpn/settings.json")

public struct Account: Codable {
    public var label: String
    public var username: String
    public var password: String
    public var secret: String
    
    public var otp: String {
        password.replacingOccurrences(of: "<@>", with: totp(using: self.secret))
    }
    
    public var certificate: String {
        SettingsFilename.deletingLastPathComponent().appendingPathComponent(label + ".ovpn").path
    }
}

let DefaultSettings = """
{
    "account": {
        "label": "?",
        "username": "?",
        "password": "?<@>",
        "secret": "?"
    },
    "openvpn": "/opt/homebrew/sbin/openvpn",
    "kill": "/bin/kill",
    "sudo": "/usr/bin/sudo"
}
"""

public struct Settings: Codable {
    public var account: Account
    
    public var openvpn: String
    public var sudo: String
    public var kill: String
    
    public var error: String?
    public var ok: Bool { error == nil }
    
    public init(from text: String) {
        do {
            self = try JSONDecoder().decode(Settings.self, from: Data(text.utf8))
        } catch {
            self = Self.defaults()
            self.error = "\(error)"
            print("settings decode error: \(self.error!)")
        }
    }

    public init(from fileURL: URL = SettingsFilename) {
        print("load settings from \(fileURL.path)")
        do {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            self.init(from: contents)
        } catch {
            self = Self.defaults()
            self.error = "\(error.localizedDescription)"
        }
    }
    
    static private func defaults() -> Self {
        return try! JSONDecoder().decode(Settings.self, from: Data(DefaultSettings.utf8))
    }
}
