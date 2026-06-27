import 'dart:io';
import 'package:flutter/material.dart';

/// A [CircleAvatar]-like widget that loads a network profile image safely.
///
/// On SSL / handshake failures (common with Google CDN on emulators or
/// restricted networks) the widget automatically falls back to [fallbackChild]
/// instead of crashing with an uncaught [HandshakeException].
class SafeNetworkAvatar extends StatelessWidget {
  const SafeNetworkAvatar({
    super.key,
    required this.radius,
    required this.backgroundColor,
    required this.fallbackChild,
    this.photoUrl,
    this.localFile,
  });

  final double radius;
  final Color backgroundColor;
  final Widget fallbackChild;

  /// Remote Google / Firebase Storage photo URL.
  final String? photoUrl;

  /// Optional local file – takes priority over [photoUrl].
  final File? localFile;

  bool get _hasLocal => localFile != null;
  bool get _hasNetwork =>
      photoUrl != null &&
      photoUrl!.isNotEmpty &&
      photoUrl!.startsWith('http');

  @override
  Widget build(BuildContext context) {
    // ── Local file (highest priority) ──────────────────────────────────────
    if (_hasLocal) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: FileImage(localFile!),
        child: null,
      );
    }

    // ── Remote URL ─────────────────────────────────────────────────────────
    if (_hasNetwork) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: Image.network(
            photoUrl!,
            fit: BoxFit.cover,
            // Show a shimmer-style placeholder while loading
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: backgroundColor,
                child: Center(
                  child: SizedBox(
                    width: radius * 0.8,
                    height: radius * 0.8,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: backgroundColor == Colors.transparent
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                ),
              );
            },
            // On any network/SSL error fall back to the default child
            errorBuilder: (context, error, stackTrace) {
              return CircleAvatar(
                radius: radius,
                backgroundColor: backgroundColor,
                child: fallbackChild,
              );
            },
          ),
        ),
      );
    }

    // ── No image source → show fallback ────────────────────────────────────
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: fallbackChild,
    );
  }
}
