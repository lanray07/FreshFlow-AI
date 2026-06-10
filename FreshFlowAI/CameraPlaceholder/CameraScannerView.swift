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
                Text("\(source.rawValue) scan review")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Prepare a focused food check, then review suggested items, freshness estimates, and storage notes before saving.")
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
                    Label("Editable review", systemImage: "checklist")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)

                Button(action: scanAction) {
                    Label("Start Food Review", systemImage: "viewfinder.circle.fill")
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
        .accessibilityLabel("Food scan review")
    }
}
