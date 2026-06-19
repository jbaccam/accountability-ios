import Foundation
import Supabase

struct SubmitProofInput {
    let challengeId: String
    let userId: String
    /// JPEG bytes from the picker/camera.
    let photoData: Data
    let caption: String
    let location: (lat: Double, lng: Double)?
}

enum SubmissionService {
    private static var client: SupabaseClient { Supa.client }

    // submissions has two FKs to profiles (user_id, resolved_by), so the embed
    // must name which relationship it wants or PostgREST refuses to guess.
    private static let detailsSelect =
        "*, profiles!user_id(id, display_name), " +
        "submission_votes(*, profiles!voter_id(id, display_name))"

    /// Uploads the proof photo, then records the submission via RPC.
    static func submitProof(_ input: SubmitProofInput) async throws -> Submission {
        let photoPath = try await uploadProofPhoto(
            challengeId: input.challengeId, userId: input.userId, data: input.photoData
        )
        let params: [String: AnyJSON] = [
            "p_challenge_id": .string(input.challengeId),
            "p_photo_path": .string(photoPath),
            "p_caption": .string(input.caption),
            "p_location_lat": input.location.map { .double($0.lat) } ?? .null,
            "p_location_lng": input.location.map { .double($0.lng) } ?? .null,
        ]
        return try await client.rpc("submit_proof", params: params).execute().value
    }

    private static func uploadProofPhoto(
        challengeId: String, userId: String, data: Data
    ) async throws -> String {
        guard !data.isEmpty else {
            throw AppError("That photo came through empty — try taking it again.")
        }
        // Path shape is enforced by storage RLS: {challenge_id}/{user_id}/{file}
        let path = "\(challengeId)/\(userId)/\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        try await client.storage.from("proofs").upload(
            path, data: data, options: FileOptions(contentType: "image/jpeg")
        )
        return path
    }

    /// Signed URL for displaying a proof photo from the private bucket.
    static func proofPhotoURL(_ photoPath: String) async throws -> URL {
        try await client.storage.from("proofs").createSignedURL(path: photoPath, expiresIn: 3600)
    }

    static func listChallengeSubmissions(_ challengeId: String) async throws -> [SubmissionWithDetails] {
        try await client
            .from("submissions")
            .select(detailsSelect)
            .eq("challenge_id", value: challengeId)
            .order("submitted_at", ascending: false)
            .limit(50)
            .execute().value
    }

    static func getSubmission(_ submissionId: String) async throws -> SubmissionWithDetails {
        try await client
            .from("submissions")
            .select(detailsSelect)
            .eq("id", value: submissionId)
            .single()
            .execute().value
    }

    @discardableResult
    static func vote(submissionId: String, vote: VoteValue, reason: String) async throws -> Submission {
        let params: [String: AnyJSON] = [
            "p_submission_id": .string(submissionId),
            "p_vote": .string(vote.rawValue),
            "p_reason": reason.isEmpty ? .null : .string(reason),
        ]
        return try await client.rpc("vote_on_submission", params: params).execute().value
    }

    /// Creator decision for a submission the group vote could not settle.
    @discardableResult
    static func resolveSubmission(submissionId: String, approve: Bool) async throws -> Submission {
        let params: [String: AnyJSON] = [
            "p_submission_id": .string(submissionId),
            "p_approve": .bool(approve),
        ]
        return try await client.rpc("resolve_submission", params: params).execute().value
    }
}

/// A plain user-facing error with a message (mirrors `throw new Error(...)`).
struct AppError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
