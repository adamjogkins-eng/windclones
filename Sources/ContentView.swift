import SwiftUI
import PencilKit
import PhotosUI

// MARK: - Models
struct MemelyItem: Identifiable {
    let id = UUID()
    var image: UIImage?
    var text: String = ""
    var isText: Bool = false
    var offset: CGSize = .zero
    var lastOffset: CGSize = .zero
    var scale: CGFloat = 1.0
    var lastScale: CGFloat = 1.0
    var rotation: Angle = .zero
    var lastRotation: Angle = .zero
    var zIndex: Double = 0
}

struct MemeTemplate: Identifiable {
    let id = UUID()
    let fileName: String
}

// MARK: - Main Studio View
struct ContentView: View {
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var layers: [MemelyItem] = []
    @State private var showTemplates = false
    @State private var showTextEditor = false
    @State private var textInput = ""
    @State private var selectedPhoto: PhotosPickerItem?

    // Change these to match your .jpg filenames on GitHub
    let preloadedImages = [
        MemeTemplate(fileName: "temp1"),
        MemeTemplate(fileName: "temp2"),
        MemeTemplate(fileName: "temp3"),
        MemeTemplate(fileName: "temp4")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // THE WORKSPACE
                GeometryReader { geo in
                    ZStack {
                        Color.black.ignoresSafeArea()
                        
                        ForEach($layers) { $layer in
                            LayerElement(item: $layer)
                                .onTapGesture {
                                    layer.zIndex = (layers.map(\.zIndex).max() ?? 0) + 1
                                }
                        }
                        
                        PKCanvasRepresentable(canvas: $canvasView, picker: $toolPicker)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .clipped()
                
                // TOOLBAR
                HStack(spacing: 25) {
                    Button { showTemplates = true } label: {
                        Image(systemName: "rectangle.grid.2x2.fill").font(.title2)
                    }
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Image(systemName: "plus.rectangle.on.rectangle.fill").font(.title2)
                    }
                    
                    Button { showTextEditor = true } label: {
                        Image(systemName: "text.bubble.fill").font(.title2)
                    }
                    
                    Spacer()
                    
                    Button(action: saveToGallery) {
                        Image(systemName: "arrow.down.circle.fill").font(.system(size: 35)).foregroundStyle(.blue)
                    }
                    
                    Button(role: .destructive) {
                        layers.removeAll()
                        canvasView.drawing = PKDrawing()
                    } label: {
                        Image(systemName: "trash.fill").font(.title2)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Memely")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showTemplates) {
                TemplateGrid(templates: preloadedImages) { selected in
                    addLayer(from: selected.fileName)
                }
            }
            .alert("Meme Text", isPresented: $showTextEditor) {
                TextField("Type here...", text: $textInput)
                Button("Add") {
                    layers.append(MemelyItem(text: textInput, isText: true, zIndex: Double(layers.count)))
                    textInput = ""
                }
                Button("Cancel", role: .cancel) {}
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        layers.append(MemelyItem(image: uiImage, zIndex: Double(layers.count)))
                    }
                }
            }
        }
    }

    func addLayer(from fileName: String) {
        // Updated logic to specifically check for .jpg first
        if let path = Bundle.main.path(forResource: fileName, ofType: "jpg") ?? 
                      Bundle.main.path(forResource: fileName, ofType: "jpeg") ??
                      Bundle.main.path(forResource: fileName, ofType: "png"),
           let img = UIImage(contentsOfFile: path) {
            layers.append(MemelyItem(image: img, zIndex: Double(layers.count)))
        }
        showTemplates = false
    }

    @MainActor
    func saveToGallery() {
        let renderer = ImageRenderer(content: body)
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
}

// MARK: - Layer Element (Movement/Collage Logic)
struct LayerElement: View {
    @Binding var item: MemelyItem
    
    var body: some View {
        Group {
            if item.isText {
                Text(item.text)
                    .font(.system(size: 50, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 2)
                    .shadow(color: .black, radius: 2)
                    .multilineTextAlignment(.center)
            } else if let img = item.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300)
            }
        }
        .rotationEffect(item.rotation)
        .scaleEffect(item.scale)
        .offset(item.offset)
        .zIndex(item.zIndex)
        .gesture(
            DragGesture()
                .onChanged { value in
                    item.offset = CGSize(
                        width: item.lastOffset.width + value.translation.width,
                        height: item.lastOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in item.lastOffset = item.offset }
        )
        .gesture(
            SimultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in item.scale = item.lastScale * value }
                    .onEnded { _ in item.lastScale = item.scale },
                RotationGesture()
                    .onChanged { value in item.rotation = item.lastRotation + value }
                    .onEnded { _ in item.lastRotation = item.rotation }
            )
        )
    }
}

struct TemplateGrid: View {
    let templates: [MemeTemplate]
    var onSelect: (MemeTemplate) -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(templates) { t in
                        Button { onSelect(t) } label: {
                            if let path = Bundle.main.path(forResource: t.fileName, ofType: "jpg") ?? Bundle.main.path(forResource: t.fileName, ofType: "jpeg"),
                               let img = UIImage(contentsOfFile: path) {
                                Image(uiImage: img).resizable().aspectRatio(contentMode: .fill).frame(height: 150).cornerRadius(12).clipped()
                            } else {
                                RoundedRectangle(cornerRadius: 12).fill(.gray).frame(height: 150).overlay(Text("Missing File").font(.caption))
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Template Gallery")
        }
    }
}

struct PKCanvasRepresentable: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    @Binding var picker: PKToolPicker
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        picker.addObserver(canvas)
        picker.setVisible(true, forFirstResponder: canvas)
        canvas.becomeFirstResponder()
        return canvas
    }
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
