
import SwiftUI
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
    @AppStorage("user_apps_v18_v1") var savedAppsData: Data = Data()
    @AppStorage("os_notes_persistent") var notes: String = ""
    
    var userApps: [UserApp] {
        if savedAppsData.isEmpty { return [] }
        return (try? JSONDecoder().decode([UserApp].self, from: savedAppsData)) ?? []
    }

    var body: some View {
        ZStack {
            // iOS 18 Mesh-style Background
            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ], colors: [
                .black, .indigo, .black,
                .blue, .black, .purple,
                .black, .black, .black
            ])
            .ignoresSafeArea()
            
            VStack {
                // Status Bar
                HStack {
                    Text(Date(), style: .time).font(.caption).bold()
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "cellularbars")
                        Image(systemName: "wifi")
                        Image(systemName: "battery.100")
                    }.font(.caption)
                }.foregroundColor(.white).padding(.horizontal, 30).padding(.top, 10)

                // App Grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 25) {
                        OSIcon(name: "Paint", icon: "paintbrush.fill", color: .purple) { openedApp = "Paint" }
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
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30))
                .padding(.bottom, 20)
            }

            // Window Manager
            if let active = openedApp {
                ZStack {
                    Color(UIColor.systemBackground).ignoresSafeArea()
                    VStack(spacing: 0) {
                        HStack {
                            Text(active.contains("USER") ? "Custom App" : active).font(.headline)
                            Spacer()
                            Button("Exit", role: .destructive) {
                                withAnimation(.spring()) { openedApp = nil }
                            }.buttonStyle(.borderedProminent).controlSize(.small)
                        }.padding().background(.ultraThinMaterial)
                        
                        if active == "Paint" { PaintView() }
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
                .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity), removal: .move(edge: .bottom)))
            }
        }
    }
}

// --- 3. PAINT STUDIO (Modern) ---
struct PaintView: View {
    @State private var lines: [Line] = []
    struct Line: Identifiable {
        var id = UUID()
        var points: [CGPoint]
        var color: Color
    }
    
    var body: some View {
        VStack {
            Canvas { context, size in
                for line in lines {
                    var path = Path()
                    path.addLines(line.points)
                    context.stroke(path, with: .color(line.color), lineWidth: 5)
                }
            }
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                let newPoint = value.location
                if lines.isEmpty || value.translation == .zero {
                    lines.append(Line(points: [newPoint], color: .blue))
                } else {
                    let index = lines.count - 1
                    lines[index].points.append(newPoint)
                }
            })
            Button("Clear Canvas") { lines.removeAll() }.padding()
        }
    }
}

// --- 4. SYSTEM APPS ---
struct DevStudioView: View {
    @AppStorage("user_apps_v18_v1") var savedAppsData: Data = Data()
    @State private var mode: UserApp.AppType = .noCode
    @State private var appName = ""
    @State private var code = "<html><body style='background:black;color:white;'><h1>New App</h1></body></html>"
    
    var body: some View {
        List {
            Picker("App Mode", selection: $mode) {
                Text("No-Code").tag(UserApp.AppType.noCode)
                Text("HTML/JS").tag(UserApp.AppType.code)
            }.pickerStyle(.segmented)
            
            TextField("App Name", text: $appName)
            if mode == .code {
                TextEditor(text: $code).font(.caption2.monospaced()).frame(height: 200)
            }
            
            Button("Install to Home Screen") {
                var apps = (try? JSONDecoder().decode([UserApp].self, from: savedAppsData)) ?? []
                apps.append(UserApp(name: appName, icon: "app", color: "4F46E5", type: mode, content: code))
                savedAppsData = (try? JSONEncoder().encode(apps)) ?? Data()
                appName = ""
            }.disabled(appName.isEmpty)
        }
    }
}

struct UserAppRunner: View {
    let app: UserApp
    var body: some View {
        if app.type == .code { WebView(html: app.content) }
        else { ContentUnavailableView(app.name, systemImage: "app.dashed", description: Text("No-Code Template running.")) }
    }
}

// --- 5. GAMES ---
struct SquareDash: View {
    @State private var pos = CGSize.zero
    var body: some View {
        Circle().fill(.orange).frame(width: 60).offset(pos)
            .onTapGesture { withAnimation(.interactiveSpring) {
                pos = CGSize(width: .random(in: -100...100), height: .random(in: -200...200))
            }}
    }
}

struct MemoryGame: View {
    let cards = ["🔥", "❄️", "⚡️", "🔥", "❄️", "⚡️"].shuffled()
    var body: some View {
        Grid {
            ForEach(0..<2) { row in
                GridRow {
                    ForEach(0..<3) { col in
                        RoundedRectangle(cornerRadius: 12).fill(.green.gradient)
                            .frame(width: 80, height: 80)
                            .overlay(Text(cards[row * 3 + col]).font(.largeTitle))
                    }
                }
            }
        }.padding()
    }
}

struct TapTitan: View {
    @State private var taps = 0
    var body: some View {
        Button { taps += 1 } label: {
            Text("\(taps)").font(.system(size: 80, weight: .black)).contentTransition(.numericText())
        }.buttonStyle(.plain)
    }
}

struct MusicView: View {
    var body: some View {
        ContentUnavailableView("Music Player", systemImage: "music.note.list", description: Text("Connect to your library."))
    }
}

// --- 6. HELPERS ---
struct OSIcon: View {
    let name: String; let icon: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack {
                RoundedRectangle(cornerRadius: 16).fill(color.gradient)
                    .frame(width: 65, height: 65)
                    .overlay(Image(systemName: icon).font(.title2).foregroundColor(.white))
                Text(name).font(.caption2).foregroundColor(.white)
            }
        }.buttonStyle(.plain)
    }
}

struct WebView: UIViewRepresentable {
    let html: String
    func makeUIView(context: Context) -> WKWebView { WKWebView() }
    func updateUIView(_ uiView: WKWebView, context: Context) { uiView.loadHTMLString(html, baseURL: nil) }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
