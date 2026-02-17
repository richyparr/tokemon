import Foundation

/// Organization member data from Anthropic Admin API /v1/organizations/members endpoint.
/// Used for Team Dashboard PRO feature.
struct TeamMember: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let email: String
    let role: String

    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name
        case email
        case role
    }
}

/// Response from Anthropic Admin API /v1/organizations/members endpoint.
struct OrganizationMembersResponse: Codable, Sendable {
    let data: [TeamMember]
    let hasMore: Bool
    let nextPage: String?

    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
        case nextPage = "next_page"
    }
}
