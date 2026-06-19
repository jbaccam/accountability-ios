import Foundation
import Supabase

struct CheckinActivity {
    /// Approved check-in count per local day key ("YYYY-MM-DD").
    let days: [String: Int]
    let now: Date
}

enum ProfileService {
    private static var client: SupabaseClient { Supa.client }

    /// Display names can be changed at most once every this many days.
    static let nameChangeDays = 30

    static func getMyProfile() async throws -> Profile {
        try await client.rpc("get_my_profile").execute().value
    }

    /// When the display name can next be changed, or nil if it's editable now.
    static func nameChangeAvailableAt(_ profile: Profile) -> Date? {
        guard let updated = profile.displayNameUpdatedAt else { return nil }
        guard let next = Calendar.current.date(byAdding: .day, value: nameChangeDays, to: updated)
        else { return nil }
        return next > Date() ? next : nil
    }

    /// Rename via RPC so the 30-day cadence is enforced. Returns the fresh profile.
    static func updateDisplayName(_ displayName: String) async throws -> Profile {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return try await client.rpc("update_display_name", params: ["p_name": name]).execute().value
    }

    /// Top up the caller's simulated practice balance. Returns the fresh profile.
    static func simulatedDeposit(amount: Double) async throws -> Profile {
        try await client
            .rpc("simulated_deposit", params: ["p_amount": AnyJSON.double(amount)])
            .execute().value
    }

    /// Upload a new profile photo and point the profile at its public URL.
    @discardableResult
    static func uploadAvatar(userId: String, jpeg data: Data) async throws -> String {
        guard !data.isEmpty else {
            throw AppError("That image came through empty — try a different photo.")
        }
        // Path shape is enforced by storage RLS: {user_id}/{file}
        let path = "\(userId)/\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        try await client.storage.from("avatars").upload(
            path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true)
        )
        let publicURL = try client.storage.from("avatars").getPublicURL(path: path)
        // Cache-bust so the new photo replaces the old one immediately.
        let url = "\(publicURL.absoluteString)?v=\(Int(Date().timeIntervalSince1970 * 1000))"
        try await client.from("profiles")
            .update(["avatar_url": url])
            .eq("id", value: userId)
            .execute()
        return url
    }

    /// Clear the profile photo, falling back to initials.
    static func removeAvatar(userId: String) async throws {
        try await client.from("profiles")
            .update(["avatar_url": AnyJSON.null])
            .eq("id", value: userId)
            .execute()
    }

    /// Permanently delete the signed-in user's account and all their data.
    static func deleteMyAccount() async throws {
        try await client.rpc("delete_my_account").execute()
        try? await client.auth.signOut()
    }

    /// Activity data for the profile contribution heatmap.
    static func getMyCheckinActivity(userId: String) async throws -> CheckinActivity {
        struct Row: Codable { let submittedAt: Date }
        let rows: [Row] = try await client
            .from("submissions")
            .select("submitted_at")
            .eq("user_id", value: userId)
            .eq("status", value: "approved")
            .order("submitted_at", ascending: false)
            .limit(500)
            .execute().value

        var days: [String: Int] = [:]
        for row in rows {
            let key = Format.localDayKey(row.submittedAt)
            days[key, default: 0] += 1
        }
        return CheckinActivity(days: days, now: Date())
    }

    static func listMyTransactions() async throws -> [SimulatedTransaction] {
        try await client
            .from("simulated_transactions")
            .select("*")
            .order("created_at", ascending: false)
            .limit(50)
            .execute().value
    }
}
