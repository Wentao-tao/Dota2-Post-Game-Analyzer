//
//  DotaModels.swift
//  DotaA
//
//  Created by Wentao Guo on 11/08/25.
//

import Foundation

// MARK: - Match Data Models
struct Match: Codable, Identifiable {
    let id = UUID()
    let matchId: Int64
    let duration: Int
    let gameMode: Int
    let radiantWin: Bool
    let startTime: Int64
    let players: [Player]
    
    enum CodingKeys: String, CodingKey {
        case matchId = "match_id"
        case duration
        case gameMode = "game_mode"
        case radiantWin = "radiant_win"
        case startTime = "start_time"
        case players
    }
}

// MARK: - Player Data Model
struct Player: Codable, Identifiable {
    let id = UUID()
    let accountId: Int64?
    let playerSlot: Int
    let heroId: Int
    let item0: Int
    let item1: Int
    let item2: Int
    let item3: Int
    let item4: Int
    let item5: Int
    let backpack0: Int
    let backpack1: Int
    let backpack2: Int
    let kills: Int
    let deaths: Int
    let assists: Int
    let lastHits: Int
    let denies: Int
    let goldPerMin: Int
    let xpPerMin: Int
    let level: Int
    let netWorth: Int
    let heroDamage: Int
    let towerDamage: Int
    let heroHealing: Int
    let gold: Int
    let goldSpent: Int
    
    // Advanced statistics
    let purchaseLog: [ItemPurchase]?
    let goldReasons: [String: Int]?
    let xpReasons: [String: Int]?
    let killsLog: [KillEvent]?
    let benchmarks: PlayerBenchmarks?
    
    enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case playerSlot = "player_slot"
        case heroId = "hero_id"
        case item0 = "item_0"
        case item1 = "item_1"
        case item2 = "item_2"
        case item3 = "item_3"
        case item4 = "item_4"
        case item5 = "item_5"
        case backpack0 = "backpack_0"
        case backpack1 = "backpack_1"
        case backpack2 = "backpack_2"
        case kills, deaths, assists
        case lastHits = "last_hits"
        case denies
        case goldPerMin = "gold_per_min"
        case xpPerMin = "xp_per_min"
        case level
        case netWorth = "net_worth"
        case heroDamage = "hero_damage"
        case towerDamage = "tower_damage"
        case heroHealing = "hero_healing"
        case gold
        case goldSpent = "gold_spent"
        case purchaseLog = "purchase_log"
        case goldReasons = "gold_reasons"
        case xpReasons = "xp_reasons"
        case killsLog = "kills_log"
        case benchmarks
    }
    
    // Computed properties
    var kda: Double {
        let k = Double(kills)
        let d = Double(deaths)
        let a = Double(assists)
        return d > 0 ? (k + a) / d : k + a
    }
    
    var isRadiant: Bool {
        return playerSlot < 128
    }
    
    var lastHitsPerMinute: Double {
        return Double(lastHits) / (Double(duration) / 60.0)
    }
    
    var heroDamagePerMinute: Double {
        return Double(heroDamage) / (Double(duration) / 60.0)
    }
    
    private var duration: Int {
        // This would be passed from the match context
        return 2400 // Default 40 minutes for calculation
    }
}

// MARK: - Item Purchase Log
struct ItemPurchase: Codable {
    let time: Int
    let itemId: String
    let charges: Int?
    
    enum CodingKeys: String, CodingKey {
        case time
        case itemId = "key"
        case charges
    }
}

// MARK: - Kill Events
struct KillEvent: Codable {
    let time: Int
    let key: String
}

// MARK: - Player Benchmarks
struct PlayerBenchmarks: Codable {
    let goldPerMin: BenchmarkData?
    let xpPerMin: BenchmarkData?
    let killsPerMin: BenchmarkData?
    let lastHitsPerMin: BenchmarkData?
    let heroDamagePerMin: BenchmarkData?
    let heroHealingPerMin: BenchmarkData?
    let towerDamage: BenchmarkData?
    
    enum CodingKeys: String, CodingKey {
        case goldPerMin = "gold_per_min"
        case xpPerMin = "xp_per_min"
        case killsPerMin = "kills_per_min"
        case lastHitsPerMin = "last_hits_per_min"
        case heroDamagePerMin = "hero_damage_per_min"
        case heroHealingPerMin = "hero_healing_per_min"
        case towerDamage = "tower_damage"
    }
}

