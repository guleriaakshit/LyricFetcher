import Foundation
import AVFoundation

struct ScanTask: Identifiable {
    let id = UUID()
    let url: URL
    var title: String?
    var artist: String?
    var album: String?
    var lyricsType: LyricsType?
    var status: ScanStatus
}

enum ScanStatus: Equatable {
    case pending
    case processing
    case success
    case failed(String)
    case skipped(String)
}

@MainActor
class AudioScanner: ObservableObject {
    @Published var tasks: [ScanTask] = []
    @Published var isScanning = false
    
    private static let lastFolderKey = "LyricFetcher.lastSelectedFolder"
    
    /// Save a folder path to UserDefaults for persistence across launches
    static func saveLastFolder(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: lastFolderKey)
    }
    
    /// Load the previously saved folder path, if it still exists
    static func loadLastFolder() -> URL? {
        guard let path = UserDefaults.standard.string(forKey: lastFolderKey) else { return nil }
        let url = URL(fileURLWithPath: path)
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else { return nil }
        return url
    }
    
    var totalCount: Int { tasks.count }
    var successCount: Int { tasks.filter { $0.status == .success }.count }
    var failedCount: Int { tasks.filter { if case .failed = $0.status { return true }; return false }.count }
    var skippedCount: Int { tasks.filter { if case .skipped = $0.status { return true }; return false }.count }
    var processedCount: Int { tasks.filter { $0.status != .pending && $0.status != .processing }.count }
    var processingCount: Int { tasks.filter { $0.status == .processing }.count }
    var syncedCount: Int { tasks.filter { $0.lyricsType == .synced }.count }
    var plainCount: Int { tasks.filter { $0.lyricsType == .plain }.count }
    var embeddedCount: Int { tasks.filter { $0.lyricsType == .embedded }.count }
    
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(processedCount) / Double(totalCount)
    }
    
    /// Extracts title, artist, and album from an AVAsset.
    /// Checks all metadata formats: commonMetadata first, then falls back to
    /// format-specific metadata (Vorbis comments for FLAC, ID3 for MP3, etc.)
    private func extractMetadata(from asset: AVURLAsset) async -> (title: String?, artist: String?, album: String?) {
        var title: String?
        var artist: String?
        var album: String?
        
        // Strategy 1: Try commonMetadata (works for MP3/M4A/AAC with standard tags)
        if let common = try? await asset.load(.commonMetadata), !common.isEmpty {
            for item in common {
                if let key = item.commonKey?.rawValue {
                    let value = try? await item.load(.value) as? String
                    if key == AVMetadataKey.commonKeyTitle.rawValue {
                        title = value
                    } else if key == AVMetadataKey.commonKeyArtist.rawValue {
                        artist = value
                    } else if key == AVMetadataKey.commonKeyAlbumName.rawValue {
                        album = value
                    }
                }
            }
        }
        
        // Strategy 2: If commonMetadata missed anything, search ALL metadata
        // (handles FLAC Vorbis comments, exotic ID3 frames, etc.)
        if title == nil || artist == nil || album == nil {
            if let allMetadata = try? await asset.load(.metadata) {
                for item in allMetadata {
                    guard let key = item.key as? String else { continue }
                    let upperKey = key.uppercased()
                    let value = try? await item.load(.value) as? String
                    guard let val = value, !val.isEmpty else { continue }
                    
                    if title == nil && upperKey == "TITLE" {
                        title = val
                    } else if artist == nil && upperKey == "ARTIST" {
                        artist = val
                    } else if album == nil && (upperKey == "ALBUM" || upperKey == "ALBUMTITLE") {
                        album = val
                    }
                }
            }
        }
        
        return (title, artist, album)
    }
    
    func scan(directory: URL) async {
        isScanning = true
        tasks.removeAll()
        
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            isScanning = false
            return
        }
        
        let supportedExtensions = ["mp3", "m4a", "flac", "wav", "aac"]
        
        // Phase 1: Enumerate all audio files and pre-check for existing .lrc files
        while let object = enumerator.nextObject() {
            if let url = object as? URL, supportedExtensions.contains(url.pathExtension.lowercased()) {
                let lrcURL = url.deletingPathExtension().appendingPathExtension("lrc")
                let alreadyHasLrc = fileManager.fileExists(atPath: lrcURL.path)
                
                tasks.append(ScanTask(
                    url: url,
                    status: alreadyHasLrc ? .skipped("LRC exists") : .pending
                ))
            }
        }
        
        // Phase 2: Process all tracks
        for index in tasks.indices {
            // For already-skipped tracks, still extract metadata for display
            if case .skipped = tasks[index].status {
                await populateMetadata(at: index)
                continue
            }
            
            let task = tasks[index]
            tasks[index].status = .processing
            
            let lrcURL = task.url.deletingPathExtension().appendingPathExtension("lrc")
            
            do {
                let asset = AVURLAsset(url: task.url)
                
                // Extract metadata for display and lookup
                let meta = await extractMetadata(from: asset)
                tasks[index].title = meta.title
                tasks[index].artist = meta.artist
                tasks[index].album = meta.album
                
                // Check if the asset has embedded lyrics, extract and save as .lrc
                if let embeddedLyrics = try? await asset.load(.lyrics), !embeddedLyrics.isEmpty {
                    try embeddedLyrics.write(to: lrcURL, atomically: true, encoding: .utf8)
                    tasks[index].lyricsType = .embedded
                    tasks[index].status = .success
                    continue
                }
                
                // Need title + artist at minimum for LRCLIB lookup
                guard let t = meta.title, !t.isEmpty, let a = meta.artist, !a.isEmpty else {
                    tasks[index].status = .skipped("Missing metadata")
                    continue
                }
                
                let durationValue = try await asset.load(.duration)
                let duration = CMTimeGetSeconds(durationValue)
                
                if let result = try await LrcLibClient.shared.fetchLyrics(trackName: t, artistName: a, albumName: meta.album, duration: duration) {
                    try result.content.write(to: lrcURL, atomically: true, encoding: .utf8)
                    tasks[index].lyricsType = result.type
                    tasks[index].status = .success
                } else {
                    tasks[index].status = .failed("No lyrics found")
                }
                
            } catch {
                tasks[index].status = .failed(error.localizedDescription)
            }
        }
        
        isScanning = false
    }
    
    /// Extracts metadata from a track purely for display (used for already-skipped tracks)
    private func populateMetadata(at index: Int) async {
        let asset = AVURLAsset(url: tasks[index].url)
        let meta = await extractMetadata(from: asset)
        tasks[index].title = meta.title
        tasks[index].artist = meta.artist
        tasks[index].album = meta.album
    }
}
