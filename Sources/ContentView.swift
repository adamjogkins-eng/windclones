import SwiftUI
import PencilKit
import PhotosUI

// MARK: - THE MODEL
struct MemelyLayer: Identifiable {
    let id = UUID()
    var image: UIImage?
    var text: String = ""
    var isText: Bool = false
    
    // Position State
    var offset: CGSize = .zero
    var newOffset: CGSize = .zero
    
    // Scale State
    var scale: CGFloat = 1.0
    var newScale: CGFloat = 1.0
    
    // Rotation State
    var rotation: Angle = .zero
    var newRotation: Angle = .zero
    
    var zIndex: Double = 0
}

// MARK: - THE MAIN STUDIO
struct ContentView: View {
    @State private var layers: [MemelyLayer] = []
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    
    @State private var isDrawingMode = false
    @State private var showTemplates = false
    @State private var showTextAlert = false
    @State private var textInput = ""
    @State private var photoSelection: PhotosPickerItem?

    // Change these to your .jpg names on Github
    let templateFiles = ["temp1", "temp2", "temp3", "temp4", "temp5"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - WORKSPACE
                ZStack {
                    Color.white.ignoresSafeArea()
                    
                    // 1. COLLAGE ELEMENTS (Images/Text)
                    ForEach($layers) { $layer in
                        MemeComponent(item: $layer)
                            .zIndex(layer.zIndex)
                            .onTapGesture {
                                // Bring to front
                                layer.zIndex = (layers.map(\.zIndex).max() ?? 0) + 1
                            }
                    }
                    
                    // 2. DRAWING LAYER
                    CanvasView(canvasView: $canvasView, toolPicker: $toolPicker, isActive: isDrawingMode)
                        .allowsHitTesting(isDrawingMode)
                        .zIndex(100)
                }
                .clipped()
                
                // MARK: - CONTROLS
                VStack(spacing: 15) {
                    // MODE TOGGLE
                    Picker("Mode", selection: $isDrawingMode) {
                        Label("Move & Scale", systemImage: "arrow.up.and.down.and.arrow.left.and.right").tag(false)
                        Label("Draw", systemImage: "paintbrush.fill").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    HStack(spacing: 25) {
                        // Templates
                        Button { showTemplates = true } label: {
                            VStack { Image(systemName: "photo.stack.fill"); Text("Gallery").font(.caption2) }
                        }
                        
                        // Add Overlay (Collaging)
                        PhotosPicker(selection: $photoSelection, matching: .images) {
                            VStack { Image(systemName: "plus.square.fill.on.square.fill"); Text("Overlay").font(.caption2) }
                        }
                        
                        // Text Overlay
                        Button { showTextAlert = true } label: {
                            VStack { Image(systemName: "text.quote"); Text("Meme Text").font(.caption2) }
                        }
                        
                        Spacer()
                        
                        // DOWNLOAD
                        Button(action: saveToPhotos) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Memely")
            .sheet(isPresented: $showTemplates) {
                TemplateBrowser(files: templateFiles) { name in
                    addTemplate(name)
                }
            }
            .alert("Add Text Overlay", isPresented: $showTextAlert) {
                TextField("Enter caption...", text: $textInput)
                Button("Add") {
                    layers.append(MemelyLayer(text: textInput, isText: true, zIndex: Double(layers.count)))
                    textInput = ""
                }
                Button("Cancel", role: .cancel) {}
            }
            .onChange(of: photoSelection) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        layers.append(MemelyLayer(image: uiImage, zIndex: Double(layers.count)))
                    }
                }
            }
        }
    }

    func addTemplate(_ name: String) {
        if let path = Bundle.main.path(forResource: name, ofType: "jpg"),
           let img = UIImage(contentsOfFile: path) {
            layers.insert(MemelyLayer(image: img, zIndex: -1), at: 0)
        }
        showTemplates = false
    }

    @MainActor
    func saveToPhotos() {
        let renderer = ImageRenderer(content: body)
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - THE COMPONENT (FIXED GESTURES)
struct MemeComponent: View {
    @Binding var item: MemelyLayer
    
    var body: some View {
        Group {
            if item.isText {
                Text(item.text)
                    .font(.system(size: 45, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 1)
                    .shadow(color: .black, radius: 5)
                    .multilineTextAlignment(.center)
            } else if let img = item.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250)
            }
        }
        // Apply persistent state + current gesture translation
        .offset(x: item.offset.width + item.newOffset.width, 
                y: item.offset.height + item.newOffset.height)
        .scaleEffect(item.scale * item.newScale)
        .rotationEffect(item.rotation + item.newRotation)
        .gesture(
            DragGesture()
                .onChanged { value in item.newOffset = value.translation }
                .onEnded { value in
                    item.offset.width += value.translation.width
                    item.offset.height += value.translation.height
                    item.newOffset = .zero
                }
        )
        .gesture(
            SimultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in item.newScale = value }
                    .onEnded { value in
                        item.scale *= value
                        item.newScale = 1.0
                    },
                RotationGesture()
                    .onChanged { value in item.newRotation = value }
                    .onEnded { value in
                        item.rotation += value
                        item.newRotation = .zero
                    }
            )
        )
    }
}

// MARK: - TEMPLATE BROWSER
struct TemplateBrowser: View {
    let files: [String]
    var onSelect: (String) -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(files, id: \.self) { file in
                        Button { onSelect(file) } label: {
                            VStack {
                                RoundedRectangle(cornerRadius: 10).fill(.blue.opacity(0.1))
                                    .frame(height: 120)
                                    .overlay(Text(file))
                                Text(file).font(.caption)
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

// MARK: - PENCILKIT CANVAS
struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    var isActive: Bool
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(isActive, forFirstResponder: canvasView)
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        toolPicker.setVisible(isActive, forFirstResponder: uiView)
        if isActive { uiView.becomeFirstResponder() }
    }
}
