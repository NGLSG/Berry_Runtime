/// Story Player Widget for VN Runtime
/// 
/// Combines all rendering layers into a unified playback widget.
library;

import 'package:flutter/material.dart';
import '../engine/vn_engine.dart';
import '../engine/node_executor.dart';
import '../models/vn_character.dart';
import '../models/vn_node.dart';
import '../models/vn_project.dart';
import 'background_layer.dart';
import 'character_layer.dart';
import 'effects_layer.dart';
import 'audio_manager.dart';
import '../effects/particles/particles.dart';
import '../effects/meta/story_meta_effects.dart';

/// Story player widget that renders the complete VN scene
class StoryPlayer extends StatefulWidget {
  final VNEngine engine;
  final Map<String, VNCharacter> characters;
  final ImageProvider Function(String path)? imageProvider;
  final Widget Function(BuildContext, DialogueExecutionData?)? dialogueBuilder;
  final Widget Function(BuildContext, List<ChoiceExecutionOption>)? choiceBuilder;
  final VoidCallback? onAdvance;
  
  /// Optional external particle system manager
  final ParticleSystemManager? particleManager;
  
  /// Optional external meta effect controller
  final StoryMetaEffectController? metaEffectController;

  const StoryPlayer({
    super.key,
    required this.engine,
    required this.characters,
    this.imageProvider,
    this.dialogueBuilder,
    this.choiceBuilder,
    this.onAdvance,
    this.particleManager,
    this.metaEffectController,
  });

  @override
  State<StoryPlayer> createState() => _StoryPlayerState();
}

class _StoryPlayerState extends State<StoryPlayer> {
  late BackgroundController _backgroundController;
  late CharacterLayerController _characterController;
  late ScreenEffectController _effectController;
  late VNAudioManager _audioManager;
  late ParticleSystemManager _particleManager;
  late StoryMetaEffectController _metaEffectController;
  bool _ownsParticleManager = false;
  bool _ownsMetaEffectController = false;

  @override
  void initState() {
    super.initState();
    _backgroundController = BackgroundController();
    _characterController = CharacterLayerController(
      characterData: widget.characters,
    );
    _effectController = ScreenEffectController();
    _audioManager = VNAudioManager();
    
    // Use provided particle manager or create our own
    if (widget.particleManager != null) {
      _particleManager = widget.particleManager!;
      _ownsParticleManager = false;
    } else {
      _particleManager = ParticleSystemManager();
      _ownsParticleManager = true;
    }
    
    // Use provided meta effect controller or create our own
    if (widget.metaEffectController != null) {
      _metaEffectController = widget.metaEffectController!;
      _ownsMetaEffectController = false;
    } else {
      _metaEffectController = StoryMetaEffectController();
      _ownsMetaEffectController = true;
    }

    // Listen to engine state changes
    widget.engine.stateStream.listen(_onEngineStateChanged);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _characterController.dispose();
    _effectController.dispose();
    _audioManager.dispose();
    if (_ownsParticleManager) {
      _particleManager.dispose();
    }
    if (_ownsMetaEffectController) {
      _metaEffectController.dispose();
    }
    super.dispose();
  }

  void _onEngineStateChanged(state) {
    // Handle pending effects
    final effect = widget.engine.pendingEffect;
    if (effect != null) {
      _applyEffect(effect);
      widget.engine.clearPendingEffect();
    }

    // Handle pending audio
    final audio = widget.engine.pendingAudio;
    if (audio != null) {
      _applyAudio(audio);
      widget.engine.clearPendingAudio();
    }

    // Update speaking character
    final dialogue = widget.engine.currentDialogue;
    _characterController.setSpeakingCharacter(dialogue?.speakerId);

    setState(() {});
  }

  void _applyEffect(EffectExecutionData effect) {
    // Check if this is a meta effect
    if (_isMetaEffect(effect.effectType)) {
      _applyMetaEffect(effect);
      return;
    }
    
    // Check if this is a particle effect
    if (_isParticleEffect(effect.effectType)) {
      _applyParticleEffect(effect);
      return;
    }
    
    final screenEffect = _parseScreenEffect(effect.effectType);
    _effectController.applyEffect(ScreenEffectConfig(
      type: screenEffect,
      intensity: effect.intensity,
      duration: Duration(milliseconds: (effect.duration * 1000).toInt()),
      color: effect.params['color'] != null 
          ? Color(effect.params['color'] as int)
          : null,
      params: effect.params,
    ));
  }
  
