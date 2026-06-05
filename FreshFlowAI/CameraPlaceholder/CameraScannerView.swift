import SwiftUI

struct CameraScannerView: View {
    var source: StorageLocation
    var scanAction: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(
                    colors: [FreshFlowTheme.charcoal, FreshFlowTheme.deepSage, FreshFlowTheme.sage],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            VStack(spacing: 16) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Camera preview placeholder")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Wire AVCaptureSession and Vision/Core ML food recognition here for \(source.rawValue.lowercased()) scans.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.76))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 12) {
                HStack {
                    Label(source.rawValue, systemImage: source == .pantry ? "cabinet.fill" : "refrigerator.fill")
                    Spacer()
                    Label("Mock AI", systemImage: "sparkles")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)

                Button(action: scanAction) {
                    Label("Run Mock Scan", systemImage: "viewfinder.circle.fill")
                        .font(.headline)
                        .foregroundStyle(FreshFlowTheme.charcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(16)
        }
        .frame(height: 360)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Camera scanner placeholder")
    }
}
