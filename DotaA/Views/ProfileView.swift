//
//  ProfileView.swift
//  DotaA
//
//  Created by Wentao Guo on 11/08/25.
//

import SwiftData
import SwiftUI
import Combine

struct ProfileView: View {
    @State private var currentPlayer: PlayerSearchResult?
    @StateObject private var openDotaService = OpenDotaService.shared
    @State private var recentMatches: [RecentMatch] = []
    @State private var historicalMatches: [RecentMatch] = []
    @State private var heroStats: [PlayerHeroStats] = []
    @State private var playerWinLoss: PlayerWinLoss?
    @State private var playerTotals: [PlayerTotal] = []
    @State private var isLoading = false
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let player = currentPlayer {
                        // Current player profile
                        CurrentPlayerView(player: player)

                        // Performance overview
                        RealPerformanceOverviewView(
                            player: player,
                            recentMatches: recentMatches,
                            historicalMatches: historicalMatches,
                            heroStats: heroStats,
                            playerWinLoss: playerWinLoss,
                            playerTotals: playerTotals,
                            isLoading: isLoading
                        )

                        // Recent achievements
                        RealRecentAchievementsView(
                            player: player,
                            recentMatches: recentMatches,
                            isLoading: isLoading
                        )
                    } else {
                        // No player selected
                        NoPlayerSelectedView()
                    }

                }
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.large)

            }.onAppear {
                loadCurrentPlayer()
            }
        }
    }
    
    private func loadCurrentPlayer() {
        print("🔍 Checking UserDefaults for current player...")
        
        guard
            let id = UserDefaults.standard.object(
                forKey: "currentPlayerAccountId") as? Int64,
            let name = UserDefaults.standard.object(
                forKey: "currentPlayerAccountName") as? String,
            let av = UserDefaults.standard.object(
                forKey: "currentPlayerAccountAV") as? String
        else { 
            print("❌ No current player found in UserDefaults")
            return 
        }

        print("✅ Found current player: \(name) (ID: \(id))")
        currentPlayer = PlayerSearchResult(
            accountId: id, personaname: name, avatarfull: av)
        
        loadPlayerData(accountId: id)
    }
    
    private func loadPlayerData(accountId: Int64) {
        isLoading = true
        print("Loading data for player AccountId: \(accountId)")
        
        let matchesPublisher = openDotaService.getRecentMatches(accountId: accountId, limit: 20)
        let heroesPublisher = openDotaService.getPlayerHeroes(accountId: accountId)
        let winLossPublisher = openDotaService.getPlayerWinLoss(accountId: accountId)
        let totalsPublisher = openDotaService.getPlayerTotals(accountId: accountId)
        
        // Load basic data first
        Publishers.CombineLatest4(matchesPublisher, heroesPublisher, winLossPublisher, totalsPublisher)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Error loading basic player data: \(error)")
                        self.isLoading = false
                    }
                },
                receiveValue: { matches, heroes, winLoss, totals in
                    print("✅ Basic data loaded successfully:")
                    print("  - Matches: \(matches.count)")
                    print("  - Heroes: \(heroes.count)")
                    print("  - Win/Loss: \(winLoss.totalMatches) total, \(winLoss.win)W \(winLoss.lose)L")
                    print("  - Totals: \(totals.count) fields")
                    
                    // Print first few totals fields for debugging
                    for total in totals.prefix(5) {
                        print("    📊 \(total.field): n=\(total.n), sum=\(total.sum), avg=\(total.average)")
                    }
                    
                    self.recentMatches = matches
                    self.heroStats = heroes
                    self.playerWinLoss = winLoss
                    self.playerTotals = totals
                    
                    // Load historical match data for best KDA calculation
                    self.loadHistoricalMatches(accountId: accountId)
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadHistoricalMatches(accountId: Int64) {
        openDotaService.getHistoricalMatches(accountId: accountId, limit: 100)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Error loading historical matches: \(error)")
                    }
                },
                receiveValue: { historicalMatches in
                    print("✅ Historical matches loaded: \(historicalMatches.count)")
                    self.historicalMatches = historicalMatches
                    self.isLoading = false
                }
            )
            .store(in: &cancellables)
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