  bool _isMetaEffect(String effectType) {
    final lower = effectType.toLowerCase();
    return lower.startsWith('meta_') ||
           lower == 'glitch' ||
           lower == 'staticnoise' ||
           lower == 'static_noise' ||
           lower == 'screentear' ||
           lower == 'screen_tear' ||
           lower == 'colorcorruption' ||
           lower == 'color_corruption' ||
           lower == 'textscramble' ||
           lower == 'text_scramble' ||
           lower == 'fakeerror' ||
           lower == 'fake_error' ||
           lower == 'screenshake_meta' ||
           lower == 'vignettepulse' ||
           lower == 'vignette_pulse' ||
           lower == 'chromaticaberration' ||
           lower == 'chromatic_aberration';
  }
  
  void _applyMetaEffect(EffectExecutionData effect) {
    final effectType = effect.effectType.toLowerCase();
    final action = effect.params['action'] as String? ?? 'start';
    
    if (action == 'stop') {
      _metaEffectController.stopEffect();
      return;
    }
    
    final metaType = _parseMetaEffectType(effectType);
    _metaEffectController.triggerEffect(StoryMetaEffectConfig(
      type: metaType,
      intensity: effect.intensity,
      duration: Duration(milliseconds: (effect.duration * 1000).toInt()),
      fakeErrorTitle: effect.params['errorTitle'] as String?,
      fakeErrorMessage: effect.params['errorMessage'] as String?,
      params: effect.params,
    ));
  }
  
  MetaEffectType _parseMetaEffectType(String effectType) {
    final lower = effectType.toLowerCase().replaceAll('meta_', '');
    switch (lower) {
      case 'glitch':
        return MetaEffectType.glitch;
      case 'staticnoise':
      case 'static_noise':
        return MetaEffectType.staticNoise;
      case 'screentear':
      case 'screen_tear':
        return MetaEffectType.screenTear;
      case 'colorcorruption':
      case 'color_corruption':
        return MetaEffectType.colorCorruption;
      case 'textscramble':
      case 'text_scramble':
        return MetaEffectType.textScramble;
      case 'fakeerror':
      case 'fake_error':
        return MetaEffectType.fakeError;
      case 'screenshake':
      case 'screen_shake':
        return MetaEffectType.screenShake;
      case 'vignettepulse':
      case 'vignette_pulse':
        return MetaEffectType.vignettePulse;
      case 'chromaticaberration':
      case 'chromatic_aberration':
        return MetaEffectType.chromaticAberration;
      default:
        return MetaEffectType.none;
    }
  }
  
  bool _isParticleEffect(String effectType) {
    final lower = effectType.toLowerCase();
    return ParticlePresets.presetNames.contains(lower) ||
           lower.startsWith('particle_') ||
           lower == 'particle';
  }
  
  void _applyParticleEffect(EffectExecutionData effect) {
    final effectType = effect.effectType.toLowerCase();
    final action = effect.params['action'] as String? ?? 'start';
    
    if (action == 'stop') {
      final immediate = effect.params['immediate'] as bool? ?? false;
      _particleManager.stopEffect(effectType, immediate: immediate);
      return;
    }
    
    // Try to get preset
    final preset = ParticlePresets.getPreset(effectType);
    if (preset != null) {
      final config = preset.copyWith(
        emissionRate: preset.emissionRate * effect.intensity,
      );
      _particleManager.startEffect(config);
    }
  }

  ScreenEffect _parseScreenEffect(String effectType) {
    switch (effectType.toLowerCase()) {
      case 'shake':
        return ScreenEffect.shake;
      case 'flash':
        return ScreenEffect.flash;
      case 'blur':
        return ScreenEffect.blur;
      case 'vignette':
        return ScreenEffect.vignette;
      case 'coloroverlay':
      case 'color_overlay':
        return ScreenEffect.colorOverlay;
      default:
        return ScreenEffect.none;
    }
  }