struct BenchmarkData: Codable {
    let raw: Double
    let pct: Double
}

// MARK: - Hero Data
struct Hero: Codable, Identifiable {
    let id: Int
    let name: String
    let localizedName: String
    let primaryAttr: String
    let attackType: String
    let roles: [String]

    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case localizedName = "localized_name"
        case primaryAttr = "primary_attr"
        case attackType = "attack_type"
        case roles

    }
}

// MARK: - Performance Analysis Results
struct PerformanceAnalysis {
    let matchId: Int64
    let playerSlot: Int
    let overallScore: Double // 0-100 score
    let strengths: [String]
    let weaknesses: [String]
    let recommendations: [Recommendation]
    let benchmarkComparison: BenchmarkComparison
    let keyMetrics: KeyMetrics
}

struct KeyMetrics {
    let farmingEfficiency: Double
    let combatPerformance: Double
    let economyScore: Double
    let itemizationScore: Double
    let mapAwareness: Double
}

struct Recommendation {
    let category: RecommendationCategory
    let title: String
    let description: String
    let priority: Priority
    let actionable: String
    let targetValue: String?
}

enum RecommendationCategory: String, CaseIterable {
    case farming = "Farming"
    case itemization = "Itemization"
    case positioning = "Positioning"
    case timing = "Timing"
    case teamfight = "Team Fighting"
    case vision = "Vision"
    case economy = "Economy"
    case mapAwareness = "Map Awareness"
}

enum Priority: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

struct BenchmarkComparison {
    let farmingEfficiency: Double // Percentile vs similar skill players
    let fightParticipation: Double
    let visionScore: Double
    let itemTimings: [String: ComparisonResult]
    let economyEfficiency: Double
}

struct ComparisonResult {
    let playerValue: Double
    let benchmarkValue: Double
    let percentile: Double
    let isGood: Bool
    let improvementTip: String?
}

// MARK: - AI Coaching Response
struct AICoachingResponse: Codable {
    let overallAnalysis: String
    let keyStrengths: [String]
    let areasForImprovement: [String]
    let actionableAdvice: [String]
    let nextMatchGoals: [String]
    let specificTips: [SpecificTip]
}

struct SpecificTip: Codable {
    let category: String
    let tip: String
    let reasoning: String
    let targetMetric: String?
}

// MARK: - Player Search Results
struct PlayerSearchResult: Codable {
    let accountId: Int64
    let personaname: String
    let avatarfull: String
    
    enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case personaname
        case avatarfull
     
    }
}

// MARK: - Recent Matches
struct RecentMatch: Codable, Identifiable {
    let id = UUID()
    let matchId: Int64
    let playerSlot: Int
    let radiantWin: Bool
    let duration: Int
    let gameMode: Int
    let lobbyType: Int
    let heroId: Int
    let startTime: Int64
    let version: Int?
    let kills: Int
    let deaths: Int
    let assists: Int
    let averageRank: Int?
    let partySize: Int?
    
    enum CodingKeys: String, CodingKey {
        case matchId = "match_id"
        case playerSlot = "player_slot"
        case radiantWin = "radiant_win"
        case duration
        case gameMode = "game_mode"
        case lobbyType = "lobby_type"
        case heroId = "hero_id"
        case startTime = "start_time"
        case version
        case kills, deaths, assists
        case averageRank = "average_rank"
        case partySize = "party_size"
    }
    
    var isWin: Bool {
        let isRadiant = playerSlot < 128
        return isRadiant == radiantWin
    }
    
    var kda: String {
        return "\(kills)/\(deaths)/\(assists)"
    }
    
    var kdaRatio: Double {
        let k = Double(kills)
        let d = Double(deaths)
        let a = Double(assists)
        return d > 0 ? (k + a) / d : k + a
    }
}

// MARK: - Item Data
struct ItemData: Codable {
    let id: Int
    let name: String
    let cost: Int?
    let secretShop: Bool?
    let sideShop: Bool?
    let recipe: Bool?
    let localizedName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, cost, recipe
        case secretShop = "secret_shop"
        case sideShop = "side_shop"
        case localizedName = "localized_name"
    }
}

// MARK: - Game Constants
struct GameConstants {
    static let importantItems = [
        1: "Blink Dagger",
        116: "Black King Bar",
        152: "Power Treads",
        63: "Mekansm",
        108: "Pipe of Insight"
    ]
    
