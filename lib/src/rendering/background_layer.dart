/// Background Layer for VN Runtime
/// 
/// Handles background image display with transition effects.

import 'dart:async';
import 'package:flutter/material.dart';

/// Transition types for background changes
enum BackgroundTransition {
  none,
  fade,
  dissolve,
  slideLeft,
  slideRight,
  slideUp,
  slideDown,
  wipe,
  pixelate,
}

/// Configuration for background transitions
class BackgroundTransitionConfig {
  final BackgroundTransition type;
  final Duration duration;
  final Curve curve;

  const BackgroundTransitionConfig({
    this.type = BackgroundTransition.fade,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOut,
  });

  static const instant = BackgroundTransitionConfig(
    type: BackgroundTransition.none,
    duration: Duration.zero,
  );

  static const defaultFade = BackgroundTransitionConfig(
    type: BackgroundTransition.fade,
    duration: Duration(milliseconds: 500),
  );

  static const slowDissolve = BackgroundTransitionConfig(
    type: BackgroundTransition.dissolve,
    duration: Duration(milliseconds: 1000),
  );
}

/// Controller for managing background state and transitions
class BackgroundController extends ChangeNotifier {
  String? _currentBackgroundPath;
  String? _previousBackgroundPath;
  BackgroundTransitionConfig _transitionConfig = BackgroundTransitionConfig.defaultFade;
  bool _isTransitioning = false;
  double _transitionProgress = 1.0;
  Timer? _transitionTimer;

  String? get currentBackgroundPath => _currentBackgroundPath;
  String? get previousBackgroundPath => _previousBackgroundPath;
  BackgroundTransitionConfig get transitionConfig => _transitionConfig;
  bool get isTransitioning => _isTransitioning;
  double get transitionProgress => _transitionProgress;

  /// Change background with optional transition
  Future<void> changeBackground(
    String? newPath, {
    BackgroundTransitionConfig? transition,
  }) async {
    if (newPath == _currentBackgroundPath) return;

    _transitionConfig = transition ?? BackgroundTransitionConfig.defaultFade;
    
    if (_transitionConfig.type == BackgroundTransition.none) {
      _currentBackgroundPath = newPath;
      _previousBackgroundPath = null;
      notifyListeners();
      return;
    }

    _previousBackgroundPath = _currentBackgroundPath;
    _currentBackgroundPath = newPath;
    _isTransitioning = true;
    _transitionProgress = 0.0;
    notifyListeners();

    // Animate transition
    final completer = Completer<void>();
    final startTime = DateTime.now();
    
    _transitionTimer?.cancel();
    _transitionTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsed = DateTime.now().difference(startTime);
      final progress = (elapsed.inMilliseconds / _transitionConfig.duration.inMilliseconds)
          .clamp(0.0, 1.0);
      
      _transitionProgress = _transitionConfig.curve.transform(progress);
      notifyListeners();

      if (progress >= 1.0) {
        timer.cancel();
        _isTransitioning = false;
        _previousBackgroundPath = null;
        notifyListeners();
        completer.complete();
      }
    });

    return completer.future;
  }

  /// Clear background
  void clearBackground() {
    _currentBackgroundPath = null;
    _previousBackgroundPath = null;
    _isTransitioning = false;
    _transitionProgress = 1.0;
    _transitionTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    super.dispose();
  }
}

/// Widget that displays the background with transitions
class BackgroundLayer extends StatelessWidget {
  final BackgroundController controller;
  final ImageProvider Function(String path)? imageProvider;
  final Color backgroundColor;
  final BoxFit fit;

