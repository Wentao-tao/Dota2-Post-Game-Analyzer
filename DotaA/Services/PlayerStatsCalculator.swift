import Foundation

/// Player Statistics Calculator - Centralized player statistics calculation logic
struct PlayerStatsCalculator {
    
    /// Calculate win rate
    /// - Parameter matches: Match data
    /// - Returns: Win rate (0.0-1.0)
    static func calculateWinRate(from matches: [RecentMatch]) -> Double {
        guard !matches.isEmpty else { return 0.0 }
        
        let wins = matches.filter { match in
            (match.playerSlot < 5 && match.radiantWin) || (match.playerSlot >= 5 && !match.radiantWin)
        }.count
        
        return Double(wins) / Double(matches.count)
    }
    
    /// Calculate average GPM
    /// Note: RecentMatch does not contain GPM data, this method is deprecated
    /// Use calculateCareerAverageGPM(from playerTotals:) instead
    /// - Parameter matches: Match data
    /// - Returns: Average GPM (always returns 0.0, as data is unavailable)
    static func calculateAverageGPM(from matches: [RecentMatch]) -> Double {
        // RecentMatch struct does not contain goldPerMin field
        // Use PlayerTotal data to calculate career average GPM
        print("⚠️ Warning: RecentMatch does not contain GPM data. Use calculateCareerAverageGPM instead.")
        return 0.0
    }
    
    /// Calculate career average GPM from PlayerTotal
    /// - Parameter playerTotals: Player total statistics
    /// - Returns: Career average GPM
    static func calculateCareerAverageGPM(from playerTotals: [PlayerTotal]) -> Double {
        guard !playerTotals.isEmpty else { return 0.0 }
        
        if let gpmTotal = playerTotals.first(where: { $0.field == "gold_per_min" }) {
            print("📊 calculateCareerAverageGPM: Found GPM data - avg=\(gpmTotal.average)")
            return gpmTotal.average
        }
        
        print("📊 calculateCareerAverageGPM: Could not find gold_per_min in totals")
        return 0.0
    }
    
    /// Get most played hero
    /// - Parameter heroStats: Hero statistics data
    /// - Returns: Tuple containing hero name and game count
    static func getMostPlayedHero(from heroStats: [PlayerHeroStats]) -> (name: String, games: Int) {
        guard !heroStats.isEmpty else { return ("Unknown", 0) }
        
        let mostPlayedHero = heroStats.max { $0.games < $1.games }
        if let hero = mostPlayedHero {
            let heroName = HeroService.shared.getHeroName(heroId: hero.heroId)
            return (heroName, hero.games)
        }
        
        return ("Unknown", 0)
    }
    
    /// Get best hero (highest win rate with at least 5 games)
    /// - Parameter heroStats: Hero statistics data
    /// - Returns: Tuple containing hero name and win rate
    static func getBestHero(from heroStats: [PlayerHeroStats]) -> (name: String, winRate: Double) {
        guard !heroStats.isEmpty else { return ("Unknown", 0.0) }
        
        // Filter heroes with at least 5 games, then sort by win rate
        let qualifiedHeroes = heroStats.filter { $0.games >= 5 }
        let bestHero = qualifiedHeroes.max { hero1, hero2 in
            let winRate1 = Double(hero1.win) / Double(hero1.games)
            let winRate2 = Double(hero2.win) / Double(hero2.games)
            return winRate1 < winRate2
        }
        
        if let hero = bestHero {
            let heroName = HeroService.shared.getHeroName(heroId: hero.heroId)
            let winRate = Double(hero.win) / Double(hero.games)
            return (heroName, winRate)
        }
        
        return ("Unknown", 0.0)
    }
    
    /// Calculate consistency score (based on KDA stability in recent matches)
    /// - Parameter matches: Match data
    /// - Returns: Consistency score (0.0-100.0)
    static func calculateConsistencyScore(from matches: [RecentMatch]) -> Double {
        guard matches.count > 1 else { return 0.0 }
        
        let kdas = matches.map { KDACalculator.calculateKDA(from: $0) }
        let averageKDA = kdas.reduce(0, +) / Double(kdas.count)
        
        // Calculate standard deviation
        let variance = kdas.map { pow($0 - averageKDA, 2) }.reduce(0, +) / Double(kdas.count)
        let standardDeviation = sqrt(variance)
        
        // Convert consistency to 0-100 score (lower standard deviation = higher consistency)
        let consistencyScore = max(0, 100 - (standardDeviation * 20))
        return consistencyScore
    }
    
    /// Calculate overall performance score
    /// - Parameter matches: Match data
    /// - Returns: Overall performance score (0.0-100.0)
    static func calculateOverallScore(from matches: [RecentMatch]) -> Double {
        guard !matches.isEmpty else { return 0.0 }
        
        let winRate = calculateWinRate(from: matches)
        let avgKDA = KDACalculator.calculateAverageKDA(from: matches)
        let consistency = calculateConsistencyScore(from: matches)
        
        // Composite score: Win rate 40% + KDA 30% + Consistency 30%
        let kdaScore = min(100, avgKDA * 20) // Convert KDA to 100-point scale
        let winRateScore = winRate * 100
        
        let overallScore = (winRateScore * 0.4) + (kdaScore * 0.3) + (consistency * 0.3)
        return overallScore
    }
}