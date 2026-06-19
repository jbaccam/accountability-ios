import Foundation
import Supabase

enum FriendService {
    private static var client: SupabaseClient { Supa.client }

    /// Search other users by display name, tagged with the caller's relationship.
    static func searchUsers(_ query: String) async throws -> [UserSearchResult] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return try await client.rpc("search_users", params: ["p_query": q]).execute().value
    }

    static func listFriends() async throws -> [Friend] {
        try await client.rpc("list_friends").execute().value
    }

    static func listFriendRequests() async throws -> [FriendRequest] {
        try await client.rpc("list_friend_requests").execute().value
    }

    static func sendFriendRequest(addresseeId: String) async throws {
        try await client
            .rpc("send_friend_request", params: ["p_addressee": addresseeId])
            .execute()
    }

    static func respondFriendRequest(requesterId: String, accept: Bool) async throws {
        let params: [String: AnyJSON] = [
            "p_requester": .string(requesterId),
            "p_accept": .bool(accept),
        ]
        try await client.rpc("respond_friend_request", params: params).execute()
    }

    static func removeFriend(otherId: String) async throws {
        try await client.rpc("remove_friend", params: ["p_other": otherId]).execute()
    }
}
