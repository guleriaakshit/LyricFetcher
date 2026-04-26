# 🎵 LyricFetcher

A native macOS app that automatically fetches synced and plain lyrics for your entire music library. Built with SwiftUI — no Xcode project required.

LyricFetcher scans a folder of audio files, reads embedded metadata (title, artist, album), queries the [LRCLIB](https://lrclib.net) API, and saves `.lrc` lyric files alongside each track. It intelligently skips tracks that already have lyrics from previous scans, making it perfect for incrementally growing music libraries.

---

## ✨ Features

- **Batch Processing** — Point it at your music library root and it recursively scans all subdirectories
- **Metadata-Driven** — Reads tags via AVFoundation, not filenames. Supports Vorbis comments (FLAC), ID3 (MP3), iTunes atoms (M4A/AAC), and more
- **Synced Lyrics Priority** — Always prefers time-synced `[mm:ss.xx]` lyrics over plain text
- **Smart Skip on Rescan** — Detects existing `.lrc` files instantly and skips them. Rescan after adding a new album and only new tracks are processed
- **Embedded Lyrics Extraction** — If a track already has lyrics embedded in its metadata, extracts and saves them as `.lrc`
- **Lyrics Type Indicators** — Each track shows whether it got **Synced**, **Plain**, or **Embedded** lyrics
- **Folder Persistence** — Remembers your last selected folder across app launches
- **Premium Dark UI** — Glassmorphism, animated gradients, micro-animations, and a polished dark theme

---

## 📋 Requirements

| Requirement | Minimum |
|---|---|
| **macOS** | 13.0 (Ventura) or later |
| **Architecture** | Apple Silicon (arm64) |
| **Xcode Command Line Tools** | Required (for `swiftc` and `codesign`) |
| **Internet** | Required for LRCLIB API calls |

> **Note:** You do **not** need Xcode.app installed — just the Command Line Tools.

### Installing Command Line Tools

If you don't have them yet:

```bash
xcode-select --install
```

---

## 🔨 Building

Clone the repo and run the build script:

```bash
git clone https://github.com/guleriaakshit/LyricFetcher.git
cd LyricFetcher
chmod +x build.sh
bash build.sh
```

The build script will:
1. Clean any previous `LyricFetcher.app` bundle
2. Create the `.app` bundle directory structure
3. Copy the app icon into `Resources/`
4. Generate `Info.plist` and `PkgInfo`
5. Compile all Swift sources with `swiftc` targeting `arm64-apple-macosx13.0`
6. Ad-hoc codesign the bundle so macOS recognizes it as a GUI app

On success you'll see:

```
Compiling Swift files...
Built LyricFetcher.app successfully.
```

### Running After Build

**Option A** — Double-click `LyricFetcher.app` in Finder.

**Option B** — Launch from terminal:

```bash
open LyricFetcher.app
```

> **First Launch:** macOS may show a Gatekeeper warning since the app is ad-hoc signed. Right-click the app → **Open** → **Open** to bypass.

---

## 🚀 Usage

### 1. Select Your Music Folder

Click the **Select Folder** button in the top-right corner. Navigate to your music library root folder (e.g., `~/My Music/`). The app will recursively scan all subdirectories for audio files.

The selected folder path is **saved automatically** — next time you launch the app, it will already be selected.

### 2. Start Fetching

Click **Start Fetching**. The app will:

1. **Enumerate** all supported audio files (`.mp3`, `.m4a`, `.flac`, `.wav`, `.aac`)
2. **Pre-check** each file for an existing `.lrc` file with the same name — if found, the track is instantly marked as **Skipped**
3. **Process** remaining tracks one by one:
   - Extract metadata (title, artist, album) from embedded tags
   - Check for embedded lyrics in the file itself
   - Query LRCLIB for synced lyrics (with fallback to plain)
   - Save the result as a `.lrc` file next to the audio file

### 3. Understand the Status Indicators

Each track in the list shows a colored status pill:

| Status | Color | Meaning |
|---|---|---|
| **Pending** | Gray | Waiting to be processed |
| **Fetching…** | Blue | Currently querying LRCLIB |
| **Synced** | Green | ✅ Time-synced lyrics saved (e.g., `[00:12.34] Line...`) |
| **Plain** | Light Blue | ✅ Plain text lyrics saved (no timestamps) |
| **Embedded** | Purple | ✅ Lyrics extracted from the file's own metadata |
| **Skipped** | Amber | ⏭ Skipped — LRC already exists or metadata missing |
| **Failed** | Red | ❌ No lyrics found on LRCLIB |

### 4. Stats Bar

The stats bar at the top shows live counts:

- **Total** — Number of audio files found
- **Synced** — Tracks that received time-synced lyrics
- **Plain** — Tracks that received plain text lyrics
- **Skipped** — Tracks skipped (existing LRC or missing metadata)
- **Failed** — Tracks where no lyrics were found

### 5. Rescanning

When you add new albums to your library and rescan:

- All tracks with existing `.lrc` files are **instantly skipped** (no network calls)
- Only new/unprocessed tracks go through the fetching pipeline
- This makes rescans fast even for large libraries

---

## 📁 Output

For each track that gets lyrics, a `.lrc` file is saved **in the same directory** as the audio file, with the same base name:

```
My Music/
├── Artist/
│   ├── Album/
│   │   ├── 01 Track Name.flac
│   │   ├── 01 Track Name.lrc    ← saved here
│   │   ├── 02 Another Track.flac
│   │   └── 02 Another Track.lrc ← saved here
```

The `.lrc` file format is the standard used by most music players (foobar2000, AIMP, Plexamp, Poweramp, Symfonium, etc.).

---

## 🎶 Supported Audio Formats

| Format | Extension | Metadata Source |
|---|---|---|
| FLAC | `.flac` | Vorbis Comments |
| MP3 | `.mp3` | ID3v2 Tags |
| AAC / ALAC | `.m4a` | iTunes/MP4 Atoms |
| AAC | `.aac` | iTunes/MP4 Atoms |
| WAV | `.wav` | INFO/RIFF Tags |

---

## 🌐 API

LyricFetcher uses the **[LRCLIB](https://lrclib.net)** API — a free, open-source lyrics database.

- **Exact match** endpoint: `/api/get?track_name=...&artist_name=...&album_name=...&duration=...`
- **Search fallback**: `/api/search?q=...` (used when exact match returns 404)
- Synced lyrics are always prioritized over plain lyrics across all search results
- No API key required. Rate limiting is respectful (sequential requests, one at a time)

---

## 🏗️ Project Structure

```
LyricFetcher/
├── Sources/
│   ├── LyricFetcherApp.swift   # App entry point, window configuration
│   ├── ContentView.swift       # Main UI — header, stats, song list, actions
│   ├── AudioScanner.swift      # Core logic — file enumeration, metadata, scanning
│   └── LrcLibClient.swift      # LRCLIB API client — fetch & search endpoints
├── Resources/
│   ├── AppIcon.icns            # App icon bundle
│   └── AppIcon.iconset/        # Icon source images (all sizes)
├── build.sh                    # Build script (compiles + codesigns)
├── .gitignore
└── README.md
```

---

## 🐛 Troubleshooting

### App won't open / crashes on launch

Re-build with `bash build.sh`. If macOS blocks it, right-click → **Open** → **Open**.

### "Missing metadata" on all tracks

Your audio files may not have embedded tags. Use a tagger like [MusicBrainz Picard](https://picard.musicbrainz.org/) or [Mp3tag](https://www.mp3tag.de/en/) to add metadata.

### No lyrics found for most tracks

LRCLIB is community-driven and may not have lyrics for every track. Niche or very new releases may not be indexed yet. The app tries both exact match and fuzzy search as a fallback.

### Build fails with "swiftc: command not found"

Install Xcode Command Line Tools:

```bash
xcode-select --install
```

### Build fails on Intel Mac

The build script targets `arm64`. For Intel, change the target in `build.sh`:

```bash
# Change this line:
-target arm64-apple-macosx13.0
# To:
-target x86_64-apple-macosx13.0
```

---

## 📄 License

This project is open source. Feel free to use, modify, and distribute.

---

## 🙏 Credits

- **[LRCLIB](https://lrclib.net)** — Free, open-source synced lyrics API
- **[AVFoundation](https://developer.apple.com/av-foundation/)** — Apple's framework for audio metadata extraction
- Built with **SwiftUI** for macOS
