import 'package:flutter/material.dart';
import '../../utils/reactions.dart';

class ReactionPicker extends StatelessWidget {
  final void Function(String emojiName) onSelectEmoji;

  const ReactionPicker({super.key, required this.onSelectEmoji});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emojis = emojiNameToChar.entries.toList();

    return Material(
      color: isDark ? const Color(0xFF17212B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      child: Container(
        width: 320,
        height: 280,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reactions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) {
                  final entry = emojis[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onSelectEmoji(entry.key),
                    child: Center(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
