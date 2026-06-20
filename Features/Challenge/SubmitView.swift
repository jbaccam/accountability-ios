import SwiftUI

/// Submit a check-in proof. Port of challenge/[id]/submit.tsx. Pick a photo,
/// optionally add a caption + location, then post it. Photo is required.
struct SubmitView: View {
    @Environment(\.theme) private var theme
    @Environment(SessionStore.self) private var session
    @Environment(Nav.self) private var nav

    let challengeId: String

    @State private var challenge: Challenge?
    @State private var currentPeriod: CheckinPeriod?
    @State private var now = Date()

    @State private var photoData: Data?
    @State private var caption = ""
    @State private var attachLocation = false
    @State private var location: (lat: Double, lng: Double)?
    @State private var locationStatus: String?
    @State private var isFetchingLocation = false

    @State private var isSubmitting = false
    @State private var toast: String?

    private let locationFetcher = LocationFetcher()

    private var requiresCaption: Bool { challenge?.proofRequiresCaption ?? false }
    private var requiresLocation: Bool { challenge?.proofRequiresLocation ?? false }
    private var wantsLocation: Bool { requiresLocation || attachLocation }
    private var missingLocation: Bool { requiresLocation && location == nil }

    private var canSubmit: Bool {
        photoData != nil
            && !(requiresCaption && caption.trimmingCharacters(in: .whitespaces).isEmpty)
            && !missingLocation
    }

    var body: some View {
        Screen(title: "Submit proof") {
            if let period = currentPeriod {
                Card(tone: .flat) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Deadline").textStyle(.label, color: theme.colors.textFaint)
                        Text(Format.countdown(deadline: period.submissionDeadline, now: now))
                            .textStyle(.title, color: theme.colors.accent)
                    }
                }
            }

            photoCard

            AppTextField(
                label: requiresCaption ? "Caption (required)" : "Caption (optional)",
                text: $caption,
                placeholder: "What are we looking at?"
            )

            locationSection

            AppButton(
                "Submit proof",
                icon: "checkmark",
                isLoading: isSubmitting,
                isDisabled: isSubmitting || !canSubmit,
                action: submit
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toast($toast)
        .task { await loadChallenge() }
    }

    // MARK: - Photo

    @ViewBuilder
    private var photoCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.two) {
                if let data = photoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(4.0 / 3.0, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    PhotoPickerButton(onPick: { photoData = $0 }) {
                        pickerLabel("Choose a different photo", icon: "photo.on.rectangle", variant: .secondary)
                    }
                } else {
                    Text("Photo proof is required. The submission time is recorded automatically.")
                        .textStyle(.small, color: theme.colors.textDim)
                    PhotoPickerButton(onPick: { photoData = $0 }) {
                        pickerLabel("Add photo", icon: "camera", variant: .primary)
                    }
                }
            }
        }
    }

    /// PhotoPickerButton wraps its label in a PhotosPicker, so we render a
    /// button-shaped label rather than a real AppButton (which has its own tap).
    private func pickerLabel(_ title: String, icon: String, variant: ButtonVariant) -> some View {
        let fg = variant == .primary ? theme.colors.onAccent : theme.colors.text
        let bg = variant == .primary ? theme.colors.accent : theme.colors.surfaceHigh
        return HStack(spacing: Spacing.two) {
            Image(systemName: icon)
            Text(title)
        }
        .textStyle(.bodyStrong, color: fg)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(bg)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.pill)
                .stroke(variant == .primary ? .clear : theme.colors.border, lineWidth: HairlineWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.pill))
    }

    // MARK: - Location

    @ViewBuilder
    private var locationSection: some View {
        if requiresLocation {
            HStack(spacing: Spacing.two) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 15))
                    .foregroundStyle(missingLocation ? theme.colors.danger : theme.colors.textFaint)
                Text(locationStatus ?? "This challenge requires your location.")
                    .textStyle(.small, color: missingLocation ? theme.colors.danger : theme.colors.textFaint)
            }
        } else {
            ToggleRow(
                title: "Attach location",
                subtitle: locationStatus ?? "Optional — adds where this was taken.",
                isOn: Binding(get: { attachLocation }, set: { toggleLocation($0) })
            )
        }
    }

    private func toggleLocation(_ on: Bool) {
        attachLocation = on
        if on {
            fetchLocation()
        } else {
            location = nil
            locationStatus = nil
        }
    }

    private func fetchLocation() {
        guard !isFetchingLocation else { return }
        isFetchingLocation = true
        locationStatus = "Getting location…"
        Task {
            defer { isFetchingLocation = false }
            if let coord = await locationFetcher.current() {
                location = coord
                locationStatus = String(format: "Location attached (%.4f, %.4f)", coord.lat, coord.lng)
            } else {
                location = nil
                locationStatus = requiresLocation
                    ? "Location permission denied — required by this challenge."
                    : "Couldn't get your location."
                if !requiresLocation { attachLocation = false }
            }
        }
    }

    // MARK: - Data + actions

    private func loadChallenge() async {
        do {
            let detail = try await ChallengeService.getDetail(
                challengeId: challengeId, myUserId: session.userId ?? ""
            )
            challenge = detail.challenge
            currentPeriod = detail.currentPeriod
            now = detail.now
            if requiresLocation { fetchLocation() }
        } catch {
            toast = Format.errorMessage(error)
        }
    }

    private func submit() {
        guard canSubmit, !isSubmitting, let userId = session.userId, let photoData else { return }
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                _ = try await SubmissionService.submitProof(
                    SubmitProofInput(
                        challengeId: challengeId,
                        userId: userId,
                        photoData: photoData,
                        caption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
                        location: wantsLocation ? location : nil
                    )
                )
                nav.pop()
            } catch {
                toast = Format.errorMessage(error)
            }
        }
    }
}
