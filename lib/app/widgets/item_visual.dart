import 'package:flutter/material.dart';

import '../../domain/models/content.dart';

/// Renders an [Item]'s picture: a real image when [Item.imageUrl] is set
/// (M1 media support, loaded from Supabase Storage), falling back to the
/// emoji [Item.glyph] -- which stays the mandatory fallback per AGENTS.md's
/// "emoji + on-device TTS" baseline -- on a missing URL or a failed load.
class ItemVisual extends StatelessWidget {
  const ItemVisual({super.key, required this.item, this.size = 58});

  final Item item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _glyph();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.15),
      child: Image.network(
        imageUrl,
        width: size * 1.4,
        height: size * 1.4,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _glyph(),
        errorBuilder: (context, error, stackTrace) => _glyph(),
      ),
    );
  }

  Widget _glyph() => Text(
        item.glyph ?? item.answer,
        style: TextStyle(fontSize: size),
      );
}