// MARK: - Real Performance Overview
struct RealPerformanceOverviewView: View {
    let player: PlayerSearchResult
    let recentMatches: [RecentMatch]
    let historicalMatches: [RecentMatch]
    let heroStats: [PlayerHeroStats]
    let playerWinLoss: PlayerWinLoss?
    let playerTotals: [PlayerTotal]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview")
                .font(.title2)
                .fontWeight(.bold)

            if isLoading {
                ProgressView("Loading stats...")
                    .frame(height: 150)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 2),
                    spacing: 12
                ) {
                    OverviewCard(
                        title: "Total Matches", 
                        value: "\(playerWinLoss?.totalMatches ?? 0)",
                        subtitle: "Career games"
                    )
                    OverviewCard(
                        title: "Career Win Rate", 
                        value: playerWinLoss?.winRatePercentage ?? "0%", 
                        subtitle: "\(playerWinLoss?.win ?? 0)W \(playerWinLoss?.lose ?? 0)L"
                    )
                    OverviewCard(
                        title: "Career Avg KDA", 
                        value: String(format: "%.1f", calculateCareerAverageKDA()),
                        subtitle: "All matches"
                    )
                    OverviewCard(
                        title: "Best Career KDA", 
                        value: String(format: "%.1f", getBestCareerKDA()),
                        subtitle: "Historical best"
                    )
                    OverviewCard(
                        title: "Most Played Hero", 
                        value: getMostPlayedHero().name, 
                        subtitle: "\(getMostPlayedHero().games) career games"
                    )
                    OverviewCard(
                        title: "Best Hero", 
                        value: getBestHero().name,
                        subtitle: "\(Int(getBestHero().winRate * 100))% career WR"
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private func calculateWinRate() -> Double {
        return PlayerStatsCalculator.calculateWinRate(from: recentMatches)
    }
    
    private func calculateCareerAverageKDA() -> Double {
        print("🔍 ProfileView calculateCareerAverageKDA: playerTotals count = \(playerTotals.count)")
        if !playerTotals.isEmpty {
            print("🔍 First few playerTotals fields: \(playerTotals.prefix(3).map { "\($0.field)=\($0.sum)" })")
        }
        let result = KDACalculator.calculateCareerAverageKDA(from: playerTotals)
        print("🔍 ProfileView calculateCareerAverageKDA result: \(result)")
        return result
    }
    
    private func getBestKDA() -> (kda: Double, heroId: Int) {
        guard !recentMatches.isEmpty else { return (0.0, 1) }
        
        let bestMatch = recentMatches.max { match1, match2 in
            let kda1 = match1.deaths > 0 ? (Double(match1.kills + match1.assists) / Double(match1.deaths)) : Double(match1.kills + match1.assists)
            let kda2 = match2.deaths > 0 ? (Double(match2.kills + match2.assists) / Double(match2.deaths)) : Double(match2.kills + match2.assists)
            return kda1 < kda2
        }
        
        if let match = bestMatch {
            let kda = match.deaths > 0 ? (Double(match.kills + match.assists) / Double(match.deaths)) : Double(match.kills + match.assists)
            return (kda, match.heroId)
        }
        return (0.0, 1)
    }
    
    private func getMostPlayedHero() -> (name: String, games: Int) {
        return PlayerStatsCalculator.getMostPlayedHero(from: heroStats)
    }
    
    private func getBestHero() -> (name: String, winRate: Double) {
        return PlayerStatsCalculator.getBestHero(from: heroStats)
    }
    
            // Hero name retrieval moved to HeroService
    
    private func getBestCareerKDA() -> Double {
        return KDACalculator.calculateBestCareerKDA(historicalMatches: historicalMatches, recentMatches: recentMatches)
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

// MARK: - Real Recent Achievements
struct RealRecentAchievementsView: View {
    let player: PlayerSearchResult
    let recentMatches: [RecentMatch]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Achievements")
                .font(.title2)
                .fontWeight(.bold)

            if isLoading {
                ProgressView("Loading achievements...")
                    .frame(height: 100)
            } else {
                let achievements = generateRealAchievements()
                
                if achievements.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No Recent Achievements")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Play more matches to unlock achievements!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 12) {
                        ForEach(achievements, id: \.title) { achievement in
                            AchievementRow(
                                icon: achievement.icon,
                                title: achievement.title,
                                description: achievement.description,
                                date: achievement.date,
                                color: achievement.color
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private func generateRealAchievements() -> [RealAchievement] {
        var achievements: [RealAchievement] = []
        
        // Check for winning streak
        if let winStreak = getWinningStreak(), winStreak >= 3 {
            achievements.append(RealAchievement(
                icon: "star.fill",
                title: "Winning Streak",
                description: "Achieved \(winStreak) consecutive wins",
                date: "Recent",
                color: .yellow
            ))
        }
        
        // Check for high KDA performance
        let highKDAMatches = recentMatches.filter { match in
            let kda = match.deaths > 0 ? (Double(match.kills + match.assists) / Double(match.deaths)) : Double(match.kills + match.assists)
            return kda >= 5.0
        }
        
        if let bestMatch = highKDAMatches.max(by: { match1, match2 in
            let kda1 = match1.deaths > 0 ? (Double(match1.kills + match1.assists) / Double(match1.deaths)) : Double(match1.kills + match1.assists)
            let kda2 = match2.deaths > 0 ? (Double(match2.kills + match2.assists) / Double(match2.deaths)) : Double(match2.kills + match2.assists)
            return kda1 < kda2
        }) {
            let kda = bestMatch.deaths > 0 ? (Double(bestMatch.kills + bestMatch.assists) / Double(bestMatch.deaths)) : Double(bestMatch.kills + bestMatch.assists)
            achievements.append(RealAchievement(
                icon: "bolt.fill",
                title: "Outstanding Performance",
                description: String(format: "Achieved %.1f KDA in recent match", kda),
                date: "Recent",
                color: .blue
            ))
        }
        
        // Check for good win rate
        let wins = recentMatches.filter { match in
            (match.playerSlot < 5 && match.radiantWin) || (match.playerSlot >= 5 && !match.radiantWin)
        }.count
        let winRate = Double(wins) / Double(recentMatches.count)
        
        if winRate >= 0.7 && recentMatches.count >= 10 {
            achievements.append(RealAchievement(
                icon: "crown.fill",
                title: "Consistent Winner",
                description: String(format: "%.0f%% win rate over %d matches", winRate * 100, recentMatches.count),
                date: "Recent",
                color: .purple
            ))
        }
        
        // Check for improvement
        if recentMatches.count >= 10 {
            let halfPoint = recentMatches.count / 2
            let recentHalf = Array(recentMatches.prefix(halfPoint))
            let olderHalf = Array(recentMatches.suffix(halfPoint))
            
            let recentWinRate = Double(recentHalf.filter { match in
                (match.playerSlot < 5 && match.radiantWin) || (match.playerSlot >= 5 && !match.radiantWin)
            }.count) / Double(recentHalf.count)
            
            let olderWinRate = Double(olderHalf.filter { match in
                (match.playerSlot < 5 && match.radiantWin) || (match.playerSlot >= 5 && !match.radiantWin)
            }.count) / Double(olderHalf.count)
            
            if recentWinRate > olderWinRate + 0.2 {
                achievements.append(RealAchievement(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Improving Player",
                    description: "Significant improvement in recent matches",
                    date: "Recent",
                    color: .green
                ))
            }
        }
        
        return Array(achievements.prefix(4))
    }
    
    private func getWinningStreak() -> Int? {
        guard !recentMatches.isEmpty else { return nil }
        
        var currentStreak = 0
        var maxStreak = 0
        
        for match in recentMatches.reversed() {
            let isWin = (match.playerSlot < 5 && match.radiantWin) || (match.playerSlot >= 5 && !match.radiantWin)
            if isWin {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return maxStreak > 0 ? maxStreak : nil
    }
}

struct RealAchievement {
    let icon: String
    let title: String
    let description: String
    let date: String
    let color: Color
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
