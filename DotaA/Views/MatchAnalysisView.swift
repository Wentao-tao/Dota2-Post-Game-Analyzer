//
//  MatchAnalysisView.swift
//  DotaA
//
//  Created by Wentao Guo on 11/08/25.
//

import Combine
import SwiftData
import SwiftUI

struct MatchAnalysisView: View {

    let match: RecentMatch
    @StateObject private var openDotaService = OpenDotaService.shared
    @StateObject private var openAIService = OpenAIService.shared
    @StateObject private var analyzer = PerformanceAnalyzer.shared

    @State private var detailedMatch: Match?
    @State private var analysis: PerformanceAnalysis?
    @State private var aiAdvice: AICoachingResponse?
    @State private var heroName = "Loading..."
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Match Header
                MatchHeaderView(match: match, heroName: heroName)

                if isLoading {
                    LoadingView()
                } else if !errorMessage.isEmpty {
                    ErrorView(message: errorMessage) {
                        loadMatchAnalysis()
                    }
                } else if let detailedMatch = detailedMatch,
                    let targetPlayer = findTargetPlayer(in: detailedMatch),
                    let analysis = analysis
                {

                    // Performance Score
                    PerformanceScoreView(analysis: analysis)

                    // Key Metrics
                    KeyMetricsView(metrics: analysis.keyMetrics)

                    // Detailed Stats
                    DetailedStatsView(
                        player: targetPlayer, match: detailedMatch)

                    // AI Coaching Advice
                    if let aiAdvice = aiAdvice {
                        AICoachingView(advice: aiAdvice)
                    }

                    // Recommendations
                    if !analysis.recommendations.isEmpty {
                        RecommendationsView(
                            recommendations: analysis.recommendations)
                    }

                    // Share Button
                    ShareButton(
                        match: detailedMatch, player: targetPlayer,
                        analysis: analysis, heroName: heroName)
                }
            }
            .padding()
        }
        .navigationTitle("Match Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadHeroName()
            loadMatchAnalysis()

        }
    }

    private func loadHeroName() {
        openDotaService.getHeroName(heroId: match.heroId) { name in
            heroName = name
        }
    }

    private func loadMatchAnalysis() {
        isLoading = true
        errorMessage = ""

        openDotaService.getMatchDetails(matchId: match.matchId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        isLoading = false
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { detailedMatch in
                    self.detailedMatch = detailedMatch

                    guard let targetPlayer = findTargetPlayer(in: detailedMatch)
                    else {
                        isLoading = false
                        errorMessage = "Could not find player data"
                        return
                    }

                    // Perform analysis
                    let analysis = analyzer.analyzePerformance(
                        match: detailedMatch,
                        targetPlayer: targetPlayer,
                        heroName: heroName
                    )
                    self.analysis = analysis

                    // Generate AI advice
                    generateAIAdvice(
                        match: detailedMatch, player: targetPlayer,
                        analysis: analysis)

                }
            )
            .store(in: &cancellables)
    }

    private func findTargetPlayer(in detailedMatch: Match) -> Player? {
        return detailedMatch.players.first { player in
            player.playerSlot == match.playerSlot
        }
    }

    private func generateAIAdvice(
        match: Match, player: Player, analysis: PerformanceAnalysis
    ) {
        openAIService.generateMatchAnalysis(
            match: match,
            player: player,
            heroName: heroName,
            benchmarks: analysis.benchmarkComparison
        )
        .sink(
            receiveCompletion: { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    print("AI advice generation failed: \(error)")
                }
            },
            receiveValue: { advice in
                self.aiAdvice = advice
            }
        )
        .store(in: &cancellables)
    }
}

// MARK: - Match Header View
struct MatchHeaderView: View {
    let match: RecentMatch
    let heroName: String

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Win/Loss status
                HStack {
                    Circle()
                        .fill(match.isWin ? Color.green : Color.red)
                        .frame(width: 16, height: 16)
                    Text(match.isWin ? "Victory" : "Defeat")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(match.isWin ? .green : .red)
                }

                Spacer()

                Text(formatTimeAgo(timestamp: match.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Hero")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(heroName)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .center) {
                    Text("KDA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(match.kda)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDuration(seconds: match.duration))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }

    private func formatTimeAgo(timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatDuration(seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes) minutes"
    }
}

// MARK: - Performance Score View
struct PerformanceScoreView: View {
    let analysis: PerformanceAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview")
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                VStack(alignment: .leading) {
                    Text("Overall Score")
                        .font(.headline)
                    Text(
                        PerformanceAnalyzer.shared.getScoreDescription(
                            score: analysis.overallScore)
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: analysis.overallScore / 100)
                        .stroke(
                            getScoreColor(analysis.overallScore), lineWidth: 8
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    VStack {
                        Text("\(Int(analysis.overallScore))")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(
                            PerformanceAnalyzer.shared.getPerformanceGrade(
                                score: analysis.overallScore)
                        )
                        .font(.caption)
                        .fontWeight(.semibold)
                    }
                }
            }

            // Strengths and Weaknesses
            if !analysis.strengths.isEmpty {
                StrengthsView(strengths: analysis.strengths)
            }

            if !analysis.weaknesses.isEmpty {
                WeaknessesView(weaknesses: analysis.weaknesses)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
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

// MARK: - Key Metrics View
struct KeyMetricsView: View {
    let metrics: KeyMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Breakdown")
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 2),
                spacing: 12
            ) {
                MetricCard(
                    title: "Farming", score: metrics.farmingEfficiency,
                    icon: "leaf.fill")
                MetricCard(
                    title: "Combat", score: metrics.combatPerformance,
                    icon: "bolt.fill")
                MetricCard(
                    title: "Economy", score: metrics.economyScore,
                    icon: "dollarsign.circle.fill")
                MetricCard(
                    title: "Items", score: metrics.itemizationScore,
                    icon: "bag.fill")
                MetricCard(
                    title: "Map Awareness", score: metrics.mapAwareness,
                    icon: "eye.fill")
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct MetricCard: View {
    let title: String
    let score: Double
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(getScoreColor(score))
                .font(.title2)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(Int(score))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(getScoreColor(score))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
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

// MARK: - Strengths View
struct StrengthsView: View {
    let strengths: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Key Strengths")
                .font(.headline)
                .foregroundColor(.green)

            ForEach(strengths, id: \.self) { strength in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(strength)
                        .font(.body)
                }
            }
        }
    }
}

// MARK: - Weaknesses View
struct WeaknessesView: View {
    let weaknesses: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Areas for Improvement")
                .font(.headline)
                .foregroundColor(.orange)

            ForEach(weaknesses, id: \.self) { weakness in
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    Text(weakness)
                        .font(.body)
                }
            }
        }
    }
}

