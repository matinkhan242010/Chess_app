import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine/chess_engine.dart';
import '../../models/game_state.dart';
import 'piece_glyphs.dart';
import 'promotion_dialog.dart';

class BoardTheme {
  final Color light;
  final Color dark;
  final Color highlight; // last move
  final Color legalDot;
  final Color checkTint;
  final Color selected;

  const BoardTheme({
    required this.light,
    required this.dark,
    required this.highlight,
    required this.legalDot,
    required this.checkTint,
    required this.selected,
  });

  static const classicGreen = BoardTheme(
    light: Color(0xFFEEEED2),
    dark: Color(0xFF769656),
    highlight: Color(0xFFF6F669),
    legalDot: Color(0x552E7D32),
    checkTint: Color(0xAAE53935),
    selected: Color(0x66FFD54F),
  );
}

class ChessBoardWidget extends StatelessWidget {
  final BoardTheme theme;

  const ChessBoardWidget({super.key, this.theme = BoardTheme.classicGreen});

  static const _files = 'abcdefgh';

  String _squareAt(int displayRow, int displayCol, bool whiteAtBottom) {
    if (whiteAtBottom) {
      final rank = 8 - displayRow;
      final file = _files[displayCol];
      return '$file$rank';
    } else {
      final rank = displayRow + 1;
      final file = _files[7 - displayCol];
      return '$file$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final whiteAtBottom = gameState.isWhiteAtBottom;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemCount: 64,
            itemBuilder: (context, index) {
              final row = index ~/ 8;
              final col = index % 8;
              final square = _squareAt(row, col, whiteAtBottom);
              final isDark = (row + col) % 2 == 1;
              return _Square(
                square: square,
                isDark: isDark,
                theme: theme,
                gameState: gameState,
              );
            },
          );
        },
      ),
    );
  }
}

class _Square extends StatelessWidget {
  final String square;
  final bool isDark;
  final BoardTheme theme;
  final GameState gameState;

  const _Square({
    required this.square,
    required this.isDark,
    required this.theme,
    required this.gameState,
  });

  Future<void> _handlePromotionIfNeeded(
      BuildContext context, bool promotionPending) async {
    if (!promotionPending) return;
    final side = gameState.engine.turn; // side that owns the promoting pawn
    final letter = await showPromotionDialog(context, side);
    if (letter != null) {
      gameState.resolvePromotion(letter);
    } else {
      gameState.cancelPromotion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final piece = gameState.engine.pieceAt(square);
    final isSelected = gameState.selectedSquare == square;
    final isLegalTarget = gameState.legalTargets.contains(square);
    final isLastMove =
        square == gameState.lastMoveFrom || square == gameState.lastMoveTo;
    final isKingInCheckHere = gameState.inCheck &&
        piece?.kind == PieceKind.king &&
        piece?.side == gameState.turn;

    Color bg = isDark ? theme.dark : theme.light;
    if (isLastMove) bg = Color.alphaBlend(theme.highlight.withOpacity(0.55), bg);
    if (isSelected) bg = Color.alphaBlend(theme.selected, bg);

    Widget content = Container(
      color: bg,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (piece != null)
            Text(
              glyphFor(piece),
              style: TextStyle(
                fontSize: 34,
                shadows: isKingInCheckHere
                    ? [Shadow(color: theme.checkTint, blurRadius: 12)]
                    : null,
              ),
            ),
          if (isLegalTarget)
            Align(
              alignment: Alignment.center,
              child: Container(
                width: piece == null ? 16 : 60,
                height: piece == null ? 16 : 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: piece == null ? theme.legalDot : Colors.transparent,
                  border: piece != null
                      ? Border.all(color: theme.legalDot, width: 4)
                      : null,
                ),
              ),
            ),
          if (isKingInCheckHere)
            Container(color: theme.checkTint.withOpacity(0.25)),
        ],
      ),
    );

    content = GestureDetector(
      onTap: () async {
        final promotionPending = gameState.handleSquareTap(square);
        await _handlePromotionIfNeeded(context, promotionPending);
      },
      child: content,
    );

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) async {
        final promotionPending =
            gameState.handleDragMove(details.data, square);
        await _handlePromotionIfNeeded(context, promotionPending);
      },
      builder: (context, candidateData, rejectedData) {
        if (piece == null || piece.side != gameState.turn) {
          return content;
        }
        return Draggable<String>(
          data: square,
          feedback: Material(
            color: Colors.transparent,
            child: Text(glyphFor(piece), style: const TextStyle(fontSize: 40)),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: content),
          onDragStarted: () => gameState.handleSquareTap(square),
          child: content,
        );
      },
    );
  }
}
