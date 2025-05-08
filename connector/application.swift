import SwiftUI

import OTPCore

struct ConsoleView: View {
    @Binding public var content: String

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(content.components(separatedBy: .newlines).enumerated()), id: \.0) { _, line in
                            HStack(alignment: .firstTextBaseline, spacing: 0) { colored(line).0 }
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .textSelection(.enabled)
                    .font(.system(size: 10))
                    .font(.system(.body, design: .monospaced))
                    .id("bottom")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minWidth: 600, minHeight: 100)
                .onChange(of: self.content) { _, _ in
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }
        }
    }
}

public extension NSWindow {
    func hide() { orderOut(nil) }
    func show() { makeKeyAndOrderFront(nil) }
    internal func visibility(_ visible: Bool) { visible ? show() : hide() }
}

enum ConnectionState {
    case disconnected
    case connected
    case connecting
}

@main
struct OTP: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var state: ConnectionState = .disconnected

    @State private var ip: String = "127.0.0.1"

    @State private var consoleVisible: Bool = false
    @State public var console: String = ""

    @State private var processIdentifier: Int32 = 0

    @State private var temporaryCredentialFilename = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

    @State private var settings = Settings()

    @StateObject private var animator = IconAnimator(symbols: ["cable.connector.video", "network"])

    func visibility(_ visible: Bool) {
        NSApp.windows.filter { $0.className == "SwiftUI.AppKitWindow" }.forEach { window in window.visibility(visible) }
    }

    let icons: [ConnectionState: String] = [
        .disconnected: "network.slash",
        .connected: "network",
        .connecting: "cable.connector.video",
    ]

    func trace(_ text: String, terminator: String = "\n", color: String? = nil) {
        print(text, terminator: terminator)
        if !console.isEmpty && console.last != "\n" { console += "\n" }
        let text: String = color == nil ? text : "@" + color! + ":" + text
        console += text + terminator
    }

    func updateIP() {
        Task {
            self.ip = try await fetchIP()
            trace("\(self.ip)", color: "blue")
        }
    }

    var body: some Scene {
        Window("VPN/OTP", id: "VPN/OTP") {
            if settings.ok {
                ConsoleView(content: self.$console)
                    .onAppear {
                        print(".onAppear()")
                        self.visibility(false)
                        self.updateIP()
                        trace(commit)
                    }
                    .onChange(of: self.consoleVisible) { before, visible in
                        print(".onChange() visibility from", before, visible)
                        self.visibility(visible)
                    }.windowMinimizeBehavior(.disabled).windowDismissBehavior(.disabled)
            } else {
                Text(settings.error!).textSelection(.enabled).padding().font(.largeTitle)
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }.restorationBehavior(.disabled).commandsRemoved()
        MenuBarExtra("-", systemImage: state == .connecting ? animator.currentSymbol : icons[state]!) {
            if settings.ok {
                Button(action: {
                    if self.state == .connected {
                        self.kill()
                    } else {
                        do {
                            let command = try openvpnCommand()
                            self.start(command)
                            self.state = .connecting
                            trace("CONNECTING", color: "green")
                        } catch {
                            trace("ERROR: \(error.localizedDescription)", color: "red")
                        }
                    }

                }) {
                    HStack {
                        Image(systemName: state == .connected ? "checkmark.circle.fill" : "circle")
                        Text(state == .connected ? "Disconnect" : "Connect")
                    }
                }
                Text(self.ip).bold()
                Button("One-time password") {
                    NSPasteboard.general.clearContents()
                    let password = settings.account.otp
                    if !NSPasteboard.general.setString(password, forType: .string) {
                        trace("NSPasteboard.general.setString failed", color: "red")
                    }
                    trace("OTP: \(password)", color: "indigo")
                }
                Toggle("Console", isOn: self.$consoleVisible)
            }
            if state == .disconnected {
                Button("Quit") { NSApplication.shared.terminate(nil) }.keyboardShortcut("q")
            }
            if commit != "..." {
                Divider()
                Text(commit)
            }
        }
    }

    func start(_ command: String) {
        let args = command.split(separator: " ").map { String($0) }

        trace("COMMAND: \(command)", color: "gray")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: args.first!)
        process.arguments = Array(args.dropFirst())

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        process.terminationHandler = { process in
            let reason = (process.terminationReason == .exit) ? "exit" : "uncaught signal"
            Task { @MainActor in
                trace("process exited with \(process.terminationStatus) due to \(reason)")
                removeCredentialsFile()
                self.state = .disconnected
            }
        }

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let text = String(data: data, encoding: .utf8), !text.isEmpty {
                Task { @MainActor in trace(text, terminator: "") }
                if text.contains("Initialization Sequence Completed") {
                    Task { @MainActor in
                        removeCredentialsFile()
                        trace("CONNECTED", color: "green")
                        self.updateIP()
                        self.state = .connected
                    }
                }
                if text.contains("SIGTERM") {
                    Task { @MainActor in
                        removeCredentialsFile()
                        trace("DISCONNECTED", color: "green")
                        self.updateIP()
                        self.state = .disconnected
                    }
                }
            }
        }

        do {
            try process.run()
            processIdentifier = Int32(process.processIdentifier)
            trace("process started \(processIdentifier)", color: "brown")
        } catch {
            trace("process error: \(error.localizedDescription)", color: "red")
            removeCredentialsFile()
        }
    }

    func kill() {
        print("\(settings.kill): \(processIdentifier)")

        let killer = Process()

        let command = "\(settings.sudo) -S \(settings.kill) \(processIdentifier)"
        trace("COMMAND: \(command)", color: "gray")

        let args = command.split(separator: " ").map { String($0) }

        killer.executableURL = URL(fileURLWithPath: args.first!)
        killer.arguments = Array(args.dropFirst())

        do {
            try killer.run()
        } catch {
            trace("ERROR: /bin/kill: \(error.localizedDescription)", color: "red")
        }
    }

    func openvpnCommand() throws -> String {
        let account = settings.account
        let credentials = account.username + "\n" + account.otp + "\n"

        try credentials.write(to: temporaryCredentialFilename, atomically: true, encoding: .utf8)
        print("credentials written to \(temporaryCredentialFilename.path)")

        let command = [
            "\(settings.sudo)", "-S",

            "\(settings.openvpn)",
            "--config", account.certificate,
            "--auth-nocache",
            "--auth-user-pass", temporaryCredentialFilename.path,
        ].joined(separator: " ")

        trace("\(command)", color: "cyan")
        return command
    }

    func removeCredentialsFile() {
        if !FileManager.default.fileExists(atPath: temporaryCredentialFilename.path) { return }
        trace("delete temporary credentials file \(temporaryCredentialFilename.path)", color: "gray")
        do {
            try FileManager.default.removeItem(at: temporaryCredentialFilename)
        } catch {}
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("---")
        for window in NSApp.windows {
            print(
                window,
                "window=\(window.identifier?.rawValue ?? "?")",
                "visible=\(window.isVisible)",
                "restorable=\(window.isRestorable)"
            )
            if window.className == "SwiftUI.AppKitWindow" {
                window.hide()
            }
        }
        print("---")
    }
}

func fetchIP() async throws -> String {
    guard let url = URL(string: "https://api.ipify.org") else { throw URLError(.badURL) }

    let configuration = URLSessionConfiguration.ephemeral
    configuration.waitsForConnectivity = true
    let session = URLSession(configuration: configuration)
    defer { session.invalidateAndCancel() }

    let data = try await session.data(from: url).0
    return String(data: data, encoding: .utf8)!
}

class IconAnimator: ObservableObject {
    @Published var currentSymbol: String

    private let symbols: [String]
    private var index = 0
    private var timer: Timer?

    init(symbols: [String]) {
        self.symbols = symbols
        currentSymbol = symbols[0]
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.index = (self.index + 1) % self.symbols.count
            self.currentSymbol = self.symbols[self.index]
        }
    }

    deinit {
        timer?.invalidate()
    }
}
