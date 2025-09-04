//
//  AnalysisView.swift
//  DotaA
//
//  Created by Wentao Guo on 11/08/25.
//

import SwiftUI
import Combine

struct AnalysisView: View {
    @State private var selectedAnalysisType = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Analysis Type", selection: $selectedAnalysisType) {
                    Text("Trends").tag(0)
                    Text("Heroes").tag(1)
                    Text("Progress").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                switch selectedAnalysisType {
                case 0:
                    PerformanceTrendsView()
                case 1:
                    HeroAnalysisView()
                case 2:
                    ProgressReportView()
                default:
                    PerformanceTrendsView()
                }
            }
            .navigationTitle("Deep Analysis")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Performance Trends View
struct PerformanceTrendsView: View {
    @StateObject private var openDotaService = OpenDotaService.shared
    @State private var recentMatches: [RecentMatch] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    // Calculated real data
    @State private var averageKDA: Double = 0
    @State private var kdaTrend: Double = 0
    @State private var winRate: Double = 0
    @State private var winRateTrend: Double = 0
    @State private var estimatedGPM: Int = 0
    @State private var gpmTrend: Double = 0
    @State private var overallScore: Double = 0
    @State private var scoreTrend: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Performance Trends")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if isLoading {
                    ProgressView("Loading performance data...")
                        .frame(height: 200)
                } else if !errorMessage.isEmpty {
                    VStack(spacing: 16) {
                        if errorMessage.contains("Please search and select") {
                            // No player selected
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("Player didnt found")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            VStack(spacing: 16) {
                                Text("Follow the steps to set up：")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("1️⃣")
                                            .font(.title3)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("swtich \"Player Search\" tab")
                                                .fontWeight(.medium)
                                            Text("at the bottom")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("2️⃣")
                                            .font(.title3)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Use Search bar")
                                                .fontWeight(.medium)
                                        }
                                    }
                                    
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("3️⃣")
                                            .font(.title3)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Enter ur acc ID")
                                                .fontWeight(.medium)
                                            Text("Select ur profile")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("4️⃣")
                                            .font(.title3)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Then back to this page")
                                                .fontWeight(.medium)
                                            Text("Check recommandation")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(12)
                                
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.orange)
                                    Text("Automatically analys selected player")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        } else {
                            // API error
                            Text("⚠️ Unable to load your data")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                loadRealData()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    // Real data loaded successfully
                    RealTrendChartView(matches: recentMatches)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        TrendCard(
                            title: "Average KDA",
                            value: String(format: "%.1f", averageKDA),
                            trend: String(format: "%+.1f", kdaTrend),
                            isPositive: kdaTrend >= 0
                        )
                        TrendCard(
                            title: "Average GPM",
                            value: "\(estimatedGPM)",
                            trend: String(format: "%+.0f", gpmTrend),
                            isPositive: gpmTrend >= 0
                        )
                        TrendCard(
                            title: "Win Rate",
                            value: String(format: "%.0f%%", winRate),
                            trend: String(format: "%+.0f%%", winRateTrend),
                            isPositive: winRateTrend >= 0
                        )
                        TrendCard(
                            title: "Overall Score",
                            value: String(format: "%.0f", overallScore),
                            trend: String(format: "%+.0f", scoreTrend),
                            isPositive: scoreTrend >= 0
                        )
                    }
                    .padding(.horizontal)
                    
                    RealImprovementAreasView(matches: recentMatches)
                }
                
                Spacer()
            }
        }
        .onAppear {
            loadRealData()
        }
    }
    
    private func loadRealData() {
        isLoading = true
        errorMessage = ""
        
        // Get current user's account ID from UserDefaults or other storage
        guard let currentAccountId = getCurrentUserAccountId() else {
            // No user selected, show message to select a player first
            errorMessage = "Please search and select a player first"
            isLoading = false
            return
        }
        
        openDotaService.getRecentMatches(accountId: currentAccountId, limit: 15)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.errorMessage = "Failed to load your data: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                },
                receiveValue: { matches in
                    self.recentMatches = matches
                    self.calculateRealTrends(from: matches)
                    self.isLoading = false
                }
            )
            .store(in: &cancellables)
    }
    
    private func getCurrentUserAccountId() -> Int64? {
        // Check if user has selected themselves as the current player
        return UserDefaults.standard.object(forKey: "currentPlayerAccountId") as? Int64
    }
    
    private func calculateRealTrends(from matches: [RecentMatch]) {
        guard !matches.isEmpty else { return }
        
        // Calculate real KDA
        let kdas = matches.map { match in
            Double(match.kills + match.assists) / max(Double(match.deaths), 1.0)
        }
        averageKDA = kdas.reduce(0, +) / Double(kdas.count)
        
        // Calculate KDA trend (recent vs older matches)
        let midPoint = matches.count / 2
        let recentKDAs = Array(kdas.prefix(midPoint))
        let olderKDAs = Array(kdas.dropFirst(midPoint))
        
        if !recentKDAs.isEmpty && !olderKDAs.isEmpty {
            let recentAvg = recentKDAs.reduce(0, +) / Double(recentKDAs.count)
            let olderAvg = olderKDAs.reduce(0, +) / Double(olderKDAs.count)
            kdaTrend = recentAvg - olderAvg
        }
        
        // Calculate real win rate
        let wins = matches.filter { match in
            (match.playerSlot < 5 && match.radiantWin) || (match.playerSlot >= 5 && !match.radiantWin)
        }.count
        winRate = Double(wins) / Double(matches.count) * 100
        
        // Calculate win rate trend
        let recentWins = matches.prefix(midPoint).filter { match in
            (match.playerSlot < 5 && match.radiantWin) || (match.playerSlot >= 5 && !match.radiantWin)
        }.count
        let olderWins = matches.dropFirst(midPoint).filter { match in
            (match.playerSlot < 5 && match.radiantWin) || (match.playerSlot >= 5 && !match.radiantWin)
        }.count
        
        if midPoint > 0 {
            let recentWinRate = Double(recentWins) / Double(midPoint) * 100
            let olderWinRate = Double(olderWins) / Double(matches.count - midPoint) * 100
            winRateTrend = recentWinRate - olderWinRate
        }
        
        // Estimate GPM based on KDA performance
        estimatedGPM = Int(350 + (averageKDA * 50))
        gpmTrend = kdaTrend * 25
        
        // Calculate overall score
        overallScore = 40 + (averageKDA * 15) + (winRate * 0.3)
        scoreTrend = kdaTrend * 20
    }
}

