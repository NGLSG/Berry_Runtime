/// Music Room Screen Widget
/// 
/// Displays unlocked BGM tracks with playback controls.
/// Supports playing, pausing, and track navigation.

import 'package:flutter/material.dart';

import '../localization/vn_ui_strings.dart';

/// A single music track in the music room
class MusicTrack {
  /// Unique identifier
  final String id;
  
  /// Display name
  final String name;
  
  /// Artist/Composer name
  final String? artist;
  
  /// Audio file path
  final String audioPath;
  
  /// Album art path (optional)
  final String? albumArtPath;
  
  /// Whether this track is unlocked
  final bool isUnlocked;
  
  /// Category (e.g., 'BGM', 'Theme', 'Ending', etc.)
  final String? category;
  
  /// Duration in seconds
  final int? durationSeconds;

  const MusicTrack({
    required this.id,
    required this.name,
    this.artist,
    required this.audioPath,
    this.albumArtPath,
    this.isUnlocked = false,
    this.category,
    this.durationSeconds,
  });

  String get formattedDuration {
    if (durationSeconds == null) return '--:--';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Configuration for the music room screen
class MusicRoomScreenConfig {
  /// Background color
  final Color backgroundColor;
  
  /// Panel background color
  final Color panelBackgroundColor;
  
  /// Text color
  final Color textColor;
  
  /// Secondary text color
  final Color secondaryTextColor;
  
  /// Accent color
  final Color accentColor;
  
  /// Playing track highlight color
  final Color playingHighlightColor;
  
  /// Title font size
  final double titleFontSize;

  const MusicRoomScreenConfig({
    this.backgroundColor = const Color(0xDD000000),
    this.panelBackgroundColor = const Color(0xFF1A1A2E),
    this.textColor = Colors.white,
    this.secondaryTextColor = const Color(0xAAFFFFFF),
    this.accentColor = const Color(0xFF6C63FF),
    this.playingHighlightColor = const Color(0x336C63FF),
    this.titleFontSize = 28.0,
  });
}

/// Music room screen widget
class MusicRoomScreen extends StatefulWidget {
  /// List of music tracks
  final List<MusicTrack> tracks;
  
  /// Callback when back is pressed
  final VoidCallback? onBack;
  
  /// Callback when a track should be played
  final void Function(MusicTrack track)? onPlay;
  
  /// Callback when playback should stop
  final VoidCallback? onStop;
  
  /// Currently playing track ID
  final String? currentlyPlayingId;
  
  /// Whether currently playing
  final bool isPlaying;
  
  /// Current playback position (0.0 - 1.0)
  final double playbackPosition;
  
  /// Configuration
  final MusicRoomScreenConfig config;
  
  /// Whether to show locked tracks
  final bool showLockedTracks;
  
  /// Language code for UI localization
  final String languageCode;

  const MusicRoomScreen({
    super.key,
    required this.tracks,
    this.onBack,
    this.onPlay,
    this.onStop,
    this.currentlyPlayingId,
    this.isPlaying = false,
    this.playbackPosition = 0.0,
    this.config = const MusicRoomScreenConfig(),
    this.showLockedTracks = true,
    this.languageCode = 'en',
  });

  @override
  State<MusicRoomScreen> createState() => _MusicRoomScreenState();
}

class _MusicRoomScreenState extends State<MusicRoomScreen> {
  String? _selectedCategory;

  List<String> get _categories {
    final cats = widget.tracks
        .map((e) => e.category)
        .where((c) => c != null)
        .cast<String>()
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  List<MusicTrack> get _filteredTracks {
    var tracks = widget.tracks;
    if (!widget.showLockedTracks) {
      tracks = tracks.where((e) => e.isUnlocked).toList();
    }
    if (_selectedCategory != null) {
      tracks = tracks.where((e) => e.category == _selectedCategory).toList();
    }
    return tracks;
  }

  MusicTrack? get _currentTrack {
    if (widget.currentlyPlayingId == null) return null;
    try {
      return widget.tracks.firstWhere((t) => t.id == widget.currentlyPlayingId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.config.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_categories.isNotEmpty) _buildCategoryTabs(),
            Expanded(child: _buildTrackList()),
            _buildNowPlaying(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: widget.config.textColor),
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 16),
          Text(
            VNUILocalizer.get('musicRoom', widget.languageCode),
            style: TextStyle(
              color: widget.config.textColor,
              fontSize: widget.config.titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Icon(Icons.music_note, color: widget.config.accentColor),
          const SizedBox(width: 8),
          Text(
            '${_filteredTracks.where((e) => e.isUnlocked).length}/${_filteredTracks.length}',
            style: TextStyle(color: widget.config.secondaryTextColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryTab(
            label: VNUILocalizer.get('all', widget.languageCode),
            isSelected: _selectedCategory == null,
            config: widget.config,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          ..._categories.map((cat) => _CategoryTab(
            label: cat,
            isSelected: _selectedCategory == cat,
            config: widget.config,
            onTap: () => setState(() => _selectedCategory = cat),
          )),
        ],
      ),
    );
  }

  Widget _buildTrackList() {
    final tracks = _filteredTracks;
    
    if (tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_off, size: 64, color: widget.config.secondaryTextColor),
            const SizedBox(height: 16),
            Text(
              VNUILocalizer.get('noMusicAvailable', widget.languageCode),
              style: TextStyle(color: widget.config.secondaryTextColor, fontSize: 18),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isCurrentTrack = track.id == widget.currentlyPlayingId;
        
        return _TrackListItem(
          track: track,
          config: widget.config,
          isPlaying: isCurrentTrack && widget.isPlaying,
          isCurrentTrack: isCurrentTrack,
          onTap: track.isUnlocked ? () => widget.onPlay?.call(track) : null,
        );
      },
    );
  }

  Widget _buildNowPlaying() {
    final track = _currentTrack;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.config.panelBackgroundColor,
        border: Border(
          top: BorderSide(color: widget.config.accentColor.withOpacity(0.3)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: widget.playbackPosition,
            backgroundColor: widget.config.secondaryTextColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(widget.config.accentColor),
          ),
          const SizedBox(height: 12),
          
          // Track info and controls
          Row(
            children: [
              // Album art
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.config.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: track?.albumArtPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          track!.albumArtPath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.music_note,
                            color: widget.config.accentColor,
                          ),
                        ),
                      )
                    : Icon(Icons.music_note, color: widget.config.accentColor),
              ),
              const SizedBox(width: 12),
              
              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track?.name ?? VNUILocalizer.get('noTrackSelected', widget.languageCode),
                      style: TextStyle(
                        color: widget.config.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (track?.artist != null)
                      Text(
                        track!.artist!,
                        style: TextStyle(
                          color: widget.config.secondaryTextColor,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              // Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.skip_previous, color: widget.config.textColor),
                    onPressed: track != null ? () => _playPrevious() : null,
                  ),
                  IconButton(
                    icon: Icon(
                      widget.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: widget.config.accentColor,
                      size: 40,
                    ),
                    onPressed: track != null
                        ? () {
                            if (widget.isPlaying) {
                              widget.onStop?.call();
                            } else {
                              widget.onPlay?.call(track);
                            }
                          }
                        : null,
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next, color: widget.config.textColor),
                    onPressed: track != null ? () => _playNext() : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _playPrevious() {
    final unlockedTracks = _filteredTracks.where((t) => t.isUnlocked).toList();
    if (unlockedTracks.isEmpty) return;
    
    final currentIndex = unlockedTracks.indexWhere((t) => t.id == widget.currentlyPlayingId);
    if (currentIndex <= 0) {
      widget.onPlay?.call(unlockedTracks.last);
    } else {
      widget.onPlay?.call(unlockedTracks[currentIndex - 1]);
    }
  }

  void _playNext() {
    final unlockedTracks = _filteredTracks.where((t) => t.isUnlocked).toList();
    if (unlockedTracks.isEmpty) return;
    
    final currentIndex = unlockedTracks.indexWhere((t) => t.id == widget.currentlyPlayingId);
    if (currentIndex < 0 || currentIndex >= unlockedTracks.length - 1) {
      widget.onPlay?.call(unlockedTracks.first);
    } else {
      widget.onPlay?.call(unlockedTracks[currentIndex + 1]);
    }
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final MusicRoomScreenConfig config;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.isSelected,
    required this.config,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: config.panelBackgroundColor,
        selectedColor: config.accentColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : config.secondaryTextColor,
        ),
      ),
    );
  }
}

class _TrackListItem extends StatefulWidget {
  final MusicTrack track;
  final MusicRoomScreenConfig config;
  final bool isPlaying;
  final bool isCurrentTrack;
  final VoidCallback? onTap;

  const _TrackListItem({
    required this.track,
    required this.config,
    required this.isPlaying,
    required this.isCurrentTrack,
    this.onTap,
  });

  @override
  State<_TrackListItem> createState() => _TrackListItemState();
}

class _TrackListItemState extends State<_TrackListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLocked = !widget.track.isUnlocked;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isLocked ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isCurrentTrack
                ? widget.config.playingHighlightColor
                : _isHovered && !isLocked
                    ? widget.config.panelBackgroundColor
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isCurrentTrack
                  ? widget.config.accentColor
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              // Play indicator or track number
              SizedBox(
                width: 32,
                child: widget.isPlaying
                    ? Icon(Icons.equalizer, color: widget.config.accentColor, size: 20)
                    : isLocked
                        ? Icon(Icons.lock, color: widget.config.secondaryTextColor, size: 16)
                        : Icon(Icons.play_arrow, color: widget.config.secondaryTextColor, size: 20),
              ),
              
              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLocked ? '???' : widget.track.name,
                      style: TextStyle(
                        color: isLocked
                            ? widget.config.secondaryTextColor
                            : widget.config.textColor,
                        fontSize: 14,
                        fontWeight: widget.isCurrentTrack ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (widget.track.artist != null && !isLocked)
                      Text(
                        widget.track.artist!,
                        style: TextStyle(
                          color: widget.config.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Duration
              Text(
                isLocked ? '--:--' : widget.track.formattedDuration,
                style: TextStyle(
                  color: widget.config.secondaryTextColor,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
