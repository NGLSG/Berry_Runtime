/// Video Background Widget for Main Menu
/// 
/// Supports MP4/WebM video playback as menu background

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/vn_project.dart';

/// Video background widget with loop and mute support
class VideoBackground extends StatefulWidget {
  final String videoPath;
  final bool loop;
  final bool muted;
  final double playbackSpeed;
  final Widget? overlay;
  final BoxFit fit;
  
  const VideoBackground({
    super.key,
    required this.videoPath,
    this.loop = true,
    this.muted = true,
    this.playbackSpeed = 1.0,
    this.overlay,
    this.fit = BoxFit.cover,
  });
  
  /// Create from VNMainMenuConfig
  factory VideoBackground.fromConfig(VNMainMenuConfig config, {Widget? overlay}) {
    return VideoBackground(
      videoPath: config.backgroundVideo ?? '',
      loop: config.videoLoop,
      muted: config.videoMuted,
      playbackSpeed: config.videoSpeed,
      overlay: overlay,
    );
  }
  
  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }
  
  @override
  void didUpdateWidget(VideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _disposeController();
      _initializeVideo();
    } else {
      _updateSettings();
    }
  }
  
  void _initializeVideo() async {
    if (widget.videoPath.isEmpty) {
      setState(() => _hasError = true);
      return;
    }
    
    try {
      // Determine video source type
      VideoPlayerController controller;
      if (widget.videoPath.startsWith('http://') || 
          widget.videoPath.startsWith('https://')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else {
        controller = VideoPlayerController.asset(widget.videoPath);
      }
      
      _controller = controller;
      
      await _controller!.initialize();
      
      if (mounted) {
        _controller!.setLooping(widget.loop);
        _controller!.setVolume(widget.muted ? 0.0 : 1.0);
        _controller!.setPlaybackSpeed(widget.playbackSpeed);
        _controller!.play();
        
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }
  
  void _updateSettings() {
    if (_controller != null && _isInitialized) {
      _controller!.setLooping(widget.loop);
      _controller!.setVolume(widget.muted ? 0.0 : 1.0);
      _controller!.setPlaybackSpeed(widget.playbackSpeed);
    }
  }
  
  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
  
  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_hasError || !_isInitialized || _controller == null) {
      return _buildFallback();
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player
        FittedBox(
          fit: widget.fit,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
        // Optional overlay
        if (widget.overlay != null) widget.overlay!,
      ],
    );
  }
  
  Widget _buildFallback() {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _hasError ? Icons.error_outline : Icons.hourglass_empty,
              color: Colors.white24,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              _hasError ? '视频加载失败' : '加载中...',
              style: const TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated background with Ken Burns effect
class AnimatedBackground extends StatefulWidget {
  final String imagePath;
  final String animationType; // 'none', 'parallax', 'slowZoom', 'ken_burns'
  final double animationSpeed;
  final Widget? overlay;
  
  const AnimatedBackground({
    super.key,
    required this.imagePath,
    this.animationType = 'none',
    this.animationSpeed = 1.0,
    this.overlay,
  });
  
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _positionAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (20000 / widget.animationSpeed).round()),
    );
    
    _setupAnimations();
    
    if (widget.animationType != 'none') {
      _controller.repeat(reverse: true);
    }
  }
  
  void _setupAnimations() {
    switch (widget.animationType) {
      case 'slowZoom':
        _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        _positionAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: Offset.zero,
        ).animate(_controller);
        break;
      case 'ken_burns':
        _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        _positionAnimation = Tween<Offset>(
          begin: const Offset(-0.02, -0.02),
          end: const Offset(0.02, 0.02),
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
        break;
      case 'parallax':
        _scaleAnimation = Tween<double>(begin: 1.05, end: 1.05).animate(_controller);
        _positionAnimation = Tween<Offset>(
          begin: const Offset(-0.02, 0),
          end: const Offset(0.02, 0),
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
        break;
      default:
        _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
        _positionAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: Offset.zero,
        ).animate(_controller);
    }
  }
  
  @override
  void didUpdateWidget(AnimatedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationType != widget.animationType ||
        oldWidget.animationSpeed != widget.animationSpeed) {
      _controller.duration = Duration(
        milliseconds: (20000 / widget.animationSpeed).round(),
      );
      _setupAnimations();
      if (widget.animationType != 'none') {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _positionAnimation.value.dx * MediaQuery.of(context).size.width,
                _positionAnimation.value.dy * MediaQuery.of(context).size.height,
              ),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Image.asset(
            widget.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: const Color(0xFF1A1A2E));
            },
          ),
        ),
        if (widget.overlay != null) widget.overlay!,
      ],
    );
  }
}
