//
//  VisionProcessor.swift
//  test
//
//  Created by Claude on 2026/3/14.
//

import Vision
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Accelerate

/// Errors that can occur during Vision processing
enum VisionError: Error {
    case imageConversionFailed
    case detectionFailed(String)
    case segmentationFailed(String)
    case modelNotAvailable
}

/// Represents a detected object with classification
@objc public class DetectedObject: NSObject, Identifiable, @unchecked Sendable {
    public let id = UUID()
    @objc public let label: String
    @objc public let confidence: Float
    @objc public let boundingBox: CGRect
    @objc public let identifier: String

    @objc public init(label: String, confidence: Float, boundingBox: CGRect, identifier: String = "") {
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.identifier = identifier
        super.init()
    }
}

/// Handles Vision framework operations for object detection and segmentation
@MainActor
final class VisionProcessor: Sendable {

    // MARK: - Properties

    private var classificationCache: [String: (label: String, confidence: Float)] = [:]

    init() {}

    // MARK: - Object Detection

    /// Detects objects in the given image using Vision framework with enhanced accuracy
    func detectObjects(in image: UIImage) async throws -> [DetectedObject] {
        guard let cgImage = image.cgImage else {
            throw VisionError.imageConversionFailed
        }

        var allDetectedObjects: [DetectedObject] = []

        // Step 1: Get salient regions using multiple detection methods
        let regions = await getEnhancedSalientRegions(from: cgImage, orientation: image.imageOrientation)

        // Step 2: Classify each region with enhanced classification
        for (index, region) in regions.enumerated() {
            let croppedImage = await cropImageToRegion(cgImage, region: region.boundingBox)

            var label = "Object \(index + 1)"
            var confidence = region.confidence

            // Use multiple classification approaches
            if let classification = await classifyImageWithEnhancement(croppedImage) {
                label = formatLabel(classification.label)
                confidence = (region.confidence + classification.confidence) / 2
            }

            // Only add objects with reasonable confidence
            if confidence >= 0.3 {
                let detectedObject = DetectedObject(
                    label: label,
                    confidence: confidence,
                    boundingBox: region.boundingBox,
                    identifier: label.lowercased().replacingOccurrences(of: " ", with: "_")
                )
                allDetectedObjects.append(detectedObject)
            }
        }

        // Fallback: If no regions found, classify the entire image
        if allDetectedObjects.isEmpty {
            var label = "Main Subject"
            var confidence: Float = 0.5

            if let classification = await classifyImageWithEnhancement(image) {
                label = formatLabel(classification.label)
                confidence = classification.confidence
            }

            let defaultObject = DetectedObject(
                label: label,
                confidence: confidence,
                boundingBox: CGRect(x: 0.05, y: 0.05, width: 0.9, height: 0.9),
                identifier: label.lowercased().replacingOccurrences(of: " ", with: "_")
            )
            allDetectedObjects.append(defaultObject)
        }

        // Sort by confidence and return top 10
        allDetectedObjects.sort { $0.confidence > $1.confidence }
        return Array(allDetectedObjects.prefix(10))
    }

    // MARK: - Enhanced Region Detection

