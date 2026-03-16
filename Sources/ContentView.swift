import SwiftUI
import PencilKit
import PhotosUI

// MARK: - Advanced Layer Model
struct WindLayer: Identifiable {
    let id = UUID()
    var image: UIImage?
    var text: String = ""
    var isText: Bool = false
    var fontName: String = "Impact" // Default Meme Font
    
    // Persistent Transformation
    var offset: CGSize = .zero
    var scale: CGFloat = 1.0
    var rotation: Angle = .zero
    var zIndex: Double = 0
}

struct ContentView: View {
    @State private var layers: [WindLayer] = []
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    
    // UI Logic
    @State private var isDrawingMode = false
    @State private var showTemplates = false
    @State private var showTextEditor = false
    @State private var textInput = ""
    @State private var selectedFont = "Impact"
    @State private var photoSelection: PhotosPickerItem?

    let availableFonts = ["Impact", "Helvetica-Bold", "Marker Felt", "Courier-Bold", "Futura-CondensedExtraBold"]
    let templateFiles = ["temp1", "temp2", "temp3", "temp4", "temp5"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - THE STUDIO
                ZStack {
                    Color.white.ignoresSafeArea()
                    
                    // The drawing layer (Background or Foreground based on toggle)
                    CanvasProvider(canvasView: $canvasView, toolPicker: $toolPicker, isActive: isDrawingMode)
                        .zIndex(isDrawingMode ? 1000 : 0)
                        .allowsHitTesting(isDrawingMode)
                    
                    ForEach($layers) { $layer in
                        WindElement(item: $layer)
                            .zIndex(layer.zIndex)
                            .onTapGesture {
                                layer.zIndex = (layers.map(\.zIndex).max() ?? 0) + 1
                            }
                    }
                }
                .clipped()
                
                // MARK: - CRAZY GOOD TOOLBAR
                VStack(spacing: 10) {
                    Picker("Mode", selection: $isDrawingMode) {
                        Image(systemName: "hand.draw").tag(true)
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    HStack(spacing: 20) {
                        Button { showTemplates = true } label: {
                            ToolbarIcon(icon: "photo.on.rectangle.angled", label: "Gallery")
                        }
                        
                        PhotosPicker(selection: $photoSelection, matching: .images) {
                            ToolbarIcon(icon: "plus.viewfinder", label: "Overlay")
                        }
                        
                        Button { showTextEditor = true } label: {
                            ToolbarIcon(icon: "textformat", label: "Text")
                        }
                        
                        Spacer()
                        
                        Button(action: exportToLibrary) {
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
            .navigationTitle("WindClones Pro")
            .sheet(isPresented: $showTemplates) {
                TemplateGallery(files: templateFiles) { name in
                    loadTemplate(name)
                    showTemplates = false
                }
            }
            .sheet(isPresented: $showTextEditor) {
                VStack(spacing: 20) {
                    Text("Meme Text Designer").font(.headline)
                    TextField("Enter text...", text: $textInput)
                        .textFieldStyle(.roundedBorder).padding()
                    
                    Picker("Font", selection: $selectedFont) {
                        ForEach(availableFonts, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.wheel)
                    
                    Button("Add to Studio") {
                        layers.append(WindLayer(text: textInput, isText: true, fontName: selectedFont, zIndex: Double(layers.count)))
                        textInput = ""
                        showTextEditor = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .presentationDetents([.medium])
            }
            .onChange(of: photoSelection) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        layers.append(WindLayer(image: uiImage, zIndex: Double(layers.count)))
                    }
                }
            }
        }
    }

    func loadTemplate(_ name: String) {
        if let path = Bundle.main.path(forResource: name, ofType: "jpg") ?? Bundle.main.path(forResource: name, ofType: "png"),
           let img = UIImage(contentsOfFile: path) {
            layers.insert(WindLayer(image: img, zIndex: -1), at: 0)
        }
    }

    @MainActor
    func exportToLibrary() {
        // Create a dedicated view for rendering to avoid UI artifacts
        let renderer = ImageRenderer(content: body) 
        renderer.scale = UIScreen.main.scale * 2
        if let image = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - Smooth Gesture Engine
struct WindElement: View {
    @Binding var item: WindLayer
    @State private var dOffset: CGSize = .zero
    @State private var dScale: CGFloat = 1.0
    @State private var dRotation: Angle = .zero

    var body: some View {
        Group {
            if item.isText {
                Text(item.text)
                    .font(.custom(item.fontName, size: 50))
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 2)
                    .shadow(color: .black, radius: 5)
                    .multilineTextAlignment(.center)
            } else if let img = item.image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250)
            }
        }
        .offset(x: item.offset.width + dOffset.width, y: item.offset.height + dOffset.height)
        .scaleEffect(item.scale * dScale)
        .rotationEffect(item.rotation + dRotation)
        .gesture(
            DragGesture()
                .onChanged { dOffset = $0.translation }
                .onEnded { value in
                    item.offset.width += value.translation.width
                    item.offset.height += value.translation.height
                    dOffset = .zero
                }
        )
        .gesture(
            SimultaneousGesture(
                MagnificationGesture()
                    .onChanged { dScale = $0 }
                    .onEnded { item.scale *= $0; dScale = 1.0 },
                RotationGesture()
                    .onChanged { dRotation = $0 }
                    .onEnded { item.rotation += $0; dRotation = .zero }
            )
        )
    }
}

// MARK: - Fixed Gallery with Previews
struct TemplateGallery: View {
    let files: [String]
    var onSelect: (String) -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(files, id: \.self) { file in
                        Button { onSelect(file) } label: {
                            VStack {
                                if let path = Bundle.main.path(forResource: file, ofType: "jpg"),
                                   let uiImage = UIImage(contentsOfFile: path) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 120).cornerRadius(10).clipped()
                                } else {
                                    RoundedRectangle(cornerRadius: 10).fill(.gray.opacity(0.3)).frame(height: 120)
                                }
                                Text(file).font(.caption).foregroundStyle(.primary)
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

struct ToolbarIcon: View {
    let icon: String
    let label: String
    var body: some View {
        VStack { Image(systemName: icon).font(.title3); Text(label).font(.caption2) }
    }
}

struct CanvasProvider: UIViewRepresentable {
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