// MARK: - Detailed Stats View
struct DetailedStatsView: View {
    let player: Player
    let match: Match

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Match Statistics")
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 2),
                spacing: 12
            ) {
                StatCard(title: "Kills", value: "\(player.kills)", subtitle: "")
                StatCard(
                    title: "Deaths", value: "\(player.deaths)", subtitle: "")
                StatCard(
                    title: "Assists", value: "\(player.assists)", subtitle: "")
                StatCard(
                    title: "Last Hits", value: "\(player.lastHits)",
                    subtitle:
                        "Per min: \(String(format: "%.1f", Double(player.lastHits) / (Double(match.duration) / 60)))"
                )
                StatCard(
                    title: "GPM", value: "\(player.goldPerMin)",
                    subtitle: "Gold efficiency")
                StatCard(
                    title: "XPM", value: "\(player.xpPerMin)",
                    subtitle: "Experience rate")
                StatCard(
                    title: "Hero Damage",
                    value: formatNumber(player.heroDamage), subtitle: "")
                StatCard(
                    title: "Tower Damage",
                    value: formatNumber(player.towerDamage), subtitle: "")
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

// MARK: - AI Coaching View
struct AICoachingView: View {
    let advice: AICoachingResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Coach Analysis")
                .font(.title2)
                .fontWeight(.bold)

            // Overall analysis
            Text(advice.overallAnalysis)
                .font(.body)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

            // Key strengths
            if !advice.keyStrengths.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What you did well:")
                        .font(.headline)
                        .foregroundColor(.green)

                    ForEach(
                        Array(advice.keyStrengths.enumerated()), id: \.offset
                    ) { index, strength in
                        HStack(alignment: .top) {
                            Text("✓")
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text(strength)
                                .font(.body)
                        }
                    }
                }
            }

            // Next match goals
            if !advice.nextMatchGoals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goals for next match:")
                        .font(.headline)
                        .foregroundColor(.blue)

                    ForEach(advice.nextMatchGoals, id: \.self) { goal in
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.blue)
                            Text(goal)
                                .font(.body)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Recommendations View
struct RecommendationsView: View {
    let recommendations: [Recommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Action Items")
                .font(.title2)
                .fontWeight(.bold)

            ForEach(Array(recommendations.enumerated()), id: \.offset) {
                index, recommendation in

                RecommendationCardA(recommendation: recommendation)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationCardA: View {
    let recommendation: Recommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recommendation.title)
                    .font(.headline)

                Spacer()

                Text(recommendation.priority.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        getPriorityColor(recommendation.priority).opacity(0.2)
                    )
                    .foregroundColor(getPriorityColor(recommendation.priority))
                    .cornerRadius(6)
            }

            Text(recommendation.description)
                .font(.body)
                .foregroundColor(.secondary)

            Text("💡 " + recommendation.actionable)
                .font(.body)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

            if let target = recommendation.targetValue {
                Text("Target: \(target)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }

    private func getPriorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

// MARK: - Share Button
struct ShareButton: View {
    let match: Match
    let player: Player
    let analysis: PerformanceAnalysis
    let heroName: String

    var body: some View {
        Menu("Share Performance") {
            Button("Share as Image") {
                ShareService.shared.sharePerformanceCard(
                    match: match,
                    player: player,
                    analysis: analysis,
                    heroName: heroName,
                    from: nil
                )
            }

            Button("Share as Text") {
                shareResults()
            }

            Button("Save to Photos") {
                ShareService.shared.savePerformanceCard(
                    match: match,
                    player: player,
                    analysis: analysis,
                    heroName: heroName
                ) { success, message in
                    
                    if success {
                        print("sucess")
                    } else {
                        print("❌ fail: \(message ?? "error")")
                    }
                }
            }
        }
    }

    private func shareResults() {
        let shareText = """
            🎮 My Dota 2 Match Analysis
            Hero: \(heroName)
            Overall Score: \(Int(analysis.overallScore))/100 (\(PerformanceAnalyzer.shared.getPerformanceGrade(score: analysis.overallScore)))
            KDA: \(player.kills)/\(player.deaths)/\(player.assists)
            GPM: \(player.goldPerMin)

            Get your AI coaching with Dota 2 Post-Game Analyzer!
            """

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first
            as? UIWindowScene,
            let window = windowScene.windows.first
        {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing match data...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
    }
}

#Preview {
    MatchAnalysisView(
        match: RecentMatch(
            matchId: 123_456_789,
            playerSlot: 0,
            radiantWin: true,
            duration: 2400,
            gameMode: 1,
            lobbyType: 0,
            heroId: 1,
            startTime: Int64(Date().timeIntervalSince1970),
            version: nil,
            kills: 10,
            deaths: 3,
            assists: 15,
            averageRank: nil,
            partySize: nil
        ))
}