struct TrendChartView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 10 Matches Performance")
                .font(.headline)
                .padding(.horizontal)
            
        }
    }
}

struct TrendCard: View {
    let title: String
    let value: String
    let trend: String
    let isPositive: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                    .foregroundColor(isPositive ? .green : .red)
                Text(trend)
                    .foregroundColor(isPositive ? .green : .red)
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct ImprovementAreasView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Areas This Week")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                FocusAreaCard(
                    title: "Last-Hit Efficiency",
                    description: "Improve from 5.2 to 6+ CS per minute",
                    progress: 0.7,
                    priority: .high
                )
                
                FocusAreaCard(
                    title: "Map Awareness",
                    description: "Reduce deaths by improving positioning",
                    progress: 0.4,
                    priority: .high
                )
                
                FocusAreaCard(
                    title: "Item Timings",
                    description: "Get core items 2 minutes earlier",
                    progress: 0.6,
                    priority: .medium
                )
            }
            .padding(.horizontal)
        }
    }
}

struct FocusAreaCard: View {
    let title: String
    let description: String
    let progress: Double
    let priority: Priority
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text(priority.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(getPriorityColor().opacity(0.2))
                    .foregroundColor(getPriorityColor())
                    .cornerRadius(6)
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
    
    private func getPriorityColor() -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

// MARK: - Hero Analysis View
struct HeroAnalysisView: View {
    @StateObject private var openDotaService = OpenDotaService.shared
    @State private var heroStats: [PlayerHeroStats] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Your Hero Performance")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if isLoading {
                    ProgressView("Loading your hero data...")
                        .frame(height: 200)
                } else if !errorMessage.isEmpty {
                    VStack(spacing: 16) {
                        if errorMessage.contains("Please search and select") {
                            Image(systemName: "gamecontroller")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Select yourself first to see your hero performance")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("⚠️ Unable to load hero data")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button("Retry") {
                                loadHeroData()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                } else if !heroStats.isEmpty {
                    // Real hero data
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Top Performing Heroes")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(Array(heroStats.prefix(5).enumerated()), id: \.offset) { index, hero in
                                RealHeroStatsRow(heroStats: hero)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Real hero recommendations based on user data
                    RealHeroRecommendationsView(heroStats: heroStats)
                } else {
                    Text("No hero data available")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                Spacer()
            }
        }
        .onAppear {
            loadHeroData()
        }
    }
    
    private func loadHeroData() {
        guard let currentAccountId = UserDefaults.standard.object(forKey: "currentPlayerAccountId") as? Int64 else {
            errorMessage = "Please search and select a player first"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        openDotaService.getPlayerHeroes(accountId: currentAccountId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.errorMessage = "Failed to load hero data: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                },
                receiveValue: { heroes in
                    // Filter meaningful hero data (at least 3 games) and sort by game count
                    let filteredHeroes = heroes
                        .filter { $0.games >= 3 }  // Show only heroes with at least 3 games
                        .sorted { $0.games > $1.games }  // Sort by game count descending
                        .prefix(10)  // Show only top 10
                    
                    self.heroStats = Array(filteredHeroes)
                    self.isLoading = false
                    
                    print("🎮 Filtered hero stats: \(self.heroStats.count) heroes with games >= 3")
                    for hero in self.heroStats.prefix(3) {
                        let heroName = HeroService.shared.getHeroName(heroId: hero.heroId)
                        print("  - \(heroName): \(hero.games) games, \(Int(hero.winRate * 100))% WR")
                    }
                }
            )
            .store(in: &cancellables)
    }
}

struct HeroStatsRow: View {
    let heroName: String
    let games: Int
    let winRate: Int
    let avgScore: Int
    let avgKDA: Double
    let suggestion: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(heroName)
                    .font(.headline)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(avgScore)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(getScoreColor(Double(avgScore)))
                    Text("Avg Score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("\(games) games")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(winRate)% WR")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(String(format: "%.1f", avgKDA)) KDA")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Text("💡 " + suggestion)
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
    
    private func getScoreColor(_ score: Double) -> Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .yellow
        } else {
            return .red
        }
    }
}

