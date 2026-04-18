// lib/widgets/back_button.dart
import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';

/// 共通の戻るボタンウィジェット
/// Stackの最後に配置することで、他のウィジェットに覆われないようにする
class BackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double? iconSize;
  final String? tooltip;

  const BackButton({
    super.key,
    this.onPressed,
    this.iconSize,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Positioned(
      top: 0,
      left: 0,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: IconButton(
            icon: Icon(Icons.arrow_back, size: iconSize),
            onPressed: onPressed ??
                () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
            tooltip: tooltip ?? l10n.back,
          ),
        ),
      ),
    );
  }
}



