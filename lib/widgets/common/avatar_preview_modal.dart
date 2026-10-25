import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';

class AvatarPreviewModal extends StatelessWidget {
  final String url;
  final String name;
  final VoidCallback onClose;

  const AvatarPreviewModal({
    super.key,
    required this.url,
    required this.name,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final token = ApiService().token;
    final headers = token != null ? {'Authorization': 'Bearer $token'} : null;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.92),
      body: SafeArea(
        child: Stack(
          children: [
            // Centered Zoomable / Pannable Image
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: url,
                  httpHeaders: headers,
                  fit: BoxFit.contain,
                  placeholder: (context, _) => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3390EC)),
                  ),
                  errorWidget: (context, url, error) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image, color: Colors.white54, size: 64),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load photo',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top Header Bar
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onClose,
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
