import Foundation

let UserHome = FileManager.default.homeDirectoryForCurrentUser

let SettingsFilename = UserHome.appendingPathComponent(".otpvpn/settings.json")

struct Account: Codable {
    var label: String
    var username: String
    var password: String
    var secret: String
    
    var otp: String {
        password.replacingOccurrences(of: "<@>", with: totp(using: self.secret))
    }
    
    var certificate: String {
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

struct Settings: Codable {
    var account: Account
    
    var openvpn: String
    var sudo: String
    var kill: String
    
    var error: String?
    var ok: Bool { error == nil }
    
    init(from text: String) {
        do {
            self = try JSONDecoder().decode(Settings.self, from: Data(text.utf8))
        } catch {
            self = Self.defaults()
            self.error = "\(error)"
            print("settings decode error: \(self.error!)")
        }
    }

    init(from fileURL: URL = SettingsFilename) {
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