struct HeroRecommendationsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hero Recommendations")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                RecommendationCard(
                    title: "Try Support Heroes",
                    description: "Based on your game sense, try Crystal Maiden or Lion",
                    reason: "Your map awareness and team fight timing suggest support potential"
                )
                
                RecommendationCard(
                    title: "Master Invoker",
                    description: "Challenge yourself with this high-skill hero",
                    reason: "Your mechanics and item usage show readiness for complex heroes"
                )
            }
            .padding(.horizontal)
        }
    }
}

struct RecommendationCard: View {
    let title: String
    let description: String
    let reason: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.body)
            
            Text("Why: \(reason)")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Progress Report View
struct ProgressReportView: View {
    @StateObject private var openDotaService = OpenDotaService.shared
    @State private var recentMatches: [RecentMatch] = []
    @State private var heroStats: [PlayerHeroStats] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Progress Report")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if isLoading {
                    ProgressView("Loading your progress data...")
                        .frame(height: 200)
                } else if !errorMessage.isEmpty {
                    VStack(spacing: 16) {
                        if errorMessage.contains("Please search and select") {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Select yourself first to see your progress")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("⚠️ Unable to load progress data")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button("Retry") {
                                loadProgressData()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                } else {
                    // Real progress data
                    RealWeeklySummaryView(matches: recentMatches)
                    RealGoalProgressView(matches: recentMatches, heroStats: heroStats)
                    RealAchievementsView(matches: recentMatches)
                }
                
                Spacer()
            }
        }
        .onAppear {
            loadProgressData()
        }
    }
    
    private func loadProgressData() {
        guard let currentAccountId = UserDefaults.standard.object(forKey: "currentPlayerAccountId") as? Int64 else {
            errorMessage = "Please search and select a player first"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        let matchesPublisher = openDotaService.getRecentMatches(accountId: currentAccountId, limit: 20)
        let heroesPublisher = openDotaService.getPlayerHeroes(accountId: currentAccountId)
        
        Publishers.CombineLatest(matchesPublisher, heroesPublisher)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.errorMessage = "Failed to load progress data: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                },
                receiveValue: { matches, heroes in
                    self.recentMatches = matches
                    
                    // Filter meaningful hero data (at least 3 games) and sort by game count
                    let filteredHeroes = heroes
                        .filter { $0.games >= 3 }  // Show only heroes with at least 3 games
                        .sorted { $0.games > $1.games }  // Sort by game count descending
                        .prefix(10)  // Show only top 10
                    
                    self.heroStats = Array(filteredHeroes)
                    self.isLoading = false
                    
                    print("📊 Progress filtered hero stats: \(self.heroStats.count) heroes with games >= 3")
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Real Weekly Summary View
struct RealWeeklySummaryView: View {
    let matches: [RecentMatch]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Performance")
                .font(.headline)
            
            VStack(spacing: 8) {
                ProgressSummaryItem(
                    title: "Matches Played", 
                    value: "\(matches.count) games", 
                    description: "Last 20 matches"
                )
                ProgressSummaryItem(
                    title: "Win Rate", 
                    value: "\(Int(calculateWinRate() * 100))%", 
                    description: winRateDescription()
                )
                ProgressSummaryItem(
                    title: "Average KDA", 
                    value: String(format: "%.1f", calculateAverageKDA()), 
                    description: kdaDescription()
                )
                ProgressSummaryItem(
                    title: "Focus Area", 
                    value: getFocusArea(), 
                    description: getFocusDescription()
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func calculateWinRate() -> Double {
        return PlayerStatsCalculator.calculateWinRate(from: matches)
    }
    
    private func calculateAverageKDA() -> Double {
        return KDACalculator.calculateAverageKDA(from: matches)
    }
    
    private func winRateDescription() -> String {
        let winRate = calculateWinRate()
        if winRate >= 0.6 {
            return "Excellent performance!"
        } else if winRate >= 0.5 {
            return "Solid win rate"
        } else {
            return "Room for improvement"
        }
    }
    
    private func kdaDescription() -> String {
        let kda = calculateAverageKDA()
        if kda >= 3.0 {
            return "Outstanding KDA"
        } else if kda >= 2.0 {
            return "Good performance"
        } else {
            return "Focus on survival"
        }
    }
    
    private func getFocusArea() -> String {
        let avgDeaths = matches.isEmpty ? 0 : matches.reduce(into: 0) { $0 += $1.deaths } / matches.count
        let avgKills = matches.isEmpty ? 0 : matches.reduce(into: 0) { $0 += $1.kills } / matches.count
        
        if avgDeaths > 8 {
            return "Survival"
        } else if avgKills < 5 {
            return "Impact"
        } else {
            return "Consistency"
        }
    }
    
    private func getFocusDescription() -> String {
        let avgDeaths = matches.isEmpty ? 0 : matches.reduce(into: 0) { $0 += $1.deaths } / matches.count
        let avgKills = matches.isEmpty ? 0 : matches.reduce(into: 0) { $0 += $1.kills } / matches.count
        
        if avgDeaths > 8 {
            return "Avg \(avgDeaths) deaths - be more careful"
        } else if avgKills < 5 {
            return "Avg \(avgKills) kills - be more aggressive"
        } else {
            return "Maintain current playstyle"
        }
    }
}

struct WeeklySummaryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week's Performance")
                .font(.headline)
            
            VStack(spacing: 8) {
                ProgressSummaryItem(title: "Matches Played", value: "23 games", description: "+3 from last week")
                ProgressSummaryItem(title: "Average Score", value: "76 points", description: "+4 improvement")
                ProgressSummaryItem(title: "Main Improvement", value: "Last-hitting", description: "From 5.2 to 6.1 CS/min")
                ProgressSummaryItem(title: "Focus Area", value: "Map awareness", description: "Deaths slightly increased")
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ProgressSummaryItem: View {
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Text(description)
                .font(.caption)
                .foregroundColor(.blue)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Real Goal Progress View
struct RealGoalProgressView: View {
    let matches: [RecentMatch]
    let heroStats: [PlayerHeroStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Progress")
                .font(.headline)
            
            GoalProgressBar(
                title: "Maintain KDA > 2.5", 
                progress: getKDAProgress(), 
                target: getKDATarget()
            )
            GoalProgressBar(
                title: "Achieve Win Rate > 60%", 
                progress: getWinRateProgress(), 
                target: getWinRateTarget()
            )
            GoalProgressBar(
                title: "Improve Consistency", 
                progress: getConsistencyProgress(), 
                target: getConsistencyTarget()
            )
            GoalProgressBar(
                title: "Master Heroes", 
                progress: getHeroMasteryProgress(), 
                target: getHeroMasteryTarget()
            )
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func getKDAProgress() -> Double {
        guard !matches.isEmpty else { return 0.0 }
        let avgKDA = matches.reduce(into: 0.0) { total, match in
            let kda = match.deaths > 0 ? (Double(match.kills + match.assists) / Double(match.deaths)) : Double(match.kills + match.assists)
            total += kda
        } / Double(matches.count)
        
        return min(avgKDA / 2.5, 1.0)
    }
    
    private func getKDATarget() -> String {
        let avgKDA = matches.reduce(into: 0.0) { total, match in
            let kda = match.deaths > 0 ? (Double(match.kills + match.assists) / Double(match.deaths)) : Double(match.kills + match.assists)
            total += kda
        } / Double(matches.count)
        
        return String(format: "Current: %.1f", avgKDA)
    }
    
    private func getWinRateProgress() -> Double {
        guard !matches.isEmpty else { return 0.0 }
        let wins = matches.filter { match in
            (match.playerSlot < 5 && match.radiantWin) || (match.playerSlot >= 5 && !match.radiantWin)
        }.count
        let winRate = Double(wins) / Double(matches.count)
        return min(winRate / 0.6, 1.0)
    }
    
    private func getWinRateTarget() -> String {
        let wins = matches.filter { match in
            (match.playerSlot < 5 && match.radiantWin) || (match.playerSlot >= 5 && !match.radiantWin)
        }.count
        let winRate = Double(wins) / Double(matches.count)
        return String(format: "Current: %.0f%%", winRate * 100)
    }
    
    private func getConsistencyProgress() -> Double {
        guard matches.count >= 5 else { return 0.0 }
        
        let recentMatches = Array(matches.prefix(5))
        let kdas = recentMatches.map { match in
            match.deaths > 0 ? (Double(match.kills + match.assists) / Double(match.deaths)) : Double(match.kills + match.assists)
        }
        
        // Calculate standard deviation (lower is better)
        let mean = kdas.reduce(0, +) / Double(kdas.count)
        let variance = kdas.map { pow($0 - mean, 2) }.reduce(0, +) / Double(kdas.count)
        let stdDev = sqrt(variance)
        
        // Convert to progress (less variance = higher progress)
        return max(0.0, min(1.0, 1.0 - (stdDev / 3.0)))
    }
    
    private func getConsistencyTarget() -> String {
        let recentMatches = Array(matches.prefix(5))
        let wins = recentMatches.filter { match in
            (match.playerSlot < 5 && match.radiantWin) || (match.playerSlot >= 5 && !match.radiantWin)
        }.count
        return "Last 5: \(wins) wins"
    }
    
    private func getHeroMasteryProgress() -> Double {
        let goodHeroes = heroStats.filter { $0.winRate >= 0.6 && $0.games >= 5 }.count
        return min(Double(goodHeroes) / 3.0, 1.0)  // Goal: 3 mastered heroes
    }
    
    private func getHeroMasteryTarget() -> String {
        let goodHeroes = heroStats.filter { $0.winRate >= 0.6 && $0.games >= 5 }.count
        return "\(goodHeroes) of 3 mastered"
    }
}

struct GoalProgressView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Progress")
                .font(.headline)
            
            GoalProgressBar(title: "Maintain KDA > 2.5", progress: 0.8, target: "80% achieved")
            GoalProgressBar(title: "Achieve GPM > 500", progress: 0.6, target: "60% achieved")
            GoalProgressBar(title: "Win rate > 70%", progress: 0.9, target: "90% achieved")
            GoalProgressBar(title: "Master 5 heroes", progress: 0.4, target: "2 of 5 mastered")
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct GoalProgressBar: View {
    let title: String
    let progress: Double
    let target: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                
                Spacer()
                
                Text(target)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: getProgressColor(progress)))
        }
    }
    
    private func getProgressColor(_ progress: Double) -> Color {
        if progress >= 0.8 {
            return .green
        } else if progress >= 0.5 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Real Achievements View
struct RealAchievementsView: View {
    let matches: [RecentMatch]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Achievements")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(generateRealAchievements(), id: \.title) { achievement in
                    AchievementBadge(
                        icon: achievement.icon,
                        title: achievement.title,
                        description: achievement.description,
                        date: achievement.date,
                        color: achievement.color
                    )
                }
                
                if generateRealAchievements().isEmpty {
                    Text("Play more matches to unlock achievements!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func generateRealAchievements() -> [Achievement] {
        var achievements: [Achievement] = []
        
        // Check for winning streak
        if let winStreak = getWinningStreak(), winStreak >= 3 {
            achievements.append(Achievement(
                icon: "star.fill",
                title: "Winning Streak",
                description: "Achieved \(winStreak) wins in a row",
                date: "Recent",
                color: .yellow
            ))
        }
        
        // Check for high KDA matches
        let highKDAMatches = matches.filter { match in
            let kda = match.deaths > 0 ? (Double(match.kills + match.assists) / Double(match.deaths)) : Double(match.kills + match.assists)
            return kda >= 5.0
        }
        
        if !highKDAMatches.isEmpty {
            let bestKDA = highKDAMatches.max { match1, match2 in
                let kda1 = match1.deaths > 0 ? (Double(match1.kills + match1.assists) / Double(match1.deaths)) : Double(match1.kills + match1.assists)
                let kda2 = match2.deaths > 0 ? (Double(match2.kills + match2.assists) / Double(match2.deaths)) : Double(match2.kills + match2.assists)
                return kda1 < kda2
            }
            
            if let bestMatch = bestKDA {
                let kda = bestMatch.deaths > 0 ? (Double(bestMatch.kills + bestMatch.assists) / Double(bestMatch.deaths)) : Double(bestMatch.kills + bestMatch.assists)
                achievements.append(Achievement(
                    icon: "bolt.fill",
                    title: "Outstanding Performance",
                    description: String(format: "Achieved %.1f KDA", kda),
                    date: "Recent",
                    color: .blue
                ))
            }
        }
        
        // Check for consistent performance
        let wins = matches.filter { match in
            (match.playerSlot < 5 && match.radiantWin) || (match.playerSlot >= 5 && !match.radiantWin)
        }.count
        let winRate = Double(wins) / Double(matches.count)
        
        if winRate >= 0.7 && matches.count >= 10 {
            achievements.append(Achievement(
                icon: "crown.fill",
                title: "Consistent Winner",
                description: String(format: "%.0f%% win rate over last %d matches", winRate * 100, matches.count),
                date: "Recent",
                color: .purple
            ))
        }
        
        return achievements
    }
    
    private func getWinningStreak() -> Int? {
        guard !matches.isEmpty else { return nil }
        
        var currentStreak = 0
        var maxStreak = 0
        
        for match in matches.reversed() { // Check from oldest to newest
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

struct Achievement {
    let icon: String
    let title: String
    let description: String
    let date: String
    let color: Color
}

struct AchievementsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Achievements")
                .font(.headline)
            
            VStack(spacing: 8) {
                AchievementBadge(
                    icon: "star.fill",
                    title: "Winning Streak",
                    description: "Achieved 5 wins in a row",
                    date: "2 days ago",
                    color: .yellow
                )
                
                AchievementBadge(
                    icon: "leaf.fill",
                    title: "Farming Master",
                    description: "Over 400 CS in a single match",
                    date: "1 week ago",
                    color: .green
                )
                
                AchievementBadge(
                    icon: "bolt.fill",
                    title: "Team Fight MVP",
                    description: "KDA over 10 in a match",
                    date: "2 weeks ago",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct AchievementBadge: View {
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
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
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

// MARK: - Real Trend Chart View
struct RealTrendChartView: View {
    let matches: [RecentMatch]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last \(matches.count) Matches Results")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(matches.enumerated()), id: \.offset) { index, match in
                        let isWin = (match.playerSlot < 5 && match.radiantWin) || (match.playerSlot >= 5 && !match.radiantWin)
                        
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isWin ? Color.green : Color.red)
                                .frame(width: 24, height: 40)
                            
                            Text("\(index + 1)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            HStack {
                Text("🟢 Win")
                    .font(.caption)
                    .foregroundColor(.green)
                Spacer()
                Text("🔴 Loss")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Real Improvement Areas View  
struct RealImprovementAreasView: View {
    let matches: [RecentMatch]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Areas Based on Recent Matches")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(generateRealImprovementAreas(), id: \.title) { area in
                    FocusAreaCard(
                        title: area.title,
                        description: area.description,
                        progress: area.progress,
                        priority: area.priority
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func generateRealImprovementAreas() -> [RealImprovementArea] {
        guard !matches.isEmpty else {
            return [
                RealImprovementArea(
                    title: "Get More Match Data",
                    description: "Play more matches to get personalized recommendations",
                    progress: 0.1,
                    priority: .medium
                )
            ]
        }
        
        var areas: [RealImprovementArea] = []
        
        // Calculate death rate
        let avgDeaths = Double(matches.map { $0.deaths }.reduce(0, +)) / Double(matches.count)
        if avgDeaths > 5 {
            areas.append(RealImprovementArea(
                title: "Reduce Deaths",
                description: "Averaging \(String(format: "%.1f", avgDeaths)) deaths per game. Focus on positioning",
                progress: max(0.1, (10 - avgDeaths) / 10),
                priority: avgDeaths > 8 ? .high : .medium
            ))
        }
        
        // Calculate KDA performance
        let avgKDA = matches.map { match in
            Double(match.kills + match.assists) / max(Double(match.deaths), 1.0)
        }.reduce(0, +) / Double(matches.count)
        
        if avgKDA < 2.0 {
            areas.append(RealImprovementArea(
                title: "Improve KDA Ratio",
                description: "Current KDA: \(String(format: "%.1f", avgKDA)). Focus on kills and assists",
                progress: avgKDA / 4.0, // Scale to 0-1
                priority: avgKDA < 1.0 ? .high : .medium
            ))
        }
        
        // Calculate win rate
        let wins = matches.filter { match in
            (match.playerSlot < 5 && match.radiantWin) || (match.playerSlot >= 5 && !match.radiantWin)
        }.count
        let winRate = Double(wins) / Double(matches.count)
        
        if winRate < 0.6 {
            areas.append(RealImprovementArea(
                title: "Increase Win Rate",
                description: "Current win rate: \(Int(winRate * 100))%. Focus on game impact",
                progress: winRate,
                priority: winRate < 0.4 ? .high : .medium
            ))
        }
        
        // If no specific issues, add a general improvement area
        if areas.isEmpty {
            areas.append(RealImprovementArea(
                title: "Maintain Performance",
                description: "Strong recent performance! Keep focusing on consistency",
                progress: 0.8,
                priority: .low
            ))
        }
        
        return Array(areas.prefix(3))
    }
}

struct RealImprovementArea {
    let title: String
    let description: String
    let progress: Double
    let priority: Priority
}

// MARK: - Real Hero Stats Row
struct RealHeroStatsRow: View {
    let heroStats: PlayerHeroStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(HeroService.shared.getHeroName(heroId: heroStats.heroId))
                    .font(.headline)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(heroStats.winRate * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(getWinRateColor(heroStats.winRate))
                    Text("Win Rate")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("\(heroStats.games) games")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(heroStats.win)W-\(heroStats.games - heroStats.win)L")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                if heroStats.games >= 5 {
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Experienced")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Text("💡 " + generateHeroSuggestion(heroStats: heroStats))
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
    
    private func getWinRateColor(_ winRate: Double) -> Color {
        if winRate >= 0.7 { return .green }
        else if winRate >= 0.5 { return .orange }
        else { return .red }
    }
    
    private func generateHeroSuggestion(heroStats: PlayerHeroStats) -> String {
        if heroStats.winRate >= 0.7 {
            return "Excellent performance! Keep playing this hero"
        } else if heroStats.winRate >= 0.5 {
            return "Good hero for you. Practice more to improve"
        } else if heroStats.games < 5 {
            return "Play more games to get reliable stats"
        } else {
            return "Consider focusing on other heroes"
        }
    }
}

// MARK: - Real Hero Recommendations
struct RealHeroRecommendationsView: View {
    let heroStats: [PlayerHeroStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations Based on Your Play")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(generateRealRecommendations(), id: \.title) { rec in
                    RecommendationCard(
                        title: rec.title,
                        description: rec.description,
                        reason: rec.reason
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func generateRealRecommendations() -> [HeroRecommendation] {
        var recommendations: [HeroRecommendation] = []
        
        if !heroStats.isEmpty {
            let bestHero = heroStats.first!
            let bestHeroName = HeroService.shared.getHeroName(heroId: bestHero.heroId)
            
            if bestHero.winRate >= 0.7 {
                recommendations.append(HeroRecommendation(
                    title: "Keep Playing \(bestHeroName)",
                    description: "Your best performing hero with \(Int(bestHero.winRate * 100))% win rate",
                    reason: "High success rate shows you understand this hero well"
                ))
            }
            
            if heroStats.count >= 3 {
                recommendations.append(HeroRecommendation(
                    title: "Expand Your Hero Pool",
                    description: "Try learning 1-2 new heroes in unranked games",
                    reason: "Having more heroes gives you better drafting flexibility"
                ))
            }
            
            let lowWinRateHeroes = heroStats.filter { $0.winRate < 0.4 && $0.games >= 5 }
            if !lowWinRateHeroes.isEmpty {
                recommendations.append(HeroRecommendation(
                    title: "Review Struggling Heroes",
                    description: "Consider avoiding heroes with very low win rates",
                    reason: "Focus on heroes that match your playstyle better"
                ))
            }
        }
        
        if recommendations.isEmpty {
            recommendations.append(HeroRecommendation(
                title: "Start Building Hero Stats",
                description: "Play ranked matches to build your hero performance data",
                reason: "More games = better recommendations"
            ))
        }
        
        return recommendations
    }
    

}

struct HeroRecommendation {
    let title: String
    let description: String
    let reason: String
}

#Preview {
    AnalysisView()
}
