import SwiftUI
import AVFoundation
import WebKit

// --- 1. DATA MODELS ---
struct UserApp: Codable, Identifiable {
    var id = UUID()
    var name: String
    var icon: String
    var color: String
    var type: AppType
    var content: String
    enum AppType: String, Codable { case code, noCode }
}

// --- 2. MAIN SYSTEM ---
struct ContentView: View {
    @State private var openedApp: String? = nil
    @AppStorage("user_apps_vFinal_v2") var savedAppsData: Data = Data()
    @AppStorage("os_notes_persistent") var notes: String = ""
    
    // SAFE DECODING: Prevents compiler from crashing if data is empty
    var userApps: [UserApp] {
        guard !savedAppsData.isEmpty else { return [] }
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([UserApp].self, from: savedAppsData) {
            return decoded
        }
        return []
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(colors: [Color(hex: "1e293b"), .black], center: .center, startRadius: 2, endRadius: 700)
                .ignoresSafeArea()
            
            VStack {
                // Status Bar
                HStack {
                    Text(Date(), style: .time).font(.system(.caption, design: .rounded)).bold()
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "video.fill")
                        Image(systemName: "mic.fill")
                        Image(systemName: "battery.100")
                    }.font(.system(size: 12))
                }.foregroundColor(.white).padding(.horizontal, 30).padding(.top, 10)

                // App Grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 25) {
                        OSIcon(name: "Camera", icon: "camera.fill", color: .gray) { openedApp = "Camera" }
                        OSIcon(name: "Dev Studio", icon: "terminal.fill", color: .blue) { openedApp = "Dev" }
                        OSIcon(name: "Notes", icon: "note.text", color: .yellow) { openedApp = "Notes" }
                        OSIcon(name: "Music", icon: "music.note", color: .pink) { openedApp = "Music" }
                        
                        OSIcon(name: "Dash", icon: "bolt.fill", color: .orange) { openedApp = "Dash" }
                        OSIcon(name: "Memory", icon: "brain.fill", color: .green) { openedApp = "Memory" }
                        OSIcon(name: "Titan", icon: "hand.tap.fill", color: .red) { openedApp = "Titan" }
                        
                        ForEach(userApps) { app in
                            OSIcon(name: app.name, icon: "app.fill", color: Color(hex: app.color)) {
                                openedApp = "USER_\(app.id.uuidString)"
                            }
                        }
                    }.padding(25)
                }
                
                Spacer()
                
                // Dock
                HStack(spacing: 30) {
                    Image(systemName: "phone.fill").foregroundColor(.green)
                    Image(systemName: "safari.fill").foregroundColor(.blue)
                    Image(systemName: "message.fill").foregroundColor(.green)
                }
                .font(.title2).padding(.vertical, 15).padding(.horizontal, 40)
                .background(.ultraThinMaterial).cornerRadius(30).padding(.bottom, 15)
            }

            // WINDOW MANAGER
            if let active = openedApp {
                ZStack {
                    Color(.systemBackground).ignoresSafeArea()
                    VStack(spacing: 0) {
                        HStack {
                            Text(active.contains("USER") ? "App Runner" : active).bold()
                            Spacer()
                            Button("Exit") { withAnimation { openedApp = nil } }.bold()
                        }.padding().background(.ultraThinMaterial)
                        
                        Group {
                            if active == "Camera" { CameraView() }
                            else if active == "Dev" { DevStudioView() }
                            else if active == "Notes" { TextEditor(text: $notes).padding() }
                            else if active == "Music" { MusicView() }
                            else if active == "Dash" { SquareDash() }
                            else if active == "Memory" { MemoryGame() }
                            else if active == "Titan" { TapTitan() }
                            else if active.contains("USER") {
                                if let app = userApps.first(where: { "USER_\($0.id.uuidString)" == active }) {
                                    UserAppRunner(app: app)
                                }
                            }
                        }
                    }
                }.transition(.move(edge: .bottom))
            }
        }
    }
}

