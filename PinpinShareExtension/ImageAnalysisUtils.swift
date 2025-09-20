import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO
import CoreML

// MARK: - Vision (classification + instance segmentation)
struct VisionClassifier {
    static func classify(_ uiImage: UIImage, maxLabels: Int = 8) -> [(label: String, confidence: Float)] {
        guard let ciImage = CIImage(image: uiImage) else { return [] }
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        let request = VNClassifyImageRequest()
        
        do {
            try handler.perform([request])
            let results = request.results ?? []
            return Array(results.prefix(maxLabels)).map { ($0.identifier, $0.confidence) }
        } catch {
            return []
        }
    }
}

// MARK: - Foreground Instance Segmentation
struct ForegroundInstanceSegmentation {
    struct DetectedInstance {
        let confidence: Float
        let boundingBox: CGRect
        let maskArea: Float
        let instanceMask: CVPixelBuffer?
    }
    
    static func detectForegroundInstances(in uiImage: UIImage) -> [DetectedInstance] {
        guard let ciImage = CIImage(image: uiImage) else { return [] }
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        // Utiliser VNGenerateForegroundInstanceMaskRequest pour la segmentation d'instances
        let request = VNGenerateForegroundInstanceMaskRequest()
        
        do {
            try handler.perform([request])
            guard let result = request.results?.first else { return [] }
            
            var detectedInstances: [DetectedInstance] = []
            
            // Parcourir toutes les instances détectées (allInstances est un IndexSet)
            for instanceIndex in result.allInstances {
                // Générer le masque pour cette instance
                let maskedImage = try result.generateMaskedImage(
                    ofInstances: IndexSet([instanceIndex]),
                    from: handler,
                    croppedToInstancesExtent: false
                )
                
                // Calculer l'aire du masque
                let maskArea = calculateMaskArea(maskedImage)
                
                // Pour l'instant, utiliser des valeurs par défaut car IndexSet ne contient que des indices
                let detectedInstance = DetectedInstance(
                    confidence: 0.8, // Valeur par défaut, l'API ne fournit pas de confidence par instance
                    boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1), // Bounding box par défaut
                    maskArea: maskArea,
                    instanceMask: maskedImage
                )
                detectedInstances.append(detectedInstance)
            }
            
            // Trier par aire du masque (plus grand = plus important)
            return detectedInstances.sorted { $0.maskArea > $1.maskArea }
            
        } catch {
            print("Foreground instance segmentation failed: \(error)")
            return []
        }
    }
    
    private static func calculateMaskArea(_ pixelBuffer: CVPixelBuffer) -> Float {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return 0 }
        
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        var maskPixels = 0
        let totalPixels = width * height
        
        // Compter les pixels non-transparents (alpha > 0)
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * bytesPerRow + x * 4 + 3 // Canal alpha
                if buffer[pixelIndex] > 0 {
                    maskPixels += 1
                }
            }
        }
        
        return Float(maskPixels) / Float(totalPixels)
    }
}


