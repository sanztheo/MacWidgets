import Foundation

enum GitHubClient {
    static let query = """
    query MyPullRequests {
      viewer {
        pullRequests(first: 100, states: OPEN, orderBy: {field: UPDATED_AT, direction: DESC}) {
          totalCount
          nodes {
            id number title url isDraft
            repository { nameWithOwner }
            commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
          }
        }
      }
    }
    """

    static func fetch(token: String) async throws -> PullRequestSnapshot {
        var request = URLRequest(url: URL(string: "https://api.github.com/graphql")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("MacWidgets", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONEncoder().encode(["query": query])
        return try decode(await HTTP.data(for: request))
    }

    static func decode(_ data: Data) throws -> PullRequestSnapshot {
        let response = try JSONDecoder().decode(Response.self, from: data)
        guard response.errors?.isEmpty != false, let connection = response.data?.viewer.pullRequests else {
            // Never turn a partial/unauthorized response into a reassuring empty PR list.
            throw WidgetFailure.message("GitHub n’a pas renvoyé toutes les données. Vérifiez les droits du jeton.")
        }
        let requests = try connection.nodes.map { node -> PullRequest in
            guard let url = URL(string: node.url), url.scheme == "https", url.host == "github.com" else {
                throw WidgetFailure.message("Lien GitHub invalide.")
            }
            return PullRequest(
                id: node.id, number: node.number, title: node.title,
                repository: node.repository.nameWithOwner, url: url, isDraft: node.isDraft,
                checks: node.commits.nodes.first?.commit.statusCheckRollup?.state
            )
        }
        return PullRequestSnapshot(requests: requests, totalCount: connection.totalCount, updatedAt: .now)
    }

    private struct Response: Decodable {
        let data: Payload?
        let errors: [APIError]?
        struct APIError: Decodable { let message: String }
        struct Payload: Decodable { let viewer: Viewer }
        struct Viewer: Decodable { let pullRequests: Connection }
        struct Connection: Decodable {
            let totalCount: Int
            let nodes: [Node]
        }
        struct Node: Decodable {
            let id: String
            let number: Int
            let title: String
            let url: String
            let isDraft: Bool
            let repository: Repository
            let commits: Commits
        }
        struct Repository: Decodable { let nameWithOwner: String }
        struct Commits: Decodable { let nodes: [CommitNode] }
        struct CommitNode: Decodable { let commit: Commit }
        struct Commit: Decodable { let statusCheckRollup: Status? }
        struct Status: Decodable { let state: String }
    }
}
