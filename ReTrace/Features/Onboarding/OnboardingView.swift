import SwiftUI

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let symbolName: String
    let title: String
    let body: String
}

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        symbolName: "camera.viewfinder",
        title: String(localized: "Take It Apart Without Losing Track"),
        body: String(localized: "Capture each step as you remove or disconnect something.")
    ),
    OnboardingPage(
        symbolName: "shippingbox",
        title: String(localized: "Keep Parts Organized"),
        body: String(localized: "Save screws, cables, brackets, and where you put them.")
    ),
    OnboardingPage(
        symbolName: "arrow.uturn.backward",
        title: String(localized: "Restore in Reverse"),
        body: String(localized: "ReTrace automatically turns your captured sequence into a restoration guide.")
    ),
]

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var pageIndex = 0

    var body: some View {
        VStack(spacing: RTSpacing.lg) {
            TabView(selection: $pageIndex) {
                ForEach(Array(onboardingPages.enumerated()), id: \.element.id) { index, page in
                    VStack(spacing: RTSpacing.lg) {
                        Spacer()
                        Image(systemName: page.symbolName)
                            .font(.system(size: 64))
                            .foregroundStyle(RTColors.accent)
                        Text(page.title)
                            .font(RTTypography.largeTitle)
                            .multilineTextAlignment(.center)
                        Text(page.body)
                            .font(RTTypography.body)
                            .foregroundStyle(RTColors.textSecondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(.horizontal, RTSpacing.xl)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if pageIndex < onboardingPages.count - 1 {
                    pageIndex += 1
                } else {
                    onFinish()
                }
            } label: {
                Text(pageIndex < onboardingPages.count - 1 ? String(localized: "Next") : String(localized: "Get Started"))
            }
            .buttonStyle(.rtPrimary)
            .padding(.horizontal, RTSpacing.xl)
            .accessibilityIdentifier("onboarding.continueButton")
        }
        .padding(.bottom, RTSpacing.xl)
        .background(RTColors.background)
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