    static let farmingBenchmarks = [
        "Herald": 3.0,
        "Guardian": 4.0,
        "Crusader": 5.0,
        "Archon": 6.0,
        "Legend": 7.0,
        "Ancient": 8.0,
        "Divine": 9.0,
        "Immortal": 10.0
    ]
    
    static let gpmBenchmarks = [
        "Herald": 300,
        "Guardian": 350,
        "Crusader": 400,
        "Archon": 450,
        "Legend": 500,
        "Ancient": 550,
        "Divine": 600,
        "Immortal": 650
    ]
}

// MARK: - Performance Trends
struct PerformanceTrend {
    let metric: String
    let values: [Double]
    let dates: [Date]
    let trend: TrendDirection
    let improvement: Double
}

enum TrendDirection {
    case improving
    case declining
    case stable
}

// MARK: - Hero Performance Stats
struct HeroPerformanceStats {
    let heroId: Int
    let heroName: String
    let gamesPlayed: Int
    let winRate: Double
    let averageKDA: Double
    let averageGPM: Double
    let averageXPM: Double
    let averageScore: Double
    let lastPlayed: Date
}

// MARK: - Player Statistics Models (moved from OpenDotaService)
struct PlayerStats: Codable {
    let rankTier: Int?
    let leaderboardRank: Int?
    let profile: PlayerProfile?

    enum CodingKeys: String, CodingKey {
        case profile
        case rankTier = "rank_tier"
        case leaderboardRank = "leaderboard_rank"
    }
}

struct PlayerProfile: Codable {
    let accountId: Int64
    let personaname: String?
    let name: String?
    let cheese: Int?
    let steamid: String?
    let avatar: String?
    let avatarmedium: String?
    let avatarfull: String?
    let profileurl: String?
    let lastLogin: String?
    let loccountrycode: String?
    let status: Int?

    enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case personaname, name, cheese, steamid
        case avatar, avatarmedium, avatarfull, profileurl
        case lastLogin = "last_login"
        case loccountrycode
        case status
    }
}

struct PlayerHeroStats: Codable {
    let heroId: Int
    let lastPlayed: Int
    let games: Int
    let win: Int
    let withGames: Int
    let withWin: Int
    let againstGames: Int
    let againstWin: Int

    enum CodingKeys: String, CodingKey {
        case heroId = "hero_id"
        case lastPlayed = "last_played"
        case games, win
        case withGames = "with_games"
        case withWin = "with_win"
        case againstGames = "against_games"
        case againstWin = "against_win"
    }

    var winRate: Double {
        return games > 0 ? Double(win) / Double(games) : 0.0
    }
}

struct PlayerTotal: Codable {
    let field: String
    let n: Int
    let sum: Double  // Use Double to handle floating point numbers

    var average: Double {
        return n > 0 ? sum / Double(n) : 0.0
    }
}

struct PlayerWinLoss: Codable {
    let win: Int
    let lose: Int
    
    // Calculate total matches
    var totalMatches: Int {
        return win + lose
    }
    
    // Calculate win rate
    var winRate: Double {
        let total = totalMatches
        return total > 0 ? Double(win) / Double(total) : 0.0
    }
    
    // Format win rate display
    var winRatePercentage: String {
        return String(format: "%.1f%%", winRate * 100)
    }
}

// MARK: - Player Counts Models
struct PlayerCounts: Codable {
    let leaverStatus: [LeaverStatusCount]
    let gameMode: [GameModeCount]
    let lobbyType: [LobbyTypeCount]
    let region: [RegionCount]
    let patch: [PatchCount]
    
    enum CodingKeys: String, CodingKey {
        case leaverStatus = "leaver_status"
        case gameMode = "game_mode"
        case lobbyType = "lobby_type"
        case region
        case patch
    }
}

struct LeaverStatusCount: Codable {
    let leaverStatus: Int
    let games: Int
    
    enum CodingKeys: String, CodingKey {
        case leaverStatus = "leaver_status"
        case games
    }
}

struct GameModeCount: Codable {
    let gameMode: Int
    let games: Int
    
    enum CodingKeys: String, CodingKey {
        case gameMode = "game_mode"
        case games
    }
}

struct LobbyTypeCount: Codable {
    let lobbyType: Int
    let games: Int
    
    enum CodingKeys: String, CodingKey {
        case lobbyType = "lobby_type"
        case games
    }
}

struct RegionCount: Codable {
    let region: Int
    let games: Int
}

struct PatchCount: Codable {
    let patch: Int
    let games: Int
}
