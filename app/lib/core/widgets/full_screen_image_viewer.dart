import 'package:flutter/material.dart';

/// Full-screen, pinch-zoomable view of an image opened from a thumbnail.
/// Handles both network URLs and bundled `assets/` paths.
class FullScreenImageViewer extends StatelessWidget {
  const FullScreenImageViewer({super.key, required this.imageUrl});

  final String imageUrl;

  static void show(BuildContext context, String imageUrl) {
    if (imageUrl.trim().isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, _, _) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Center(
                  child: imageUrl.startsWith('assets/')
                      ? Image.asset(imageUrl, fit: BoxFit.contain)
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 64,
                          ),
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The standard "full aspect ratio, no cropping" image widget for Sudut Info
/// content -- width fills the parent, height follows the image's own aspect
/// ratio. Optionally tappable to open a full-screen zoomed view.
class SudutInfoImage extends StatelessWidget {
  const SudutInfoImage({super.key, required this.imageUrl, this.zoomable = true, this.borderRadius});

  final String imageUrl;
  final bool zoomable;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl.startsWith('assets/')
        ? Image.asset(imageUrl, width: double.infinity, fit: BoxFit.fitWidth)
        : Image.network(
            imageUrl,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          );

    final clipped = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: image,
    );

    if (!zoomable) return clipped;

    return GestureDetector(
      onTap: () => FullScreenImageViewer.show(context, imageUrl),
      child: clipped,
    );
  }
}
