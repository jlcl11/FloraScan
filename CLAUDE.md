# CLAUDE.md — FloraScan Project Context

> Este archivo es el documento maestro que Claude Code lee al iniciar cada sesión en este repositorio. Contiene todo el contexto necesario para implementar FloraScan correctamente sin tener que volver a explicar decisiones de producto, arquitectura o diseño.

---

## 1. Identidad del proyecto

**Nombre:** FloraScan

**Pitch en una frase:** Gestor visual de jardín con identificación de plantas por cámara, 100% nativo iOS 26, on-device + APIs gratuitas, sin cuenta de Apple Developer paga.

**Audiencia:** personas con plantas en casa, balcón o jardín que quieren un único lugar para identificarlas, recordar cuándo cuidarlas, y compartir su jardín.

**Diferenciador competitivo:** mientras Greg, Planta, PictureThis son apps cross-platform genéricas, FloraScan es **nativa iOS 26 desde el día uno**: Liquid Glass, MeshGradient animado, zoom transitions cinematográficos, SF Symbols 7 con animaciones Draw On. Ese es el moat estético.

**Estado:** greenfield. Empezamos desde cero con Xcode 26, Swift 6.2, iOS 26.0 deployment target.

---

## 2. Restricciones críticas que NUNCA hay que olvidar

Estas restricciones determinan TODAS las decisiones técnicas. Léelas antes de proponer cualquier cosa.

1. **Sin cuenta Apple Developer paga.** El developer no tiene los $99/año. Esto significa:
   - **NO** usar CloudKit en producción (sí compila en development environment).
   - **NO** usar Push Notifications remotas.
   - **NO** usar WeatherKit (requiere cuenta paga).
   - **NO** publicar en App Store, ni TestFlight externo.
   - **SÍ** funcionan: notificaciones locales, Live Activities locales, Core ML, Vision, AVFoundation, SwiftData (local), todas las APIs gratuitas externas.
   - El provisioning profile gratuito caduca cada 7 días → la app hay que reinstalarla periódicamente en el dispositivo personal.

2. **Solo Mac + simulador iPhone.** No hay iPad. No optimizar UI para iPad en MVP.

3. **Liquid Glass no se renderiza correctamente en simulador.** Los specular highlights y la refracción solo se ven en hardware real. Mitigación: validar visualmente con screenshots de apps Apple (Camera, Photos, Maps) en iOS 26.

4. **iOS 26.0+ deployment target.** Usamos las APIs nuevas sin paranoia de compatibilidad. No hay `if #available` para iOS 26 features.

5. **Idioma de la UI: español (España)** como principal, inglés como secundario. Localizable.xcstrings.

6. **Identificador de bundle:** `io.jlcl11.florascan`. Equipo: Personal Team (Apple ID gratuito).

---

## 3. Stack tecnológico definitivo

```
Lenguaje:          Swift 6.2 (strict concurrency activado)
UI framework:      SwiftUI (puro, nada UIKit salvo bridges puntuales)
Deployment target: iOS 26.0
IDE:               Xcode 26
Persistencia:      SwiftData (sin CloudKit en MVP)
ML:                Core ML 9.0 + Vision framework
Cámara:            AVFoundation con UIViewRepresentable bridge
Notificaciones:    UserNotifications (locales)
Networking:        URLSession async/await (sin Alamofire)
Testing:           Swift Testing (no XCTest)
Concurrencia:      async/await + actors + @Observable (NO Combine)
APIs externas:     Pl@ntNet, Perenual, Wikipedia, GBIF
```

Lo que NO usamos (no añadir sin justificación explícita):
- ❌ Combine (usar async/await + AsyncSequence)
- ❌ UIKit (salvo `UIViewRepresentable` para AVCaptureVideoPreviewLayer)
- ❌ CocoaPods, Carthage (solo Swift Package Manager si hace falta)
- ❌ RxSwift, Alamofire, Lottie, Firebase, Supabase
- ❌ CloudKit (en MVP)
- ❌ XCTest (usamos Swift Testing con `@Test` y `#expect`)

---

## 4. Arquitectura general

```
FloraScan/
├── FloraScanApp.swift                  ← entry point, modelContainer
├── App/
│   ├── AppContainer.swift              ← inyección de dependencias
│   └── Theme.swift                     ← paleta, tipografía, helpers de color
├── Features/
│   ├── Onboarding/
│   ├── Garden/                         ← inventario "Mi jardín"
│   ├── Today/                          ← vista de tareas del día
│   ├── Identify/                       ← cámara + clasificación
│   ├── PlantDetail/                    ← ficha de planta
│   └── Share/                          ← exportar/compartir jardín
├── Core/
│   ├── ML/
│   │   ├── PlantClassifier.swift       ← actor que envuelve VNCoreMLRequest
│   │   ├── ClassificationResult.swift
│   │   └── ModelLoader.swift
│   ├── Camera/
│   │   ├── CameraSession.swift         ← AVCaptureSession + delegate
│   │   ├── CameraPreviewView.swift     ← UIViewRepresentable
│   │   └── FrameThrottler.swift
│   ├── Networking/
│   │   ├── PlantNetClient.swift        ← API de identificación online
│   │   ├── PerenualClient.swift        ← API de cuidados
│   │   └── WikipediaClient.swift       ← descripciones
│   ├── Models/                         ← @Model SwiftData
│   ├── Persistence/
│   ├── Notifications/
│   │   └── CareReminderScheduler.swift ← UNUserNotifications wrapper
│   ├── Sharing/
│   │   └── GardenExport.swift          ← Transferable + UTType
│   └── Extensions/
│       └── View+CompatibleGlass.swift  ← helper Liquid Glass
└── Resources/
    ├── Localizable.xcstrings
    ├── Assets.xcassets
    └── PlantClassifier.mlpackage
```

**Principios arquitectónicos:**

- **Feature-first**: cada pantalla tiene su carpeta con View + ViewModel + componentes específicos.
- **Servicios reutilizables en `Core/`**: cada uno encapsulado, testeable, sin dependencias de UI.
- **Actores para estado mutable concurrente**: clasificador, sesión de cámara, networking caches.
- **`@MainActor @Observable`** para ViewModels de SwiftUI.
- **Inyección de dependencias por inicializador**, no singletons (excepto donde es genuinamente necesario, como `TimerStore.shared` no aplica aquí).

---

## 5. Modelo de datos (SwiftData)

```swift
import Foundation
import SwiftData

@Model
final class Plant {
    @Attribute(.unique) var id: UUID = UUID()
    var nickname: String = ""                      // "Pothos del salón"
    var scientificName: String = ""                // "Epipremnum aureum"
    var commonName: String = ""                    // "Potos"
    var locationLabel: String = ""                 // "Salón", "Balcón"
    var lightLevel: String = "medium"              // raw de LightLevel enum
    var acquisitionDate: Date = Date()
    var healthScore: Double = 1.0                  // 0.0...1.0
    var notes: String = ""
    var createdAt: Date = Date()
    var lastWateredAt: Date?
    var lastPrunedAt: Date?
    var lastFertilizedAt: Date?

    // Identificación externa
    var plantNetGBIFID: Int?
    var perenualID: Int?

    // Care profile derivado de Perenual + heurística estacional
    var wateringIntervalDays: Int = 7
    var pruningMonths: [Int] = []                  // meses 1-12
    var fertilizingIntervalDays: Int = 30

    // Relaciones
    @Relationship(deleteRule: .cascade, inverse: \PlantPhoto.plant)
    var photos: [PlantPhoto] = []

    @Relationship(deleteRule: .cascade, inverse: \CareTask.plant)
    var careTasks: [CareTask] = []

    init(scientificName: String, commonName: String, nickname: String) {
        self.scientificName = scientificName
        self.commonName = commonName
        self.nickname = nickname
    }
}

@Model
final class PlantPhoto {
    @Attribute(.unique) var id: UUID = UUID()
    var fileName: String = ""                      // en Documents/Plants/
    var capturedAt: Date = Date()
    var isPrimary: Bool = false
    var plant: Plant?

    init(fileName: String, isPrimary: Bool = false) {
        self.fileName = fileName
        self.isPrimary = isPrimary
    }
}

@Model
final class CareTask {
    @Attribute(.unique) var id: UUID = UUID()
    var typeRaw: String = "watering"               // CareType.rawValue
    var intervalDays: Int = 7
    var lastDoneAt: Date?
    var nextDueAt: Date = Date()
    var notificationID: String?
    var plant: Plant?

    var type: CareType {
        get { CareType(rawValue: typeRaw) ?? .watering }
        set { typeRaw = newValue.rawValue }
    }

    init(type: CareType, intervalDays: Int, nextDueAt: Date) {
        self.typeRaw = type.rawValue
        self.intervalDays = intervalDays
        self.nextDueAt = nextDueAt
    }
}

enum CareType: String, Codable, CaseIterable {
    case watering, pruning, fertilizing, repotting, rotation
}

enum LightLevel: String, Codable, CaseIterable {
    case low, medium, bright, direct

    var modifier: Double {
        switch self {
        case .low: 1.3       // riego menos frecuente
        case .medium: 1.0
        case .bright: 0.85
        case .direct: 0.7    // riego más frecuente
        }
    }
}
```

**Reglas críticas:**
- Todas las propiedades tienen valor por defecto o son opcionales (futura compatibilidad CloudKit).
- Las relaciones son siempre opcionales en el lado inverso.
- Las fotos como blobs grandes NUNCA en SwiftData: solo `fileName` referenciando `Documents/Plants/`.
- Los enums se persisten como `String` raw value, con computed property tipada.

---

## 6. Identificación de plantas: estrategia híbrida

### 6.1 Filosofía: API online primaria + Core ML local de fallback

**Razón:** Pl@ntNet API tiene 78.225 especies con accuracy profesional, gratis 500 ids/día. Un modelo local nunca igualará eso en MVP. Pero la conexión puede fallar, y la latencia puede ser alta. Solución: lanzar AMBAS en paralelo y mostrar la primera que llegue.

### 6.2 Pl@ntNet API (motor primario)

**Endpoint:**
```
POST https://my-api.plantnet.org/v2/identify/all?api-key=KEY
Content-Type: multipart/form-data
Parts: images=@photo.jpg, organs=auto
```

