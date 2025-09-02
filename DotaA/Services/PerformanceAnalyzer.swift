//
//  PerformanceAnalyzer.swift
//  DotaA
//
//  Created by Wentao Guo on 11/08/25.
//

import Foundation

class PerformanceAnalyzer: ObservableObject {
    static let shared = PerformanceAnalyzer()
    
    private init() {}
    
    // MARK: - Main Analysis Method
    func analyzePerformance(
        match: Match,
        targetPlayer: Player,
        heroName: String,
        playerRank: Int? = nil
    ) -> PerformanceAnalysis {
        
        let matchDurationMinutes = Double(match.duration) / 60.0
        
        // Calculate individual metric scores
        let farmingScore = calculateFarmingScore(player: targetPlayer, duration: matchDurationMinutes, rank: playerRank)
        let combatScore = calculateCombatScore(player: targetPlayer, duration: matchDurationMinutes)
        let economyScore = calculateEconomyScore(player: targetPlayer, duration: matchDurationMinutes)
        let itemizationScore = calculateItemizationScore(player: targetPlayer, heroName: heroName)
        let mapAwarenessScore = calculateMapAwarenessScore(player: targetPlayer, duration: matchDurationMinutes)
        
        // Create key metrics
        let keyMetrics = KeyMetrics(
            farmingEfficiency: farmingScore,
            combatPerformance: combatScore,
            economyScore: economyScore,
            itemizationScore: itemizationScore,
            mapAwareness: mapAwarenessScore
        )
        
        // Calculate overall score (weighted average)
        let overallScore = calculateOverallScore(metrics: keyMetrics)
        
        // Identify strengths and weaknesses
        let strengths = identifyStrengths(metrics: keyMetrics)
        let weaknesses = identifyWeaknesses(metrics: keyMetrics)
        
        // Generate recommendations
        let recommendations = generateRecommendations(
            player: targetPlayer,
            duration: matchDurationMinutes,
            metrics: keyMetrics,
            heroName: heroName
        )
        
        // Create benchmark comparison
        let benchmarkComparison = createBenchmarkComparison(
            player: targetPlayer,
            duration: matchDurationMinutes,
            playerRank: playerRank
        )
        
        return PerformanceAnalysis(
            matchId: match.matchId,
            playerSlot: targetPlayer.playerSlot,
            overallScore: overallScore,
            strengths: strengths,
            weaknesses: weaknesses,
            recommendations: recommendations,
            benchmarkComparison: benchmarkComparison,
            keyMetrics: keyMetrics
        )
    }
    
    // MARK: - Farming Efficiency Score
    private func calculateFarmingScore(player: Player, duration: Double, rank: Int?) -> Double {
        let lastHitsPerMin = Double(player.lastHits) / duration
        let deniesPerMin = Double(player.denies) / duration
        
        // Get rank-adjusted benchmarks
        let rankTier = getRankTier(rank: rank)
        let targetLHPM = GameConstants.farmingBenchmarks[rankTier] ?? 6.0
        let excellentLHPM = targetLHPM * 1.3
        let goodLHPM = targetLHPM * 1.1
        
        var score: Double = 0
        
        // Last hits score (75% of farming score)
        if lastHitsPerMin >= excellentLHPM {
            score += 75
        } else if lastHitsPerMin >= goodLHPM {
            score += 75 * (lastHitsPerMin / excellentLHPM)
        } else if lastHitsPerMin >= targetLHPM {
            score += 60 * (lastHitsPerMin / goodLHPM)
        } else {
            score += 40 * (lastHitsPerMin / targetLHPM)
        }
        
        // Denies score (25% of farming score)
        let targetDeniesPerMin: Double = 1.5
        let deniesScore = min(25, (deniesPerMin / targetDeniesPerMin) * 25)
        score += deniesScore
        
        return min(100, score)
    }
    