  void _applyAudio(AudioExecutionData audio) {
    final channel = _parseAudioChannel(audio.channel);
    final action = _parseAudioAction(audio.action);

    action.execute(
      _audioManager,
      channel,
      audioId: audio.audioId,
      path: audio.audioId ?? '', // In real impl, resolve path from resource library
      volume: audio.volume,
      loop: audio.loop,
      fadeDuration: audio.fadeDuration != null
          ? Duration(milliseconds: (audio.fadeDuration! * 1000).toInt())
          : null,
    );
  }

  VNAudioChannel _parseAudioChannel(String channel) {
    switch (channel.toLowerCase()) {
      case 'bgm':
        return VNAudioChannel.bgm;
      case 'sfx':
        return VNAudioChannel.sfx;
      case 'voice':
        return VNAudioChannel.voice;
      case 'ambient':
        return VNAudioChannel.ambient;
      default:
        return VNAudioChannel.bgm;
    }
  }

  AudioAction _parseAudioAction(String action) {
    switch (action.toLowerCase()) {
      case 'play':
        return AudioAction.play;
      case 'stop':
        return AudioAction.stop;
      case 'pause':
        return AudioAction.pause;
      case 'resume':
        return AudioAction.resume;
      case 'fadein':
      case 'fade_in':
        return AudioAction.fadeIn;
      case 'fadeout':
      case 'fade_out':
        return AudioAction.fadeOut;
      case 'crossfade':
        return AudioAction.crossfade;
      default:
        return AudioAction.play;
    }
  }

  void _handleTap() {
    final choices = widget.engine.currentChoices;
    if (choices != null && choices.isNotEmpty) {
      // Don't advance when showing choices
      return;
    }

    widget.onAdvance?.call();
    widget.engine.advance();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: StoryMetaEffectLayer(
        controller: _metaEffectController,
        child: ScreenEffectLayer(
          controller: _effectController,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background layer
              BackgroundLayer(
                controller: _backgroundController,
                imageProvider: widget.imageProvider,
              ),

              // Character layer
              CharacterLayer(
                controller: _characterController,
                imageProvider: widget.imageProvider,
              ),
              
              // Particle layer (between characters and UI)
              ParticleLayer(
                manager: _particleManager,
              ),

              // UI layer (dialogue, choices, etc.)
              _buildUILayer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUILayer() {
    final dialogue = widget.engine.currentDialogue;
    final choices = widget.engine.currentChoices;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Dialogue display
        if (dialogue != null && widget.dialogueBuilder != null)
          widget.dialogueBuilder!(context, dialogue),

        // Choice display
        if (choices != null && choices.isNotEmpty && widget.choiceBuilder != null)
          widget.choiceBuilder!(context, choices),
      ],
    );
  }
}

/// Simple default dialogue widget
class DefaultDialogueWidget extends StatelessWidget {
  final DialogueExecutionData dialogue;
  final TextStyle? nameStyle;
  final TextStyle? textStyle;
  final Color backgroundColor;

  const DefaultDialogueWidget({
    super.key,
    required this.dialogue,
    this.nameStyle,
    this.textStyle,
    this.backgroundColor = const Color(0xCC000000),
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: const Border(
            top: BorderSide(color: Colors.white24, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dialogue.speakerName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  dialogue.speakerName!,
                  style: nameStyle ?? const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              dialogue.text,
              style: textStyle ?? const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple default choice widget
class DefaultChoiceWidget extends StatelessWidget {
  final List<ChoiceExecutionOption> choices;
  final void Function(int index)? onSelect;
  final TextStyle? textStyle;
  final Color enabledColor;
  final Color disabledColor;

  const DefaultChoiceWidget({
    super.key,
    required this.choices,
    this.onSelect,
    this.textStyle,
    this.enabledColor = const Color(0xCC000000),
    this.disabledColor = const Color(0x66000000),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: choices.asMap().entries.map((entry) {
            final index = entry.key;
            final choice = entry.value;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Material(
                color: choice.isEnabled ? enabledColor : disabledColor,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: choice.isEnabled ? () => onSelect?.call(index) : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Text(
                      choice.text,
                      style: textStyle ?? TextStyle(
                        color: choice.isEnabled ? Colors.white : Colors.white54,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
