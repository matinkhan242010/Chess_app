import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game_state.dart';

class MoveHistoryPanel extends StatelessWidget {
  const MoveHistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final history = gameState.history;

    // Group plies into (white, black) pairs by move number.
    final pairs = <(int, String, String?)>[];
    for (final entry in history) {
      if (pairs.isNotEmpty && pairs.last.$1 == entry.moveNumber && pairs.last.$3 == null) {
        final last = pairs.removeLast();
        pairs.add((last.$1, last.$2, entry.san));
      } else {
        pairs.add((entry.moveNumber, entry.san, null));
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('Moves', style: Theme.of(context).textTheme.titleMedium),
          ),
          const Divider(height: 1),
          Expanded(
            child: pairs.isEmpty
                ? const Center(child: Text('No moves yet'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: pairs.length,
                    itemBuilder: (context, index) {
                      final (num, white, black) = pairs[index];
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text('$num.',
                                  style: TextStyle(
                                      color: Theme.of(context).hintColor)),
                            ),
                            Expanded(child: _MoveChip(san: white)),
                            const SizedBox(width: 8),
                            Expanded(child: _MoveChip(san: black ?? '')),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MoveChip extends StatelessWidget {
  final String san;
  const _MoveChip({required this.san});

  @override
  Widget build(BuildContext context) {
    if (san.isEmpty) return const SizedBox.shrink();
    return Text(san, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]));
  }
}