    // MARK: - Combat Performance Score
    private func calculateCombatScore(player: Player, duration: Double) -> Double {
        let kda = player.kda
        let killsPerMin = Double(player.kills) / duration
        let deathsPerMin = Double(player.deaths) / duration
        let heroDamagePerMin = Double(player.heroDamage) / duration
        
        var score: Double = 0
        
        // KDA Score (40%)
        if kda >= 4.0 {
            score += 40
        } else if kda >= 3.0 {
            score += 38
        } else if kda >= 2.5 {
            score += 35
        } else if kda >= 2.0 {
            score += 32
        } else if kda >= 1.5 {
            score += 28
        } else if kda >= 1.0 {
            score += 24
        } else {
            score += 15
        }
        
        // Kill participation (30%)
        if killsPerMin >= 0.6 {
            score += 30
        } else if killsPerMin >= 0.4 {
            score += 25
        } else if killsPerMin >= 0.3 {
            score += 20
        } else {
            score += 15 * (killsPerMin / 0.3)
        }
        
        // Survival score (30%)
        if deathsPerMin <= 0.15 {
            score += 30
        } else if deathsPerMin <= 0.25 {
            score += 25
        } else if deathsPerMin <= 0.35 {
            score += 20
        } else if deathsPerMin <= 0.5 {
            score += 15
        } else {
            score += 10
        }
        
        return min(100, score)
    }
    
    // MARK: - Economy Score
    private func calculateEconomyScore(player: Player, duration: Double) -> Double {
        let gpm = Double(player.goldPerMin)
        let xpm = Double(player.xpPerMin)
        let goldEfficiency = Double(player.goldSpent) / Double(player.gold + player.goldSpent)
        
        var score: Double = 0
        
        // GPM Score (50%)
        if gpm >= 650 {
            score += 50
        } else if gpm >= 550 {
            score += 45
        } else if gpm >= 450 {
            score += 40
        } else if gpm >= 350 {
            score += 30
        } else {
            score += 20 * (gpm / 350)
        }
        
        // XPM Score (30%)
        if xpm >= 650 {
            score += 30
        } else if xpm >= 550 {
            score += 25
        } else if xpm >= 450 {
            score += 20
        } else {
            score += 15 * (xpm / 450)
        }
        
        // Gold efficiency (20%)
        if goldEfficiency >= 0.9 {
            score += 20
        } else {
            score += 20 * goldEfficiency
        }
        
        return min(100, score)
    }
    
    // MARK: - Itemization Score
    private func calculateItemizationScore(player: Player, heroName: String) -> Double {
        let items = [player.item0, player.item1, player.item2, player.item3, player.item4, player.item5]
        let nonEmptyItems = items.filter { $0 > 0 }
        
        var score: Double = 0
        
        // Item slot utilization (30%)
        score += Double(nonEmptyItems.count) * 5 // 6 items = 30 points
        
        // Core item presence (40%)
        let hasCoreItems = checkForCoreItems(items: nonEmptyItems, heroName: heroName)
        score += hasCoreItems ? 40 : 20
        
        // Item diversity (15%)
        let itemCategories = categorizeItems(items: nonEmptyItems)
        score += min(15, Double(itemCategories.count) * 3)
        
        // Situational items (15%)
        let hasSituationalItems = checkForSituationalItems(items: nonEmptyItems)
        score += hasSituationalItems ? 15 : 5
        
        return min(100, score)
    }
    
    // MARK: - Map Awareness Score
    private func calculateMapAwarenessScore(player: Player, duration: Double) -> Double {
        let deathsPerMin = Double(player.deaths) / duration
        
        var score: Double = 0
        
        // Death frequency (primary indicator of map awareness)
        if deathsPerMin <= 0.15 {
            score += 60 // Excellent awareness
        } else if deathsPerMin <= 0.25 {
            score += 50
        } else if deathsPerMin <= 0.35 {
            score += 40
        } else if deathsPerMin <= 0.5 {
            score += 30
        } else {
            score += 20
        }
        
        // Participation in team fights (assists relative to team kills)
        let assistScore = min(40, Double(player.assists) * 2)
        score += assistScore
        
        return min(100, score)
    }
    