// MARK: - Colors (dominant + small palette)
struct ColorAnalyzer {
    static func averageColor(of uiImage: UIImage) -> UIColor? {
        guard let input = CIImage(image: uiImage) else { return nil }
        let filter = CIFilter.areaAverage()
        filter.inputImage = input
        filter.extent = input.extent
        let context = CIContext() // default context for broad compatibility
        guard let out = filter.outputImage else { return nil }
        var pixel = [UInt8](repeating: 0, count: 4)
        context.render(
            out,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        return UIColor(
            red: CGFloat(pixel[0]) / 255.0,
            green: CGFloat(pixel[1]) / 255.0,
            blue: CGFloat(pixel[2]) / 255.0,
            alpha: 1.0
        )
    }

    static func quickPalette(of uiImage: UIImage, binsPerChannel: Int = 8, topK: Int = 3) -> [UIColor] {
        guard let down = uiImage.downscaled(maxSide: 96),
              let cg = down.cgImage else { return [] }
        let width = cg.width, height = cg.height
        guard let data = cg.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return [] }

        let bytesPerPixel = 4
        var histogram: [Int: Int] = [:]

        @inline(__always) func binIndex(_ r: UInt8, _ g: UInt8, _ b: UInt8) -> Int {
            let q = 256 / binsPerChannel
            let br = min(Int(r) / q, binsPerChannel - 1)
            let bg = min(Int(g) / q, binsPerChannel - 1)
            let bb = min(Int(b) / q, binsPerChannel - 1)
            return (br * binsPerChannel + bg) * binsPerChannel + bb
        }

        for y in 0..<height {
            let row = y * cg.bytesPerRow
            for x in 0..<width {
                let i = row + x * bytesPerPixel
                let r = ptr[i]
                let g = ptr[i+1]
                let b = ptr[i+2]
                let idx = binIndex(r, g, b)
                histogram[idx, default: 0] += 1
            }
        }

        let top = histogram.sorted { $0.value > $1.value }.prefix(topK).map { $0.key }

        func colorFor(bin: Int) -> UIColor {
            let q = 256 / binsPerChannel
            let bb = bin % binsPerChannel
            let tmp = bin / binsPerChannel
            let bg = tmp % binsPerChannel
            let br = tmp / binsPerChannel
            let r = CGFloat(br * q + q/2) / 255.0
            let g = CGFloat(bg * q + q/2) / 255.0
            let b = CGFloat(bb * q + q/2) / 255.0
            return UIColor(red: r, green: g, blue: b, alpha: 1)
        }

        return top.map(colorFor)
    }
    
    // Couleur dominante basée sur un masque d'instance précis
    static func averageColorFromInstanceMask(image: UIImage, mask: CVPixelBuffer) -> UIColor? {
        guard let cgImage = image.cgImage else { return nil }
        
        // Redimensionner l'image pour matcher le masque si nécessaire
        let maskWidth = CVPixelBufferGetWidth(mask)
        let maskHeight = CVPixelBufferGetHeight(mask)
        let imageWidth = cgImage.width
        let imageHeight = cgImage.height
        
        // Obtenir les données de l'image
        guard let imageData = cgImage.dataProvider?.data,
              let imagePtr = CFDataGetBytePtr(imageData) else { return nil }
        
        // Verrouiller le masque
        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }
        
        guard let maskBaseAddress = CVPixelBufferGetBaseAddress(mask) else { return nil }
        let maskBuffer = maskBaseAddress.assumingMemoryBound(to: UInt8.self)
        let maskBytesPerRow = CVPixelBufferGetBytesPerRow(mask)
        
        var totalR: Int = 0, totalG: Int = 0, totalB: Int = 0, count: Int = 0
        
        // Parcourir le masque et accumuler les couleurs correspondantes
        for y in 0..<maskHeight {
            for x in 0..<maskWidth {
                // Index pour le canal alpha du masque (RGBA)
                let maskIndex = y * maskBytesPerRow + x * 4 + 3
                
                // Si ce pixel fait partie du masque (alpha > 0)
                if maskBuffer[maskIndex] > 0 {
                    // Convertir les coordonnées du masque vers l'image originale
                    let imageX = Int(Float(x) * Float(imageWidth) / Float(maskWidth))
                    let imageY = Int(Float(y) * Float(imageHeight) / Float(maskHeight))
                    
                    // Vérifier les limites
                    if imageX < imageWidth && imageY < imageHeight {
                        let imageIndex = (imageY * cgImage.bytesPerRow) + (imageX * 4)
                        
                        if imageIndex + 2 < CFDataGetLength(imageData) {
                            totalR += Int(imagePtr[imageIndex])
                            totalG += Int(imagePtr[imageIndex + 1])
                            totalB += Int(imagePtr[imageIndex + 2])
                            count += 1
                        }
                    }
                }
            }
        }
        
        guard count > 0 else { return nil }
        
