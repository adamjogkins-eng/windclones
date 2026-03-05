import SwiftUI

struct ContentView: View {
    @State private var openNotepad = false
    @State private var notepadText = "Hello from your Windows Clone!"
    @State private var notepadOffset = CGSize(width: 20, height: 50)
    @State private var showStartMenu = false

    var body: some View {
        ZStack {
            // 1. THE DESKTOP (Classic Teal)
            Color(red: 0.0, green: 0.5, blue: 0.5).edgesIgnoringSafeArea(.all)

            // 2. DESKTOP ICONS
            VStack {
                DesktopIcon(name: "Notepad", icon: "doc.text.fill") {
                    openNotepad = true
                }
                DesktopIcon(name: "My Computer", icon: "desktopcomputer") { }
                Spacer()
            }
            .padding(.top, 50)
            .frame(maxWidth: .infinity, alignment: .leading)

            // 3. THE NOTEPAD WINDOW (Only shows if openNotepad is true)
            if openNotepad {
                VStack(spacing: 0) {
                    // Title Bar
                    HStack {
                        Text("Notepad").font(.caption).foregroundColor(.white).padding(.leading, 10)
                        Spacer()
                        Button(action: { openNotepad = false }) {
                            Image(systemName: "xmark.square.fill").foregroundColor(.white)
                        }.padding(.trailing, 10)
                    }
                    .frame(height: 30).background(Color.blue)

                    // Text Area
                    TextEditor(text: $notepadText)
                        .font(.custom("Courier", size: 14))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 300, height: 350)
                .background(Color.white)
                .border(Color.black, width: 1)
                .offset(notepadOffset)
                .gesture(DragGesture().onChanged { value in
                    self.notepadOffset = CGSize(width: value.location.x - 150, height: value.location.y - 20)
                })
            }

            // 4. THE TASKBAR & START MENU
            VStack {
                Spacer()
                if showStartMenu {
                    StartMenu()
                }
                HStack {
                    Button(action: { showStartMenu.toggle() }) {
                        HStack {
                            Image(systemName: "logo.xbox").resizable().frame(width: 15, height: 15)
                            Text("Start").bold()
                        }
                        .padding(5).background(Color.gray).border(Color.white, width: 2)
                    }
                    Spacer()
                }
                .padding(5).background(Color(white: 0.8))
            }
        }
    }
}

// Support components
struct DesktopIcon: View {
    let name: String
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon).font(.largeTitle).foregroundColor(.white)
                Text(name).font(.caption).foregroundColor(.white)
            }
        }.padding(20)
    }
}

struct StartMenu: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Programs").padding().frame(width: 150, alignment: .leading).border(Color.white)
            Text("Settings").padding().frame(width: 150, alignment: .leading).border(Color.white)
            Text("Shutdown").padding().frame(width: 150, alignment: .leading).border(Color.white)
        }
        .background(Color.gray).border(Color.black).padding(.leading, 5)
    }
}
