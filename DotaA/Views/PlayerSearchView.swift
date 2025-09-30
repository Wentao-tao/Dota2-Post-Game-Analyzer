//
//  PlayerSearchView.swift
//  DotaA
//
//  Created by Wentao Guo on 11/08/25.
//

import Combine
import SwiftUI

struct PlayerSearchView: View {
    @StateObject private var openDotaService = OpenDotaService.shared
    @State private var searchText = ""
    @State private var searchResults: [PlayerSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage = ""
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Search Header
                VStack(spacing: 12) {
                    Text("Find Your Dota 2 Account")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(
                        "Search for your Steam username or ID to view personal analytics"
                    )
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                }
                .padding()

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Enter Steam username or ID", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            if !searchText.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ).isEmpty {
                                searchPlayers()
                            }
                        }

                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if !searchText.isEmpty {
                        Button("Search") {
                            searchPlayers()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.horizontal)

                // Search Results
                if !errorMessage.isEmpty {
                    ErrorView(message: errorMessage) {
                        searchPlayers()
                    }
                    .padding()
                } else if searchResults.isEmpty && !searchText.isEmpty
                    && !isSearching
                {
                    VStack(spacing: 12) {
                        Image(
                            systemName: "person.crop.circle.badge.questionmark"
                        )
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                        Text("No Players Found")
                            .font(.headline)
                            .fontWeight(.bold)

                        Text("Try different keywords or check spelling")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(searchResults, id: \.accountId) { player in
                                NavigationLink(
                                    destination: PlayerDetailView(
                                        player: player)
                                ) {
                                    PlayerSearchResultRow(player: player)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                if searchResults.isEmpty && searchText.isEmpty {
                    Image("background1")
                        .resizable()

                        .scaledToFit()
                        .scaleEffect(2)

                        .opacity(0.8)

                        .padding(.bottom, 20)
                }
        
                Spacer()

                // Usage Tips
                if searchResults.isEmpty && searchText.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.blue)
                            Text("Search Tips")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Use your Steam display name")
                            Text("• Try partial usernames")
                            Text("• Make sure spelling is correct")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Dota 2 Post-Game Analyzer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func searchPlayers() {
        guard
            !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }

        isSearching = true
        errorMessage = ""

        openDotaService.searchPlayer(query: searchText)
            .sink(
                receiveCompletion: { completion in
                    isSearching = false
                    if case .failure(let error) = completion {
                        errorMessage =
                            "Search failed: \(error.localizedDescription)"
                    }
                },
                receiveValue: { results in
                    searchResults = results
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Player Search Result Row
struct PlayerSearchResultRow: View {
    let player: PlayerSearchResult

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: player.avatarfull)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            // Player Info
            VStack(alignment: .leading, spacing: 4) {
                Text(player.personaname)
                    .font(.headline)
                    .lineLimit(1)

                Text("Steam ID: \(player.accountId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Selection indicator
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    init(message: String, retryAction: @escaping () -> Void) {
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                retryAction()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    PlayerSearchView()
}

#Preview("Error View") {
    ErrorView(
        message:
            "Unable to connect to server. Please check your internet connection."
    ) {
        print("Retry tapped")
    }
    .padding()
}