**Ejemplo de cliente:**
```swift
actor PlantNetClient {
    enum ClientError: Error, LocalizedError {
        case noConnection, badResponse(Int), decoding(Error), rateLimited

        var errorDescription: String? {
            switch self {
            case .noConnection: "Sin conexión a internet."
            case .badResponse(let code): "Servidor devolvió \(code)."
            case .decoding(let e): "Error de decodificación: \(e.localizedDescription)"
            case .rateLimited: "Has alcanzado el límite diario de identificaciones."
            }
        }
    }

    private let apiKey: String
    private let session: URLSession
    private let baseURL = URL(string: "https://my-api.plantnet.org/v2/identify/all")!

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func identify(imageData: Data) async throws -> [PlantNetCandidate] {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "api-key", value: apiKey),
            URLQueryItem(name: "include-related-images", value: "false")
        ]

        let boundary = UUID().uuidString
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")
        request.httpBody = makeMultipartBody(imageData: imageData, boundary: boundary)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClientError.badResponse(0) }
        if http.statusCode == 429 { throw ClientError.rateLimited }
        guard (200..<300).contains(http.statusCode) else {
            throw ClientError.badResponse(http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(PlantNetResponse.self, from: data)
            return decoded.results.prefix(5).map(PlantNetCandidate.init)
        } catch {
            throw ClientError.decoding(error)
        }
    }

    private func makeMultipartBody(imageData: Data, boundary: String) -> Data {
        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"organs\"\r\n\r\nauto\r\n")
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"images\"; filename=\"photo.jpg\"\r\n")
        body.appendString("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.appendString("\r\n--\(boundary)--\r\n")
        return body
    }
}

struct PlantNetCandidate: Equatable, Identifiable {
    let id = UUID()
    let scientificName: String
    let commonNames: [String]
    let score: Double             // 0.0...1.0
    let gbifID: Int?

    var preferredCommonName: String {
        commonNames.first ?? scientificName
    }
}
```

### 6.3 Core ML local (motor de fallback offline)

**Modelo recomendado para producción:** PlantNet-300K ResNet-18 convertido a Core ML.
- 1.081 especies europeas comunes.
- ~22 MB FP16, latencia <30 ms.
- Licencia CC-BY (atribuir en pantalla "Acerca de").

**Modelo de arranque (sprint 1):** Oxford 102 Flowers `.mlmodel` ya convertido (102 flores).
- Tamaño <30 MB.
- Funcional desde día 1 sin conversión propia.
- Mientras avanza la conversión de PlantNet-300K en paralelo.

**Wrapper en Swift:**
```swift
import Vision
import CoreML
import CoreImage

actor PlantClassifier {
    enum ClassifierError: Error {
        case modelNotLoaded, noResults
    }

    private var visionModel: VNCoreMLModel?

    func loadIfNeeded() throws {
        guard visionModel == nil else { return }
        visionModel = try ModelLoader.loadVisionModel()
    }

    func classify(ciImage: CIImage,
                  orientation: CGImagePropertyOrientation = .up) async throws -> [LocalCandidate] {
        try loadIfNeeded()
        guard let visionModel else { throw ClassifierError.modelNotLoaded }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: visionModel) { req, err in
                if let err { continuation.resume(throwing: err); return }
                guard let observations = req.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: ClassifierError.noResults); return
                }
                let top5 = Array(observations.prefix(5)).map {
                    LocalCandidate(label: $0.identifier, confidence: Double($0.confidence))
                }
                continuation.resume(returning: top5)
            }
            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(ciImage: ciImage,
                                                orientation: orientation,
                                                options: [:])
            do { try handler.perform([request]) }
            catch { continuation.resume(throwing: error) }
        }
    }
}

struct LocalCandidate: Equatable, Identifiable {
    let id = UUID()
    let label: String         // ej: "Epipremnum_aureum" o "Olea europaea"
    let confidence: Double    // 0.0...1.0
}

enum ModelLoader {
    static func loadVisionModel() throws -> VNCoreMLModel {
        guard let url = Bundle.main.url(forResource: "PlantClassifier",
                                        withExtension: "mlmodelc")
            ?? Bundle.main.url(forResource: "PlantClassifier",
                               withExtension: "mlpackage") else {
            throw NSError(domain: "ModelLoader", code: 1)
        }
        let config = MLModelConfiguration()
        config.computeUnits = .all              // CPU + GPU + Neural Engine
        let model = try MLModel(contentsOf: url, configuration: config)
        return try VNCoreMLModel(for: model)
    }
}
```

### 6.4 Orquestador: race entre API y modelo local

```swift
@MainActor
@Observable
final class IdentifyViewModel {
    enum State: Equatable {
        case idle
        case identifying
        case results(IdentificationResults)
        case failed(String)
    }

    struct IdentificationResults: Equatable {
        let primary: PlantNetCandidate?       // de la API
        let local: [LocalCandidate]            // del modelo on-device
        let bestGuess: BestGuess
    }

    enum BestGuess: Equatable {
        case fromAPI(PlantNetCandidate)
        case fromLocal(LocalCandidate)
        case none
    }

    private(set) var state: State = .idle
    private let plantNet: PlantNetClient
    private let classifier = PlantClassifier()

    init(plantNet: PlantNetClient) { self.plantNet = plantNet }

    func identify(imageData: Data, ciImage: CIImage) async {
        state = .identifying

        async let apiTask = identifyAPI(imageData: imageData)
        async let localTask = identifyLocal(ciImage: ciImage)

        let (apiResult, localResult) = await (apiTask, localTask)

        let bestGuess = chooseBestGuess(api: apiResult, local: localResult)
        state = .results(IdentificationResults(
            primary: apiResult,
            local: localResult,
            bestGuess: bestGuess
        ))
    }

    private func identifyAPI(imageData: Data) async -> PlantNetCandidate? {
        do {
            let candidates = try await plantNet.identify(imageData: imageData)
            return candidates.first
        } catch {
            return nil
        }
    }

    private func identifyLocal(ciImage: CIImage) async -> [LocalCandidate] {
        do {
            return try await classifier.classify(ciImage: ciImage)
        } catch {
            return []
        }
    }

    private func chooseBestGuess(api: PlantNetCandidate?,
                                 local: [LocalCandidate]) -> BestGuess {
        // Reglas:
        // 1. Si la API responde con score > 0.4, ganamos la API (más amplia)
        // 2. Si la API falla pero el modelo local tiene confianza > 0.7, gana local
        // 3. Si no hay nada confiable, .none
        if let api, api.score > 0.4 { return .fromAPI(api) }
        if let top = local.first, top.confidence > 0.7 { return .fromLocal(top) }
        return .none
    }
}
```

### 6.5 Cómo convertir PlantNet-300K a Core ML

Documento de referencia técnica si se aborda la conversión propia:

```python
# venv con Python 3.11
# pip install coremltools==9.0 torch==2.7 torchvision==0.22

import torch, torchvision
import coremltools as ct
import json

# 1. Cargar pesos PlantNet-300K
model = torchvision.models.resnet18(num_classes=1081)
ckpt = torch.load("resnet18_weights_best_acc.tar", map_location="cpu")
model.load_state_dict(ckpt["model_state_dict"])
model.eval()

# 2. Trazar
example = torch.rand(1, 3, 224, 224)
traced = torch.jit.trace(model, example)

# 3. Cargar mapping clase → species_name
class_idx_to_species_id = json.load(open("class_idx_to_species_id.json"))
species_id_to_name = json.load(open("plantnet300K_species_id_2_name.json"))
labels = [species_id_to_name[class_idx_to_species_id[str(i)]] for i in range(1081)]

# 4. Convertir
mlmodel = ct.convert(
    traced,
    inputs=[ct.ImageType(name="image",
                         shape=(1, 3, 224, 224),
                         bias=[-0.485/0.229, -0.456/0.224, -0.406/0.225],
                         scale=1/(0.226*255))],
    classifier_config=ct.ClassifierConfig(labels),
    convert_to="mlprogram",
    minimum_deployment_target=ct.target.iOS18,
    compute_precision=ct.precision.FLOAT16
)
mlmodel.save("PlantClassifier.mlpackage")
```

