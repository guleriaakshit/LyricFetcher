import SwiftUI

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.06, blue: 0.15),
                Color(red: 0.14, green: 0.08, blue: 0.22),
                Color(red: 0.11, green: 0.07, blue: 0.20),
                Color(red: 0.08, green: 0.05, blue: 0.16)
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Glass Card Modifier
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(0.6))
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Pulsing Dot Animation
struct PulsingDot: View {
    @State private var isPulsing = false
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .scaleEffect(isPulsing ? 1.3 : 0.8)
            .opacity(isPulsing ? 1 : 0.5)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: ScanStatus
    var lyricsType: LyricsType? = nil
    
    var body: some View {
        HStack(spacing: 6) {
            statusIcon
            statusText
        }
        .font(.caption)
        .fontWeight(.medium)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .pending:
            Circle()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 6, height: 6)
        case .processing:
            PulsingDot(color: Color(red: 0.4, green: 0.6, blue: 1.0))
        case .success:
            Image(systemName: lyricsTypeIcon)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(lyricsTypeColor)
        case .failed:
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(red: 1.0, green: 0.42, blue: 0.54))
        case .skipped:
            Image(systemName: "forward.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Color(red: 1.0, green: 0.70, blue: 0.28))
        }
    }
    
    private var lyricsTypeIcon: String {
        switch lyricsType {
        case .synced: return "timer"
        case .plain: return "text.alignleft"
        case .embedded: return "square.and.arrow.down.fill"
        case nil: return "checkmark"
        }
    }
    
    private var lyricsTypeColor: Color {
        switch lyricsType {
        case .synced: return Color(red: 0.0, green: 0.83, blue: 0.67)
        case .plain: return Color(red: 0.4, green: 0.75, blue: 1.0)
        case .embedded: return Color(red: 0.65, green: 0.55, blue: 1.0)
        case nil: return Color(red: 0.0, green: 0.83, blue: 0.67)
        }
    }
    
    private var statusText: some View {
        Text(statusLabel)
            .foregroundColor(statusColor)
    }
    
    private var statusLabel: String {
        switch status {
        case .pending: return "Pending"
        case .processing: return "Fetching…"
        case .success:
            switch lyricsType {
            case .synced: return "Synced"
            case .plain: return "Plain"
            case .embedded: return "Embedded"
            case nil: return "Done"
            }
        case .failed(let msg): return msg
        case .skipped(let msg): return msg
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending: return .secondary
        case .processing: return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .success: return lyricsTypeColor
        case .failed: return Color(red: 1.0, green: 0.42, blue: 0.54)
        case .skipped: return Color(red: 1.0, green: 0.70, blue: 0.28)
        }
    }
}

// MARK: - Song Row
struct SongRow: View {
    let task: ScanTask
    let index: Int
    @State private var appeared = false
    
    private var fileIcon: String {
        let ext = task.url.pathExtension.lowercased()
        switch ext {
        case "flac": return "waveform"
        case "mp3": return "music.note"
        case "m4a": return "music.quarternote.3"
        case "wav": return "waveform.path"
        default: return "music.note"
        }
    }
    
    private var accentColor: Color {
        let colors: [Color] = [
            Color(red: 0.55, green: 0.36, blue: 0.96),
            Color(red: 0.40, green: 0.60, blue: 1.0),
            Color(red: 0.0, green: 0.83, blue: 0.67),
            Color(red: 1.0, green: 0.70, blue: 0.28),
            Color(red: 1.0, green: 0.42, blue: 0.54)
        ]
        return colors[index % colors.count]
    }
    
    /// Display name: prefer metadata title, fall back to filename
    private var displayTitle: String {
        if let title = task.title, !title.isEmpty {
            return title
        }
        return task.url.deletingPathExtension().lastPathComponent
    }
    
    /// Subtitle: show artist if available, otherwise file format
    private var displaySubtitle: String {
        if let artist = task.artist, !artist.isEmpty {
            return artist
        }
        return task.url.pathExtension.uppercased()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // File icon with colored background
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: fileIcon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            
            // Track metadata
            VStack(alignment: .leading, spacing: 2) {
                Text(displayTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(displaySubtitle)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Status badge with lyrics type
            StatusBadge(status: task.status, lyricsType: task.lyricsType)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.02)) {
                appeared = true
            }
        }
    }
}

// MARK: - Stat Pill
struct StatPill: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Custom Progress Bar
struct GradientProgressBar: View {
    let progress: Double
    