    // MARK: - Overall Score Calculation
    private func calculateOverallScore(metrics: KeyMetrics) -> Double {
        // Weighted average of all metrics
        let weights: [Double] = [0.25, 0.25, 0.20, 0.15, 0.15] // farming, combat, economy, items, map awareness
        let scores = [
            metrics.farmingEfficiency,
            metrics.combatPerformance,
            metrics.economyScore,
            metrics.itemizationScore,
            metrics.mapAwareness
        ]
        
        return zip(weights, scores).reduce(0) { result, pair in
            result + (pair.0 * pair.1)
        }
    }
    
    // MARK: - Identify Strengths
    private func identifyStrengths(metrics: KeyMetrics) -> [String] {
        var strengths: [String] = []
        
        if metrics.farmingEfficiency >= 80 {
            strengths.append("Excellent farming efficiency")
        }
        
        if metrics.combatPerformance >= 80 {
            strengths.append("Outstanding combat performance")
        }
        
        if metrics.economyScore >= 80 {
            strengths.append("Strong economic development")
        }
        
        if metrics.itemizationScore >= 80 {
            strengths.append("Smart item choices")
        }
        
        if metrics.mapAwareness >= 80 {
            strengths.append("Great map awareness")
        }
        
        // If no excellent scores, identify good ones
        if strengths.isEmpty {
            if metrics.farmingEfficiency >= 65 {
                strengths.append("Solid farming fundamentals")
            }
            if metrics.combatPerformance >= 65 {
                strengths.append("Good team fight participation")
            }
            if metrics.economyScore >= 65 {
                strengths.append("Decent economic growth")
            }
        }
        
        return strengths
    }
    
    // MARK: - Identify Weaknesses
    private func identifyWeaknesses(metrics: KeyMetrics) -> [String] {
        var weaknesses: [String] = []
        
        if metrics.farmingEfficiency < 60 {
            weaknesses.append("Farming efficiency needs improvement")
        }
        
        if metrics.combatPerformance < 60 {
            weaknesses.append("Combat effectiveness could be better")
        }
        
        if metrics.economyScore < 60 {
            weaknesses.append("Economic development is lagging")
        }
        
        if metrics.itemizationScore < 60 {
            weaknesses.append("Item choices need optimization")
        }
        
        if metrics.mapAwareness < 60 {
            weaknesses.append("Map awareness requires attention")
        }
        
        return weaknesses
    }
    
    // MARK: - Generate Recommendations
    private func        generateRecommendations(
        player: Player,
        duration: Double,
        metrics: KeyMetrics,
        heroName: String
    ) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        let lastHitsPerMin = Double(player.lastHits) / duration
        
        // Farming recommendations
        if metrics.farmingEfficiency < 70 {
            let targetCS = Int(6.0 * duration)
            recommendations.append(Recommendation(
                category: .farming,
                title: "Improve Last-Hit Efficiency",
                description: "Current CS per minute: \(String(format: "%.1f", lastHitsPerMin)). Aim for 6+ CS per minute.",
                priority: lastHitsPerMin < 4.0 ? .high : .medium,
                actionable: "Practice last-hitting in demo mode. Focus on timing and positioning.",
                targetValue: "\(targetCS) total CS in a \(Int(duration))-minute game"
            ))
        }
        
        // Combat recommendations
        if metrics.combatPerformance < 70 {
            if player.kda < 2.0 {
                recommendations.append(Recommendation(
                    category: .positioning,
                    title: "Improve Survival and KDA",
                    description: "Current KDA: \(String(format: "%.2f", player.kda)). Focus on positioning and decision-making.",
                    priority: .high,
                    actionable: "Stay further back in fights. Only engage when you have backup or clear advantage.",
                    targetValue: "KDA ratio above 2.0"
                ))
            }
        }
        
        // Economy recommendations
        if metrics.economyScore < 70 {
            if player.goldPerMin < 450 {
                recommendations.append(Recommendation(
                    category: .economy,
                    title: "Boost Economic Efficiency",
                    description: "Current GPM: \(player.goldPerMin). Target 450+ GPM for consistent impact.",
                    priority: .medium,
                    actionable: "Balance farming and fighting. Use efficient farming patterns between fights.",
                    targetValue: "450+ GPM"
                ))
            }
        }
        
