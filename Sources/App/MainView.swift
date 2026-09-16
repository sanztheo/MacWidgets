import SwiftUI

struct MainView: View {
    @Bindable var model: AppModel
    @ViewState private var tab = "Aperçus"
    @ViewState private var githubToken = ""
    @ViewState private var selectedDate = PreviewData.date

    var body: some View {
        NavigationSplitView {
            List(selection: $tab) {
                Label("Aperçus", systemImage: "square.grid.2x2").tag("Aperçus")
                Label("Connexions", systemImage: "person.crop.circle").tag("Connexions")
            }
            .navigationTitle("MacWidgets")
            .navigationSplitViewColumnWidth(180)
        } detail: {
            if tab == "Aperçus" { previews } else { connections }
        }
        .toolbar {
            if model.githubConnected || model.googleConnected {
                Button("Actualiser", systemImage: "arrow.clockwise") { Task { await model.refresh() } }
                    .disabled(model.busy)
            }
        }
    }

    private var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Votre bureau, à jour.").font(.largeTitle.bold())
                    Text("GitHub et Google Calendar. Directement sur votre Mac.")
                        .font(.title3).foregroundStyle(.secondary)
                    Text("Aperçus avec des données fictives · Clic droit sur le bureau → Modifier les widgets → MacWidgets")
                        .font(.callout).foregroundStyle(.secondary)
                }
                HStack(alignment: .top, spacing: 24) {
                    preview(size: .small) {
                        CalendarView(snapshot: PreviewData.calendar, selectedDate: selectedDate,
                                     size: .small, selectDate: { selectedDate = $0 })
                    }
                    preview(size: .medium) {
                        CalendarView(snapshot: PreviewData.calendar, selectedDate: selectedDate,
                                     size: .medium, selectDate: { selectedDate = $0 })
                    }
                }
                HStack(alignment: .top, spacing: 24) {
                    preview(size: .large) {
                        CalendarView(snapshot: PreviewData.calendar, selectedDate: selectedDate,
                                     size: .large, selectDate: { selectedDate = $0 })
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        PullRequestView(snapshot: PreviewData.github, size: .large)
                            .frame(width: 300, height: 300)
                            .background(WidgetStyle.background, in: RoundedRectangle(cornerRadius: 24))
                        Text("GitHub · Pull requests").font(.caption).foregroundStyle(.secondary)
                    }
                }
                preview(size: .wide) {
                    CalendarView(snapshot: PreviewData.calendar, selectedDate: selectedDate,
                                 size: .wide, selectDate: { selectedDate = $0 })
                }
            }
            .padding(28)
        }
        .background(Color(red: 0.055, green: 0.07, blue: 0.095))
    }

    private func preview<Content: View>(size: WidgetSize, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content().frame(width: size.dimensions.width, height: size.dimensions.height)
                .background(WidgetStyle.background, in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.14), lineWidth: 0.5))
            Text(size.title).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var connections: some View {
        Form {
            Section("GitHub") {
                LabeledContent("Compte", value: model.githubConnected ? "Connecté" : "Non connecté")
                if model.githubConnected {
                    Button("Déconnecter GitHub", role: .destructive) { model.disconnect("github") }
                } else {
                    SecureField("Jeton personnel GitHub", text: $githubToken)
                        .textContentType(.password)
                    Text("Jeton à accès fin : sélectionnez vos dépôts et autorisez Pull requests, Checks et Commit statuses en lecture. Un accès non accordé ne peut pas apparaître dans le widget.")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Link("Créer un jeton", destination: URL(string: "https://github.com/settings/personal-access-tokens/new")!)
                        Spacer()
                        Button("Connecter GitHub") {
                            let token = githubToken
                            githubToken = ""
                            Task { await model.connectGitHub(token: token) }
                        }
                        .disabled(githubToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            Section("Google Calendar et Google Tasks") {
                LabeledContent("Compte", value: model.googleConnected ? "Connecté" : "Non connecté")
                Text("Calendrier principal et tâches datées, en lecture seule. Vos identifiants restent dans le Trousseau de votre Mac.")
                    .font(.caption).foregroundStyle(.secondary)
                if model.googleConnected {
                    Button("Déconnecter Google", role: .destructive) { model.disconnect("google") }
                } else {
                    Text("Cette première version utilise votre propre client OAuth Google de type Application de bureau. Activez Calendar API et Tasks API, puis importez son fichier JSON.")
                        .font(.callout)
                    Link("Guide de connexion Google", destination: URL(string: "https://github.com/sanztheo/MacWidgets/blob/main/docs/setup.md")!)
                    Button(model.googleConfiguration == nil ? "Importer la configuration Google…" : "Remplacer la configuration Google…") {
                        model.importGoogleConfiguration()
                    }
                    Button("Se connecter avec Google") { model.connectGoogle() }
                        .disabled(model.googleConfiguration == nil)
                }
            }
            Section {
                Text("Pour ajouter un widget : clic droit sur le bureau → Modifier les widgets → MacWidgets. Les rafraîchissements automatiques sont planifiés par macOS.")
                if let message = model.message {
                    Text(message).textSelection(.enabled).foregroundStyle(.secondary)
                }
                if model.busy {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text("Connexion ou actualisation en cours…")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .disabled(model.busy)
        .safeAreaInset(edge: .bottom) {
            if model.signInTask != nil {
                Button("Annuler la connexion") { model.signInTask?.cancel() }.padding()
            }
        }
    }
}
