import Foundation

/// Organization user data from Anthropic Admin API /v1/organizations/users endpoint.
/// Used for Team Dashboard PRO feature.
struct TeamMember: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let email: String
    let role: String
    let addedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case role
        case addedAt = "added_at"
    }
}

/// Response from Anthropic Admin API /v1/organizations/users endpoint.
struct OrganizationMembersResponse: Codable, Sendable {
    let data: [TeamMember]
    let hasMore: Bool
    let lastId: String?
    let firstId: String?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case lastId = "last_id"
        case firstId = "first_id"
    }
}
