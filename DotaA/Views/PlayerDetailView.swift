//
//  PlayerDetailView.swift
//  DotaA
//
//  Created by Wentao Guo on 11/08/25.
//

import SwiftUI
import Combine

struct PlayerDetailView: View {
    let player: PlayerSearchResult
    @StateObject private var openDotaService = OpenDotaService.shared
    @State private var recentMatches: [RecentMatch] = []
    @State private var playerStats: PlayerStats?
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Player Header
                PlayerHeaderView(player: player, stats: playerStats)
                
                if isLoading {
                    ProgressView("Loading player data...")
                        .frame(height: 200)
                } else if !errorMessage.isEmpty {
                    ErrorView(message: errorMessage) {
                        loadPlayerData()
                    }
                } else {
                    // Recent Matches Section
                    RecentMatchesSection(matches: recentMatches)
                }
            }
            .padding()
        }
        .navigationTitle(player.personaname)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadPlayerData()
            UserDefaults.standard.set(player.accountId, forKey: "currentPlayerAccountId")
            UserDefaults.standard.set(player.personaname, forKey: "currentPlayerAccountName")
            UserDefaults.standard.set(player.avatarfull, forKey: "currentPlayerAccountAV")
            
        }
    }
    private func loadPlayerData() {
        isLoading = true
        errorMessage = ""
        
        let matchesPublisher = openDotaService.getRecentMatches(accountId: player.accountId)
        let statsPublisher = openDotaService.getPlayerStats(accountId: player.accountId)
        
        Publishers.CombineLatest(matchesPublisher, statsPublisher)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print(123)
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { matches, stats in
                  
                    recentMatches = matches
                    playerStats = stats
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Player Header View
struct PlayerHeaderView: View {
    let player: PlayerSearchResult
    let stats: PlayerStats?
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar and basic info
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: player.avatarfull)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(player.personaname)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Steam ID: \(player.accountId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let rank = stats?.rankTier, rank > 0 {
                        RankBadge(rankTier: rank)
                    }
                }
                
                Spacer()
            }
            
            // Stats cards
            if let stats = stats {
                PlayerStatsCards(stats: stats)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Rank Badge
struct RankBadge: View {
    let rankTier: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            Text(getRankName(tier: rankTier))
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func getRankName(tier: Int) -> String {
        let ranks = ["Herald", "Guardian", "Crusader", "Archon", "Legend", "Ancient", "Divine", "Immortal"]
        let rankIndex = max(0, min(7, (tier - 10) / 10))
        return ranks[rankIndex]
    }
}

// MARK: - Player Stats Cards
struct PlayerStatsCards: View {
    let stats: PlayerStats
    
    var body: some View {
        HStack(spacing: 12) {
            StatCardA(title: "Rank", value: getRankText(), color: .blue)
            StatCardA(title: "Status", value: getStatusText(), color: .green)
            if let cheese = stats.profile?.cheese {
                StatCardA(title: "Plus", value: "\(cheese)", color: .orange)
            }
        }
    }
    
    private func getRankText() -> String {
        if let rank = stats.rankTier, rank > 0 {
            let ranks = ["Herald", "Guardian", "Crusader", "Archon", "Legend", "Ancient", "Divine", "Immortal"]
            let rankIndex = max(0, min(7, (rank - 10) / 10))
            return ranks[rankIndex]
        }
        return "Unranked"
    }
    
    private func getStatusText() -> String {
        return (stats.profile?.status ?? 0) == 1 ? "Online" : "Offline"
    }
}

struct StatCardA: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(8)
    }
}

// MARK: - Recent Matches Section
struct RecentMatchesSection: View {
    let matches: [RecentMatch]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Matches")
                .font(.title3)
                .fontWeight(.bold)
            
            LazyVStack(spacing: 8) {
                ForEach(matches.prefix(10), id: \.matchId) { match in
                    NavigationLink(destination: MatchAnalysisView(match: match)) {
                        RecentMatchRow(match: match)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Recent Match Row
struct RecentMatchRow: View {
    let match: RecentMatch
    @State private var heroName = "Loading..."
    
    var body: some View {
        HStack {
            // Win/Loss indicator
            Circle()
                .fill(match.isWin ? Color.green : Color.red)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(heroName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formatTimeAgo(timestamp: match.startTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("KDA: \(match.kda)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDuration(seconds: match.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(match.isWin ? "Victory" : "Defeat")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(match.isWin ? .green : .red)
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
        .onAppear {
            loadHeroName()
        }
    }
    
    private func loadHeroName() {
        OpenDotaService.shared.getHeroName(heroId: match.heroId) { name in
            heroName = name
        }
    }
    
    private func formatTimeAgo(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatDuration(seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes)m"
    }
}

#Preview {
    PlayerDetailView(player: PlayerSearchResult(
        accountId: 123456789,
        personaname: "Sample Player",
        avatarfull: ""
    ))
}