Referencias:
- [Apple Core ML Tools — PyTorch Workflow](https://apple.github.io/coremltools/docs-guides/source/convert-pytorch-workflow.html)
- [PlantNet-300K repo](https://github.com/plantnet/PlantNet-300K)

---

## 7. Pipeline de cámara

### 7.1 Arquitectura de captura

```
AVCaptureSession (background queue)
    ↓ AVCaptureVideoDataOutput delegate
CameraSession (actor proxy a clase ObjC)
    ↓ frames a 30fps
FrameThrottler (5 fps)
    ↓ CIImage + CGImagePropertyOrientation
IdentifyViewModel (@MainActor @Observable)
    ↓ resultados clasificación
DetectionOverlay (SwiftUI)
```

### 7.2 CameraSession

```swift
import AVFoundation
import CoreImage

@MainActor
final class CameraSession: NSObject {
    enum Status: Equatable {
        case idle, running, denied, failed(String)
    }

    private(set) var status: Status = .idle
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "io.jlcl11.florascan.camera")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()

    var onFrame: ((CIImage, CGImagePropertyOrientation) -> Void)?
    var onPhoto: ((Data?) -> Void)?

    func start() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            await configureAndStart()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted { await configureAndStart() } else { status = .denied }
        default:
            status = .denied
        }
    }

    func stop() {
        queue.async { [weak self] in self?.session.stopRunning() }
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.photoQualityPrioritization = .balanced
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private func configureAndStart() async {
        await withCheckedContinuation { cont in
            queue.async { [weak self] in
                guard let self else { cont.resume(); return }
                self.session.beginConfiguration()
                self.session.sessionPreset = .high

                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                           for: .video,
                                                           position: .back),
                      let input = try? AVCaptureDeviceInput(device: device),
                      self.session.canAddInput(input) else {
                    Task { @MainActor in self.status = .failed("Cámara no disponible.") }
                    self.session.commitConfiguration()
                    cont.resume(); return
                }
                self.session.addInput(input)

                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.setSampleBufferDelegate(self, queue: self.queue)
                if self.session.canAddOutput(self.videoOutput) {
                    self.session.addOutput(self.videoOutput)
                }
                if self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                }

                self.session.commitConfiguration()
                self.session.startRunning()
                Task { @MainActor in self.status = .running }
                cont.resume()
            }
        }
    }
}

extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        Task { @MainActor in self.onFrame?(ciImage, .right) }
    }
}

extension CameraSession: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        let data = photo.fileDataRepresentation()
        Task { @MainActor in self.onPhoto?(data) }
    }
}
```

### 7.3 FrameThrottler

```swift
final class FrameThrottler {
    private let interval: TimeInterval
    private var lastFireTime: TimeInterval = 0

    init(framesPerSecond: Double) {
        self.interval = 1.0 / framesPerSecond
    }

    func shouldFire(now: TimeInterval = CACurrentMediaTime()) -> Bool {
        if now - lastFireTime >= interval {
            lastFireTime = now
            return true
        }
        return false
    }
}
```

Para FloraScan: **5 FPS es suficiente**. La planta no se mueve.

### 7.4 CameraPreviewView (puente UIKit ↔ SwiftUI)

```swift
import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
```

---

## 8. Liquid Glass: filosofía y aplicación

### 8.1 Regla cardinal de la HIG iOS 26

**Liquid Glass va en la capa de navegación flotante, NUNCA en el contenido.**

- ✅ Tab bar inferior, navegación, botones flotantes, cards de resultado superpuestas a video, banners.
- ❌ El feed de video de la cámara, las fotos de plantas, listas densas, TextEditor, ContentUnavailableView.

### 8.2 APIs principales

```swift
// Glass simple por defecto (capsule shape, .regular variant)
Text("Identificar").padding().glassEffect()

// Con shape personalizado
Image(systemName: "leaf.fill")
    .padding()
    .glassEffect(.regular, in: .rect(cornerRadius: 16))

// Con tinte semántico
Button("Capturar") { }
    .glassEffect(.regular.tint(.green.opacity(0.5)).interactive(),
                 in: .circle)

// GlassEffectContainer: agrupa cristales para que se vean cohesionados
@Namespace var ns
GlassEffectContainer(spacing: 12) {
    HStack {
        Button("Hoja")  { }.glassEffect().glassEffectID("organ_leaf",   in: ns)
        Button("Flor")  { }.glassEffect().glassEffectID("organ_flower", in: ns)
        Button("Fruto") { }.glassEffect().glassEffectID("organ_fruit",  in: ns)
    }
}

// Estilo de botón (atajo)
Button("Añadir") { }.buttonStyle(.glass)               // sutil
Button("Identificar") { }.buttonStyle(.glassProminent) // CTA
```

### 8.3 Helper compartido del proyecto

```swift
// Core/Extensions/View+CompatibleGlass.swift
import SwiftUI

extension View {
    /// Liquid Glass con shape custom y tinte opcional.
    @ViewBuilder
    func glassed<S: Shape>(in shape: S = Capsule(),
                           tint: Color? = nil,
                           interactive: Bool = false) -> some View {
        if let tint, interactive {
            self.glassEffect(.regular.tint(tint).interactive(), in: shape)
        } else if let tint {
            self.glassEffect(.regular.tint(tint), in: shape)
        } else if interactive {
            self.glassEffect(.regular.interactive(), in: shape)
        } else {
            self.glassEffect(.regular, in: shape)
        }
    }

    /// Card de cristal con esquinas 18.
    func glassedCard() -> some View {
        glassed(in: .rect(cornerRadius: 18))
    }
}
```

### 8.4 Aplicación específica por pantalla en FloraScan

| Pantalla | Elementos en Liquid Glass | Elementos sin glass |
|---|---|---|
| **Identify (cámara)** | Botón shutter (`circle`), chip "Olea europaea 92%" superpuesto al video, selector hoja/flor/fruto/corteza con `GlassEffectContainer`, toolbar inferior | Preview de video full-bleed |
| **Garden (inventario)** | Tab bar, FAB para añadir, toolbar superior, search bar | Cards de plantas con foto (foto es contenido) |
| **PlantDetail** | Toolbar de acciones flotantes, sheet de "Marcar como regada" | Foto hero arriba, texto descriptivo, tabla de cuidados |
| **Today** | Tab bar, header con resumen del día | Lista de tareas (cada fila plana) |
| **Onboarding** | Botón "Continuar" sobre MeshGradient | El propio MeshGradient (es el fondo) |
| **Share** | Botones de export sobre snapshot del jardín | El snapshot mismo |

### 8.5 Reglas de oro

1. **Tinte con significado semántico**, no decorativo: verde para acción primaria/éxito, rojo solo si es destructivo, ámbar/naranja para atención.
2. **Texto importante (nombre de planta, % confianza, fecha de riego) siempre opaco**, nunca translúcido.
3. **Honrar `accessibilityReduceTransparency`** del entorno: cuando esté activo, fallback a `.regularMaterial`.
4. **Probar con Reduce Transparency activado** y con Increase Contrast.
5. **Liquid Glass no se ve perfecto en simulador** — validar visualmente con screenshots de Apple Camera/Photos en iOS 26 cuando no sea posible probar en device.

---

## 9. Animaciones: catálogo aplicado a FloraScan

Estas son las animaciones que SÍ vamos a usar en FloraScan, con su uso concreto.

### 9.1 phaseAnimator — pulso del botón cámara

```swift
struct PulsingShutterButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().stroke(.white, lineWidth: 3)
                Circle().fill(.white).padding(6)
            }
            .frame(width: 76, height: 76)
        }
        .phaseAnimator([1.0, 1.08, 1.0]) { content, scale in
            content.scaleEffect(scale)
        } animation: { _ in
            .smooth(duration: 1.4)
        }
    }
}
```

### 9.2 keyframeAnimator — thumbnail vuela tras capturar

Cuando el usuario captura una foto y se identifica, la miniatura "vuela" desde la posición de la cámara hasta la grid de "Mi jardín".

```swift
struct FlyingThumbnail: View {
    let image: UIImage
    @Binding var trigger: Bool

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: 80, height: 80)
            .clipShape(.rect(cornerRadius: 12))
            .keyframeAnimator(initialValue: FlightState(),
                              trigger: trigger) { content, value in
                content
                    .scaleEffect(value.scale)
                    .offset(value.offset)
                    .opacity(value.opacity)
                    .rotationEffect(.degrees(value.rotation))
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    LinearKeyframe(1.0, duration: 0.1)
                    SpringKeyframe(1.4, duration: 0.3, spring: .bouncy)
                    SpringKeyframe(0.4, duration: 0.5, spring: .smooth)
                }
                KeyframeTrack(\.offset) {
                    LinearKeyframe(.zero, duration: 0.1)
                    CubicKeyframe(CGSize(width: 0, height: -100), duration: 0.4)
                    CubicKeyframe(CGSize(width: 130, height: 280), duration: 0.5)
                }
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1.0, duration: 0.7)
                    LinearKeyframe(0.0, duration: 0.2)
                }
                KeyframeTrack(\.rotation) {
                    LinearKeyframe(0, duration: 0.1)
                    CubicKeyframe(360, duration: 0.7)
                }
            }
    }

    struct FlightState {
        var scale: CGFloat = 1.0
        var offset: CGSize = .zero
        var opacity: CGFloat = 1.0
        var rotation: Double = 0
    }
}
```

### 9.3 MeshGradient — fondo "vivo" en onboarding e Identify

```swift
struct LivingMeshBackground: View {
    let palette: [Color]

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = Float(ctx.date.timeIntervalSinceReferenceDate)
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0],
                    [0.5 + 0.05 * sin(t * 0.4), 0],
                    [1, 0],
                    [0, 0.5 + 0.05 * cos(t * 0.3)],
                    [0.5 + 0.1 * sin(t * 0.2), 0.5 + 0.1 * cos(t * 0.25)],
                    [1, 0.5 + 0.05 * sin(t * 0.35)],
                    [0, 1],
                    [0.5 + 0.05 * cos(t * 0.4), 1],
                    [1, 1]
                ],
                colors: palette
            )
            .ignoresSafeArea()
        }
    }
}

extension LivingMeshBackground {
    /// Paleta general para pantallas premium (share, settings premium, etc.)
    static let nature: [Color] = [
        Color(hex: "#0E5C3F").opacity(0.85),
        Color(hex: "#5DA271"),
        Color(hex: "#0E5C3F").opacity(0.85),
        Color(hex: "#5DA271"),
        Color(hex: "#E6A85C"),
        Color(hex: "#5DA271"),
        Color(hex: "#0E5C3F").opacity(0.95),
        Color(hex: "#5DA271"),
        Color(hex: "#0E5C3F").opacity(0.85)
    ]

    /// Paleta EXCLUSIVA del Onboarding Hero (pantalla 1).
    /// Diagonal NW (verde botánico oscuro) → SE (mostaza cálida).
    /// Validada visualmente contra el mockup aprobado de Claude Design.
    /// NO sustituir por `nature` — el hero tiene tratamiento propio.
    static let onboardingHero: [Color] = [
        Color(hex: "#1F5A3F"),   // top-left: verde botánico oscuro
        Color(hex: "#3E8264"),   // top-mid: verde medio
        Color(hex: "#7AB089"),   // top-right: verde claro tirando a menta
        Color(hex: "#5DA271"),   // mid-left: verde claro
        Color(hex: "#A8C99A"),   // mid-center: verde menta luminoso (punto vivo)
        Color(hex: "#D4B88A"),   // mid-right: amber suave inicio
        Color(hex: "#7B9568"),   // bottom-left: verde apagado
        Color(hex: "#B89868"),   // bottom-mid: amber medio
        Color(hex: "#E6A85C")    // bottom-right: mostaza cálida (accentHero)
    ]
}
```

**Notas de uso:**
- `onboardingHero` se usa SOLO en `OnboardingHeroPage` (pantalla 1 del onboarding).
- `nature` se usa en pantalla 2 y 3 del onboarding (privacidad, permiso cámara), share view y splash.
- La animación de los puntos del mesh debe ser muy lenta (período 8-12s) y sutil (amplitud ±0.05). NO hipnótica.

### 9.4 navigationTransition zoom — hero en cards de planta

```swift
@Namespace var transitionNS

NavigationLink(value: plant) {
    PlantCard(plant: plant)
}
.matchedTransitionSource(id: plant.id, in: transitionNS)

.navigationDestination(for: Plant.self) { plant in
    PlantDetailView(plant: plant)
        .navigationTransition(.zoom(sourceID: plant.id, in: transitionNS))
}
```

Esta es **la animación firma** de FloraScan. Convierte la card en la foto hero del detalle con efecto cinematográfico.

### 9.5 symbolEffect — feedback emocional

```swift
// Planta saludable: "respirando"
Image(systemName: "leaf.fill")
    .symbolEffect(.breathe.pulse.byLayer, isActive: plant.healthScore > 0.7)

// Planta sedienta: gota oscilando
Image(systemName: "drop.fill")
    .foregroundStyle(.blue)
    .symbolEffect(.wiggle.byLayer, options: .repeat(.continuous), isActive: needsWater)

// Tarea completada: bounce
Image(systemName: "checkmark.circle.fill")
    .foregroundStyle(.green)
    .symbolEffect(.bounce, value: trigger)

// Cargando identificación: variableColor
Image(systemName: "sparkles")
    .symbolEffect(.variableColor.iterative.reversing, isActive: isIdentifying)
```

### 9.6 contentTransition — contadores

```swift
Text("\(plantCount) plantas")
    .contentTransition(.numericText())
    .animation(.smooth, value: plantCount)
```

### 9.7 scrollTransition — cards que se elevan al pasar

```swift
LazyVGrid(columns: columns, spacing: 16) {
    ForEach(plants) { plant in
        PlantCard(plant: plant)
            .scrollTransition(.interactive(timingCurve: .easeOut)) { content, phase in
                content
                    .opacity(phase.isIdentity ? 1.0 : 0.5)
                    .scaleEffect(phase.isIdentity ? 1.0 : 0.92)
                    .blur(radius: phase.isIdentity ? 0 : 1.5)
            }
    }
}
```

---

## 10. Sistema de diseño: paleta, tipografía, spacing, componentes

> ⚠️ Esta sección está validada contra el sistema visual aprobado de Claude Design (tokens.css + app.css). Los valores son **tokens semánticos** con contraste WCAG AA verificado en pares texto/fondo. NO improvisar colores ni tamaños.

### 10.1 Paleta — 30 tokens semánticos (Theme.swift)

La paleta se organiza en grupos: brand, surface, text, status, care semantic. Cada token tiene un nombre semántico (no literal) y, donde aplica, su contraste verificado WCAG AA sobre el fondo de uso típico.

```swift
import SwiftUI

enum Palette {
    // ─── Brand core ─────────────────────────────────────────
    static let leaf900 = Color(hex: "#082E1F")       // deepest botanical, accents on light
    static let leaf700 = Color(hex: "#0E5C3F")       // PRIMARY — 7.1:1 sobre cream
    static let leaf500 = Color(hex: "#2F8262")       // active/interactive — 4.6:1
    static let leaf300 = Color(hex: "#5DA271")       // decorativo soft
    static let leaf100 = Color(hex: "#C7DCC9")       // tinted bg

    static let amber700 = Color(hex: "#B57828")      // accent text — 4.6:1 (textual)
    static let amber500 = Color(hex: "#E6A85C")      // ACCENT HERO — solo bg, nunca texto solo
    static let amber200 = Color(hex: "#F4D9A8")      // tint suave

    static let clay700 = Color(hex: "#A24A3A")       // critical textual — 5.1:1
    static let clay500 = Color(hex: "#C95252")       // alert decorativo (nunca solo en body)
    static let clay200 = Color(hex: "#F2C5BD")       // tint

    // ─── Care semantic (refinados WCAG) ─────────────────────
    static let careWater = Color(hex: "#4E78B0")     // refinado desde #7B9ACC para AA
    static let careWaterSoft = Color(hex: "#7B9ACC") // decorativo
    static let carePrune = Color(hex: "#6F5734")
    static let carePruneSoft = Color(hex: "#8B6F47")
    static let careFertilize = Color(hex: "#6F4F90")
    static let careFertilizeSoft = Color(hex: "#9B7BB8")
    static let careRepot = Color(hex: "#9C5635")
    static let careRepotSoft = Color(hex: "#C77B5C")

    // ─── Surface (light mode) ───────────────────────────────
    static let surfaceApp = Color(hex: "#F5F1E8")        // app background, paper-manila
    static let surfaceCard = Color(hex: "#FFFFFF")
    static let surfaceElev = Color(hex: "#FBF8F1")       // elevación sutil sin blanco puro
    static let surfaceTinted = Color(hex: "#EDE7D7")     // chips secundarios, segmented inactivo

    // ─── Text on light (contraste sobre surfaceApp) ─────────
    static let textPrimary = Color(hex: "#1A1612")       // 14.6:1 AAA
    static let textSecondary = Color(hex: "#4A4640")     // 7.8:1 AAA
    static let textTertiary = Color(hex: "#7A766F")      // 4.6:1 AA
    static let textQuaternary = Color(hex: "#B0ACA4")    // decorativo solo, NO texto funcional
    static let textOnLeaf = Color(hex: "#FFFFFF")        // sobre leaf-700 → 7.1:1
    static let textOnAmber = Color(hex: "#1A1612")       // sobre amber-500 → 9.4:1

    // ─── Borders / dividers ─────────────────────────────────
    static let borderSubtle = Color.black.opacity(0.08)
    static let borderDefault = Color.black.opacity(0.14)
    static let borderStrong = Color.black.opacity(0.22)
    static let dividerHair = Color.black.opacity(0.06)

    // ─── Status semantic (alias) ────────────────────────────
    static let statusOk = leaf500
    static let statusWarning = amber700
    static let statusCritical = clay700

    // ─── Aliases legacy (mantener por compatibilidad) ───────
    static let primary = leaf700
    static let accent = amber500
    static let healthOk = leaf500
    static let healthWarning = amber700
    static let healthCritical = clay700
}

// Dark mode tokens — SwiftUI Color con dynamic provider
extension Palette {
    /// Dark mode usa una capa adicional encima de los anteriores.
    /// Para tokens dynamic-aware, usa estos:
    enum Dynamic {
        static let surfaceApp = Color(light: "#F5F1E8", dark: "#0F1411")
        static let surfaceCard = Color(light: "#FFFFFF", dark: "#1A211C")
        static let surfaceElev = Color(light: "#FBF8F1", dark: "#222A24")
        static let surfaceTinted = Color(light: "#EDE7D7", dark: "#2A332C")

        static let textPrimary = Color(light: "#1A1612", dark: "#F1EDE2")     // 14.4:1 dark
        static let textSecondary = Color(light: "#4A4640", dark: "#C2BDB1")   // 8.5:1 dark
        static let textTertiary = Color(light: "#7A766F", dark: "#8E8A80")    // 4.7:1 dark
        static let textOnLeaf = Color(light: "#FFFFFF", dark: "#F1EDE2")

        // Brand re-tuned para dark (más brillante para contraste)
        static let primary = Color(light: "#0E5C3F", dark: "#2F8262")
        static let accent = Color(light: "#E6A85C", dark: "#F0BF7E")
        static let critical = Color(light: "#A24A3A", dark: "#E08070")

        static let careWater = Color(light: "#4E78B0", dark: "#8FB3E0")
        static let carePrune = Color(light: "#6F5734", dark: "#B79567")
        static let careFertilize = Color(light: "#6F4F90", dark: "#B89AD4")
        static let careRepot = Color(light: "#9C5635", dark: "#DC9C7A")
    }
}

// Helpers
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.replacingOccurrences(of: "#", with: ""))
        var int: UInt64 = 0
        scanner.scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    /// Color que cambia según trait collection (light/dark).
    init(light: String, dark: String) {
        self.init(uiColor: UIColor { trait in
            UIColor(Color(hex: trait.userInterfaceStyle == .dark ? dark : light))
        })
    }
}
```

**Reglas semánticas críticas:**

1. **`amber500` (#E6A85C) NUNCA va solo como color de texto sobre `surfaceApp`** — solo 3.0:1. Para texto en color amber, usar `amber700` (#B57828).
2. **`careWaterSoft` y similares decorativos** son para fills/badges grandes. Para iconos pequeños y texto, usar la variante `care*` sin `Soft` (ya refinada para AA).
3. **`textTertiary` es el límite mínimo legible** (4.6:1). `textQuaternary` es decorativo, jamás para texto que el usuario tenga que leer.
4. **`leaf700` es la marca**. Cuando dudes qué verde usar, usa `leaf700`. Es el único que va en CTA primarios y wordmark.
5. **Glass tinte semántico:** los chips glass tintados usan opacidad 0.5-0.6 sobre la superficie glass para preservar el efecto cristal sin perder semántica.

### 10.2 Tipografía — escala completa

Stack:
- **Display y títulos**: SF Pro Display (sistema, weight 700 default).
- **Cuerpo y UI**: SF Pro Text (sistema).
- **Nombres científicos**: New York Italic (serif del sistema, gratis).
- **Mono caps (etiquetas y metadata)**: SF Mono.

| Token | Tamaño / Line / Tracking | Uso |
|---|---|---|
| `Display` | 44pt / 50pt / -1.0 | Hero del onboarding ("Tu jardín, en una cámara.") — único uso |
| `Large Title` | 34pt / 41pt / -0.4 | Títulos de pantalla principal ("Mi jardín", "Hoy") |
| `Title 1` | 28pt / 34pt / -0.3 | Nombres de planta en detalle, título sheet result |
| `Title 2` | 22pt / 28pt / -0.2 | Headers de secciones grandes, "Salud excelente" |
| `Title 3` | 20pt / 25pt / -0.1 | Subtítulos de cards grandes ("Próximo riego") |
| `Headline` | 17pt / 22pt / -0.2 (semibold) | Etiquetas destacadas, nombre planta en card del jardín |
| `Body` | 17pt / 22pt / -0.2 (regular) | Texto descriptivo principal |
| `Callout` | 16pt / 21pt / -0.15 (medium) | Texto informativo secundario, search bar placeholder |
| `Subhead` | 15pt / 20pt / -0.1 (medium) | Subtítulos en filas |
| `Footnote` | 13pt / 18pt (medium) | Metadata bajo títulos, "Última actualización" |
| `Caption 1` | 12pt / 16pt (medium) | Captions pequeñas, fechas relativas |
| `Caption 2` | 11pt / 13pt (semibold, +0.06) | Microlabels |
| `Mono Cap` | 11pt SF Mono (medium, +0.4, UPPERCASE) | Etiquetas técnicas: "27 ABR · MÁLAGA", "FAMILIA · OLEACEAE" |
| `Serif Italic` | New York Italic 400 | EXCLUSIVO para nombres científicos |

```swift
extension Font {
    // Scale custom (sigue iOS 17+ semantic typography pero con sizes específicos)
    static let fsDisplay = Font.system(size: 44, weight: .bold, design: .default)
    static let fsLargeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let fsTitle1 = Font.system(size: 28, weight: .bold, design: .default)
    static let fsTitle2 = Font.system(size: 22, weight: .bold, design: .default)
    static let fsTitle3 = Font.system(size: 20, weight: .semibold, design: .default)
    static let fsHeadline = Font.system(size: 17, weight: .semibold, design: .default)
    static let fsBody = Font.system(size: 17, weight: .regular, design: .default)
    static let fsCallout = Font.system(size: 16, weight: .medium, design: .default)
    static let fsSubhead = Font.system(size: 15, weight: .medium, design: .default)
    static let fsFootnote = Font.system(size: 13, weight: .medium, design: .default)
    static let fsCaption1 = Font.system(size: 12, weight: .medium, design: .default)
    static let fsCaption2 = Font.system(size: 11, weight: .semibold, design: .default)
    static let fsMonoCap = Font.system(size: 11, weight: .medium, design: .monospaced)

    // Serif italic para nombres científicos
    static let fsSciSmall = Font.custom("NewYorkItalic", size: 13, relativeTo: .footnote)
    static let fsSciDefault = Font.custom("NewYorkItalic", size: 17, relativeTo: .body)
    static let fsSciLarge = Font.custom("NewYorkItalic", size: 22, relativeTo: .title2)
    static let fsSciHero = Font.custom("NewYorkItalic", size: 28, relativeTo: .title1)
}
```

**Uso semántico estricto:**

```swift
// Mono cap para etiquetas tipo metadata
Text("27 ABR · MÁLAGA")
    .font(.fsMonoCap)
    .tracking(0.4)
    .textCase(.uppercase)
    .foregroundStyle(Palette.textTertiary)

// Nombre común y científico, siempre juntos en este orden
VStack(alignment: .leading, spacing: 2) {
    Text("Olivo")
        .font(.fsTitle1)
        .foregroundStyle(Palette.textPrimary)
    Text("Olea europaea")
        .font(.fsSciDefault)
        .foregroundStyle(Palette.textSecondary)
}
```

### 10.3 Spacing — sistema 8pt grid

Una sola escala. Todo es múltiplo de 8 con la excepción de **4pt** (densidad fina, divisores).

| Token | Valor | Uso |
|---|---|---|
| `s1` | 4pt | Hairline, divisores internos en cards densas |
| `s2` | 8pt | Tight, gap entre icono y texto pequeño |
| `s3` | 12pt | Gap interno de card, padding lateral chips |
| `s4` | 16pt | Padding card estándar, gap entre cards en grid |
| `s5` | 20pt | Margen pantalla horizontal (default) |
| `s6` | 24pt | Gap entre secciones |
| `s7` | 32pt | Headers con espacio respiratorio |
| `s8` | 40pt | Hero blocks |
| `s9` | 56pt | Bloques principales del onboarding |
| `s10` | 72pt | Espaciado máximo (raro) |

```swift
enum Spacing {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20
    static let s6: CGFloat = 24
    static let s7: CGFloat = 32
    static let s8: CGFloat = 40
    static let s9: CGFloat = 56
    static let s10: CGFloat = 72
}
```

**Reglas:**
- Margen horizontal estándar de pantallas: `s5` (20pt).
- Gap entre cards de un LazyVGrid: `s3` (12pt).
- Padding interior de card mediana: `s4` (16pt) por todos los lados.
- Gap entre secciones grandes en una scroll view: `s6` (24pt).

### 10.4 Radii — esquinas

| Token | Valor | Uso |
|---|---|---|
| `pill` | 999pt | Botones, chips, segmented |
| `chip` | 14pt | Chips no pill (raro) |
| `cardSmall` | 14pt | Cards pequeñas (TaskRow estilo box) |
| `cardMedium` | 18pt | Cards estándar (PlantCard, info cards del detail) |
| `cardLarge` | 22pt | Cards grandes hero |
| `sheet` | 24pt | Sheets modales (top corners) |
| `hero` | 28pt | Hero photo del PlantDetail |

```swift
enum Radius {
    static let pill: CGFloat = 999
    static let chip: CGFloat = 14
    static let cardSmall: CGFloat = 14
    static let cardMedium: CGFloat = 18
    static let cardLarge: CGFloat = 22
    static let sheet: CGFloat = 24
    static let hero: CGFloat = 28
}
```

### 10.5 Elevation — sombras

Sistema de 4 niveles. Solo aplicar a superficies sobre `surfaceApp`. Glass NO lleva shadow propio (ya viene del material).

| Token | Specs | Uso |
|---|---|---|
| `shadow1` | y=1, blur=2, opacity=0.06 | Hairline, cards sobre surface plano |
| `shadow2` | y=2, blur=6, opacity=0.08 | Card estándar |
| `shadow3` | y=8, blur=24, opacity=0.10 | Sheet, popover |
| `shadow4` | y=16, blur=40, opacity=0.14 | Overlay máximo |

```swift
extension View {
    func fsShadow(_ level: Int) -> some View {
        switch level {
        case 1: return self.shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
        case 2: return self.shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        case 3: return self.shadow(color: .black.opacity(0.10), radius: 24, x: 0, y: 8)
        case 4: return self.shadow(color: .black.opacity(0.14), radius: 40, x: 0, y: 16)
        default: return self.shadow(color: .clear, radius: 0)
        }
    }
}
```

### 10.6 Componentes atómicos

#### Botones

4 variantes. Siempre con `Capsule()` (radius pill).

```swift
extension View {
    /// Botón primario: fondo verde leaf700 sólido, texto blanco.
    func fsButtonProminent() -> some View {
        self
            .font(.fsHeadline)
            .foregroundStyle(Palette.textOnLeaf)
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .background(Palette.leaf700, in: Capsule())
    }

    /// Botón glass: Liquid Glass capsule, texto primary.
    func fsButtonGlass() -> some View {
        self
            .font(.fsHeadline)
            .foregroundStyle(Palette.textPrimary)
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .glassed(in: .capsule)
    }

    /// Plain: solo texto verde, sin background.
    func fsButtonPlain() -> some View {
        self
            .font(.fsHeadline)
            .foregroundStyle(Palette.leaf700)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
    }

    /// Destructive: texto clay, sin background.
    func fsButtonDestructive() -> some View {
        self
            .font(.fsHeadline)
            .foregroundStyle(Palette.clay700)
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
    }
}
```

Estados: default · pressed (-4% L con scale 0.97) · disabled (40% opacity) · focused (ring 2pt accent).

#### Chips

```swift
extension View {
    /// Chip neutral con fondo tinted.
    func fsChip() -> some View {
        self
            .font(.fsCaption2)
            .foregroundStyle(Palette.textPrimary)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Palette.surfaceTinted, in: Capsule())
    }

    /// Chip glass para overlays sobre fotos/cámara.
    func fsChipGlass() -> some View {
        self
            .font(.fsCaption2)
            .foregroundStyle(Palette.textPrimary)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .glassed(in: .capsule)
    }

    /// Chip leaf — verde sólido para "Sano", "Mediterránea", etc.
    func fsChipLeaf() -> some View {
        self
            .font(.fsCaption2)
            .foregroundStyle(Palette.textOnLeaf)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Palette.leaf700, in: Capsule())
    }
}
```

#### Cards

```swift
struct FSCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(Spacing.s4)
            .background(Palette.Dynamic.surfaceCard,
                        in: .rect(cornerRadius: Radius.cardMedium))
            .fsShadow(1)
    }
}
```

#### HealthRing

Anillo semicircular animado. 3 tamaños: 28pt (en card de jardín), 48pt (componente standalone), 56pt (en plant detail con label numérico).

```swift
struct HealthRing: View {
    let value: Double          // 0.0...1.0
    let size: CGFloat
    let stroke: CGFloat
    let label: String?         // opcional ("92")

    init(value: Double, size: CGFloat = 32, stroke: CGFloat = 3, label: String? = nil) {
        self.value = value
        self.size = size
        self.stroke = stroke
        self.label = label
    }

    private var color: Color {
        switch value {
        case 0.7...1.0: return Palette.statusOk
        case 0.4..<0.7: return Palette.statusWarning
        default: return Palette.statusCritical
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.black.opacity(0.10), lineWidth: stroke)

            Circle()
                .trim(from: 0, to: value)
                .stroke(color, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 0.6), value: value)

            if let label, size >= 40 {
                Text(label)
                    .font(.system(size: size * 0.28, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Salud \(Int(value * 100)) por ciento, \(value > 0.7 ? "óptima" : value > 0.4 ? "atenta" : "crítica")")
    }
}
```

### 10.7 SF Symbols 7 — catálogo aprobado

> ⚠️ **Importante**: el sistema de diseño usa un **set propio de iconos line** dibujados a medida (no SF Symbols redrawn) en los mockups HTML. Sin embargo, para la implementación iOS usamos SF Symbols 7 nativos por simplicidad y consistencia con el sistema. El estilo visual es similar (line, stroke 1.6-1.7).

| Símbolo | Uso en FloraScan |
|---|---|
| `leaf` / `leaf.fill` | Plantas en general, salud OK, tab Mi jardín |
| `tree.fill` | Plantas grandes, árboles |
| `camera.aperture` | Tab Identificar (iOS 26 — más moderno que `camera.macro`) |
| `drop` / `drop.fill` | Riego |
| `scissors` | Poda |
| `sparkles` | Fertilizar (también `sparkles.rectangle.stack.fill`) |
| `square.and.arrow.up.on.square` | Trasplantar |
| `sun.max.fill` / `sun.dust.fill` | Niveles de luz |
| `humidity.fill` | Humedad |
| `thermometer.medium` | Temperatura |
| `bell.fill` | Recordatorios |
| `figure.gardening` | Onboarding contextual |
| `mappin.and.ellipse` | Ubicación de la planta |
| `square.and.arrow.up` | Compartir |
| `checkmark.circle.fill` | Tarea completada |
| `exclamationmark.triangle.fill` | Atención |
| `magnifyingglass` | Búsqueda |
| `bolt.fill` | Flash en cámara |
| `slider.horizontal.3` | Ajustes inline |
| `photo.on.rectangle` | Galería |
| `xmark` | Cerrar/dismissal |
| `chevron.left` / `chevron.right` / `chevron.down` | Navegación |
| `lock.shield.fill` | Onboarding privacidad |
| `gearshape.fill` | Settings |
| `pencil` | Editar |
| `trash` | Eliminar (con tinte clay700) |

**Animaciones con symbolEffect 7**:
- `.breathe` para plantas saludables (latido suave).
- `.wiggle` para plantas que necesitan agua.
- `.bounce` al completar tareas.
- `.variableColor.iterative` durante carga de identificación.
- `.replace.downUp` al cambiar `drop` → `drop.fill` tras regar.
- `.pulse` para indicador "vivo" del chip de identificación live.

### 10.8 Identidad de marca: wordmark y App Icon

#### Wordmark "FloraScan"

```swift
struct Wordmark: View {
    var size: CGFloat = 28          // tamaño base; auto-escala todo lo demás
    var color: Color = Palette.leaf700
    var accentColor: Color = Palette.amber700

    var body: some View {
        HStack(spacing: 0) {
            Text("Flora")
                .font(.system(size: size, weight: .bold, design: .default))
                .foregroundStyle(color)

            Text("Scan")
                .font(.custom("NewYorkItalic", size: size, relativeTo: .title))
                .fontWeight(.medium)
                .foregroundStyle(accentColor)
        }
        .tracking(-0.8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("FloraScan")
    }
}
```

**Reglas:**
- "Flora" siempre en SF Pro Display bold, color `leaf700`.
- "Scan" siempre en New York Italic medium, color `amber700`.
- Tracking -0.8pt.
- En contexto sobre fondo verde (Mesh hero, splash): usar versión invertida con `color: .white` y `accentColor: amber500`.
- En modo monocromo (favicon, watermark): un solo color `leaf700` con "Scan" manteniendo italic pero mismo color.

#### App Icon — concepto "F-Leaf con MeshGradient"

El icono ganador (Concepto C según exploración del sistema visual) es un híbrido orgánico:
- **Forma "F"** estilizada como tallo + 2 hojas horizontales que insinúan letra y planta a la vez.
- **Punto naranja** abajo a la derecha (representa obturador de cámara + fruto + accent de marca).
- **Fondo MeshGradient** verde botánico con difuminado amber.

Para implementar el icono en Xcode:

1. Generar 4 PNG variants 1024×1024 con la app diseñada (Light, Dark, Tinted, Clear).
2. Importar a `Assets.xcassets/AppIcon.appiconset` como Single Size con las 4 variantes iOS 26.
3. iOS 26 maneja el resto (escalas automáticas, masks, shadows).

**Variantes y especificaciones:**

| Variante | Fondo | Stem/Leaves | Aperture dot |
|---|---|---|---|
| Light | radial #5DA271 → #2F8262 → #0E5C3F + blob amber | `#F5F1E8` (cream) | `#E6A85C` |
| Dark | radial #2F8262 → #0E5C3F → #082E1F + blob amber | `#F5F1E8` (cream) | `#E6A85C` |
| Tinted | linear #C7DCC9 → #5DA271 (sin blobs amber) | `#082E1F` (dark) | `#0E5C3F` |
| Clear | rgba blanco con blur, sin fondo | `rgba(255,255,255,0.95)` | `rgba(255,255,255,0.9)` |

**SVG path del símbolo central (referencia):**
```
<svg viewBox="0 0 100 100">
  <!-- Stem vertical -->
  <path d="M 38 12 Q 38 50 38 88" stroke="cream" stroke-width="6" stroke-linecap="round" fill="none"/>
  <!-- Top horizontal leaf (F superior) -->
  <path d="M 38 22 Q 60 18 74 30 Q 70 36 60 36 Q 48 36 38 32 Z" fill="cream"/>
  <!-- Mid leaf (F del medio) -->
  <path d="M 38 50 Q 55 46 66 56 Q 62 62 54 62 Q 46 62 38 58 Z" fill="cream" opacity="0.85"/>
  <!-- Aperture dot -->
  <circle cx="74" cy="76" r="8" fill="#E6A85C"/>
  <circle cx="74" cy="76" r="3" fill="cream" opacity="0.4"/>
</svg>
```

---

## 11. Pantallas: especificación detallada

### 11.1 Onboarding (3 pantallas) — DISEÑO APROBADO

> ⚠️ El onboarding es la primera impresión y está validado contra el mockup de Claude Design. La especificación técnica completa con valores exactos está en SCREENS.md sección 1. Resumen aquí:

**Pantalla 1 — Hero "Tu jardín, en una cámara." (la pieza estrella)**
- Fondo: `LivingMeshBackground(palette: .onboardingHero)` — paleta diagonal verde→amber EXCLUSIVA de esta pantalla.
- Sin icono central. El gradiente es el protagonista.
- Wordmark "FLORASCAN" arriba a la izquierda (mono caps, opacity 0.7, tracking 2pt).
- Título alineado a la izquierda, 44pt bold, con la palabra "cámara" en New York Italic serif.
- Subtítulo de 3 líneas largas: "Identifica plantas al instante. Recuerda cuándo regarlas. Comparte tu jardín con quien quieras."
- DOS botones apilados al fondo: "Empezar" (blanco sólido pill, primario) + "Tengo cuenta" (glass pill, placeholder).
- 3 dots indicador entre botones y home indicator.

**Pantalla 2 — Privacidad "Todo en tu iPhone."**
- Fondo: `LivingMeshBackground(palette: .nature)` (más sobrio que la 1).
- Misma estructura compositiva: wordmark + título + subtítulo + bullets + botón único.
- Bullets: "▪ Identificación on-device  ▪ Sin servidores  ▪ Sin tracking".
- Un solo botón "Continuar" (blanco sólido).

**Pantalla 3 — "Acceso a la cámara."**
- Fondo: `LivingMeshBackground(palette: .nature)`.
- Misma estructura.
- Botón primario "Permitir cámara" → dispara `AVCaptureDevice.requestAccess(for: .video)`.
- Botón secundario "Más tarde" (glass) → entra a la app sin pedir permiso, se pedirá runtime al primer uso.
- Si rechazo de cámara: la pestaña Identificar mostrará `ContentUnavailableView` con CTA "Ir a Ajustes".

**Reglas no negociables del onboarding:**
1. Texto siempre alineado a la izquierda, nunca centrado.
2. Mucho aire vertical entre el bloque de texto superior y los botones inferiores.
3. La palabra clave de cada título va en New York Italic serif para contraste tipográfico.
4. El botón primario es BLANCO SÓLIDO, no glass. Glass se reserva para acciones secundarias.
5. El gradiente respira lentamente (período 8-12s, amplitud ±0.05). No hipnótico.
6. Validar contraste WCAG AA — el texto vive en el tercio superior donde el gradiente es oscuro.

### 11.2 Tab Bar principal

```swift
struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Mi jardín", systemImage: "leaf.fill") {
                GardenView()
            }
            Tab("Hoy", systemImage: "calendar") {
                TodayView()
            }
            Tab("Identificar", systemImage: "camera.macro") {
                IdentifyView()
            }
        }
    }
}
```

iOS 26 lo aplica automáticamente con Liquid Glass, no hay que añadir modificadores manuales.

### 11.3 GardenView (pestaña "Mi jardín")

**Layout:**
- `NavigationStack` con título "Mi jardín".
- Toolbar `.topBarTrailing`: botón `+` con `.glassed(in: .circle, interactive: true)`.
- Cuerpo: `ScrollView` con `LazyVGrid` 2 columnas.
- Cards con foto + nombre común + indicador de salud.
- Cuando vacío: `ContentUnavailableView("Tu jardín está vacío", systemImage: "leaf", description: Text("Toca + para añadir tu primera planta."))` con botón "Añadir planta".
- Search bar con `.searchable` por nombre.

**PlantCard:**
```swift
struct PlantCard: View {
    let plant: Plant

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if let photo = plant.photos.first(where: \.isPrimary),
                   let img = ImageStore.load(fileName: photo.fileName) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .clipShape(.rect(cornerRadius: 16))
                } else {
                    placeholder
                }

                HealthRing(score: plant.healthScore)
                    .frame(width: 28, height: 28)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(plant.nickname.isEmpty ? plant.commonName : plant.nickname)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(plant.scientificName)
                    .font(.scientificName)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
        }
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(Palette.primary.opacity(0.1))
            Image(systemName: "leaf.fill")
                .font(.largeTitle)
                .foregroundStyle(Palette.primary)
        }
        .frame(height: 160)
    }
}
```

**Hero animation al tap:**
```swift
@Namespace var ns
NavigationLink(value: plant) { PlantCard(plant: plant) }
    .matchedTransitionSource(id: plant.id, in: ns)

.navigationDestination(for: Plant.self) { plant in
    PlantDetailView(plant: plant)
        .navigationTransition(.zoom(sourceID: plant.id, in: ns))
}
```

### 11.4 TodayView (pestaña "Hoy")

**Layout (estilo Greg "Upcoming"):**
- `NavigationStack` con título "Hoy".
- Header (no glass): "Tienes 3 cuidados pendientes hoy" con contador animado (`.contentTransition(.numericText())`).
- Sections: "Hoy" / "Esta semana" / "Próximas".
- Cada `TaskRow`: foto thumbnail + nombre planta + tipo de tarea + botón ✅ "Hecho".
- Toggle en toolbar: lista vs calendario mensual.

**TaskRow:**
```swift
struct TaskRow: View {
    let task: CareTask
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let plant = task.plant,
               let photo = plant.photos.first,
               let img = ImageStore.load(fileName: photo.fileName) {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(.rect(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(task.plant?.nickname ?? "")
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    Image(systemName: task.type.symbolName)
                        .foregroundStyle(task.type.color)
                    Text(task.type.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onComplete) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Palette.healthOk)
                    .symbolEffect(.bounce, value: task.lastDoneAt)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
```

### 11.5 IdentifyView (pestaña "Identificar")

Esta es **la pantalla protagonista**. Cámara full-bleed, controles flotantes.

**Layout:**
- `ZStack`:
  - Layer 0: `CameraPreviewView(session:)` ocupando toda la pantalla.
  - Layer 1 superior: chip "Detectando…" con `.glassed(in: .capsule)` y `symbolEffect(.variableColor)`.
  - Layer 1 lateral derecho: chip "Olea europaea — 92%" con `.glassed` y `tint(.green.opacity(0.5))` cuando hay match.
  - Layer 2 inferior: selector hoja/flor/fruto/corteza con `GlassEffectContainer`.
  - Layer 3 inferior centro: `PulsingShutterButton`.

**Selector de órgano:**
```swift
struct OrganSelector: View {
    @Binding var selected: PlantOrgan
    @Namespace var ns

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(PlantOrgan.allCases, id: \.self) { organ in
                    Button {
                        withAnimation(.smooth) { selected = organ }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: organ.symbolName)
                            Text(organ.displayName).font(.caption2)
                        }
                        .padding(10)
                    }
                    .glassed(in: .rect(cornerRadius: 12),
                             tint: selected == organ ? Palette.primary.opacity(0.5) : nil,
                             interactive: true)
                    .glassEffectID(organ.rawValue, in: ns)
                }
            }
        }
    }
}

enum PlantOrgan: String, CaseIterable {
    case auto, leaf, flower, fruit, bark

    var displayName: String {
        switch self {
        case .auto: "Auto"
        case .leaf: "Hoja"
        case .flower: "Flor"
        case .fruit: "Fruto"
        case .bark: "Corteza"
        }
    }

    var symbolName: String {
        switch self {
        case .auto: "wand.and.stars"
        case .leaf: "leaf.fill"
        case .flower: "camera.macro"
        case .fruit: "apple.logo"
        case .bark: "tree.fill"
        }
    }
}
```

**Flujo de captura:**
1. Usuario toca shutter → vibración háptica `.impact(.medium)`.
2. Flash blanco breve (overlay con animación de opacidad 0→1→0 en 200ms).
3. Aparece overlay glass "Identificando…" con `MeshGradient` sutil de fondo.
4. En paralelo: API + modelo local.
5. Resultado: sheet `IdentificationResultSheet` que sube con `.transition(.move(edge: .bottom))`.

### 11.6 IdentificationResultSheet

**Layout:**
- Foto capturada arriba ocupando ~40% (clipShape rect 18).
- Card de resultado con `.glassedCard()`:
  - Nombre común grande.
  - Nombre científico debajo, en `.scientificName` italic.
  - Score como `ConfidenceBar` animada.
  - Texto descriptivo de Wikipedia (3-4 líneas, "Ver más" si más largo).
- Si hay top-3 alternativas: section "Otras posibilidades" con rows mini.
- Botón "Añadir a mi jardín" con `.buttonStyle(.glassProminent)`.
- Botón "Compartir" con `ShareLink`.

### 11.7 PlantDetailView

**Layout:**
- Hero: foto principal a `geometry.size.width * 1.0` aspect ratio 1:1, con scroll que la encoge (`scrollTargetBehavior(.viewAligned)`).
- Below: card de cuidados con `.glassedCard()`:
  - Próximo riego con countdown, símbolo `drop.fill` con `.wiggle` si vence pronto.
  - Próxima poda.
  - Próximo abono.
- Sección "Mi cuidado":
  - Botones acción: "Marqué como regada", "Marqué como podada", "Marqué como abonada".
  - Cada uno con `.symbolEffect(.bounce, value: trigger)`.
- Sección "Información":
  - Hábitat, época de floración, tóxica/no tóxica (Perenual data).
  - Texto largo de Wikipedia.
- Sección "Notas":
  - TextEditor (sin glass, fondo plano).
- Sección "Fotos":
  - Scroll horizontal de fotos históricas con thumbnails clickables → fullscreen.
- Toolbar:
  - "..." menu con: Editar, Mover de habitación, Eliminar, Compartir.

### 11.8 Add Plant Flow (modal full-screen)

Este flow se invoca desde el resultado de identificación O desde el FAB "+".

**Pasos (inspirado en Greg):**

1. **Identificación confirmada o búsqueda manual**
   - Si viene de cámara: ya tienes especie + foto.
   - Si viene de "+": pantalla con search bar para buscar por nombre + lista de candidatos.

2. **Foto principal**
   - "Esta foto la usaremos como portada. ¿OK?" Botones "Sí" / "Tomar otra".

3. **Apodo**
   - "¿Cómo la quieres llamar?" `TextField` con placeholder "Mi pothos del salón".

4. **Ubicación**
   - "¿Dónde está?" Lista de habitaciones existentes + opción "Nueva habitación".

5. **Luz que recibe**
   - "¿Cuánta luz le llega?" 4 cards visuales: poca / media / brillante indirecta / sol directo.
   - Cada card con SF Symbol y descripción ("Pocas horas de luz", etc.).

6. **Resumen y guardar**
   - Card grande con foto + datos.
   - Barra de progreso "100% completo" con `.contentTransition(.numericText())`.
   - Botón "Añadir a mi jardín" con confetti animation al guardar.

**Indicador de progreso global** en top: barra que rellena conforme avanza el flow (`@State private var progress: Double` que va de 0 a 1).

---

## 12. Notificaciones locales

### 12.1 Solicitar permiso

```swift
import UserNotifications

@MainActor
final class NotificationsManager {
    static let shared = NotificationsManager()

    func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional: return true
        case .denied: return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .ephemeral: return false
        @unknown default: return false
        }
    }
}
```

### 12.2 Categorías y acciones (registrar al arrancar app)

```swift
extension NotificationsManager {
    func registerCategories() {
        let watered = UNNotificationAction(
            identifier: "WATERED",
            title: "✅ Regada",
            options: []
        )
        let snooze = UNNotificationAction(
            identifier: "SNOOZE_1D",
            title: "⏰ Mañana",
            options: []
        )

        let wateringCategory = UNNotificationCategory(
            identifier: "WATERING_TASK",
            actions: [watered, snooze],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([wateringCategory])
    }
}
```

### 12.3 Programar recordatorio de cuidado

```swift
final class CareReminderScheduler {
    func schedule(task: CareTask) async throws {
        guard let plant = task.plant else { return }

        let content = UNMutableNotificationContent()
        content.title = title(for: task.type, plant: plant)
        content.body = body(for: task.type, plant: plant)
        content.sound = .default
        content.categoryIdentifier = "WATERING_TASK"
        content.userInfo = [
            "plantID": plant.id.uuidString,
            "taskID": task.id.uuidString
        ]

        var components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: task.nextDueAt
        )
        components.hour = 8
        components.minute = 30

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = task.notificationID ?? UUID().uuidString
        task.notificationID = identifier

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        try await UNUserNotificationCenter.current().add(request)
    }

    private func title(for type: CareType, plant: Plant) -> String {
        switch type {
        case .watering: "Tu \(plant.nickname.isEmpty ? plant.commonName : plant.nickname) pide agua 💧"
        case .pruning: "Hora de podar tu \(plant.nickname)"
        case .fertilizing: "Tu \(plant.nickname) necesita abono"
        case .repotting: "Tu \(plant.nickname) necesita maceta nueva"
        case .rotation: "Recuerda rotar tu \(plant.nickname)"
        }
    }

    private func body(for type: CareType, plant: Plant) -> String {
        switch type {
        case .watering: "Han pasado \(plant.wateringIntervalDays) días desde el último riego."
        default: "Toca para ver detalles."
        }
    }
}
```

### 12.4 Manejar acciones desde el delegate

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        guard let taskIDString = userInfo["taskID"] as? String,
              let taskID = UUID(uuidString: taskIDString) else { return }

        switch response.actionIdentifier {
        case "WATERED":
            // Marcar tarea como completada
            await TaskCompletionService.shared.complete(taskID: taskID)
        case "SNOOZE_1D":
            await TaskCompletionService.shared.snooze(taskID: taskID, days: 1)
        default:
            break
        }
    }
}
```

### 12.5 Reglas de UX

- **Nunca más de 1 notificación por día por planta.**
- **Hora fija 8:30**. No randomizar, los usuarios se acostumbran.
- **Si hay >3 tareas pendientes hoy**, agregar en una sola notificación: "Tu jardín necesita 3 cuidados hoy" → tap abre TodayView.
- **Sin recordatorios duplicados**. Antes de programar, cancelar cualquier `notificationID` previo.

---

## 13. APIs externas: cliente y caché

### 13.1 Perenual (cuidados)

```swift
actor PerenualClient {
    private let apiKey: String
    private let session = URLSession.shared
    private let base = URL(string: "https://perenual.com/api/v2")!

    init(apiKey: String) { self.apiKey = apiKey }

    func searchSpecies(query: String) async throws -> [PerenualSpecies] {
        var components = URLComponents(url: base.appendingPathComponent("species-list"),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "q", value: query)
        ]
        let (data, _) = try await session.data(from: components.url!)
        let response = try JSONDecoder().decode(PerenualSearchResponse.self, from: data)
        return response.data
    }

    func careDetails(speciesID: Int) async throws -> PerenualCareProfile {
        let url = base.appendingPathComponent("species/details/\(speciesID)")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        let (data, _) = try await session.data(from: components.url!)
        return try JSONDecoder().decode(PerenualCareProfile.self, from: data)
    }
}

