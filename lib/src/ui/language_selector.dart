/// Language Selector Widget
/// 
/// Provides UI for selecting game language in visual novels.
/// Can be used in settings screen or as a standalone dialog.

import 'package:flutter/material.dart';
import '../localization/localization_manager.dart';

/// Configuration for language selector
class LanguageSelectorConfig {
  /// Background color
  final Color backgroundColor;
  
  /// Text color
  final Color textColor;
  
  /// Selected item color
  final Color selectedColor;
  
  /// Hover color
  final Color hoverColor;
  
  /// Border radius
  final double borderRadius;
  
  /// Show flag emoji
  final bool showFlag;
  
  /// Show native name
  final bool showNativeName;
  
  /// Show English name
  final bool showEnglishName;
  
  /// Item padding
  final EdgeInsets itemPadding;

  const LanguageSelectorConfig({
    this.backgroundColor = const Color(0xFF1A1A2E),
    this.textColor = Colors.white,
    this.selectedColor = const Color(0xFF6200EE),
    this.hoverColor = const Color(0xFF2A2A4E),
    this.borderRadius = 8.0,
    this.showFlag = true,
    this.showNativeName = true,
    this.showEnglishName = true,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });
}

/// Language selector widget
class LanguageSelector extends StatefulWidget {
  /// Configuration
  final LanguageSelectorConfig config;
  
  /// Callback when language is selected
  final void Function(String languageCode)? onLanguageSelected;
  
  /// Whether to show as dropdown or list
  final bool isDropdown;

  const LanguageSelector({
    super.key,
    this.config = const LanguageSelectorConfig(),
    this.onLanguageSelected,
    this.isDropdown = false,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  final _localization = LocalizationManager.instance;

  @override
  Widget build(BuildContext context) {
    if (widget.isDropdown) {
      return _buildDropdown();
    }
    return _buildList();
  }

  Widget _buildDropdown() {
    final languages = _localization.availableLanguages;
    final current = _localization.currentLanguageInfo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: widget.config.backgroundColor,
        borderRadius: BorderRadius.circular(widget.config.borderRadius),
        border: Border.all(color: widget.config.textColor.withOpacity(0.3)),
      ),
      child: DropdownButton<String>(
        value: _localization.currentLanguage,
        dropdownColor: widget.config.backgroundColor,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: widget.config.textColor),
        items: languages.map((lang) {
          return DropdownMenuItem<String>(
            value: lang.code,
            child: _buildLanguageItem(lang, isSelected: lang.code == current?.code),
          );
        }).toList(),
        onChanged: (code) {
          if (code != null) {
            _selectLanguage(code);
          }
        },
      ),
    );
  }

  Widget _buildList() {
    final languages = _localization.availableLanguages;
    final current = _localization.currentLanguage;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: languages.map((lang) {
        final isSelected = lang.code == current;
        return _LanguageListItem(
          language: lang,
          isSelected: isSelected,
          config: widget.config,
          onTap: () => _selectLanguage(lang.code),
        );
      }).toList(),
    );
  }

  Widget _buildLanguageItem(VNLanguage lang, {bool isSelected = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.config.showFlag && lang.flag != null) ...[
          Text(lang.flag!, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.config.showNativeName)
              Text(
                lang.nativeName,
                style: TextStyle(
                  color: isSelected 
                      ? widget.config.selectedColor 
                      : widget.config.textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            if (widget.config.showEnglishName && widget.config.showNativeName)
              Text(
                lang.englishName,
                style: TextStyle(
                  color: widget.config.textColor.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            if (widget.config.showEnglishName && !widget.config.showNativeName)
              Text(
                lang.englishName,
                style: TextStyle(
                  color: isSelected 
                      ? widget.config.selectedColor 
                      : widget.config.textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectLanguage(String code) async {
    await _localization.setLanguage(code);
    widget.onLanguageSelected?.call(code);
    if (mounted) setState(() {});
  }
}

/// Individual language list item
class _LanguageListItem extends StatefulWidget {
  final VNLanguage language;
  final bool isSelected;
  final LanguageSelectorConfig config;
  final VoidCallback onTap;

  const _LanguageListItem({
    required this.language,
    required this.isSelected,
    required this.config,
    required this.onTap,
  });

  @override
  State<_LanguageListItem> createState() => _LanguageListItemState();
}

class _LanguageListItemState extends State<_LanguageListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: widget.config.itemPadding,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.config.selectedColor.withOpacity(0.2)
                : _isHovered
                    ? widget.config.hoverColor
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(widget.config.borderRadius),
            border: widget.isSelected
                ? Border.all(color: widget.config.selectedColor, width: 2)
                : null,
          ),
          child: Row(
            children: [
              if (widget.config.showFlag && widget.language.flag != null) ...[
                Text(widget.language.flag!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.config.showNativeName)
                      Text(
                        widget.language.nativeName,
                        style: TextStyle(
                          color: widget.isSelected
                              ? widget.config.selectedColor
                              : widget.config.textColor,
                          fontSize: 16,
                          fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    if (widget.config.showEnglishName)
                      Text(
                        widget.language.englishName,
                        style: TextStyle(
                          color: widget.config.textColor.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.isSelected)
                Icon(
                  Icons.check_circle,
                  color: widget.config.selectedColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Language selection dialog
class LanguageSelectionDialog extends StatelessWidget {
  /// Dialog title
  final String title;
  
  /// Configuration
  final LanguageSelectorConfig config;
  
  /// Callback when language is selected
  final void Function(String languageCode)? onLanguageSelected;

  const LanguageSelectionDialog({
    super.key,
    this.title = '选择语言 / Select Language',
    this.config = const LanguageSelectorConfig(),
    this.onLanguageSelected,
  });

  /// Show the dialog
  static Future<String?> show(
    BuildContext context, {
    String title = '选择语言 / Select Language',
    LanguageSelectorConfig config = const LanguageSelectorConfig(),
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => LanguageSelectionDialog(
        title: title,
        config: config,
        onLanguageSelected: (code) => Navigator.of(context).pop(code),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: config.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              title,
              style: TextStyle(
                color: config.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Language list
            Flexible(
              child: SingleChildScrollView(
                child: LanguageSelector(
                  config: config,
                  onLanguageSelected: onLanguageSelected,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Close button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '关闭 / Close',
                style: TextStyle(color: config.textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
