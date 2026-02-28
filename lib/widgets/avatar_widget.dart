import 'package:flutter/material.dart';
import '../models/avatar_model.dart';
import '../config/theme.dart';

class AvatarWidget extends StatelessWidget {
  final String? avatarId;
  final double size;
  final bool showEditButton;
  final VoidCallback? onEditTap;
  final bool showBorder;
  final double borderWidth;

  const AvatarWidget({
    Key? key,
    this.avatarId,
    this.size = 60,
    this.showEditButton = false,
    this.onEditTap,
    this.showBorder = true,
    this.borderWidth = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get avatar or use default
    final avatar = avatarId != null 
        ? Avatars.getById(avatarId!) ?? Avatars.defaultAvatar
        : Avatars.defaultAvatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Avatar Circle
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                _hexToColor(avatar.gradient1),
                _hexToColor(avatar.gradient2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: showBorder
                ? Border.all(
                    color: Colors.white,
                    width: borderWidth,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: _hexToColor(avatar.gradient2).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              avatar.emoji,
              style: TextStyle(
                fontSize: size * 0.5, // Emoji size is 50% of circle
              ),
            ),
          ),
        ),

        // Edit Button
        if (showEditButton && onEditTap != null)
          Positioned(
            right: -4,
            bottom: -4,
            child: GestureDetector(
              onTap: onEditTap,
              child: Container(
                padding: EdgeInsets.all(size * 0.12),
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: size * 0.25,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Helper to convert hex color to Flutter Color
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

// ==========================================
// AVATAR SELECTION ITEM (for selection screen)
// ==========================================
class AvatarSelectionItem extends StatelessWidget {
  final AvatarModel avatar;
  final bool isSelected;
  final VoidCallback onTap;

  const AvatarSelectionItem({
    Key? key,
    required this.avatar,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? _hexToColor(avatar.gradient1).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? _hexToColor(avatar.gradient1)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _hexToColor(avatar.gradient1),
                    _hexToColor(avatar.gradient2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _hexToColor(avatar.gradient2).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  avatar.emoji,
                  style: const TextStyle(fontSize: 35),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Name
            Text(
              avatar.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? _hexToColor(avatar.gradient1)
                    : AppColors.gray700,
              ),
              textAlign: TextAlign.center,
            ),

            // Selected indicator
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle,
                color: _hexToColor(avatar.gradient1),
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}