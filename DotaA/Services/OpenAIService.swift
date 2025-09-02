//
//  OpenAIService.swift
//  DotaA
//
//  Created by Wentao Guo on 11/08/25.
//

import Combine
import Foundation

class OpenAIService: ObservableObject {
    static let shared = OpenAIService()

    private let baseURL = "https://api.openai.com/v1"
    private let apiKey =
        Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
        ?? ""  // Replace with actual API key
    private let session = URLSession.shared

    private init() {}

    // MARK: - Generate Match Analysis
    func generateMatchAnalysis(
        match: Match,
        player: Player,
        heroName: String,
        benchmarks: BenchmarkComparison
    ) -> AnyPublisher<AICoachingResponse, Error> {

        let prompt = createAnalysisPrompt(
            match: match,
            player: player,
            heroName: heroName,
            benchmarks: benchmarks
        )

        return callOpenAI(prompt: prompt)
            .decode(type: OpenAIResponse.self, decoder: JSONDecoder())
            .map { response in
                self.parseAIResponse(
                    response.output.first?.content.first?.text ?? "")
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Generate Quick Performance Summary
    func generateQuickSummary(
        player: Player,
        heroName: String,
        matchResult: Bool,
        duration: Int
    ) -> String {
        let resultText = matchResult ? "Victory" : "Defeat"
        let kdaText = "\(player.kills)/\(player.deaths)/\(player.assists)"
        let durationMinutes = duration / 60

        if player.kda >= 3.0 {
            return
                "🎉 Excellent performance with \(heroName)! \(resultText) in \(durationMinutes)m with KDA \(kdaText)"
        } else if player.kda >= 2.0 {
            return
                "👍 Good game with \(heroName)! \(resultText) in \(durationMinutes)m with KDA \(kdaText)"
        } else if player.kda >= 1.0 {
            return
                "📈 Decent performance with \(heroName). \(resultText) in \(durationMinutes)m with KDA \(kdaText)"
        } else {
            return
                "💪 Tough game with \(heroName), but every game is a learning opportunity! KDA \(kdaText)"
        }
    }

    // MARK: - Create Analysis Prompt
    private func createAnalysisPrompt(
        match: Match,
        player: Player,
        heroName: String,
        benchmarks: BenchmarkComparison
    ) -> String {
        let matchDurationMinutes = match.duration / 60
        let winStatus =
            (player.isRadiant == match.radiantWin) ? "Victory" : "Defeat"
        let lastHitsPerMin =
            Double(player.lastHits) / Double(matchDurationMinutes)

        return """
            You are an expert Dota 2 coach analyzing a player's performance. Provide detailed, actionable feedback in JSON format.

            **Match Information:**
            - Hero: \(heroName)
            - Duration: \(matchDurationMinutes) minutes
            - Result: \(winStatus)

            **Player Performance:**
            - KDA: \(player.kills)/\(player.deaths)/\(player.assists) (Ratio: \(String(format: "%.2f", player.kda)))
            - Last Hits: \(player.lastHits) (\(String(format: "%.1f", lastHitsPerMin)) per minute)
            - Denies: \(player.denies)
            - GPM: \(player.goldPerMin)
            - XPM: \(player.xpPerMin)
            - Hero Damage: \(player.heroDamage)
            - Tower Damage: \(player.towerDamage)
            - Net Worth: \(player.netWorth)

            **Benchmark Comparison (vs similar skill players):**
            - Farming Efficiency: \(String(format: "%.1f", benchmarks.farmingEfficiency))%
            - Fight Participation: \(String(format: "%.1f", benchmarks.fightParticipation))%
            - Economy Efficiency: \(String(format: "%.1f", benchmarks.economyEfficiency))%

            Provide analysis in this JSON format:
            {
                "overallAnalysis": "Comprehensive 100-150 word analysis of performance",
                "keyStrengths": [
                    "Specific strength 1",
                    "Specific strength 2"
                ],
                "areasForImprovement": [
                    "Specific area 1",
                    "Specific area 2",
                    "Specific area 3"
                ],
                "actionableAdvice": [
                    "Specific actionable tip 1",
                    "Specific actionable tip 2",
                    "Specific actionable tip 3"
                ],
                "nextMatchGoals": [
                    "Measurable goal 1 (e.g., Achieve 6+ CS per minute)",
                    "Measurable goal 2 (e.g., Keep deaths under 5)",
                    "Measurable goal 3 (e.g., Buy BKB before 25 minutes)"
                ],
                "specificTips": [
                    {
                        "category": "Farming",
                        "tip": "Focus on last-hitting efficiency",
                        "reasoning": "Your CS per minute is below average",
                        "targetMetric": "6+ CS per minute"
                    },
                    {
                        "category": "Positioning",
                        "tip": "Stay further back in team fights",
                        "reasoning": "High death count suggests positioning issues",
                        "targetMetric": "Less than 5 deaths per game"
                    }
                ]
            }

            Focus on specific, measurable improvements. Avoid generic advice.
            """
    }

    // MARK: - Call OpenAI API
    private func callOpenAI(prompt: String) -> AnyPublisher<Data, Error> {
        guard let url = URL(string: "\(baseURL)/responses") else {
            return Fail(error: OpenAIError.invalidURL)
                .eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = OpenAIRequest(
            model: "gpt-4o",
            input: [
                OpenAIMessage(
                    role: "system",
                    content:
                        "You are an expert Dota 2 coach who provides detailed, actionable feedback to help players improve their gameplay."
                ),
                OpenAIMessage(role: "user", content: prompt),
            ],
            maxTokens: 1500,
            temperature: 0.7
        )

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .mapError { OpenAIError.networkError($0) }
            .eraseToAnyPublisher()
    }

    // MARK: - Parse AI Response
    private func parseAIResponse(_ content: String) -> AICoachingResponse {
        // Try to parse JSON response
        let cleanedContent =
            content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleanedContent.data(using: .utf8),
            let response = try? JSONDecoder().decode(
                AICoachingResponse.self, from: data)
        else {
            // Return fallback response if parsing fails
            return AICoachingResponse(
                overallAnalysis: content,
                keyStrengths: ["Game participation", "Item progression"],
                areasForImprovement: [
                    "Farm efficiency", "Map awareness", "Positioning",
                ],
                actionableAdvice: [
                    "Focus on last-hitting in lane",
                    "Buy wards and place them strategically",
                    "Avoid unnecessary deaths by playing safer",
                ],
                nextMatchGoals: [
                    "Achieve 6+ CS per minute",
                    "Keep deaths under 5",
                    "Participate in 70% of team kills",
                ],
                specificTips: [
                    SpecificTip(
                        category: "Farming",
                        tip: "Practice last-hitting in demo mode",
                        reasoning: "Consistent CS leads to better item timings",
                        targetMetric: "6+ CS per minute"
                    )
                ]
            )
        }

        return response
    }

    // MARK: - Generate Hero-Specific Advice
    func generateHeroSpecificAdvice(
        heroName: String,
        playerPerformance: Player,
        averagePerformance: BenchmarkComparison
    ) -> AnyPublisher<[String], Error> {

        let prompt = """
            Provide 3 specific tips for playing \(heroName) better based on this performance:
            - GPM: \(playerPerformance.goldPerMin) (average efficiency: \(averagePerformance.farmingEfficiency)%)
            - KDA: \(playerPerformance.kda)
            - Hero Damage: \(playerPerformance.heroDamage)

            Focus on hero-specific advice, not generic Dota tips.
            Return as a simple JSON array of strings.
            """

        return callOpenAI(prompt: prompt)
            .decode(type: OpenAIResponse.self, decoder: JSONDecoder())
            .map { response in
                let content = response.output.first?.content.first?.text ?? ""
                return self.parseStringArray(content)
            }
            .eraseToAnyPublisher()
    }

    private func parseStringArray(_ content: String) -> [String] {
        guard let data = content.data(using: .utf8),
            let array = try? JSONDecoder().decode([String].self, from: data)
        else {
            return [
                "Focus on efficient farming patterns",
                "Improve map awareness and positioning",
                "Time your abilities better in team fights",
            ]
        }
        return array
    }
}

// MARK: - OpenAI API Data Models
struct OpenAIRequest: Codable {
    let model: String
    let input: [OpenAIMessage]
    let maxTokens: Int
    let temperature: Double

    enum CodingKeys: String, CodingKey {
        case model, input, temperature
        case maxTokens = "max_output_tokens"
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let output: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let content: [OpenAIText]
}

struct OpenAIText: Codable {
    let text: String
}

// MARK: - Error Handling
enum OpenAIError: Error, LocalizedError {
    case invalidURL
    case invalidAPIKey
    case networkError(Error)
    case decodingError
    case quotaExceeded
    case rateLimited
    case serverError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidAPIKey:
            return "Invalid API key"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to decode response"
        case .quotaExceeded:
            return "API quota exceeded"
        case .rateLimited:
            return "Rate limited. Please try again later."
        case .serverError:
            return "Server error. Please try again later."
        }
    }
}

// MARK: - Coaching Templates
extension OpenAIService {
    func getCoachingTemplate(for category: RecommendationCategory) -> String {
        switch category {
        case .farming:
            return
                "Focus on improving your farming efficiency by practicing last-hitting and optimizing your farming routes."
        case .itemization:
            return
                "Consider your item choices and timing. Build items that counter the enemy team and suit your game situation."
        case .positioning:
            return
                "Work on your positioning in team fights. Stay at safe distances and use terrain to your advantage."
        case .timing:
            return
                "Improve your timing for key moments like ganks, pushes, and item purchases."
        case .teamfight:
            return
                "Focus on your role in team fights and coordinate better with your team."
        case .vision:
            return
                "Invest in vision control. Buy and place wards strategically to improve map awareness."
        case .economy:
            return
                "Optimize your resource management. Balance farming and fighting to maximize your impact."
        case .mapAwareness:
            return
                "Improve your map awareness. Watch the minimap frequently and react to enemy movements."
        }
    }
}