        // Map awareness recommendations
        if metrics.mapAwareness < 70 {
            let deathsPerMin = Double(player.deaths) / duration
            if deathsPerMin > 0.3 {
                recommendations.append(Recommendation(
                    category: .mapAwareness,
                    title: "Reduce Unnecessary Deaths",
                    description: "Dying \(String(format: "%.1f", deathsPerMin)) times per minute. Improve map awareness.",
                    priority: .high,
                    actionable: "Check minimap every 3-5 seconds. Buy wards and avoid farming alone.",
                    targetValue: "Less than 5 deaths per game"
                ))
            }
        }
        
        return recommendations
    }
    
    // MARK: - Benchmark Comparison
    private func createBenchmarkComparison(
        player: Player,
        duration: Double,
        playerRank: Int?
    ) -> BenchmarkComparison {
        
        let rankTier = getRankTier(rank: playerRank)
        let benchmarkGPM = Double(GameConstants.gpmBenchmarks[rankTier] ?? 450)
        let benchmarkLHPM = GameConstants.farmingBenchmarks[rankTier] ?? 6.0
        
        let playerLHPM = Double(player.lastHits) / duration
        let playerGPM = Double(player.goldPerMin)
        
        let farmingEfficiency = (playerLHPM / benchmarkLHPM) * 100
        let economyEfficiency = (playerGPM / benchmarkGPM) * 100
        let fightParticipation = (player.kda / 2.0) * 100 // Assuming 2.0 as baseline
        
        return BenchmarkComparison(
            farmingEfficiency: farmingEfficiency,
            fightParticipation: fightParticipation,
            visionScore: 75.0, // Placeholder - would need ward data
            itemTimings: [:], // Would need detailed item timing analysis
            economyEfficiency: economyEfficiency
        )
    }
    
    // MARK: - Helper Methods
    private func getRankTier(rank: Int?) -> String {
        guard let rank = rank else { return "Archon" }
        
        switch rank {
        case 1...10: return "Herald"
        case 11...20: return "Guardian"
        case 21...30: return "Crusader"
        case 31...40: return "Archon"
        case 41...50: return "Legend"
        case 51...60: return "Ancient"
        case 61...70: return "Divine"
        case 71...80: return "Immortal"
        default: return "Archon"
        }
    }
    
    private func checkForCoreItems(items: [Int], heroName: String) -> Bool {
        // Simplified core item check - in real implementation, 
        // would have hero-specific core item databases
        let commonCoreItems = [1, 116, 152, 63] // Basic core items
        return items.contains { commonCoreItems.contains($0) }
    }
    
    private func categorizeItems(items: [Int]) -> Set<String> {
        // Simplified categorization
        var categories: Set<String> = []
        
        for item in items {
            switch item {
            case 1...50: categories.insert("Basic")
            case 51...100: categories.insert("Upgraded")
            case 101...200: categories.insert("Advanced")
            default: categories.insert("Luxury")
            }
        }
        
        return categories
    }
    
    private func checkForSituationalItems(items: [Int]) -> Bool {
        // Check for items that indicate good game sense
        let situationalItems = [116, 108, 152] // BKB, Pipe, etc.
        return items.contains { situationalItems.contains($0) }
    }
    
    // MARK: - Public Utility Methods
    func getScoreColor(score: Double) -> String {
        if score >= 80 {
            return "green"
        } else if score >= 60 {
            return "yellow"
        } else {
            return "red"
        }
    }
    
    func getScoreDescription(score: Double) -> String {
        switch score {
        case 90...100: return "Exceptional"
        case 80..<90: return "Excellent"
        case 70..<80: return "Good"
        case 60..<70: return "Average"
        case 50..<60: return "Below Average"
        case 40..<50: return "Needs Work"
        default: return "Requires Improvement"
        }
    }
    
    func getPerformanceGrade(score: Double) -> String {
        switch score {
        case 90...100: return "S+"
        case 85..<90: return "S"
        case 80..<85: return "A+"
        case 75..<80: return "A"
        case 70..<75: return "B+"
        case 65..<70: return "B"
        case 60..<65: return "C+"
        case 55..<60: return "C"
        case 50..<55: return "D+"
        default: return "D"
        }
    }
}
