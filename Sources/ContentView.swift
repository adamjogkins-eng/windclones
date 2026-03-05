import SwiftUI
import WebKit

struct ContentView: View {
    @State private var htmlCode = "<html><body style='background:#f0f0f0;font-family:sans-serif;'><h2>HTML App</h2><button onclick='alert(\"Hello from HTML!\")'>Test Me</button></body></html>"
    @State private var showAppMaker = false
    @State private var windowOffset = CGSize(width: 20, height: 50)
    
    var body: some View {
        ZStack {
            // 1. Desktop Background (Classic Windows Teal)
            Color(red: 0.0, green: 128/255, blue: 128/255).ignoresSafeArea()
            
            // 2. Desktop Icons
            VStack {
                Button(action: { showAppMaker = true }) {
                    VStack {
                        Image(systemName: "square.and.pencil").font(.system(size: 40)).foregroundColor(.white)
                        Text("App Maker").font(.caption).foregroundColor(.white).bold()
                    }
                }
                .padding(.top, 40).padding(.leading, 20)
                Spacer()
            }.frame(maxWidth: .infinity, alignment: .leading)

            // 3. The HTML App Maker Window
            if showAppMaker {
                VStack(spacing: 0) {
                    // Title Bar
                    HStack {
                        Text("HTML App Engine").font(.caption).foregroundColor(.white).bold().padding(.leading, 10)
                        Spacer()
                        Button(action: { showAppMaker = false }) {
                            Image(systemName: "xmark.square.fill").foregroundColor(.white).font(.title3)
                        }.padding(.trailing, 5)
                    }
                    .frame(height: 30).background(Color.blue)
                    
                    // Code Editor Area
                    VStack(alignment: .leading) {
                        Text("Write HTML/JS Code:").font(.caption).padding([.top, .leading], 5)
                        TextEditor(text: $htmlCode)
                            .font(.system(.body, design: .monospaced))
                            .frame(height: 120).border(Color.gray)
                        
                        Divider()
                        
                        Text("Live App Preview:").font(.caption).padding(.leading, 5)
                        // This runs your HTML
                        HTMLRunnerView(html: htmlCode)
                            .background(Color.white)
                            .border(Color.black, width: 1)
                    }.background(Color(white: 0.9))
                }
                .frame(width: 340, height: 500)
                .border(Color.black, width: 1)
                .offset(windowOffset)
                // This makes the window draggable
                .gesture(DragGesture().onChanged { value in windowOffset = value.translation })
            }

            // 4. Taskbar
            VStack {
                Spacer()
                HStack {
                    Button(action: {}) {
                        Text("Start").bold().italic().padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color.gray).border(Color.white, width: 2)
                    }.padding(.leading, 5)
                    
                    Spacer()
                    
                    // Taskbar Clock
                    Text(Date(), style: .time)
                        .font(.system(size: 14, design: .monospaced))
                        .padding(.trailing, 10)
                }
                .frame(height: 40).background(Color(white: 0.75)).border(Color.white, width: 1)
            }
        }
    }
}

// The "Engine" that turns your text into a working HTML App
struct HTMLRunnerView: UIViewRepresentable {
    let html: String
    func makeUIView(context: Context) -> WKWebView { WKWebView() }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(html, baseURL: nil)
    }
}
