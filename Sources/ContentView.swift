import SwiftUI
import PencilKit
import PhotosUI

// MARK: - Layer Model
struct MemelyLayer: Identifiable {
    let id = UUID()
    var image: UIImage?
    var text: String = ""
    var isText: Bool = false
    
    // Persistent States
    var offset: CGSize = .zero
    var scale: CGFloat = 1.0
    var rotation: Angle = .zero
    var zIndex: Double = 0
}

struct ContentView: View {
    @State private var layers: [MemelyLayer] = []
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    
    // Control States
    @State private var isDrawingMode = false
    @State private var showTemplates = false
    @State private var showTextAlert = false
    @State private var textInput = ""
    @State private var photoSelection: PhotosPickerItem?

    // Update these strings to match your .jpg filenames in your repo
    let templateFiles = ["temp1", "temp2", "temp3", "temp4", "temp5"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - THE STUDIO
                ZStack {
                    Color.white.ignoresSafeArea()
                    
                    // 1. Collage/Image/Text Layers
                    ForEach($layers) { $layer in
                        MemelyComponent(item: $layer)
                            .zIndex(layer.zIndex)
                            .onTapGesture {
                                // Bring tapped item to the absolute front
                                layer.zIndex = (layers.map(\.zIndex).max() ?? 0) + 1
                            }
                    }
                    
                    // 2. Painting Layer
                    CanvasRepresentable(canvasView: $canvasView, toolPicker: $toolPicker, isActive: isDrawingMode)
                        .allowsHitTesting(isDrawingMode)
                        .zIndex(999) // Always on top, but pass-through when inactive
                }
                .clipped()
                
                // MARK: - TOOLBAR
                VStack(spacing: 12) {
                    // Mode Toggle (Essential for offline collaging)
                    Picker("Control Mode", selection: $isDrawingMode) {
                        Label("Move & Scale", systemImage: "hand.tap.fill").tag(false)
                        Label("Draw", systemImage: "pencil.tip.crop.circle.fill").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    HStack(spacing: 25) {
                        // Template Gallery
                        Button { showTemplates = true } label: {
                            VStack { Image(systemName: "photo.on.rectangle.angled"); Text("Temps").font(.caption2) }
                        }
                        
                        // Image Overlay (The Collage Adder)
                        PhotosPicker(selection: $photoSelection, matching: .images) {
                            VStack { Image(systemName: "plus.viewfinder"); Text("Overlay").font(.caption2) }
                        }
                        
                        // Text Overlay
                        Button { showTextAlert = true } label: {
                            VStack { Image(systemName: "textformat.size"); Text("Text").font(.caption2) }
                        }
                        
                        Spacer()
                        
                        // SAVE TO PHOTOS
                        Button(action: saveMeme) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 15)
                }
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Memely")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showTemplates) {
                TemplateBrowser(files: templateFiles) { name in
                    addTemplate(name)
                }
            }
            .alert("Add Meme Text", isPresented: $showTextAlert) {
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
            // Adds as a background layer
            layers.insert(MemelyLayer(image: img, zIndex: -1), at: 0)
        }
        showTemplates = false
    }

    @MainActor
    func saveMeme() {
        let renderer = ImageRenderer(content: body)
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - Persistent Gesture Component
struct MemelyComponent: View {
    @Binding var item: MemelyLayer
    
    // Current gesture states
    @State private var currentOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero
    
    var body: some View {
        Group {
            if item.isText {
                Text(item.text)
                    .font(.system(size: 45, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 4)
                    .multilineTextAlignment(.center)
            } else if let img = item.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250)
            }
        }
        .offset(x: item.offset.width + currentOffset.width, 
                y: item.offset.height + currentOffset.height)
        .scaleEffect(item.scale * currentScale)
        .rotationEffect(item.rotation + currentRotation)
        .gesture(
            DragGesture()
                .onChanged { currentOffset = $0.translation }
                .onEnded { value in
                    item.offset.width += value.translation.width
                    item.offset.height += value.translation.height
                    currentOffset = .zero
                }
        )
        .gesture(
            SimultaneousGesture(
                MagnificationGesture()
                    .onChanged { currentScale = $0 }
                    .onEnded { value in
                        item.scale *= value
                        currentScale = 1.0
                    },
                RotationGesture()
                    .onChanged { currentRotation = $0 }
                    .onEnded { value in
                        item.rotation += value
                        currentRotation = .zero
                    }
            )
        )
    }
}

// MARK: - Template Picker
struct TemplateBrowser: View {
    let files: [String]
    var onSelect: (String) -> Void
    var body: some View {
        NavigationStack {
            List(files, id: \.self) { file in
                Button { onSelect(file) } label: {
                    HStack {
                        Image(systemName: "photo.fill")
                        Text(file)
                    }
                }
            }
            .navigationTitle("Select Background")
        }
    }
}

// MARK: - PencilKit Wrap
struct CanvasRepresentable: UIViewRepresentable {
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