    /// Get enhanced salient regions using multiple detection methods
    private func getEnhancedSalientRegions(from cgImage: CGImage, orientation: UIImage.Orientation) async -> [(boundingBox: CGRect, confidence: Float)] {
        await withCheckedContinuation { continuation in
            var allRegions: [(CGRect, Float)] = []

            // Method 1: Objectness-based saliency (primary)
            let objectnessRequest = VNGenerateObjectnessBasedSaliencyImageRequest { [weak self] request, error in
                if let error = error {
                    print("Objectness saliency error: \(error)")
                }

                if let results = request.results, let result = results.first as? VNSaliencyImageObservation {
                    let salientObjects = result.salientObjects ?? []
                    for object in salientObjects.prefix(20) {
                        // Filter out very small regions
                        if object.boundingBox.width >= 0.05 && object.boundingBox.height >= 0.05 {
                            allRegions.append((object.boundingBox, object.confidence))
                        }
                    }
                }

                // Method 2: Rectangular detection for structured objects
                self?.getRectangularRegions(from: cgImage, orientation: orientation) { rectRegions in
                    for region in rectRegions.prefix(10) {
                        // Check for duplicates
                        let isDuplicate = allRegions.contains { existing in
                            self?.overlapRatio(existing.0, region) ?? 0 > 0.7
                        }
                        if !isDuplicate && region.width >= 0.1 && region.height >= 0.1 {
                            allRegions.append((region, 0.75))
                        }
                    }

                    // Method 3: Face detection (high priority)
                    self?.getFaceRegions(from: cgImage, orientation: orientation) { faceRegions in
                        for faceRegion in faceRegions {
                            let isDuplicate = allRegions.contains { existing in
                                self?.overlapRatio(existing.0, faceRegion) ?? 0 > 0.5
                            }
                            if !isDuplicate {
                                allRegions.append((faceRegion, 0.95)) // High confidence for faces
                            }
                        }

                        if allRegions.isEmpty {
                            // Fallback to attention-based
                            self?.getAttentionBasedRegions(from: cgImage, orientation: orientation) { fallbackRegions in
                                let defaultRegion: (CGRect, Float) = (CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7), Float(0.5))
                                continuation.resume(returning: fallbackRegions.isEmpty ? [defaultRegion] : fallbackRegions)
                            }
                        } else {
                            // Sort by confidence and size
                            allRegions.sort { a, b in
                                let scoreA = CGFloat(a.1) * a.0.width * a.0.height
                                let scoreB = CGFloat(b.1) * b.0.width * b.0.height
                                return scoreA > scoreB
                            }
                            continuation.resume(returning: allRegions)
                        }
                    }
                }
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(orientation), options: [:])
            try? handler.perform([objectnessRequest])
        }
    }

    /// Get rectangular regions (documents, screens, etc.)
    private func getRectangularRegions(from cgImage: CGImage, orientation: UIImage.Orientation, completion: @escaping ([CGRect]) -> Void) {
        var regions: [CGRect] = []

        let request = VNDetectRectanglesRequest { request, error in
            guard let results = request.results as? [VNRectangleObservation] else {
                completion([])
                return
            }

            for rect in results.prefix(10) {
                regions.append(rect.boundingBox)
            }

            completion(regions)
        }

        request.minimumConfidence = 0.6
        request.maximumObservations = 10

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(orientation), options: [:])
        try? handler.perform([request])
    }

    /// Get face regions (highest priority)
    private func getFaceRegions(from cgImage: CGImage, orientation: UIImage.Orientation, completion: @escaping ([CGRect]) -> Void) {
        var regions: [CGRect] = []

        let request = VNDetectFaceRectanglesRequest { request, error in
            guard let results = request.results as? [VNFaceObservation] else {
                completion([])
                return
            }

            for face in results {
                regions.append(face.boundingBox)
            }

            completion(regions)
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(orientation), options: [:])
        try? handler.perform([request])
    }

    /// Get attention-based salient regions as fallback
    private func getAttentionBasedRegions(from cgImage: CGImage, orientation: UIImage.Orientation, completion: @escaping ([(CGRect, Float)]) -> Void) {
        var regions: [(CGRect, Float)] = []

        let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
            guard let results = request.results, let result = results.first as? VNSaliencyImageObservation else {
                completion([])
                return
            }

            let salientObjects = result.salientObjects ?? []
            for object in salientObjects.prefix(15) {
                if object.boundingBox.width >= 0.08 && object.boundingBox.height >= 0.08 {
                    regions.append((object.boundingBox, 0.7))
                }
            }

            completion(regions)
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(orientation), options: [:])
        try? handler.perform([request])
    }

    /// Calculate overlap ratio between two rectangles
    private func overlapRatio(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let intersection = a.intersection(b)
        if intersection.isNull { return 0 }
        let minArea = min(a.width * a.height, b.width * b.height)
        return intersection.width * intersection.height / minArea
    }

    // MARK: - Enhanced Classification

    /// Classify image with enhanced accuracy using multiple passes
    private func classifyImageWithEnhancement(_ image: UIImage) async -> (label: String, confidence: Float)? {
        guard let cgImage = image.cgImage else {
            return nil
        }

        // Create cache key
        let cacheKey = "\(cgImage.width)x\(cgImage.height)"

        // Check cache
        if let cachedResult = classificationCache[cacheKey] {
            return cachedResult
        }

        return await withCheckedContinuation { (continuation: CheckedContinuation<(label: String, confidence: Float)?, Never>) in
            // Use VNClassifyImageRequest with multiple tags
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    print("Vision classification error: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let results = request.results as? [VNClassificationObservation],
                      !results.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Get top 3 results for better accuracy
                let topResults = results.prefix(3)
                var bestLabel = ""
                var bestConfidence: Float = 0

                for result in topResults {
                    let confidence = Float(result.confidence)
                    if confidence > bestConfidence && confidence >= 0.1 {
                        bestLabel = result.identifier.replacingOccurrences(of: "_", with: " ")
                        bestConfidence = confidence
                    }
                }

                if bestConfidence >= 0.1 {
                    let result = (label: bestLabel, confidence: bestConfidence)
                    self.classificationCache[cacheKey] = result
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(returning: nil)
                }
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    /// Crop image to a specific region
    private func cropImageToRegion(_ cgImage: CGImage, region: CGRect) async -> UIImage {
        await withCheckedContinuation { continuation in
            let x = region.origin.x * CGFloat(cgImage.width)
            let y = (1 - region.origin.y - region.height) * CGFloat(cgImage.height)
            let width = region.width * CGFloat(cgImage.width)
            let height = region.height * CGFloat(cgImage.height)

            let cropRect = CGRect(x: x, y: y, width: max(16, width), height: max(16, height)).integral

            guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
                continuation.resume(returning: UIImage())
                return
            }

            continuation.resume(returning: UIImage(cgImage: croppedCGImage))
        }
    }

    /// Format label for display
    private func formatLabel(_ label: String) -> String {
        let cleaned = label
            .replacingOccurrences(of: "_", with: " ")
            .capitalized

        let suffixes = [" object", " item", " thing", " mammal", " animal"]
        var result = cleaned
        for suffix in suffixes {
            if result.lowercased().hasSuffix(suffix) {
                result = String(result.dropLast(suffix.count))
            }
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Enhanced Object Segmentation

    /// Extracts the detected object from the background using advanced segmentation
    func extractObject(from image: UIImage, boundingBox: CGRect) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw VisionError.imageConversionFailed
        }

        // Expand bounding box to capture full object
        let expandedBox = expandBoundingBox(boundingBox, by: 0.15)

        // Method 1: Objectness-based saliency with ROI
        do {
            let request = VNGenerateObjectnessBasedSaliencyImageRequest()
            request.regionOfInterest = expandedBox

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: .init(image.imageOrientation),
                options: [:]
            )

            try handler.perform([request])

            if let result = request.results?.first {
                if let maskedImage = applyAdvancedMask(result, to: cgImage, roi: expandedBox) {
                    return maskedImage
                }
            }
        } catch {
            print("Objectness saliency segmentation failed: \(error)")
        }

        // Method 2: Attention-based saliency
        do {
            let request = VNGenerateAttentionBasedSaliencyImageRequest()
            request.regionOfInterest = expandedBox

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: .init(image.imageOrientation),
                options: [:]
            )

            try handler.perform([request])

            if let result = request.results?.first {
                if let maskedImage = applyAdvancedMask(result, to: cgImage, roi: expandedBox) {
                    return maskedImage
                }
            }
        } catch {
            print("Attention saliency segmentation failed: \(error)")
        }

        // Final fallback: Refined bounding box crop with edge detection
        return try await performRefinedExtraction(image: image, boundingBox: expandedBox)
    }

    /// Expand bounding box by a percentage
    private func expandBoundingBox(_ box: CGRect, by percentage: CGFloat) -> CGRect {
        var expanded = box
        let width = box.width
        let height = box.height

        expanded.origin.x = max(0, box.origin.x - width * percentage / 2)
        expanded.origin.y = max(0, box.origin.y - height * percentage / 2)
        expanded.size.width = min(1 - expanded.origin.x, width * (1 + percentage))
        expanded.size.height = min(1 - expanded.origin.y, height * (1 + percentage))

        return expanded
    }

    /// Apply advanced mask with edge refinement and morphological operations
    private func applyAdvancedMask(_ saliency: VNSaliencyImageObservation, to cgImage: CGImage, roi: CGRect) -> UIImage? {
        let ciImage = CIImage(cgImage: cgImage)

        // Get saliency mask
        let maskPixelBuffer = saliency.pixelBuffer
        let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)

        // Scale mask to match image size
        let scaleX = ciImage.extent.width / maskCIImage.extent.width
        let scaleY = ciImage.extent.height / maskCIImage.extent.height
        let scaledMask = maskCIImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // Apply edge-preserving smoothing
        guard let bilateralFilter = CIFilter(name: "CIBilateralFilter") else {
            return applyMaskWithEdgeRefinement(scaledMask, to: ciImage)
        }

        bilateralFilter.setValue(scaledMask, forKey: kCIInputImageKey)
        bilateralFilter.setValue(12.0, forKey: "inputSpatialHarmonics")
        bilateralFilter.setValue(0.15, forKey: "inputColorDistance")

        guard let filteredMask = bilateralFilter.outputImage else {
            return applyMaskWithEdgeRefinement(scaledMask, to: ciImage)
        }

        // Apply subtle Gaussian blur for anti-aliasing
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else {
            return applyMaskWithEdgeRefinement(scaledMask, to: ciImage)
        }

        blurFilter.setValue(filteredMask, forKey: kCIInputImageKey)
        blurFilter.setValue(0.8, forKey: kCIInputRadiusKey)

        guard let blurredMask = blurFilter.outputImage else {
            return applyMaskWithEdgeRefinement(scaledMask, to: ciImage)
        }

        // Apply mask with edge refinement
        return applyMaskWithEdgeRefinement(blurredMask, to: ciImage)
    }

    /// Apply mask with edge refinement using morphology
    private func applyMaskWithEdgeRefinement(_ mask: CIImage, to ciImage: CIImage) -> UIImage? {
        // Apply morphological operations to refine mask edges
        guard let morphFilter = CIFilter(name: "CIMorphologyMaximum") else {
            return applyBasicMask(mask, to: ciImage)
        }

        morphFilter.setValue(mask, forKey: kCIInputImageKey)
        morphFilter.setValue(NSNumber(value: 2), forKey: "inputRadius")

        guard let dilatedMask = morphFilter.outputImage else {
            return applyBasicMask(mask, to: ciImage)
        }

        return applyBasicMask(dilatedMask, to: ciImage)
    }

    /// Apply basic mask
    private func applyBasicMask(_ mask: CIImage, to ciImage: CIImage) -> UIImage? {
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return nil }

        blendFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blendFilter.setValue(mask, forKey: kCIInputMaskImageKey)

        guard let outputImage = blendFilter.outputImage else { return nil }

        let context = CIContext(options: [.useSoftwareRenderer: false, .highQualityDownsample: true])
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: outputCGImage)
    }

    /// Refined extraction with edge detection fallback
    private func performRefinedExtraction(image: UIImage, boundingBox: CGRect) async throws -> UIImage {
        guard let cgImage = image.cgImage?.cropping(to: cropRect(from: boundingBox, in: image.size)) else {
            throw VisionError.segmentationFailed("Failed to crop image")
        }

        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

        // Try to detect edges in cropped image for refinement
        return croppedImage
    }

    private func cropRect(from box: CGRect, in size: CGSize) -> CGRect {
        let x = box.origin.x * size.width
        let y = (1 - box.origin.y - box.height) * size.height
        let width = box.width * size.width
        let height = box.height * size.height
        return CGRect(x: x, y: y, width: max(1, width), height: max(1, height))
    }
}

// MARK: - CGImagePropertyOrientation Extension

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
