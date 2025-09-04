import Foundation

/// KDA Calculator - Centralized KDA calculation logic
struct KDACalculator {
    
    /// Calculate KDA for a single match
    /// - Parameters:
    ///   - kills: Number of kills
    ///   - deaths: Number of deaths
    ///   - assists: Number of assists
    /// - Returns: KDA value
    static func calculateKDA(kills: Int, deaths: Int, assists: Int) -> Double {
        guard deaths > 0 else {
            return Double(kills + assists) // If no deaths, return K+A
        }
        return Double(kills + assists) / Double(deaths)
    }
    
    /// Calculate KDA from match data
    /// - Parameter match: Match data
    /// - Returns: KDA value
    static func calculateKDA(from match: RecentMatch) -> Double {
        return calculateKDA(kills: match.kills, deaths: match.deaths, assists: match.assists)
    }
    
    /// Calculate average KDA for multiple matches
    /// - Parameter matches: Array of match data
    /// - Returns: Average KDA value
    static func calculateAverageKDA(from matches: [RecentMatch]) -> Double {
        guard !matches.isEmpty else { return 0.0 }
        
        let totalKills = matches.reduce(into: 0) { $0 += $1.kills }
        let totalDeaths = matches.reduce(into: 0) { $0 += $1.deaths }
        let totalAssists = matches.reduce(into: 0) { $0 += $1.assists }
        
        return calculateKDA(kills: totalKills, deaths: totalDeaths, assists: totalAssists)
    }
    
    /// Calculate career average KDA from PlayerTotal data
    /// - Parameter playerTotals: Player total statistics
    /// - Returns: Career average KDA
    static func calculateCareerAverageKDA(from playerTotals: [PlayerTotal]) -> Double {
        guard !playerTotals.isEmpty else { 
            print("📊 calculateCareerAverageKDA: playerTotals is empty")
            return 0.0 
        }
        
        // Method 1: Use KDA field directly from API
        if let kdaTotal = playerTotals.first(where: { $0.field == "kda" }) {
            let avgKDA = kdaTotal.average
            print("📊 calculateCareerAverageKDA: Using KDA field - avg=\(avgKDA), total=\(kdaTotal.sum), games=\(kdaTotal.n)")
            return avgKDA
        }
        
        // Method 2: Manual calculation (fallback)
        let killsTotal = playerTotals.first { $0.field == "kills" }
        let deathsTotal = playerTotals.first { $0.field == "deaths" }
        let assistsTotal = playerTotals.first { $0.field == "assists" }
        
        guard let kills = killsTotal,
              let deaths = deathsTotal,
              let assists = assistsTotal else {
            print("📊 calculateCareerAverageKDA: Missing required data - kills=\(killsTotal?.field ?? "nil"), deaths=\(deathsTotal?.field ?? "nil"), assists=\(assistsTotal?.field ?? "nil")")
            return 0.0
        }
        
        let totalMatches = kills.n // Use kills count as total matches
        
        guard totalMatches > 0, deaths.sum > 0 else {
            print("📊 calculateCareerAverageKDA: Invalid data - totalMatches=\(totalMatches), deathsSum=\(deaths.sum)")
            return 0.0
        }
        
        let kda = (kills.sum + assists.sum) / deaths.sum
        print("📊 calculateCareerAverageKDA: Manual calculation - K=\(kills.sum), D=\(deaths.sum), A=\(assists.sum), KDA=\(kda)")
        return kda
    }
    
    /// Find best KDA match
    /// - Parameter matches: Array of match data
    /// - Returns: Tuple containing best KDA and hero ID
    static func findBestKDA(from matches: [RecentMatch]) -> (kda: Double, heroId: Int) {
        guard !matches.isEmpty else { return (0.0, 1) }
        
        let bestMatch = matches.max { match1, match2 in
            let kda1 = calculateKDA(from: match1)
            let kda2 = calculateKDA(from: match2)
            return kda1 < kda2
        }
        
        if let match = bestMatch {
            let kda = calculateKDA(from: match)
            print("📊 findBestKDA: Best KDA=\(kda) from match \(match.matchId) (\(match.kills)/\(match.deaths)/\(match.assists))")
            return (kda, match.heroId)
        }
        
        return (0.0, 1)
    }
    
    /// Calculate best career KDA from historical match data
    /// - Parameters:
    ///   - historicalMatches: Historical match data
    ///   - recentMatches: Recent match data (fallback)
    /// - Returns: Best KDA value
    static func calculateBestCareerKDA(historicalMatches: [RecentMatch], recentMatches: [RecentMatch] = []) -> Double {
        // Prioritize historical match data
        if !historicalMatches.isEmpty {
            let bestResult = findBestKDA(from: historicalMatches)
            print("📊 calculateBestCareerKDA: Historical best KDA=\(bestResult.kda)")
            return bestResult.kda
        }
        
        // Fallback: Use recent match data
        if !recentMatches.isEmpty {
            let bestResult = findBestKDA(from: recentMatches)
            print("📊 calculateBestCareerKDA: Recent best KDA=\(bestResult.kda) (fallback)")
            return bestResult.kda
        }
        
        print("📊 calculateBestCareerKDA: No match data available")
        return 0.0
    }
}