// --- 3. HARDWARE: CAMERA ---
struct CameraView: View {
    var body: some View {
        ZStack {
            CameraPreview().ignoresSafeArea()
            VStack {
                Spacer()
                Circle().stroke(Color.white, lineWidth: 4).frame(width: 70, height: 70)
                    .padding(.bottom, 40)
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return view }
        if session.canAddInput(input) { session.addInput(input) }
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.frame
        view.layer.addSublayer(preview)
        DispatchQueue.global().async { session.startRunning() }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// --- 4. DEV STUDIO ---
struct DevStudioView: View {
    @AppStorage("user_apps_vFinal_v2") var savedAppsData: Data = Data()
    @State private var mode: UserApp.AppType = .noCode
    @State private var appName = ""
    @State private var code = "<html><body style='background:cyan;'><h1>New App</h1></body></html>"
    
    var body: some View {
        VStack {
            Picker("Mode", selection: $mode) {
                Text("No-Code").tag(UserApp.AppType.noCode)
                Text("Code").tag(UserApp.AppType.code)
            }.pickerStyle(.segmented).padding()
            
            Form {
                TextField("App Name", text: $appName)
                if mode == .code {
                    TextEditor(text: $code).font(.system(.body, design: .monospaced)).frame(height: 200)
                }
                Button("Install App") {
                    var apps: [UserApp] = []
                    if let decoded = try? JSONDecoder().decode([UserApp].self, from: savedAppsData) {
                        apps = decoded
                    }
                    apps.append(UserApp(name: appName, icon: "app", color: "3b82f6", type: mode, content: code))
                    if let data = try? JSONEncoder().encode(apps) { savedAppsData = data }
                    appName = ""
                }.disabled(appName.isEmpty)
            }
        }
    }
}

struct UserAppRunner: View {
    let app: UserApp
    var body: some View {
        if app.type == .code { WebView(html: app.content) }
        else { VStack { Text(app.name).font(.largeTitle); Text("Custom App Template") } }
    }
}

// --- 5. GAMES & EXTRAS ---
struct SquareDash: View {
    @State private var pos = CGSize.zero
    var body: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 10).fill(.orange).frame(width: 50, height: 50)
                .offset(pos).onTapGesture {
                    pos = CGSize(width: .random(in: -100...100), height: .random(in: -200...200))
                }
            Spacer()
        }
    }
}

struct MemoryGame: View {
    @State private var cards = ["💎", "💎", "👻", "👻", "🔥", "🔥"].shuffled()
    var body: some View {
        LazyVGrid(columns: [GridItem(), GridItem()]) {
            ForEach(0..<cards.count, id: \.self) { i in
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(.green).frame(height: 100)
                    Text(cards[i]).font(.largeTitle)
                }
            }
        }.padding()
    }
}

struct TapTitan: View {
    @State private var taps = 0
    var body: some View {
        VStack {
            Text("\(taps)").font(.system(size: 80, weight: .bold))
            Button("TAP") { taps += 1 }.buttonStyle(.borderedProminent)
        }
    }
}

struct MusicView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "music.note").font(.system(size: 80)).foregroundColor(.pink)
            Text("Now Playing").font(.headline)
            HStack(spacing: 40) {
                Image(systemName: "backward.fill")
                Image(systemName: "play.fill")
                Image(systemName: "forward.fill")
            }.font(.largeTitle).padding()
            Spacer()
        }
    }
}

// --- 6. HELPERS ---
struct OSIcon: View {
    let name: String; let icon: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 15).fill(color.gradient).frame(width: 60, height: 60)
                    Image(systemName: icon).foregroundColor(.white).font(.title3)
                }
                Text(name).font(.system(size: 10)).foregroundColor(.white).lineLimit(1)
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let html: String
    func makeUIView(context: Context) -> WKWebView { WKWebView() }
    func updateUIView(_ uiView: WKWebView, context: Context) { uiView.loadHTMLString(html, baseURL: nil) }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        r = Double((int >> 16) & 0xFF) / 255
        g = Double((int >> 8) & 0xFF) / 255
        b = Double(int & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
