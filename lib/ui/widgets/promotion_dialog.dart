import 'package:flutter/material.dart';
import '../../engine/chess_engine.dart';
import 'piece_glyphs.dart';

/// Shows a modal piece picker and resolves with the FEN promotion letter:
/// 'q', 'r', 'b', or 'n'. Never dismissible by tapping outside — the move
/// is already half-made and needs an answer.
Future<String?> showPromotionDialog(BuildContext context, Side side) {
  const options = [
    ('q', PieceKind.queen),
    ('r', PieceKind.rook),
    ('b', PieceKind.bishop),
    ('n', PieceKind.knight),
  ];

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('Promote pawn to'),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final glyph = glyphFor(BoardPiece(side, opt.$2));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.of(context).pop(opt.$1),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(glyph, style: const TextStyle(fontSize: 34)),
                ),
              ),
            );
          }).toList(),
        ),
      );
    },
  );
}