        let avgR = CGFloat(totalR) / CGFloat(count) / 255.0
        let avgG = CGFloat(totalG) / CGFloat(count) / 255.0
        let avgB = CGFloat(totalB) / CGFloat(count) / 255.0
        
        return UIColor(red: avgR, green: avgG, blue: avgB, alpha: 1.0)
    }
    
}


// Orientation mapping to ensure Vision gets the correct orientation
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

// MARK: - Helpers
extension UIColor {
    var hexRGB: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r*255), Int(g*255), Int(b*255))
    }

    var hsb: (h: CGFloat, s: CGFloat, b: CGFloat)? {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return nil }
        return (h, s, b)
    }

    var basicColorName: String {
        // Simple, human-friendly color names based on HSB
        guard let hsb = self.hsb else { return "unknown" }
        let h = hsb.h * 360.0
        let s = hsb.s
        let b = hsb.b
        if b < 0.12 { return "black" }
        if b > 0.92 && s < 0.12 { return "white" }
        if s < 0.15 { return "gray" }
        switch h {
        case ..<10, 350...: return "red"        // Rouge pur : 0-10° et 350-360°
        case 10..<40: return "orange"           // Orange : 10-40°
        case 40..<65: return "yellow"           // Jaune : 40-65°
        case 65..<170: return "green"           // Vert : 65-170°
        case 170..<255: return "blue"           // Bleu : 170-255°
        case 255..<350: return "purple"         // Violet : 255-350°
        default: return "unknown"
        }
    }

    // Couleurs ultra-simplifiées (KISS maximal)
    var colorNameEN: String {
        guard let hsb = self.hsb else { return "unknown" }
        let b = hsb.b
        let s = hsb.s
        
        // Grayscale simple
        if b < 0.15 { return "black" }
        if b > 0.85 && s < 0.15 { return "white" }
        if s < 0.15 { return "gray" }
        
        // Couleurs de base uniquement
        return basicColorName
    }

    var colorNameFR: String {
        switch colorNameEN {
        case "black": return "noir"
        case "white": return "blanc"
        case "gray": return "gris"
        case "red": return "rouge"
        case "orange": return "orange"
        case "yellow": return "jaune"
        case "green": return "vert"
        case "blue": return "bleu"
        case "purple": return "violet"
        default: return "inconnu"
        }
    }
}

extension UIImage {
    func downscaled(maxSide: CGFloat) -> UIImage? {
        let maxDim = max(size.width, size.height)
        guard maxDim > maxSide else { return self }
        let scale = maxSide / maxDim
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: fmt).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // Crop using a normalized rect (0..1) in image coordinates, origin at top-left
    func cropNormalized(_ rect: CGRect) -> UIImage? {
        let cropSize = CGSize(width: size.width * rect.width, height: size.height * rect.height)
        let drawOrigin = CGPoint(x: -size.width * rect.origin.x, y: -size.height * rect.origin.y)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1
        return UIGraphicsImageRenderer(size: cropSize, format: fmt).image { _ in
            self.draw(at: drawOrigin)
        }
    }
}

// MARK: - OCR (short)
private func recognizeText(in uiImage: UIImage, maxChars: Int = 160) -> String {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    
    let handler: VNImageRequestHandler
    let orientation = CGImagePropertyOrientation(uiImage.imageOrientation)
    if let cg = uiImage.cgImage {
        handler = VNImageRequestHandler(cgImage: cg, orientation: orientation, options: [:])
    } else if let ci = CIImage(image: uiImage) {
        handler = VNImageRequestHandler(ciImage: ci, orientation: orientation, options: [:])
    } else { return "" }
    
    do {
        try handler.perform([request])
        let observations = request.results ?? []
        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
        if lines.isEmpty { return "" }
        let joined = lines.joined(separator: " ")
        return String(joined.prefix(maxChars))
    } catch {
        return ""
    }
}

