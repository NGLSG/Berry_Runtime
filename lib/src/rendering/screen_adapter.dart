/// Screen Adaptation System
/// 
/// Handles different screen sizes and aspect ratios:
/// - Letterbox (black bars top/bottom)
/// - Pillarbox (black bars left/right)
/// - Stretch (fill screen, may distort)
/// - Crop (fill screen, may cut content)
/// - Safe area handling

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Screen adaptation mode
enum ScreenAdaptMode {
  /// Add black bars to maintain aspect ratio (letterbox/pillarbox)
  letterbox,
  
  /// Stretch to fill screen (may distort)
  stretch,
  
  /// Crop to fill screen (may cut content)
  crop,
  
  /// Scale to fit within screen (may have empty space)
  contain,
  
  /// Scale to cover screen (may overflow)
  cover,
}

/// Screen adapter configuration
class ScreenAdapterConfig {
  /// Target aspect ratio (width / height)
  final double targetAspectRatio;
  
  /// Adaptation mode
  final ScreenAdaptMode mode;
  
  /// Background color for letterbox/pillarbox bars
  final Color backgroundColor;
  
  /// Whether to respect safe areas (notches, etc.)
  final bool respectSafeArea;
  
  /// Minimum scale factor (prevent too small)
  final double minScale;
  
  /// Maximum scale factor (prevent too large)
  final double maxScale;
  
  const ScreenAdapterConfig({
    this.targetAspectRatio = 16 / 9,
    this.mode = ScreenAdaptMode.letterbox,
    this.backgroundColor = Colors.black,
    this.respectSafeArea = true,
    this.minScale = 0.5,
    this.maxScale = 2.0,
  });
  
  /// Common aspect ratios
  static const double ratio16x9 = 16 / 9;
  static const double ratio4x3 = 4 / 3;
  static const double ratio21x9 = 21 / 9;
  static const double ratio1x1 = 1;
}

/// Screen adapter widget
class ScreenAdapter extends StatelessWidget {
  final Widget child;
  final ScreenAdapterConfig config;
  
