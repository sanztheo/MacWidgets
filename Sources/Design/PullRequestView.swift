import SwiftUI

struct PullRequestView: View {
    let snapshot: PullRequestSnapshot?
    let size: WidgetSize
    var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: size.compact ? 12 : 20) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.pull").foregroundStyle(.green)
                if let snapshot {
                    Text("\(snapshot.totalCount)").foregroundStyle(.white)
                    Text("created").foregroundStyle(WidgetStyle.secondary)
                } else {
                    Text("Pull requests").foregroundStyle(.white)
                }
                Spacer(minLength: 0)
                Image("GitHubMark").resizable().scaledToFit()
                    .frame(width: size.compact ? 24 : 32, height: size.compact ? 24 : 32)
                    .accessibilityHidden(true)
            }
            .font(.system(size: size.compact ? 14 : 17, weight: .semibold))
            if let snapshot {
                if snapshot.requests.isEmpty {
                    Text("Aucune pull request ouverte")
                        .font(.system(size: 13)).foregroundStyle(WidgetStyle.secondary)
                } else {
                    ForEach(snapshot.requests.prefix(size.compact ? 2 : 5)) { request in
                        Link(destination: request.url) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text("\(request.repository) #\(request.number)")
                                        .foregroundStyle(WidgetStyle.secondary).lineLimit(1)
                                    checkIndicator(request)
                                }
                                .font(.system(size: size.compact ? 11 : 14, weight: .medium))
                                Text(request.title)
                                    .font(.system(size: size.compact ? 12 : 16, weight: .semibold))
                                    .foregroundStyle(.white).lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else if error == nil {
                Text("Connectez GitHub dans MacWidgets.")
                    .font(.system(size: 12)).foregroundStyle(WidgetStyle.secondary)
            }
            Spacer(minLength: 0)
            WidgetNotice(message: error, updatedAt: snapshot?.updatedAt)
        }
        .padding(size.compact ? 14 : 20)
    }

    @ViewBuilder
    private func checkIndicator(_ request: PullRequest) -> some View {
        if request.isDraft {
            Image(systemName: "circle.dotted").foregroundStyle(WidgetStyle.secondary)
                .accessibilityLabel("Brouillon")
        } else {
            switch request.checks {
            case "SUCCESS":
                Image(systemName: "checkmark").foregroundStyle(.green).accessibilityLabel("Vérifications réussies")
            case "FAILURE", "ERROR":
                Image(systemName: "xmark").foregroundStyle(.red).accessibilityLabel("Vérifications en échec")
            case "PENDING", "EXPECTED":
                Image(systemName: "clock").foregroundStyle(.orange).accessibilityLabel("Vérifications en cours")
            default: EmptyView()
            }
        }
    }
}