struct PerenualCareProfile: Decodable {
    let watering: String?              // "Frequent" / "Average" / "Minimum"
    let sunlight: [String]?
    let pruningCount: PruningCount?
    let pruningMonth: [String]?
    let propagation: [String]?
    let hardiness: Hardiness?
    let cycle: String?

    struct PruningCount: Decodable {
        let amount: Int?
        let interval: String?
    }
    struct Hardiness: Decodable {
        let min: String?
        let max: String?
    }
}
```

### 13.2 Wikipedia (descripciones)

```swift
actor WikipediaClient {
    func summary(scientificName: String) async throws -> String? {
        let title = scientificName.replacingOccurrences(of: " ", with: "_")
        let url = URL(string: "https://es.wikipedia.org/api/rest_v1/page/summary/\(title)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else { return nil }
        struct Summary: Decodable { let extract: String? }
        let decoded = try JSONDecoder().decode(Summary.self, from: data)
        return decoded.extract
    }
}
```

### 13.3 Caché en SwiftData

Cualquier respuesta enriquecida (Perenual, Wikipedia) se persiste en la entidad `Plant` directamente (campos nuevos) y se considera válida durante 30 días. Antes de pegarse a la red, comprobar `lastEnrichedAt`.

---

## 14. Compartir el jardín

### 14.1 Estrategia: Transferable + UTType custom

```swift
// Resources/Info.plist (declarado como exported type)
// UTI: io.jlcl11.florascan.garden
// Conforms to: public.data
// Description: FloraScan Garden Export

import CoreTransferable
import UniformTypeIdentifiers

extension UTType {
    static let florascanGarden = UTType(exportedAs: "io.jlcl11.florascan.garden")
}

struct GardenExport: Codable, Transferable {
    let plants: [PlantExport]
    let exportedAt: Date
    let appVersion: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .florascanGarden)
        ProxyRepresentation(exporting: \.snapshotImage)
    }

    var snapshotImage: Image {
        // Generado con ImageRenderer al solicitar
        Image(systemName: "leaf.fill")  // placeholder
    }
}

