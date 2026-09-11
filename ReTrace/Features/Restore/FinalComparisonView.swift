import PhotosUI
import SwiftUI

struct FinalComparisonView: View {
    let project: RTProject

    @Environment(\.dismiss) private var dismiss
    @State private var finalImageData: Data?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var isShowingCamera = false

    private var originalImagePath: String? {
        project.orderedSteps.first(where: { $0.stepType == .reference })?.imagePath
            ?? project.orderedSteps.first?.imagePath
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: RTSpacing.lg) {
                    VStack(alignment: .leading, spacing: RTSpacing.xs) {
                        Text("Original").font(RTTypography.cardTitle)
                        RTStoredImage(path: originalImagePath) {
                            placeholder
                        }
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: RTRadius.card, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: RTSpacing.xs) {
                        Text("Current").font(RTTypography.cardTitle)
                        if let finalImageData, let uiImage = UIImage(data: finalImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: RTRadius.card, style: .continuous))
                        } else {
                            placeholder.frame(height: 220)
                        }

                        HStack(spacing: RTSpacing.sm) {
                            Button(String(localized: "Take Photo")) {
                                if LaunchEnvironment.useMockCamera || !CameraAvailability.isAvailable {
                                    finalImageData = MockCameraProvider.placeholderImageData()
                                } else {
                                    isShowingCamera = true
                                }
                            }
                            .buttonStyle(.rtSecondary)

                            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                                Text("Choose Photo")
                            }
                            .buttonStyle(.rtSecondary)
                            .onChange(of: photosPickerItem) { _, newValue in
                                guard let newValue else { return }
                                Task {
                                    finalImageData = try? await newValue.loadTransferable(type: Data.self)
                                    photosPickerItem = nil
                                }
                            }
                        }
                    }
                }
                .padding(RTSpacing.md)
            }
            .background(RTColors.background)
            .navigationTitle("Final Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraCaptureView(
                    onCapture: { data in
                        finalImageData = data
                        isShowingCamera = false
                    },
                    onCancel: { isShowingCamera = false }
                )
                .ignoresSafeArea()
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: RTRadius.card, style: .continuous)
            .fill(RTColors.surfaceSecondary)
            .overlay {
                Image(systemName: "photo").font(.system(size: 28)).foregroundStyle(RTColors.textTertiary)
            }
    }
}
