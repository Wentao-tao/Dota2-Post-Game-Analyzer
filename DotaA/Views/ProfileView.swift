//
//  ProfileView.swift
//  DotaA
//
//  Created by Wentao Guo on 11/08/25.
//

import SwiftData
import SwiftUI

struct ProfileView: View {
    @State private var currentPlayer: PlayerSearchResult?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let player = currentPlayer {
                        // Current player profile
                        CurrentPlayerView(player: player)

                        // Performance overview
                        PerformanceOverviewView()

                        // Recent achievements
                        RecentAchievementsView()
                    } else {
                        // No player selected
                        NoPlayerSelectedView()
                    }

                }
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.large)

            }.onAppear {
                guard
                    let id = UserDefaults.standard.object(
                        forKey: "currentPlayerAccountId") as? Int64,
                    let name = UserDefaults.standard.object(
                        forKey: "currentPlayerAccountName") as? String,
                    let av = UserDefaults.standard.object(
                        forKey: "currentPlayerAccountAV") as? String

                else { return }

                currentPlayer = PlayerSearchResult(
                    accountId: id, personaname: name, avatarfull: av)
            }
        }
    }

}

// MARK: - Current Player View
struct CurrentPlayerView: View {
    let player: PlayerSearchResult

    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: player.avatarfull)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())

            VStack(spacing: 8) {
                Text(player.personaname)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Steam ID: \(player.accountId)")
                    .font(.caption)
                    .foregroundColor(.secondary)

            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Performance Overview
struct PerformanceOverviewView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview")
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 2),
                spacing: 12
            ) {
                OverviewCard(
                    title: "Total Matches", value: "1,245",
                    subtitle: "89 analyzed")
                OverviewCard(
                    title: "Average Score", value: "76",
                    subtitle: "+3 this month")
                OverviewCard(
                    title: "Best KDA", value: "12.5", subtitle: "Anti-Mage")
                OverviewCard(
                    title: "Highest GPM", value: "745",
                    subtitle: "Phantom Assassin")
                OverviewCard(
                    title: "Win Rate", value: "67%", subtitle: "Last 20 games")
                OverviewCard(
                    title: "Improvement", value: "+8%",
                    subtitle: "Since last month")
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct OverviewCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

// MARK: - Recent Achievements
struct RecentAchievementsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Achievements")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                AchievementRow(
                    icon: "star.fill",
                    title: "Winning Streak",
                    description: "Achieved 5 consecutive wins",
                    date: "2 days ago",
                    color: .yellow
                )

                AchievementRow(
                    icon: "crown.fill",
                    title: "Farming Expert",
                    description: "Over 400 last hits in single match",
                    date: "1 week ago",
                    color: .orange
                )

                AchievementRow(
                    icon: "bolt.fill",
                    title: "Team Fight MVP",
                    description: "KDA over 10 in one match",
                    date: "2 weeks ago",
                    color: .blue
                )

                AchievementRow(
                    icon: "target",
                    title: "Goal Achiever",
                    description: "Completed weekly improvement goals",
                    date: "3 weeks ago",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct AchievementRow: View {
    let icon: String
    let title: String
    let description: String
    let date: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

// MARK: - No Player Selected
struct NoPlayerSelectedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("No Player Set")
                .font(.title2)
                .fontWeight(.bold)

            Text(
                "Search and select your Dota 2 account to start tracking your performance"
            )
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)

            NavigationLink(destination: PlayerSearchView()) {
                Text("Search for Player")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }

            VStack(alignment: .leading, spacing: 8) {
                FeatureHighlight(
                    icon: "chart.bar.fill",
                    text: "Track performance across matches")
                FeatureHighlight(
                    icon: "brain.head.profile",
                    text: "Get AI-powered coaching advice")
                FeatureHighlight(
                    icon: "target", text: "Set and achieve improvement goals")
                FeatureHighlight(
                    icon: "trophy.fill", text: "Unlock achievements and badges")
            }
            .padding(.top)
        }
        .padding()
    }
}

struct FeatureHighlight: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ProfileView()
}
