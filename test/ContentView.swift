//
//  ContentView.swift
//  test
//
//  Created by Claude on 2026/3/14.
//

import SwiftUI
import UIKit
import Photos

@objc public class ContentViewWrapper: NSObject {
    @MainActor
    @objc public static func createHostingController(onDismiss: (() -> Void)?) -> UIViewController {
        return UIHostingController(rootView: ContentView(onDismiss: onDismiss))
    }
}

struct ContentView: View {
    @State private var originalImage: UIImage?
    @State private var segmentedImage: UIImage?
    @State private var detectedObjects: [DetectedObject] = []
    @State private var selectedObject: DetectedObject?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showCameraPicker = false
    @State private var showPhotoLibraryPicker = false
    @State private var showSaveConfirmation = false

    let onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            toolbarView

            // Main content
            VStack(spacing: 20) {
                contentView
                Spacer()
                actionButton
            }
            .padding(.top)
        }
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(sourceType: .camera, selectedImage: $originalImage)
        }
        .sheet(isPresented: $showPhotoLibraryPicker) {
            ImagePicker(sourceType: .photoLibrary, selectedImage: $originalImage)
        }
        .onChange(of: originalImage) { _ in
            processImage()
        }
    }

    private var toolbarView: some View {
        HStack {
            Button(action: { onDismiss?() }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Close")
                }
                .font(.system(size: 16))
            }
            .foregroundColor(.red)

            Spacer()

            if segmentedImage != nil {
                Button(action: { saveToPhotoLibrary() }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save")
                    }
                    .font(.system(size: 16))
                }
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }

    @ViewBuilder
    private var contentView: some View {
        if let originalImage = originalImage {
            ScrollView {
                VStack(spacing: 16) {
                    ImageSection(title: "Original Image", image: originalImage)
                    processingIndicator
                    detectedObjectsList
                    segmentedResult
                    errorMessageView
                }
                .padding(.vertical)
            }
        } else {
            placeholderView
        }
    }

    @ViewBuilder
    private var processingIndicator: some View {
        if isProcessing {
            HStack {
                ProgressView()
                Text("Processing with Vision...").foregroundColor(.secondary)
            }
            .padding()
        }
    }

    @ViewBuilder
    private var detectedObjectsList: some View {
        if !detectedObjects.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Detected Objects (Top 10)").font(.headline).padding(.horizontal)
                ForEach(detectedObjects) { object in
                    ObjectRow(object: object, isSelected: selectedObject?.id == object.id) {
                        Task {
                            await MainActor.run {
                                self.selectObject(object)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var segmentedResult: some View {
        if let segmentedImage = segmentedImage {
            ImageSection(title: "Extracted Object", image: segmentedImage)
        }
    }

    @ViewBuilder
    private var errorMessageView: some View {
        if let errorMessage = errorMessage {
            Text(errorMessage).foregroundColor(.red).multilineTextAlignment(.center).padding()
        }
    }

    private var placeholderView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill").font(.system(size: 80)).foregroundColor(.gray)
            Text("Take a photo to detect and extract objects")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxHeight: .infinity)
    }

    private var actionButton: some View {
        Menu {
            Button(action: {
                showCameraPicker = true
            }) {
                Label("Camera", systemImage: "camera")
            }
            Button(action: {
                showPhotoLibraryPicker = true
            }) {
                Label("Photo Library", systemImage: "photo.on.rectangle")
            }
        } label: {
            HStack {
                Image(systemName: "camera.fill")
                Text(originalImage == nil ? "Take Photo" : "New Photo")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }

    @MainActor
    private func processImage() {
        guard let image = originalImage else { return }
        isProcessing = true
        errorMessage = nil
        detectedObjects = []
        segmentedImage = nil
        selectedObject = nil
        let processor = VisionProcessor()
        Task {
            do {
                var objects = try await processor.detectObjects(in: image)
                // Sort by confidence and take top 10
                objects.sort { $0.confidence > $1.confidence }
                self.detectedObjects = Array(objects.prefix(10))
                self.isProcessing = false
                if let firstObject = detectedObjects.first { selectObject(firstObject) }
            } catch {
                self.errorMessage = "Detection failed: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }

    @MainActor
    private func selectObject(_ object: DetectedObject) {
        guard let image = originalImage else { return }
        selectedObject = object
        isProcessing = true
        errorMessage = nil
        segmentedImage = nil
        let processor = VisionProcessor()
        Task {
            do {
                let segmented = try await processor.extractObject(from: image, boundingBox: object.boundingBox)
                self.segmentedImage = segmented
                self.isProcessing = false
            } catch {
                self.errorMessage = "Segmentation failed: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }

    private func saveToPhotoLibrary() {
        guard let image = segmentedImage else { return }

        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            showSaveConfirmation = true
                        } else {
                            errorMessage = "Save failed: \(error?.localizedDescription ?? "Unknown error")"
                        }
                    }
                }
            } else {
                errorMessage = "Photo library access denied"
            }
        }
    }
}

struct ImageSection: View {
    let title: String
    let image: UIImage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).padding(.horizontal)
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .cornerRadius(12)
                .padding(.horizontal)
        }
    }
}

struct ObjectRow: View {
    let object: DetectedObject
    let isSelected: Bool
    let action: @Sendable () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(object.label).font(.subheadline).fontWeight(.semibold)
                    Text("Confidence: \(Int(object.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                } else {
                    Image(systemName: "chevron.right").foregroundColor(.gray)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(onDismiss: nil)
    }
}
