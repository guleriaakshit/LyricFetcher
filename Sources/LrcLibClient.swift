import Foundation

struct LrcLibResponse: Codable {
    let id: Int
    let trackName: String?
    let artistName: String?
    let albumName: String?
    let duration: Double?
    let instrumental: Bool?
    let plainLyrics: String?
    let syncedLyrics: String?
}

enum LyricsType: Equatable {
    case synced
    case plain
    case embedded
}

struct LyricsResult {
    let content: String
    let type: LyricsType
}

class LrcLibClient {
    static let shared = LrcLibClient()
    
    func fetchLyrics(trackName: String, artistName: String, albumName: String?, duration: Double?) async throws -> LyricsResult? {
        var components = URLComponents(string: "https://lrclib.net/api/get")!
        var queryItems = [
            URLQueryItem(name: "track_name", value: trackName),
            URLQueryItem(name: "artist_name", value: artistName)
        ]
        if let albumName = albumName, !albumName.isEmpty {
            queryItems.append(URLQueryItem(name: "album_name", value: albumName))
        }
        if let duration = duration, duration > 0 {
            queryItems.append(URLQueryItem(name: "duration", value: String(Int(duration))))
        }
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("LyricFetcher/1.0.0 (https://github.com/user/LyricFetcher)", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 404 {
                // Not found via exact match, try search
                return try await searchLyrics(trackName: trackName, artistName: artistName)
            }
            guard httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(LrcLibResponse.self, from: data)
        
        if let synced = result.syncedLyrics, !synced.isEmpty {
            return LyricsResult(content: synced, type: .synced)
        } else if let plain = result.plainLyrics, !plain.isEmpty {
            return LyricsResult(content: plain, type: .plain)
        }
        
        return nil
    }
    
    private func searchLyrics(trackName: String, artistName: String) async throws -> LyricsResult? {
        var components = URLComponents(string: "https://lrclib.net/api/search")!
        let queryItems = [
            URLQueryItem(name: "q", value: "\(trackName) \(artistName)")
        ]
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("LyricFetcher/1.0.0 (https://github.com/user/LyricFetcher)", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let results = try decoder.decode([LrcLibResponse].self, from: data)
        
        // Prioritize synced lyrics: scan ALL results for synced first
        for result in results {
            if let synced = result.syncedLyrics, !synced.isEmpty {
                return LyricsResult(content: synced, type: .synced)
            }
        }
        // Fall back to plain lyrics only if no synced lyrics were found
        for result in results {
            if let plain = result.plainLyrics, !plain.isEmpty {
                return LyricsResult(content: plain, type: .plain)
            }
        }
        
        return nil
    }
}
