import SwiftUI
import UIKit

/// Wraps `UIImagePickerController` for the system camera. The simulator has
/// no camera, and automated UI tests can't drive the system camera UI across
/// processes anyway, so callers should check `CameraAvailability.isAvailable`
/// and fall back to `MockCameraProvider` first.
struct CameraCaptureView: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (Data) -> Void
        let onCancel: () -> Void

        init(onCapture: @escaping (Data) -> Void, onCancel: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.9) {
                onCapture(data)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}

enum CameraAvailability {
    static var isAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
}

/// Deterministic stand-in for the camera, used in the simulator and whenever
/// `-useMockCamera` is passed so UI tests never depend on real hardware.
enum MockCameraProvider {
    static func placeholderImageData() -> Data {
        let size = CGSize(width: 640, height: 480)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            RTMockCameraPalette.background.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 120, weight: .regular)
            if let symbol = UIImage(systemName: "camera.viewfinder", withConfiguration: symbolConfig) {
                let tinted = symbol.withTintColor(RTMockCameraPalette.symbol, renderingMode: .alwaysOriginal)
                let symbolSize = tinted.size
                let origin = CGPoint(x: (size.width - symbolSize.width) / 2, y: (size.height - symbolSize.height) / 2)
                tinted.draw(at: origin)
            }
        }
        return image.jpegData(compressionQuality: 0.9) ?? Data()
    }
}

private enum RTMockCameraPalette {
    static let background = UIColor(red: 0.90, green: 0.90, blue: 0.91, alpha: 1)
    static let symbol = UIColor(red: 0.35, green: 0.37, blue: 0.40, alpha: 1)
}
