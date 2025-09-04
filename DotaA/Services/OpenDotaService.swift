//
//  OpenDotaService.swift
//  DotaA
//
//  Created by Wentao Guo on 11/08/25.
//

import Combine
import Foundation

class OpenDotaService: ObservableObject {
    static let shared = OpenDotaService()

    private let baseURL = "https://api.opendota.com/api"
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    // MARK: - Player Search
    func searchPlayer(query: String) -> AnyPublisher<
        [PlayerSearchResult], Error
    > {
        guard
            let encodedQuery = query.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "\(baseURL)/search?q=\(encodedQuery)")
        else {
            return Fail(error: OpenDotaError.invalidURL)
                .eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [PlayerSearchResult].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Recent Matches
    func getRecentMatches(accountId: Int64, limit: Int = 20) -> AnyPublisher<
        [RecentMatch], Error
    > {
        guard
            let url = URL(
                string:
                    "\(baseURL)/players/\(accountId)/recentMatches?limit=\(limit)"
            )
        else {
            return Fail(error: OpenDotaError.invalidURL)
                .eraseToAnyPublisher()
        }
        print(122443)

        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [RecentMatch].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Historical Matches for Best KDA
    func getHistoricalMatches(accountId: Int64, limit: Int = 100) -> AnyPublisher<
        [RecentMatch], Error
    > {
        guard
            let url = URL(
                string:
                    "\(baseURL)/players/\(accountId)/matches?limit=\(limit)"
            )
        else {
            return Fail(error: OpenDotaError.invalidURL)
                .eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [RecentMatch].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Match Details
    func getMatchDetails(matchId: Int64) -> AnyPublisher<Match, Error> {
        guard let url = URL(string: "\(baseURL)/matches/\(matchId)") else {
            return Fail(error: OpenDotaError.invalidURL)
                .eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: Match.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Heroes Data
    func getHeroes() -> AnyPublisher<[Hero], Error> {
        guard let url = URL(string: "\(baseURL)/heroes") else {
            return Fail(error: OpenDotaError.invalidURL)
                .eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [Hero].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Items Data
    func getItems() -> AnyPublisher<[String: ItemData], Error> {
        guard let url = URL(string: "\(baseURL)/constants/items") else {
            return Fail(error: OpenDotaError.invalidURL)
                .eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [String: ItemData].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Player Statistics
    func getPlayerStats(accountId: Int64) -> AnyPublisher<PlayerStats, Error> {
        guard let url = URL(string: "\(baseURL)/players/\(accountId)") else {
            return Fail(error: OpenDotaError.invalidURL)
                .eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: PlayerStats.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Player Win/Loss Records
    func getPlayerWinLoss(accountId: Int64) -> AnyPublisher<PlayerWinLoss, Error> {
        guard let url = URL(string: "\(baseURL)/players/\(accountId)/wl") else {
            return Fail(error: OpenDotaError.invalidURL)
                .eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: PlayerWinLoss.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Player Heroes Performance
    func getPlayerHeroes(accountId: Int64, limit: Int? = nil) -> AnyPublisher<
        [PlayerHeroStats], Error
    > {
        let urlString = if let limit = limit {
            "\(baseURL)/players/\(accountId)/heroes?limit=\(limit)"
        } else {
            "\(baseURL)/players/\(accountId)/heroes"
        }
        
        guard let url = URL(string: urlString) else {
            return Fail(error: OpenDotaError.invalidURL)
                .eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [PlayerHeroStats].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Match Benchmarks
    func getMatchBenchmarks(matchId: Int64) -> AnyPublisher<
        [String: [BenchmarkData]], Error
    > {
        guard let url = URL(string: "\(baseURL)/matches/\(matchId)/benchmarks")
        else {
            return Fail(error: OpenDotaError.invalidURL)
                .eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(
                type: [String: [BenchmarkData]].self, decoder: JSONDecoder()
            )
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Player Totals (for trends)
    func getPlayerTotals(accountId: Int64) -> AnyPublisher<[PlayerTotal], Error>
    {
        guard let url = URL(string: "\(baseURL)/players/\(accountId)/totals")
        else {
            return Fail(error: OpenDotaError.invalidURL)
                .eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [PlayerTotal].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Helper method to get hero name by ID
    func getHeroName(heroId: Int, completion: @escaping (String) -> Void) {
        getHeroes()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { heroes in
                    let hero = heroes.first { $0.id == heroId }
                    completion(hero?.localizedName ?? "Unknown Hero")
                }
            )
            .store(in: &cancellables)
    }
}

    // MARK: - Data models moved to DotaModels.swift

// MARK: - Error Handling
enum OpenDotaError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case rateLimited
    case serverError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data returned"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimited:
            return "Rate limited. Please try again later."
        case .serverError:
            return "Server error. Please try again later."
        }
    }
}

// MARK: - Request Extensions
extension OpenDotaService {
    private func makeRequest(url: URL) -> AnyPublisher<Data, Error> {
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return session.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let httpResponse = output.response as? HTTPURLResponse
                else {
                    throw OpenDotaError.networkError(
                        URLError(.badServerResponse))
                }

                switch httpResponse.statusCode {
                case 200...299:
                    return output.data
                case 429:
                    throw OpenDotaError.rateLimited
                case 500...599:
                    throw OpenDotaError.serverError
                default:
                    throw OpenDotaError.networkError(
                        URLError(.badServerResponse))
                }
            }
            .mapError { error in
                if error is OpenDotaError {
                    return error
                }
                return OpenDotaError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
}