struct PlantExport: Codable {
    let nickname: String
    let scientificName: String
    let commonName: String
    let acquisitionDate: Date
    let locationLabel: String
    let photosBase64: [String]
}
```

### 14.2 ShareLink en toolbar

```swift
struct ShareGardenButton: View {
    let plants: [Plant]

    var body: some View {
        ShareLink(
            item: GardenExport(plants: plants.map(PlantExport.init), exportedAt: .now, appVersion: "1.0"),
            preview: SharePreview("Mi jardín FloraScan",
                                  image: snapshot)
        ) {
            Label("Compartir", systemImage: "square.and.arrow.up")
        }
    }

    private var snapshot: Image {
        // ImageRenderer del grid de "Mi jardín"
        let view = GardenSnapshotView(plants: plants)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return Image(uiImage: renderer.uiImage ?? UIImage())
    }
}
```

### 14.3 Recibir un archivo `.florascan`

```swift
.onOpenURL { url in
    guard url.pathExtension == "florascan" else { return }
    Task { await GardenImporter.shared.importFile(url: url) }
}
```

---

## 15. Privacy & permisos (Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>FloraScan necesita la cámara para identificar tus plantas. Las fotos no salen del dispositivo.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>FloraScan guarda fotos de tus plantas en el carrete (opcional).</string>
```

