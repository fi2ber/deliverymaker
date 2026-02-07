import 'package:flutter/material.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../core/sync/sync_engine.dart';

/// Shows sync status at the top of the screen
/// iOS 18 style with glassmorphism
class SyncStatusBar extends StatelessWidget {
  final SyncStatus status;
  final bool isOnline;
  final VoidCallback? onTap;

  const SyncStatusBar({
    super.key,
    required this.status,
    required this.isOnline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.synced && isOnline) {
      return const SizedBox.shrink(); // Hide when everything is good
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(IOSTheme.radiusLg),
          border: Border.all(
            color: _borderColor,
            width: 1,
          ),
          boxShadow: IOSTheme.shadowSm,
        ),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _title,
                    style: IOSTheme.headline.copyWith(
                      color: _textColor,
                      fontSize: 15,
                    ),
                  ),
                  if (_subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _subtitle!,
                      style: IOSTheme.caption.copyWith(
                        color: _textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (status == SyncStatus.syncing)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(_textColor),
                ),
              )
            else if (!isOnline)
              IOSButton(
                text: 'Повторить',
                onPressed: onTap,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color color;

    if (!isOnline) {
      iconData = Icons.signal_wifi_off;
      color = IOSTheme.systemOrange;
    } else if (status == SyncStatus.syncing) {
      iconData = Icons.sync;
      color = IOSTheme.systemBlue;
    } else if (status == SyncStatus.error) {
      iconData = Icons.error_outline;
      color = IOSTheme.systemRed;
    } else {
      iconData = Icons.check_circle;
      color = IOSTheme.systemGreen;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 22),
    );
  }

  Color get _backgroundColor {
    if (!isOnline) return IOSTheme.systemOrange.withOpacity(0.1);
    if (status == SyncStatus.error) return IOSTheme.systemRed.withOpacity(0.1);
    if (status == SyncStatus.syncing) return IOSTheme.systemBlue.withOpacity(0.1);
    return IOSTheme.systemGreen.withOpacity(0.1);
  }

  Color get _borderColor {
    if (!isOnline) return IOSTheme.systemOrange.withOpacity(0.3);
    if (status == SyncStatus.error) return IOSTheme.systemRed.withOpacity(0.3);
    if (status == SyncStatus.syncing) return IOSTheme.systemBlue.withOpacity(0.3);
    return IOSTheme.systemGreen.withOpacity(0.3);
  }

  Color get _textColor {
    if (!isOnline) return IOSTheme.systemOrange;
    if (status == SyncStatus.error) return IOSTheme.systemRed;
    if (status == SyncStatus.syncing) return IOSTheme.systemBlue;
    return IOSTheme.systemGreen;
  }

  String get _title {
    if (!isOnline) return 'Нет подключения к интернету';
    if (status == SyncStatus.syncing) return 'Синхронизация...';
    if (status == SyncStatus.error) return 'Ошибка синхронизации';
    return 'Все данные синхронизированы';
  }

  String? get _subtitle {
    if (!isOnline) return 'Данные сохранены локально';
    if (status == SyncStatus.error) return 'Нажмите чтобы повторить';
    return null;
  }
}

/// Compact sync indicator for app bar
class SyncIndicator extends StatelessWidget {
  final SyncStatus status;
  final bool isOnline;

  const SyncIndicator({
    super.key,
    required this.status,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.synced && isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == SyncStatus.syncing)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(_iconColor),
              ),
            )
          else
            Icon(_icon, color: _iconColor, size: 14),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: _iconColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData get _icon {
    if (!isOnline) return Icons.signal_wifi_off;
    if (status == SyncStatus.error) return Icons.error_outline;
    return Icons.sync;
  }

  Color get _iconColor {
    if (!isOnline) return IOSTheme.systemOrange;
    if (status == SyncStatus.error) return IOSTheme.systemRed;
    return IOSTheme.systemBlue;
  }

  Color get _backgroundColor {
    if (!isOnline) return IOSTheme.systemOrange.withOpacity(0.1);
    if (status == SyncStatus.error) return IOSTheme.systemRed.withOpacity(0.1);
    return IOSTheme.systemBlue.withOpacity(0.1);
  }

  String get _label {
    if (!isOnline) return 'Оффлайн';
    if (status == SyncStatus.error) return 'Ошибка';
    if (status == SyncStatus.syncing) return 'Синхр...';
    return '';
  }
}
