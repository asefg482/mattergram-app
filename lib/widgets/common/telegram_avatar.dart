import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';

class TelegramAvatar extends StatelessWidget {
  final String? userId;
  final String name;
  final String? customUrl;
  final double size;
  final bool isOnline;
  final bool showOnlineBadge;
  final bool isSavedMessages;
  final VoidCallback? onTap;

  const TelegramAvatar({
    super.key,
    this.userId,
    required this.name,
    this.customUrl,
    this.size = 44,
    this.isOnline = false,
    this.showOnlineBadge = false,
    this.isSavedMessages = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarContent;

    if (isSavedMessages) {
      avatarContent = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF3390EC), Color(0xFF2481CC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(
          Icons.bookmark,
          color: Colors.white,
          size: size * 0.55,
        ),
      );
    } else {
      final avatarUrl = customUrl ??
          (userId != null && userId!.isNotEmpty
              ? ApiService().getUserAvatarUrl(userId!)
              : null);

      final token = ApiService().token;
      final headers = token != null ? {'Authorization': 'Bearer $token'} : null;

      avatarContent = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: getAvatarGradient(userId ?? name),
        ),
        clipBehavior: Clip.antiAlias,
        child: avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                httpHeaders: headers,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => _buildInitials(),
                placeholder: (context, url) => _buildInitials(),
              )
            : _buildInitials(),
      );
    }

    Widget result = Stack(
      clipBehavior: Clip.none,
      children: [
        avatarContent,
        if (showOnlineBadge && isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: const Color(0xFF4FAE60), // Telegram online green
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).cardColor,
                  width: size > 40 ? 2 : 1.5,
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      result = GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: result,
        ),
      );
    }

    return result;
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        getInitials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.40,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