NO pedir:
- Ubicación.
- Photos read access.
- Notificaciones (se piden runtime cuando aplica).
- Bluetooth, micrófono, etc.

---

## 16. Convenciones de código

### 16.1 Nomenclatura

- **Tipos**: `PascalCase`. Ej: `PlantClassifier`, `IdentifyViewModel`.
- **Métodos y propiedades**: `camelCase`. Ej: `identifyPlant()`, `isLoading`.
- **Vistas**: terminan en `View`. Ej: `GardenView`, `PlantDetailView`.
- **ViewModels**: `@Observable @MainActor`, terminan en `ViewModel`.
- **Servicios reutilizables**: terminan en `Service`, `Manager`, `Client` o `Scheduler`.

### 16.2 SwiftUI

- Property wrappers en orden: `@Environment` → `@Query` → `@State` → `@StateObject` (legacy) → `@Bindable` → resto.
- Una `View` por archivo cuando supera 80 líneas.
- Subvistas privadas dentro del mismo archivo si solo se usan localmente: `private struct HealthRing: View {...}`.

### 16.3 Concurrencia Swift 6

- Strict concurrency activado. Sin warnings de Sendable.
- ViewModels: `@MainActor @Observable final class`.
- Servicios con estado mutable: `actor`.
- Servicios stateless: `struct` o función libre.
- AVCaptureSession requiere wrapping cuidadoso (`@unchecked Sendable` con cola serial propia, o un actor wrapper). Ver `CameraSession` en sección 7.