// MARK: - Public API
func analyzeImage(_ image: UIImage) -> [String: String] {
    var meta: [String: String] = [:]

    // Vision classification (native iOS) - amélioré
    let labels = VisionClassifier.classify(image, maxLabels: 8)
    if !labels.isEmpty {
        let namesOnly = labels.map { $0.label }.joined(separator: ",")
        meta["detected_labels"] = namesOnly
        meta["detected_labels_source"] = "vision_enhanced"
        
        // Ajouter les scores de confiance pour debug/qualité
        let confidences = labels.map { String(format: "%.2f", $0.confidence) }.joined(separator: ",")
        meta["detected_confidences"] = confidences
        
        // Label le plus confiant
        if let best = labels.first {
            meta["best_label"] = best.label
            meta["best_confidence"] = String(format: "%.3f", best.confidence)
        }
    }

    // OCR (short, on-device)
    let fast = image.downscaled(maxSide: 1024) ?? image
    let ocr = recognizeText(in: fast, maxChars: 160)
    if !ocr.isEmpty {
        meta["ocr_text"] = ocr
    }

    return meta
}

// MARK: - Intelligent main-subject analysis (foreground instance segmentation)
func analyzeMainSubject(_ image: UIImage) -> [String: String] {
    var meta: [String: String] = [:]
    
    // Essayer d'abord l'instance segmentation avec VNGenerateForegroundInstanceMaskRequest
    let detectedInstances = ForegroundInstanceSegmentation.detectForegroundInstances(in: image)
    
    if let mainInstance = detectedInstances.first {
        // L'instance principale est celle avec la plus grande aire de masque
        meta["main_object_detection_method"] = "foreground_instance_segmentation"
        meta["main_object_confidence"] = String(format: "%.3f", mainInstance.confidence)
        meta["main_object_area"] = String(format: "%.3f", mainInstance.maskArea)
        
        // Obtenir le label via classification de la région de l'objet
        let bbox = mainInstance.boundingBox
        let normalizedRect = CGRect(
            x: bbox.origin.x,
            y: 1.0 - bbox.origin.y - bbox.height, // Vision utilise un système de coordonnées inversé
            width: bbox.width,
            height: bbox.height
        )
        
        if let objectImage = image.cropNormalized(normalizedRect) {
            let objectLabels = VisionClassifier.classify(objectImage, maxLabels: 3)
            if let first = objectLabels.first {
                meta["main_object_label"] = first.label
                meta["main_object_label_confidence"] = String(format: "%.3f", first.confidence)
                
                // Labels alternatifs
                if objectLabels.count > 1 {
                    let alternatives = objectLabels.dropFirst().map { $0.label }.joined(separator: ",")
                    meta["main_object_alternatives"] = alternatives
                }
            }
        }
        
        // Couleur dominante basée sur le masque précis de l'instance
        if let instanceMask = mainInstance.instanceMask,
           let dominantColor = ColorAnalyzer.averageColorFromInstanceMask(image: image, mask: instanceMask) {
            meta["main_object_color_name"] = dominantColor.colorNameEN
            meta["main_object_color_name_fr"] = dominantColor.colorNameFR
            meta["main_object_color_hex"] = dominantColor.hexRGB
        }
        
    } else {
        // Fallback vers l'ancienne méthode si l'instance segmentation échoue
        meta["main_object_detection_method"] = "center_crop_fallback"
        
        let centerROI = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
        let roiImage = image.cropNormalized(centerROI) ?? image
        
        let mainLabels = VisionClassifier.classify(roiImage, maxLabels: 3)
        if let first = mainLabels.first {
            meta["main_object_label"] = first.label
            meta["main_object_confidence"] = String(format: "%.3f", first.confidence)
            
            if mainLabels.count > 1 {
                let alternatives = mainLabels.dropFirst().map { $0.label }.joined(separator: ",")
                meta["main_object_alternatives"] = alternatives
            }
        }
        
        if let avg = ColorAnalyzer.averageColor(of: roiImage) {
            meta["main_object_color_name"] = avg.colorNameEN
            meta["main_object_color_name_fr"] = avg.colorNameFR
        }
    }
    
    return meta
}
