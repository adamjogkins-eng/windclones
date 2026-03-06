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

// --- 2. MAIN OS INTERFACE ---
struct ContentView: View {
    @State private var openedApp: String? = nil
    @AppStorage("user_apps_v9") var savedAppsData: Data = Data()
    @AppStorage("os_notes_v9") var notes: String = ""
    
    // Fixed decoding logic to prevent the build crash
    var userApps: [UserApp] {
        guard let decoded = try? JSONDecoder().decode([UserApp].self, from: savedAppsData) else {
            return []
        }
        return decoded
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Status Bar
                HStack {
                    Text(Date(), style: .time).font(.system(.caption, design: .rounded)).bold()
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "video.fill")
                        Image(systemName: "battery.100")
                    }.font(.system(size: 12))
                }.foregroundColor(.white).padding(.horizontal, 30).padding(.top, 10)

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

            // Window Manager
            if let active = openedApp {
                ZStack {
                    Color(.systemBackground).ignoresSafeArea()
                    VStack(spacing: 0) {
                        HStack {
                            Text(active.contains("USER") ? "Custom App" : active).bold()
                            Spacer()
                            Button("Exit") { openedApp = nil }.bold()
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
                }
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
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return view }
        
        if session.canAddInput(input) { session.addInput(input) }
        
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.frame
        view.layer.addSublayer(preview)
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// --- 4. SYSTEM APPS & HELPERS ---
struct DevStudioView: View {
    @AppStorage("user_apps_v9") var savedAppsData: Data = Data()
    @State private var appName = ""
    var body: some View {
        Form {
            TextField("App Name", text: $appName)
            Button("Create App") {
                var apps = [UserApp]()
                if let decoded = try? JSONDecoder().decode([UserApp].self, from: savedAppsData) { apps = decoded }
                apps.append(UserApp(name: appName, icon: "app", color: "3b82f6", type: .noCode, content: ""))
                if let data = try? JSONEncoder().encode(apps) { savedAppsData = data }
                appName = ""
            }.disabled(appName.isEmpty)
        }
    }
}

struct UserAppRunner: View {
    let app: UserApp
    var body: some View {
        VStack { Text(app.name).font(.title); Text("Installed Application") }
    }
}

struct SquareDash: View {
    @State private var pos = CGSize.zero
    var body: some View {
        Rectangle().fill(.orange).frame(width: 50, height: 50).offset(pos)
            .onTapGesture { pos = CGSize(width: .random(in: -100...100), height: .random(in: -100...100)) }
    }
}

struct MemoryGame: View { var body: some View { Text("Memory Challenge") } }
struct TapTitan: View { @State var t = 0; var body: some View { Button("Taps: \(t)") { t += 1 } } }
struct MusicView: View { var body: some View { Image(systemName: "music.note.list").font(.system(size: 80)) } }

struct OSIcon: View {
    let name: String; let icon: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 15).fill(color.gradient).frame(width: 60, height: 60)
                    Image(systemName: icon).foregroundColor(.white)
                }
                Text(name).font(.system(size: 10)).foregroundColor(.white)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0; Scanner(string: hex).scanHexInt64(&int)
        self.init(.sRGB, red: Double(int >> 16) / 255, green: Double(int >> 8 & 0xFF) / 255, blue: Double(int & 0xFF) / 255, opacity: 1)
    }
}