### 16.4 Errores

- Cada subsistema define su propio enum `Error` con `LocalizedError`.
- Mensajes user-facing en español, traducibles vía `String(localized:)`.

### 16.5 Tests

- Swift Testing (`import Testing`, `@Test`, `#expect`).
- Cada feature con su carpeta de tests.
- Mocking por protocolos cuando sea necesario aislar servicios.
- Foco: lógica de dominio (CareScheduler, IdentifyViewModel state machine, parser de respuestas API). NO testear vistas SwiftUI directamente.

---

## 17. Performance y batería

### 17.1 Reglas

- **Cámara solo activa en IdentifyView**. Al salir de la pestaña, `cameraSession.stop()`.
- **Throttling 5 FPS** en clasificación. No procesar todos los frames.
- **Modelo Core ML** carga lazy la primera vez, luego se mantiene en memoria mientras la app vive.
- **Imágenes en disco**: comprimir a JPEG 0.85 antes de guardar. Resize a 1024x1024 max.
- **Listas grandes**: `LazyVGrid` y `LazyVStack` siempre.
- **MeshGradient** solo en pantallas hero (onboarding, identify, share). NO de fondo en GardenView.

### 17.2 Memoria

- `URLSession.shared` reusada (no crear nuevas).
- ImageCache simple LRU para thumbnails (máx 50 imágenes en RAM).
- Liberar `CIImage` y `CGImage` con `autoreleasepool` en hot paths.

