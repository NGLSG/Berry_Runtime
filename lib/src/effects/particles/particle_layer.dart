import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'particle_system_manager.dart';
import 'particle_emitter.dart';

/// Widget that renders particle effects as an overlay layer
class ParticleLayer extends StatefulWidget {
  /// The particle system manager
  final ParticleSystemManager manager;
  
  /// Child widget to render behind particles
  final Widget? child;
  
  /// Whether to automatically update the manager
  final bool autoUpdate;

  const ParticleLayer({
    super.key,
    required this.manager,
    this.child,
    this.autoUpdate = true,
  });

  @override
  State<ParticleLayer> createState() => _ParticleLayerState();
}

class _ParticleLayerState extends State<ParticleLayer> 
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.autoUpdate) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(ParticleLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoUpdate && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.autoUpdate && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTime).inMicroseconds / 1000000.0;
    _lastTime = elapsed;
    
    if (dt > 0 && dt < 0.1) { // Cap dt to avoid huge jumps
      widget.manager.update(dt);
      // Force repaint
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Update manager bounds
        widget.manager.updateBounds(
          Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight),
        );
        
        return Stack(
          fit: StackFit.expand,
          children: [
            if (widget.child != null) widget.child!,
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ParticlePainter(widget.manager),
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom painter for rendering particles
class _ParticlePainter extends CustomPainter {
  final ParticleSystemManager manager;

  _ParticlePainter(this.manager);

  @override
  void paint(Canvas canvas, Size size) {
    manager.render(canvas, size: size);
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

/// Standalone particle layer that creates its own manager
class StandaloneParticleLayer extends StatefulWidget {
  /// Initial effects to start
  final List<String> initialPresets;
  
  /// Child widget
  final Widget? child;

  const StandaloneParticleLayer({
    super.key,
    this.initialPresets = const [],
    this.child,
  });

  @override
  State<StandaloneParticleLayer> createState() => _StandaloneParticleLayerState();
}

class _StandaloneParticleLayerState extends State<StandaloneParticleLayer> {
  late ParticleSystemManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = ParticleSystemManager();
    
    // Start initial presets
    for (final preset in widget.initialPresets) {
      _manager.startPreset(preset);
    }
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ParticleLayer(
      manager: _manager,
      child: widget.child,
    );
  }
}

/// Controller for particle layer that can be used with InheritedWidget
class ParticleLayerController extends InheritedWidget {
  final ParticleSystemManager manager;

  const ParticleLayerController({
    super.key,
    required this.manager,
    required super.child,
  });

  static ParticleSystemManager? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ParticleLayerController>()
        ?.manager;
  }

  @override
  bool updateShouldNotify(ParticleLayerController oldWidget) {
    return manager != oldWidget.manager;
  }
}
