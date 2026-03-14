//
//  ContentView.swift
//  test
//
//  Created by Claude on 2026/3/14.
//

import SwiftUI
import UIKit

@objc public class ContentViewWrapper: NSObject {
    @MainActor
    @objc public static func createHostingController() -> UIViewController {
        return UIHostingController(rootView: ContentView())
    }
}

struct ContentView: View {
    @State private var originalImage: UIImage?
    @State private var segmentedImage: UIImage?
    @State private var detectedObjects: [DetectedObject] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var showSourceSelection = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                contentView
                Spacer()
                actionButton
            }
            .navigationTitle("Vision Camera")
            .confirmationDialog("Choose Source", isPresented: $showSourceSelection) {
                Button("Camera") { sourceType = .camera; showImagePicker = true }
                Button("Photo Library") { sourceType = .photoLibrary; showImagePicker = true }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: sourceType, selectedImage: $originalImage)
                    .onDisappear {
                        if originalImage != nil { processImage() }
                    }
            }
        }
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
                Text("Detected Objects").font(.headline).padding(.horizontal)
                ForEach(detectedObjects) { object in
                    ObjectRow(object: object) {
                        Task { @MainActor in selectObject(object) }
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
        Button(action: { showSourceSelection = true }) {
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
        let processor = VisionProcessor()
        Task {
            do {
                let objects = try await processor.detectObjects(in: image)
                self.detectedObjects = objects
                self.isProcessing = false
                if let firstObject = objects.first { selectObject(firstObject) }
            } catch {
                self.errorMessage = "Detection failed: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }

    @MainActor
    private func selectObject(_ object: DetectedObject) {
        guard let image = originalImage else { return }
        isProcessing = true
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
                Image(systemName: "chevron.right").foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