  const ScreenAdapter({
    super.key,
    required this.child,
    this.config = const ScreenAdapterConfig(),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        final adaptedLayout = _calculateLayout(screenSize);
        
        return Container(
          color: config.backgroundColor,
          child: Stack(
            children: [
              Positioned(
                left: adaptedLayout.offset.dx,
                top: adaptedLayout.offset.dy,
                width: adaptedLayout.size.width,
                height: adaptedLayout.size.height,
                child: config.mode == ScreenAdaptMode.crop
                    ? ClipRect(
                        child: OverflowBox(
                          maxWidth: adaptedLayout.contentSize.width,
                          maxHeight: adaptedLayout.contentSize.height,
                          child: child,
                        ),
                      )
                    : SizedBox(
                        width: adaptedLayout.contentSize.width,
                        height: adaptedLayout.contentSize.height,
                        child: FittedBox(
                          fit: _getBoxFit(),
                          child: SizedBox(
                            width: adaptedLayout.contentSize.width,
                            height: adaptedLayout.contentSize.height,
                            child: child,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  BoxFit _getBoxFit() {
    switch (config.mode) {
      case ScreenAdaptMode.letterbox:
      case ScreenAdaptMode.contain:
        return BoxFit.contain;
      case ScreenAdaptMode.stretch:
        return BoxFit.fill;
      case ScreenAdaptMode.crop:
      case ScreenAdaptMode.cover:
        return BoxFit.cover;
    }
  }
  
  _AdaptedLayout _calculateLayout(Size screenSize) {
    final screenAspect = screenSize.width / screenSize.height;
    final targetAspect = config.targetAspectRatio;
    
    double width, height;
    double offsetX = 0, offsetY = 0;
    
    switch (config.mode) {
      case ScreenAdaptMode.letterbox:
      case ScreenAdaptMode.contain:
        if (screenAspect > targetAspect) {
          // Screen is wider - pillarbox (bars on sides)
          height = screenSize.height;
          width = height * targetAspect;
          offsetX = (screenSize.width - width) / 2;
        } else {
          // Screen is taller - letterbox (bars on top/bottom)
          width = screenSize.width;
          height = width / targetAspect;
          offsetY = (screenSize.height - height) / 2;
        }
        break;
        
      case ScreenAdaptMode.stretch:
        width = screenSize.width;
        height = screenSize.height;
        break;
        
      case ScreenAdaptMode.crop:
      case ScreenAdaptMode.cover:
        if (screenAspect > targetAspect) {
          // Screen is wider - crop top/bottom
          width = screenSize.width;
          height = width / targetAspect;
          offsetY = (screenSize.height - height) / 2;
        } else {
          // Screen is taller - crop sides
          height = screenSize.height;
          width = height * targetAspect;
          offsetX = (screenSize.width - width) / 2;
        }
        break;
    }
    
    // Apply scale limits
    final scale = (width / (screenSize.height * targetAspect))
        .clamp(config.minScale, config.maxScale);
    
    return _AdaptedLayout(
      size: Size(width.clamp(0, screenSize.width), height.clamp(0, screenSize.height)),
      offset: Offset(offsetX.clamp(0, screenSize.width), offsetY.clamp(0, screenSize.height)),
      contentSize: Size(
        screenSize.height * targetAspect,
        screenSize.height,
      ),
      scale: scale,
    );
  }
}

class _AdaptedLayout {
  final Size size;
  final Offset offset;
  final Size contentSize;
  final double scale;
  
  const _AdaptedLayout({
    required this.size,
    required this.offset,
    required this.contentSize,
    required this.scale,
  });
}

/// Safe area wrapper that respects device notches and system UI
class VNSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final Color backgroundColor;
  
  const VNSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.backgroundColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: child,
      ),
    );
  }
}

/// Responsive layout helper
class VNResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  /// Breakpoint for tablet (default 600)
  final double tabletBreakpoint;
  
  /// Breakpoint for desktop (default 1200)
  final double desktopBreakpoint;
  
  const VNResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.tabletBreakpoint = 600,
    this.desktopBreakpoint = 1200,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        if (width >= desktopBreakpoint && desktop != null) {
          return desktop!;
        } else if (width >= tabletBreakpoint && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
  
  /// Get current device type
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Orientation lock wrapper
class VNOrientationLock extends StatefulWidget {
  final Widget child;
  final List<DeviceOrientation> allowedOrientations;
  
  const VNOrientationLock({
    super.key,
    required this.child,
    this.allowedOrientations = const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
  });

  @override
  State<VNOrientationLock> createState() => _VNOrientationLockState();
}

class _VNOrientationLockState extends State<VNOrientationLock> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(widget.allowedOrientations);
  }
  
  @override
  void dispose() {
    // Reset to allow all orientations
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Screen utility functions
class ScreenUtils {
  /// Get the current screen size
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }
  
  /// Get the current aspect ratio
  static double getAspectRatio(BuildContext context) {
    final size = getScreenSize(context);
    return size.width / size.height;
  }
  
  /// Check if the screen is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  /// Check if the screen is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
  
  /// Get safe area insets
  static EdgeInsets getSafeAreaInsets(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  /// Calculate scaled size based on reference resolution
  static double scaleWidth(BuildContext context, double value, {double referenceWidth = 1920}) {
    final screenWidth = getScreenSize(context).width;
    return value * (screenWidth / referenceWidth);
  }
  
  static double scaleHeight(BuildContext context, double value, {double referenceHeight = 1080}) {
    final screenHeight = getScreenSize(context).height;
    return value * (screenHeight / referenceHeight);
  }
  
  /// Calculate font size that scales with screen
  static double scaleFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = getScreenSize(context).width;
    final scaleFactor = (screenWidth / 1920).clamp(0.8, 1.2);
    return baseFontSize * scaleFactor;
  }
}

/// Aspect ratio presets for common VN resolutions
class VNAspectRatios {
  /// Standard 16:9 (1920x1080, 1280x720)
  static const double standard = 16 / 9;
  
  /// Classic 4:3 (1024x768, 800x600)
  static const double classic = 4 / 3;
  
  /// Ultrawide 21:9
  static const double ultrawide = 21 / 9;
  
  /// Mobile portrait 9:16
  static const double mobilePortrait = 9 / 16;
  
  /// Square 1:1
  static const double square = 1;
  
  /// Get recommended aspect ratio for device
  static double getRecommended(BuildContext context) {
    final deviceType = VNResponsiveLayout.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return ScreenUtils.isPortrait(context) ? mobilePortrait : standard;
      case DeviceType.tablet:
        return classic;
      case DeviceType.desktop:
        return standard;
    }
  }
}
