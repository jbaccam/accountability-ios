import SwiftUI
import PhotosUI
import CoreLocation

/// A button that presents the photo library and returns the picked image as
/// JPEG `Data`. Wraps PhotosPicker so screens don't repeat the plumbing.
struct PhotoPickerButton<Label: View>: View {
    var onPick: (Data) -> Void
    @ViewBuilder var label: () -> Label

    @State private var item: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $item, matching: .images, photoLibrary: .shared()) {
            label()
        }
        .onChange(of: item) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let jpeg = ImageJPEG.encode(data) {
                    await MainActor.run { onPick(jpeg) }
                }
            }
        }
    }
}

enum ImageJPEG {
    /// Re-encode arbitrary image data to JPEG, downscaling large images.
    static func encode(_ data: Data, maxDimension: CGFloat = 1600, quality: CGFloat = 0.8) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scaled = downscale(image, maxDimension: maxDimension)
        return scaled.jpegData(compressionQuality: quality)
    }

    private static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

/// One-shot current location (replaces expo-location). Returns nil if denied/unavailable.
@MainActor
final class LocationFetcher: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<(lat: Double, lng: Double)?, Never>?

    func current() async -> (lat: Double, lng: Double)? {
        manager.delegate = self
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted { return nil }
        if status == .notDetermined { manager.requestWhenInUseAuthorization() }
        return await withCheckedContinuation { cont in
            self.continuation = cont
            manager.requestLocation()
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {
        let coord = locations.first?.coordinate
        let value = coord.map { (lat: $0.latitude, lng: $0.longitude) }
        Task { @MainActor in self.finish(value) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish(nil) }
    }

    private func finish(_ value: (lat: Double, lng: Double)?) {
        continuation?.resume(returning: value)
        continuation = nil
    }
}
