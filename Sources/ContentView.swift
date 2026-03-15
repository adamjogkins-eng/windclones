import SwiftUI
import PencilKit
import PhotosUI

// MARK: - Models
struct StudioItem: Identifiable {
    let id = UUID()
    var image: UIImage?
    var text: String = ""
    var isText: Bool = false
    var offset: CGSize = .zero
    var scale: CGFloat = 1.0
    var zIndex: Double = 0
}

struct MemeTemplate: Identifiable {
    let id = UUID()
    let name: String
    let fileName: String
}

// MARK: - Main Studio View
struct ContentView: View {
    // Canvas Engine
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    
    // Layers & Items
    @State private var items: [StudioItem] = []
    
    // Selection & UI
    @State private var selectedPickerItem: PhotosPickerItem?
    @State private var showTemplates = false
    @State private var showTextInput = false
    @State private var textBuffer = ""
    
    // Export State
    @State private var exportedImage: Image?
    @State private var isSharing = false

    // Offline Templates (Make sure these files exist in your project)
    let templates = [
        MemeTemplate(name: "Distracted BF", fileName: "distracted"),
        MemeTemplate(name: "Drake No/Yes", fileName: "drake"),
        MemeTemplate(name: "Two Buttons", fileName: "buttons"),
        MemeTemplate(name: "Woman Yelling", fileName: "cat")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - THE PAINTING SURFACE
                ZStack {
                    Color.white.ignoresSafeArea() // The Paper
                    
                    // All Images and Text Blocks
                    ForEach($items) { $item in
                        CanvasItemView(item: $item)
                            .onTapGesture {
                                // Bring tapped item to front
                                item.zIndex = (items.map(\.zIndex).max() ?? 0) + 1
                            }
                    }
                    
                    // The PencilKit Drawing Layer
                    CanvasRepresentable(canvas: $canvasView, picker: $toolPicker)
                }
                .clipped()
                .background(Color(UIColor.secondarySystemBackground))
                
                // MARK: - PRO TOOLBAR
                HStack(spacing: 25) {
                    // 1. Templates
                    Button { showTemplates = true } label: {
                        ToolButton(icon: "rectangle.stack.badge.plus", label: "Template")
                    }
                    
                    // 2. Add Photos
                    PhotosPicker(selection: $selectedPickerItem, matching: .images) {
                        ToolButton(icon: "photo.badge.plus", label: "Image")
                    }
                    
                    // 3. Add Meme Text
                    Button { showTextInput = true } label: {
                        ToolButton(icon: "textformat.size", label: "Text")
                    }
                    
                    // 4. Save to Photos (OFFLINE DOWNLOAD)
                    Button(action: saveToGallery) {
                        ToolButton(icon: "arrow.down.to.line.circle.fill", label: "Save")
                            .foregroundStyle(.blue)
                    }
                    
                    // 5. Clear All
                    Button(role: .destructive) {
                        items.removeAll()
                        canvasView.drawing = PKDrawing()
                    } label: {
                        ToolButton(icon: "trash", label: "Clear")
                            .foregroundStyle(.red)
                    }
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Meme Studio Pro")
            .navigationBarTitleDisplayMode(.inline)
            // MARK: - MODALS & ALERTS
            .sheet(isPresented: $showTemplates) {
                TemplatePicker(templates: templates) { selected in
                    addOfflineTemplate(selected)
                }
            }
            .alert("Add Text", isPresented: $showTextInput) {
                TextField("Enter meme caption...", text: $textBuffer)
                Button("Add") {
                    items.append(StudioItem(text: textBuffer, isText: true, zIndex: Double(items.count)))
                    textBuffer = ""
                }
                Button("Cancel", role: .cancel) { textBuffer = "" }
            }
            .onChange(of: selectedPickerItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        items.append(StudioItem(image: uiImage, zIndex: Double(items.count)))
                    }
                }
            }
        }
    }

    // MARK: - Logic
    func addOfflineTemplate(_ template: MemeTemplate) {
        // Look for image in the App Bundle (Offline)
        if let path = Bundle.main.path(forResource: template.fileName, ofType: "jpg") ?? 
                      Bundle.main.path(forResource: template.fileName, ofType: "png"),
           let uiImage = UIImage(contentsOfFile: path) {
            items.insert(StudioItem(image: uiImage, zIndex: -1), at: 0)
        }
        showTemplates = false
    }

    @MainActor
    func saveToGallery() {
        // Render the view to a UIImage
        let renderer = ImageRenderer(content: body) 
        renderer.scale = 3.0 // High Resolution
        
        if let uiImage = renderer.uiImage {
            // Save directly to Camera Roll
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            
            // Haptic Feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

// MARK: - Helper Views
struct ToolButton: View {
    let icon: String
    let label: String
    var body: some View {
        VStack {
            Image(systemName: icon).font(.title2)
            Text(label).font(.caption2)
        }
    }
}

struct CanvasItemView: View {
    @Binding var item: StudioItem
    @GestureState private var tempScale: CGFloat = 1.0
    @GestureState private var tempOffset: CGSize = .zero

    var body: some View {
        Group {
            if item.isText {
                Text(item.text)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 1)
                    .shadow(color: .black, radius: 1)
                    .shadow(color: .black, radius: 3) // Thick meme outline
            } else if let img = item.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250)
            }
        }
        .scaleEffect(item.scale * tempScale)
        .offset(x: item.offset.width + tempOffset.width, y: item.offset.height + tempOffset.height)
        .zIndex(item.zIndex)
        .gesture(
            DragGesture()
                .updating($tempOffset) { value, state, _ in state = value.translation }
                .onEnded { value in item.offset.width += value.translation.width; item.offset.height += value.translation.height }
        )
        .gesture(
            MagnificationGesture()
                .updating($tempScale) { value, state, _ in state = value }
                .onEnded { value in item.scale *= value }
        )
    }
}

struct TemplatePicker: View {
    let templates: [MemeTemplate]
    let onSelect: (MemeTemplate) -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                    ForEach(templates) { t in
                        Button(action: { onSelect(t) }) {
                            VStack {
                                RoundedRectangle(cornerRadius: 10).fill(.gray.opacity(0.2))
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(Image(systemName: "photo"))
                                Text(t.name).font(.caption).foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Templates")
        }
    }
}

struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    @Binding var picker: PKToolPicker
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.backgroundColor = .clear
        canvas.drawingPolicy = .anyInput
        picker.addObserver(canvas)
        picker.setVisible(true, forFirstResponder: canvas)
        canvas.becomeFirstResponder()
        return canvas
    }
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
