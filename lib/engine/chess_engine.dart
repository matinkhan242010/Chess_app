import 'package:chess/chess.dart' as chess_lib;

/// Which side a piece belongs to. Kept separate from chess_lib.Color so the
/// rest of the app never has to import the `chess` package directly.
enum Side { white, black }

/// Piece kind, independent of the underlying rules package.
enum PieceKind { pawn, knight, bishop, rook, queen, king }

class BoardPiece {
  final Side side;
  final PieceKind kind;
  const BoardPiece(this.side, this.kind);
}

class MoveResult {
  final bool success;
  final String? san;
  final bool isCapture;
  final bool isCastle;
  final bool isEnPassant;
  final bool isCheck;
  final bool isCheckmate;
  final bool isPromotion;

  const MoveResult({
    required this.success,
    this.san,
    this.isCapture = false,
    this.isCastle = false,
    this.isEnPassant = false,
    this.isCheck = false,
    this.isCheckmate = false,
    this.isPromotion = false,
  });

  factory MoveResult.failure() => const MoveResult(success: false);
}

enum GameOverReason {
  none,
  checkmate,
  stalemate,
  threefoldRepetition,
  fiftyMoveRule,
  insufficientMaterial,
}

/// Wraps the `chess` package (a chess.js port) so nothing else in the app
/// talks to it directly. Swap the implementation here to change rules
/// engines without touching UI or state-management code.
class ChessEngine {
  final chess_lib.Chess _game = chess_lib.Chess();

  String get fen => _game.fen;

  Side get turn =>
      _game.turn == chess_lib.Chess.WHITE ? Side.white : Side.black;

  bool get inCheck => _game.in_check;
  bool get isGameOver => _game.game_over;

  GameOverReason get gameOverReason {
    if (_game.in_checkmate) return GameOverReason.checkmate;
    if (_game.in_stalemate) return GameOverReason.stalemate;
    if (_game.in_threefold_repetition) {
      return GameOverReason.threefoldRepetition;
    }
    if (_game.insufficient_material) {
      return GameOverReason.insufficientMaterial;
    }
    if (_isFiftyMoveRule()) return GameOverReason.fiftyMoveRule;
    return GameOverReason.none;
  }

  bool _isFiftyMoveRule() {
    // FEN: <placement> <turn> <castling> <ep> <halfmove> <fullmove>
    final parts = _game.fen.split(' ');
    if (parts.length < 5) return false;
    final halfmoves = int.tryParse(parts[4]) ?? 0;
    return halfmoves >= 100; // 50 full moves = 100 half-moves
  }

  BoardPiece? pieceAt(String square) {
    final p = _game.get(square);
    if (p == null) return null;
    return BoardPiece(
      p.color == chess_lib.Chess.WHITE ? Side.white : Side.black,
      _kindFromLetter(p.type.toUpperCase()),
    );
  }

  PieceKind _kindFromLetter(String letter) {
    switch (letter) {
      case 'P':
        return PieceKind.pawn;
      case 'N':
        return PieceKind.knight;
      case 'B':
        return PieceKind.bishop;
      case 'R':
        return PieceKind.rook;
      case 'Q':
        return PieceKind.queen;
      case 'K':
      default:
        return PieceKind.king;
    }
  }

  /// Legal destination squares for the piece on [square], e.g. "e2" -> ["e3","e4"].
  List<String> legalMovesFrom(String square) {
    final moves = _game.moves({'square': square, 'verbose': true}) as List;
    return moves
        .map<String>((m) => (m as Map)['to'].toString())
        .toList(growable: false);
  }

  /// True if moving from->to is a pawn promotion (caller should then show
  /// the piece picker and re-call makeMove with `promotion` set).
  bool isPromotionMove(String from, String to) {
    final moves = _game.moves({'square': from, 'verbose': true}) as List;
    for (final m in moves) {
      final map = m as Map;
      if (map['to'].toString() == to &&
          map['flags'].toString().contains('p')) {
        return true;
      }
    }
    return false;
  }

  MoveResult makeMove(String from, String to, {String? promotion}) {
    final moveMap = <String, String>{'from': from, 'to': to};
    if (promotion != null) moveMap['promotion'] = promotion;

    final ok = _game.move(moveMap);
    if (ok != true) return MoveResult.failure();

    final history = _game.getHistory({'verbose': true}) as List;
    final last = history.isNotEmpty ? history.last as Map : null;
    final flags = last != null ? last['flags'].toString() : '';
    final san = last != null ? last['san']?.toString() : null;

    return MoveResult(
      success: true,
      san: san,
      isCapture: flags.contains('c') || flags.contains('e'),
      isCastle: flags.contains('k') || flags.contains('q'),
      isEnPassant: flags.contains('e'),
      isCheck: _game.in_check,
      isCheckmate: _game.in_checkmate,
      isPromotion: flags.contains('p'),
    );
  }

  /// Undo one half-move (ply). Returns true if a move was undone.
  bool undo() => _game.undo_move() != null;

  /// SAN history, e.g. ["e4", "e5", "Nf3", ...].
  List<String> get sanHistory {
    final history = _game.getHistory({'verbose': false}) as List;
    return history.map((m) => m.toString()).toList(growable: false);
  }

  int get plyCount => sanHistory.length;

  void reset() => _game.reset();

  /// 8x8 board. Row 0 = rank 8 (top of a White-at-bottom board), col 0 = file a.
  List<List<BoardPiece?>> get board {
    const files = 'abcdefgh';
    return List<List<BoardPiece?>>.generate(8, (row) {
      final rank = 8 - row;
      return List<BoardPiece?>.generate(8, (col) {
        return pieceAt('${files[col]}$rank');
      });
    });
  }
}