    private let gradient = LinearGradient(
        colors: [
            Color(red: 0.55, green: 0.36, blue: 0.96),
            Color(red: 0.0, green: 0.83, blue: 0.67)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 6)
                
                // Fill
                Capsule()
                    .fill(gradient)
                    .frame(width: max(0, geometry.size.width * CGFloat(progress)), height: 6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                
                // Glow on the leading edge
                if progress > 0 && progress < 1 {
                    Circle()
                        .fill(Color(red: 0.0, green: 0.83, blue: 0.67))
                        .frame(width: 10, height: 10)
                        .blur(radius: 4)
                        .offset(x: max(0, geometry.size.width * CGFloat(progress) - 5))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                }
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var scanner = AudioScanner()
    @State private var selectedDirectory: URL?
    @State private var showTitle = false
    
    var body: some View {
        ZStack {
            // Animated background
            AnimatedGradientBackground()
            
            // Decorative orbs
            decorativeOrbs
            
            // Main content
            VStack(spacing: 0) {
                // Draggable title bar area
                Color.clear
                    .frame(height: 12)
                
                VStack(spacing: 18) {
                    headerSection
                    statsSection
                    songListSection
                    bottomSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .frame(minWidth: 660, minHeight: 560)
        .onAppear {
            // Restore last selected folder
            if selectedDirectory == nil {
                selectedDirectory = AudioScanner.loadLastFolder()
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showTitle = true
            }
        }
    }
    
    // MARK: - Decorative Orbs
    private var decorativeOrbs: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -150, y: -200)
            
            Circle()
                .fill(Color(red: 0.0, green: 0.83, blue: 0.67).opacity(0.08))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 180, y: 150)
            
            Circle()
                .fill(Color(red: 1.0, green: 0.42, blue: 0.54).opacity(0.06))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 100, y: -100)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center) {
                // App title with icon
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.55, green: 0.36, blue: 0.96),
                                        Color(red: 0.40, green: 0.60, blue: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "music.note.list")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("LyricFetcher")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.white.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : -10)
                
                Spacer()
                
                // Select folder button
                Button(action: selectFolder) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Select Folder")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.55, green: 0.36, blue: 0.96),
                                Color(red: 0.40, green: 0.50, blue: 0.96)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.4), radius: 8, y: 3)
                }
                .buttonStyle(.plain)
                .disabled(scanner.isScanning)
                .opacity(scanner.isScanning ? 0.5 : 1)
            }
            
            // Directory path display
            if let dir = selectedDirectory {
                HStack(spacing: 8) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.55, green: 0.36, blue: 0.96))
                    
                    Text(dir.path)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .glassCard(cornerRadius: 10)
            }
        }
    }
    
    // MARK: - Stats Section
    @ViewBuilder
    private var statsSection: some View {
        if !scanner.tasks.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    StatPill(
                        icon: "music.note.list",
                        label: "Total",
                        count: scanner.totalCount,
                        color: Color(red: 0.55, green: 0.36, blue: 0.96)
                    )
                    StatPill(
                        icon: "timer",
                        label: "Synced",
                        count: scanner.syncedCount,
                        color: Color(red: 0.0, green: 0.83, blue: 0.67)
                    )
                    StatPill(
                        icon: "text.alignleft",
                        label: "Plain",
                        count: scanner.plainCount,
                        color: Color(red: 0.4, green: 0.75, blue: 1.0)
                    )
                    StatPill(
                        icon: "forward.fill",
                        label: "Skipped",
                        count: scanner.skippedCount,
                        color: Color(red: 1.0, green: 0.70, blue: 0.28)
                    )
                    StatPill(
                        icon: "xmark.circle.fill",
                        label: "Failed",
                        count: scanner.failedCount,
                        color: Color(red: 1.0, green: 0.42, blue: 0.54)
                    )
                }
                .padding(.horizontal, 2)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    
    // MARK: - Song List
    private var songListSection: some View {
        VStack(spacing: 0) {
            if scanner.tasks.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "music.note.list")
                            .font(.system(size: 30, weight: .light))
                            .foregroundColor(Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.6))
                    }
                    
                    VStack(spacing: 6) {
                        Text("No Music Loaded")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        Text("Select a folder to scan for audio files")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Song list
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(scanner.tasks.enumerated()), id: \.element.id) { index, task in
                            SongRow(task: task, index: index)
                        }
                    }
                    .padding(8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassCard(cornerRadius: 16)
    }
    
    // MARK: - Bottom Section
    private var bottomSection: some View {
        VStack(spacing: 14) {
            // Progress bar (only when scanning or done scanning with results)
            if !scanner.tasks.isEmpty {
                VStack(spacing: 6) {
                    GradientProgressBar(progress: scanner.progress)
                    
                    HStack {
                        Text("\(scanner.processedCount) of \(scanner.totalCount) processed")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(scanner.progress * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.0, green: 0.83, blue: 0.67))
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Action button
            Button(action: startFetching) {
                HStack(spacing: 8) {
                    if scanner.isScanning {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    
                    Text(scanner.isScanning ? "Fetching Lyrics…" : "Start Fetching")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if selectedDirectory == nil || scanner.isScanning {
                            LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            LinearGradient(
                                colors: [
                                    Color(red: 0.55, green: 0.36, blue: 0.96),
                                    Color(red: 0.40, green: 0.50, blue: 0.96),
                                    Color(red: 0.0, green: 0.73, blue: 0.67)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(
                    color: selectedDirectory != nil && !scanner.isScanning
                        ? Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.4)
                        : Color.clear,
                    radius: 12, y: 4
                )
            }
            .buttonStyle(.plain)
            .disabled(selectedDirectory == nil || scanner.isScanning)
        }
    }
    
    // MARK: - Actions
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        // Start from last saved folder if available
        if let saved = selectedDirectory {
            panel.directoryURL = saved
        }
        
        if panel.runModal() == .OK {
            selectedDirectory = panel.url
            if let url = panel.url {
                AudioScanner.saveLastFolder(url)
            }
        }
    }
    
    private func startFetching() {
        if let dir = selectedDirectory {
            Task {
                await scanner.scan(directory: dir)
            }
        }
    }
}
