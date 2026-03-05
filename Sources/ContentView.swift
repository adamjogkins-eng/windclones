import SwiftUI

// --- DATA MODELS ---
struct OSApp: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    var content: AnyView
}

// --- MAIN INTERFACE ---
struct ContentView: View {
    @State private var openedApp: OSApp? = nil
    @State private var currentTime = Date()
    
    // Timer to update the clock
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Your App Library
    let apps: [OSApp] = [
        OSApp(name: "App Maker", icon: "hammer.fill", color: .blue, content: AnyView(AppMakerView())),
        OSApp(name: "Safari", icon: "safari.fill", color: .blue, content: AnyView(BrowserView())),
        OSApp(name: "Photos", icon: "photo.on.rectangle.angled", color: .purple, content: AnyView(GalleryView())),
        OSApp(name: "Files", icon: "folder.fill", color: .yellow, content: AnyView(PlaceholderView(text: "No Documents Found"))),
        OSApp(name: "Settings", icon: "gearshape.fill", color: .gray, content: AnyView(PlaceholderView(text: "Version 2.0 (Stable)"))),
        OSApp(name: "Weather", icon: "cloud.sun.fill", color: .cyan, content: AnyView(PlaceholderView(text: "Sunny - 72°")))
    ]
    
    var body: some View {
        ZStack {
            // 1. Wallpaper (iOS Style Gradient)
            LinearGradient(gradient: Gradient(colors: [Color(hex: "1e3a8a"), Color(hex: "7e22ce")]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                // 2. Status Bar
                HStack {
                    Text(currentTime, style: .time)
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    HStack(spacing: 5) {
                        Image(systemName: "cellularbars")
                        Image(systemName: "wifi")
                        Image(systemName: "battery.100")
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                
                // 3. App Grid
                LazyVGrid(columns: [GridItem(.fixed(85)), GridItem(.fixed(85)), GridItem(.fixed(85)), GridItem(.fixed(85))], spacing: 25) {
                    ForEach(apps) { app in
                        AppIconView(app: app) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { openedApp = app }
                        }
                    }
                }
                .padding(.top, 30)
                
                Spacer()
                
                // 4. The Dock (Ultra Thin Material)
                HStack(spacing: 22) {
                    ForEach(apps.prefix(4)) { app in
                        AppIconView(app: app, isDock: true) {
                            withAnimation(.spring()) { openedApp = app }
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(.ultraThinMaterial)
                .cornerRadius(35)
                .padding(.bottom, 20)
            }
            
            // 5. App Window System
            if let activeApp = openedApp {
                ZStack {
                    Color.black.opacity(0.1).ignoresSafeArea()
                        .onTapGesture { withAnimation { openedApp = nil } }
                    
                    VStack(spacing: 0) {
                        // Handle bar for "Closing"
                        Capsule()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 40, height: 5)
                            .padding(.top, 10)
                        
                        HStack {
                            Text(activeApp.name).font(.title3).bold()
                            Spacer()
                            Button(action: { withAnimation { openedApp = nil } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.gray)
                                    .font(.title2)
                            }
                        }
                        .padding()
                        
                        activeApp.content
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(30)
                    .padding(.top, 40) // Makes it look like a slide-up sheet
                    .shadow(color: .black.opacity(0.3), radius: 20)
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea()
            }
        }
        .onReceive(timer) { input in currentTime = input }
    }
}

// --- SUBVIEWS ---

struct AppIconView: View {
    let app: OSApp
    var isDock: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: isDock ? 14 : 18)
                        .fill(app.color.gradient)
                        .frame(width: isDock ? 60 : 65, height: isDock ? 60 : 65)
                    Image(systemName: app.icon)
                        .foregroundColor(.white)
                        .font(.system(size: isDock ? 28 : 32))
                }
                if !isDock {
                    Text(app.name)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct AppMakerView: View {
    @State private var htmlCode = "<h1>Hello iOS</h1>\n<p>This is my custom app engine.</p>"
    var body: some View {
        VStack {
            TextEditor(text: $htmlCode)
                .font(.system(.body, design: .monospaced))
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            Text("PREVIEW")
                .font(.caption).bold().foregroundColor(.gray)
            
            ScrollView {
                Text("Rendering: \(htmlCode)") // Simplified for demo
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(10)
        }
        .padding()
    }
}

struct BrowserView: View {
    @State private var url = "google.com"
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "lock.fill").font(.caption)
                TextField("Search or enter website", text: $url)
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding()
            
            Spacer()
            Image(systemName: "safari").font(.system(size: 100)).foregroundColor(.gray.opacity(0.2))
            Spacer()
        }
    }
}

struct GalleryView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                ForEach(0..<6) { _ in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 150)
                }
            }
            .padding()
        }
    }
}

struct PlaceholderView: View {
    let text: String
    var body: some View {
        VStack {
            Spacer()
            Text(text).foregroundColor(.gray)
            Spacer()
        }
    }
}

// Helper for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