  const BackgroundLayer({
    super.key,
    required this.controller,
    this.imageProvider,
    this.backgroundColor = Colors.black,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          color: backgroundColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Previous background (during transition)
              if (controller.isTransitioning && controller.previousBackgroundPath != null)
                _buildBackgroundImage(
                  controller.previousBackgroundPath!,
                  opacity: _getPreviousOpacity(),
                  offset: _getPreviousOffset(),
                ),
              
              // Current background
              if (controller.currentBackgroundPath != null)
                _buildBackgroundImage(
                  controller.currentBackgroundPath!,
                  opacity: _getCurrentOpacity(),
                  offset: _getCurrentOffset(),
                  pixelate: _shouldPixelate(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundImage(
    String path, {
    double opacity = 1.0,
    Offset offset = Offset.zero,
    bool pixelate = false,
  }) {
    Widget image;
    
    if (imageProvider != null) {
      image = Image(
        image: imageProvider!(path),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
            ),
          );
        },
      );
    } else {
      // Default: try to load as asset or file
      image = Image.asset(
        path,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
            ),
          );
        },
      );
    }

    if (pixelate) {
      image = _PixelateEffect(
        progress: controller.transitionProgress,
        child: image,
      );
    }

    return Transform.translate(
      offset: offset,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: image,
      ),
    );
  }

  double _getCurrentOpacity() {
    if (!controller.isTransitioning) return 1.0;
    
    switch (controller.transitionConfig.type) {
      case BackgroundTransition.fade:
      case BackgroundTransition.dissolve:
        return controller.transitionProgress;
      case BackgroundTransition.pixelate:
        return controller.transitionProgress > 0.5 ? 1.0 : 0.0;
      default:
        return 1.0;
    }
  }

  double _getPreviousOpacity() {
    if (!controller.isTransitioning) return 0.0;
    
    switch (controller.transitionConfig.type) {
      case BackgroundTransition.fade:
        return 1.0 - controller.transitionProgress;
      case BackgroundTransition.dissolve:
        return 1.0; // Both visible during dissolve
      case BackgroundTransition.pixelate:
        return controller.transitionProgress > 0.5 ? 0.0 : 1.0;
      default:
        return 1.0 - controller.transitionProgress;
    }
  }

  Offset _getCurrentOffset() {
    if (!controller.isTransitioning) return Offset.zero;
    
    // Get screen size approximation
    const screenWidth = 1920.0;
    const screenHeight = 1080.0;
    final progress = controller.transitionProgress;
    
    switch (controller.transitionConfig.type) {
      case BackgroundTransition.slideLeft:
        return Offset(screenWidth * (1 - progress), 0);
      case BackgroundTransition.slideRight:
        return Offset(-screenWidth * (1 - progress), 0);
      case BackgroundTransition.slideUp:
        return Offset(0, screenHeight * (1 - progress));
      case BackgroundTransition.slideDown:
        return Offset(0, -screenHeight * (1 - progress));
      default:
        return Offset.zero;
    }
  }

  Offset _getPreviousOffset() {
    if (!controller.isTransitioning) return Offset.zero;
    
    const screenWidth = 1920.0;
    const screenHeight = 1080.0;
    final progress = controller.transitionProgress;
    
    switch (controller.transitionConfig.type) {
      case BackgroundTransition.slideLeft:
        return Offset(-screenWidth * progress, 0);
      case BackgroundTransition.slideRight:
        return Offset(screenWidth * progress, 0);
      case BackgroundTransition.slideUp:
        return Offset(0, -screenHeight * progress);
      case BackgroundTransition.slideDown:
        return Offset(0, screenHeight * progress);
      default:
        return Offset.zero;
    }
  }

  bool _shouldPixelate() {
    return controller.isTransitioning && 
           controller.transitionConfig.type == BackgroundTransition.pixelate;
  }
}

/// Pixelate effect widget for pixelate transition
class _PixelateEffect extends StatelessWidget {
  final double progress;
  final Widget child;

  const _PixelateEffect({
    required this.progress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate pixel size based on progress
    // At progress 0.5, maximum pixelation; at 0 and 1, no pixelation
    final pixelProgress = progress < 0.5 
        ? progress * 2 
        : (1 - progress) * 2;
    
    if (pixelProgress < 0.01) {
      return child;
    }

    // Use a simple blur approximation for pixelation effect
    final sigma = pixelProgress * 20;
    
    return ImageFiltered(
      imageFilter: ColorFilter.mode(
        Colors.transparent,
        BlendMode.srcOver,
      ),
      child: child,
    );
  }
}

/// Extension to create transition configs from string names
extension BackgroundTransitionExtension on String {
  BackgroundTransitionConfig toTransitionConfig({
    Duration? duration,
    Curve? curve,
  }) {
    final type = BackgroundTransition.values.firstWhere(
      (t) => t.name.toLowerCase() == toLowerCase(),
      orElse: () => BackgroundTransition.fade,
    );
    
    return BackgroundTransitionConfig(
      type: type,
      duration: duration ?? const Duration(milliseconds: 500),
      curve: curve ?? Curves.easeInOut,
    );
  }
}