---

## 18. Plan de implementación por sprints

### Sprint 1 (semana 1) — Fundamentos

**Día 1-2**
- Crear proyecto Xcode 26, configurar Swift 6 strict, target iOS 26.
- Schema SwiftData (`Plant`, `PlantPhoto`, `CareTask`).
- `Theme.swift` con paleta y tipografía.
- Estructura de carpetas Features/Core.
- `RootTabView` con tab bar Liquid Glass.

**Día 3-4**
- `CameraSession` con AVCaptureSession.
- `CameraPreviewView` UIViewRepresentable.
- `FrameThrottler`.
- `IdentifyView` mínima con preview y shutter button.
- `PulsingShutterButton` con phaseAnimator.

**Día 5**
- `PlantNetClient` con multipart.
- `IdentifyViewModel` con state machine completa.
- Sheet de resultados básico.

**Día 6-7**
- Integrar Core ML local (Oxford 102 Flowers como arranque).
- `PlantClassifier` actor.
- Race API + local con `chooseBestGuess`.
- Tests de `IdentifyViewModel`.

### Sprint 2 (semana 2) — Inventario y cuidados

**Día 8-9**
- `GardenView` con `LazyVGrid` y `PlantCard`.
- `HealthRing` componente.
- `matchedTransitionSource` + `navigationTransition(.zoom)`.
- `PlantDetailView` con foto hero.

**Día 10-11**
- Add Plant Flow completo (6 pasos).
- `LivingMeshBackground` para onboarding.
- Captura keyframeAnimator del thumbnail volando.
- Guardar foto en `Documents/Plants/`.

**Día 12-13**
- `CareScheduler` con cálculo estacional.
- `TodayView` con secciones Hoy/Semana/Próximas.
- `TaskRow` con botón completar.
- `NotificationsManager` + `CareReminderScheduler`.

**Día 14**
- Configurar categorías de notificaciones con custom actions.
- Manejo de acciones desde delegate.
- Test manual del flujo completo notificación → acción → estado actualizado.

### Sprint 3 (semana 3) — Datos, share, polish

**Día 15-16**
- `PerenualClient` y `WikipediaClient`.
- Enriquecimiento del `PlantDetailView` con datos externos.
- Cache 30 días en `Plant`.
- Manejo de errores y rate limits.

**Día 17-18**
- `GardenExport` Transferable.
- UTType custom registrado.
- `ShareLink` en toolbar.
- `ImageRenderer` para snapshot del jardín.
- `onOpenURL` para importar archivo `.florascan`.

**Día 19**
- Onboarding 3 pantallas con MeshGradient.
- Permission flow para cámara.
- Empty states con `ContentUnavailableView`.

**Día 20-21**
- QA visual: verificar Liquid Glass en device prestado o screenshots Apple.
- Accessibility: VoiceOver, Dynamic Type, Reduce Transparency.
- Bug fixes.
- README del repo con GIFs.

---

## 19. Anti-patrones específicos a evitar

1. ❌ Cargar el modelo Core ML desde disco en cada clasificación (lento, lazy una vez).
2. ❌ Hacer `try? await` y silenciar errores en networking sin notificar al usuario.
3. ❌ Usar `Color(.systemGray)` en lugar de `Palette` (perdemos consistencia).
4. ❌ Aplicar `.glassEffect()` a un `TextEditor` o a una `List` (rompe legibilidad).
5. ❌ Programar 10 notificaciones diferentes para 10 tareas del mismo día (agregar).
6. ❌ Guardar imágenes como `Data` en SwiftData (saturar la BD).
7. ❌ Usar `Combine` en código nuevo (estamos en async/await).
8. ❌ `DispatchQueue.main.async {}` en código SwiftUI moderno (usar `@MainActor`).
9. ❌ Singleton para cualquier cosa que no sea genuinamente global (NotificationsManager sí, IdentifyViewModel no).
10. ❌ Probar Liquid Glass solo en simulador y dar por bueno el resultado visual.

---

## 20. Recursos de referencia

### Documentación oficial Apple
- [Liquid Glass — Applying to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
- [Core ML Tools — PyTorch Conversion](https://apple.github.io/coremltools/docs-guides/source/convert-pytorch-workflow.html)
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [SwiftData](https://developer.apple.com/documentation/swiftdata)
- [UserNotifications](https://developer.apple.com/documentation/usernotifications)

### Modelos y datasets
- [PlantNet-300K (NeurIPS 2021)](https://github.com/plantnet/PlantNet-300K)
- [PlantCLEF 2024 weights](https://zenodo.org/records/10848263)
- [Oxford 102 Flowers Core ML demo](https://github.com/gaelfoppolo/CoreML-Flowers)
- [Awesome Core ML Models](https://github.com/likedan/Awesome-CoreML-Models)

### APIs externas
- [Pl@ntNet API docs](https://my.plantnet.org/doc/api/identify) — registrar para api-key gratuita.
- [Perenual API pricing](https://www.perenual.com/subscription-api-pricing) — registrar tier gratuito.
- [Wikipedia REST API](https://en.wikipedia.org/api/rest_v1/) — sin clave.

### Diseño
- [Greg](https://greg.app/) — referencia maestra de UX en gestores de plantas.
- [SF Symbols 7](https://developer.apple.com/sf-symbols/) — descargar app oficial.
- [iOS 26 Design Resources](https://developer.apple.com/design/resources/) — Sketch/Figma kits.
- [LiquidGlassReference cheat-sheet](https://github.com/conorluddy/LiquidGlassReference)

---

## 21. Checklist antes de cada commit

- [ ] El código compila sin warnings de Swift 6 strict concurrency.
- [ ] No hay `print()` ni `// TODO` sin issue asociada.
- [ ] Las cadenas user-facing están en `Localizable.xcstrings`.
- [ ] Las imágenes nuevas están en `Assets.xcassets` con `@1x @2x @3x` cuando aplique.
- [ ] He añadido tests para nueva lógica de dominio.
- [ ] He probado el flujo completo en el simulador.
- [ ] Si toqué UI con Liquid Glass, lo he validado visualmente con referencia Apple.
- [ ] Si toqué cámara/ML, he probado en device físico cuando ha sido posible.

---

**Última actualización:** 27 abril 2026
**Mantenedor:** José Luis Corral López ([@jlcl11](https://github.com/jlcl11))
