import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Vision (classification)
struct VisionClassifier {
    static func classify(_ uiImage: UIImage, maxLabels: Int = 3) -> [(label: String, confidence: Float)] {
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
        case ..<15, 345...: return "red"
        case 15..<35: return "orange"
        case 35..<50: return "yellow"
        case 50..<170: return "green"
        case 170..<200: return "cyan"
        case 200..<255: return "blue"
        case 255..<290: return "purple"
        case 290..<320: return "magenta"
        case 320..<345: return "pink"
        default: return "unknown"
        }
    }

    // Extended, bilingual names (simple heuristics, KISS)
    var colorNameEN: String {
        guard let hsb = self.hsb else { return "unknown" }
        let h = hsb.h * 360.0
        let s = hsb.s
        let b = hsb.b
        // Grayscale
        if b < 0.12 { return "black" }
        if b > 0.92 && s < 0.12 { return "white" }
        if s < 0.12 {
            if b > 0.85 { return "silver" }
            return "gray"
        }
        // Warm special cases
        if (15..<45).contains(h) && b < 0.55 { return "brown" }
        if (30..<60).contains(h) && s < 0.35 && b > 0.75 { return "beige" }
        if (45..<60).contains(h) && s > 0.5 && (0.6..<0.9).contains(b) { return "gold" }
        if (0..<15).contains(h) && b < 0.35 && s > 0.4 { return "maroon" }
        // Cool special cases
        if (200..<255).contains(h) && b < 0.35 && s > 0.35 { return "navy" }
        if (170..<200).contains(h) && s > 0.4 { return "teal" }
        if (60..<90).contains(h) && (0.25..<0.5).contains(s) && (0.3..<0.65).contains(b) { return "olive" }
        if (85..<105).contains(h) && s > 0.5 && b > 0.7 { return "lime" }
        // Fallback to basic buckets
        return basicColorName
    }

    var colorNameFR: String {
        switch colorNameEN {
        case "black": return "noir"
        case "white": return "blanc"
        case "gray": return "gris"
        case "silver": return "argent"
        case "red": return "rouge"
        case "maroon": return "bordeaux"
        case "orange": return "orange"
        case "yellow": return "jaune"
        case "gold": return "or"
        case "green": return "vert"
        case "lime": return "vert clair"
        case "olive": return "olive"
        case "teal": return "sarcelle"
        case "cyan": return "cyan"
        case "blue": return "bleu"
        case "navy": return "bleu marine"
        case "purple": return "violet"
        case "magenta": return "magenta"
        case "pink": return "rose"
        case "brown": return "marron"
        case "beige": return "beige"
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
    request.recognitionLevel = .fast
    request.usesLanguageCorrection = false
    
    let handler: VNImageRequestHandler
    if let cg = uiImage.cgImage {
        handler = VNImageRequestHandler(cgImage: cg, options: [:])
    } else if let ci = CIImage(image: uiImage) {
        handler = VNImageRequestHandler(ciImage: ci, options: [:])
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

    // Vision classification
    let labels = VisionClassifier.classify(image, maxLabels: 3)
    if !labels.isEmpty {
        let namesOnly = labels.map { $0.label }.joined(separator: ",")
        meta["detected_labels"] = namesOnly
    }

    // OCR (short, on-device)
    let fast = image.downscaled(maxSide: 1024) ?? image
    let ocr = recognizeText(in: fast, maxChars: 160)
    if !ocr.isEmpty {
        meta["ocr_text"] = ocr
    }

    return meta
}

// MARK: - Simple main-subject analysis (center crop)
func analyzeMainSubject(_ image: UIImage) -> [String: String] {
    var meta: [String: String] = [:]
    // Use a central ROI as a proxy for the main subject (simple and fast)
    let centerROI = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
    let roiImage = image.cropNormalized(centerROI) ?? image

    // Primary label from ROI
    if let first = VisionClassifier.classify(roiImage, maxLabels: 1).first {
        meta["main_object_label"] = first.label
    }

    // Dominant color name from ROI
    if let avg = ColorAnalyzer.averageColor(of: roiImage) {
        meta["main_object_color_name"] = avg.colorNameEN
        meta["main_object_color_name_fr"] = avg.colorNameFR
    }

    return meta
}
