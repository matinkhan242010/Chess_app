import 'package:flutter/foundation.dart';
import '../engine/chess_engine.dart';

/// A single played move, kept for the move-history panel.
class HistoryEntry {
  final int moveNumber; // 1-based full-move number
  final Side sideMoved;
  final String san;

  const HistoryEntry({
    required this.moveNumber,
    required this.sideMoved,
    required this.san,
  });
}

enum GameMode { twoPlayer, vsBot }

/// Top-level game state for a single live game. Owns the ChessEngine and
/// exposes everything the board/UI needs as plain, UI-friendly values.
class GameState extends ChangeNotifier {
  GameState({this.mode = GameMode.twoPlayer, this.flipBoardEachTurn = false})
      : _engine = ChessEngine();

  final ChessEngine _engine;
  final GameMode mode;

  /// Whether the board should flip to face the player on move (2-player mode).
  bool flipBoardEachTurn;

  bool _manualFlip = false;

  /// True if White's back rank should render at the bottom of the screen.
  bool get isWhiteAtBottom {
    final auto = flipBoardEachTurn ? turn == Side.white : true;
    return _manualFlip ? !auto : auto;
  }

  /// Manually flip the board (e.g. a "flip board" button), independent of
  /// the auto-flip-each-turn setting.
  void toggleManualFlip() {
    _manualFlip = !_manualFlip;
    notifyListeners();
  }

  // --- selection / interaction state -------------------------------------
  String? _selectedSquare;
  List<String> _legalTargets = [];
  String? _lastMoveFrom;
  String? _lastMoveTo;

  // --- pending promotion --------------------------------------------------
  String? _pendingPromotionFrom;
  String? _pendingPromotionTo;

  // --- history / review mode ----------------------------------------------
  final List<HistoryEntry> _history = [];
  final List<String> _fenStack = []; // fen after each ply, for review jumps
  int? _reviewPlyIndex; // null = live position

  ChessEngine get engine => _engine;
  String? get selectedSquare => _selectedSquare;
  List<String> get legalTargets => _legalTargets;
  String? get lastMoveFrom => _lastMoveFrom;
  String? get lastMoveTo => _lastMoveTo;
  List<HistoryEntry> get history => List.unmodifiable(_history);
  bool get isPromotionPending => _pendingPromotionFrom != null;
  bool get isReviewing => _reviewPlyIndex != null;

  Side get turn => _engine.turn;
  bool get inCheck => _engine.inCheck;
  bool get isGameOver => _engine.isGameOver;
  GameOverReason get gameOverReason => _engine.gameOverReason;

  String get statusText {
    if (isGameOver) {
      switch (gameOverReason) {
        case GameOverReason.checkmate:
          final winner = turn == Side.white ? 'Black' : 'White';
          return 'Checkmate — $winner wins';
        case GameOverReason.stalemate:
          return 'Draw — stalemate';
        case GameOverReason.threefoldRepetition:
          return 'Draw — threefold repetition';
        case GameOverReason.fiftyMoveRule:
          return 'Draw — 50-move rule';
        case GameOverReason.insufficientMaterial:
          return 'Draw — insufficient material';
        case GameOverReason.none:
          return 'Game over';
      }
    }
    if (inCheck) {
      return '${turn == Side.white ? 'White' : 'Black'} is in check';
    }
    return '${turn == Side.white ? 'White' : 'Black'} to move';
  }

  /// Called when the user taps or drops a piece on [square].
  /// Returns true if this triggered a promotion dialog that the caller
  /// must resolve via [resolvePromotion].
  bool handleSquareTap(String square) {
    if (isReviewing || isGameOver) return false;

    final piece = _engine.pieceAt(square);

    // No selection yet: select a square if it holds a piece of the side to move.
    if (_selectedSquare == null) {
      if (piece != null && piece.side == _engine.turn) {
        _select(square);
      }
      return false;
    }

    // Tapping the already-selected square deselects it.
    if (_selectedSquare == square) {
      _clearSelection();
      return false;
    }

    // Tapping another one of your own pieces re-selects instead of moving.
    if (piece != null && piece.side == _engine.turn) {
      _select(square);
      return false;
    }

    // Attempt the move.
    return _attemptMove(_selectedSquare!, square);
  }

  /// Called by drag-and-drop once a piece from [from] is dropped on [to].
  /// Returns true if a promotion dialog must be shown.
  bool handleDragMove(String from, String to) {
    if (isReviewing || isGameOver) return false;
    _selectedSquare = from;
    return _attemptMove(from, to);
  }

  bool _attemptMove(String from, String to) {
    if (!_legalMovesFromCache(from).contains(to)) {
      _clearSelection();
      return false;
    }
    if (_engine.isPromotionMove(from, to)) {
      _pendingPromotionFrom = from;
      _pendingPromotionTo = to;
      notifyListeners();
      return true;
    }
    _commitMove(from, to);
    return false;
  }

  List<String> _legalMovesFromCache(String from) => _engine.legalMovesFrom(from);

  /// Resolve a pending promotion with the chosen piece letter: 'q','r','b','n'.
  void resolvePromotion(String promotionLetter) {
    if (_pendingPromotionFrom == null || _pendingPromotionTo == null) return;
    _commitMove(
      _pendingPromotionFrom!,
      _pendingPromotionTo!,
      promotion: promotionLetter,
    );
    _pendingPromotionFrom = null;
    _pendingPromotionTo = null;
  }

  void cancelPromotion() {
    _pendingPromotionFrom = null;
    _pendingPromotionTo = null;
    _clearSelection();
  }

  void _commitMove(String from, String to, {String? promotion}) {
    final result = _engine.makeMove(from, to, promotion: promotion);
    if (!result.success) {
      _clearSelection();
      return;
    }

    final movedSide = turn == Side.white ? Side.black : Side.white; // side that just moved
    final moveNumber = (_engine.plyCount / 2).ceil();
    _history.add(HistoryEntry(
      moveNumber: moveNumber,
      sideMoved: movedSide,
      san: result.san ?? '?',
    ));
    _fenStack.add(_engine.fen);

    _lastMoveFrom = from;
    _lastMoveTo = to;
    _clearSelection(notify: false);
    notifyListeners();
  }

  void _select(String square) {
    _selectedSquare = square;
    _legalTargets = _engine.legalMovesFrom(square);
    notifyListeners();
  }

  void _clearSelection({bool notify = true}) {
    _selectedSquare = null;
    _legalTargets = [];
    if (notify) notifyListeners();
  }

  /// Undo the last move. In vs-bot mode, callers should invoke this twice
  /// (bot reply + player move) so it becomes the player's turn again.
  bool undo() {
    if (isReviewing) return false;
    final ok = _engine.undo();
    if (ok && _history.isNotEmpty) {
      _history.removeLast();
      if (_fenStack.isNotEmpty) _fenStack.removeLast();
      _lastMoveFrom = null;
      _lastMoveTo = null;
      _clearSelection(notify: false);
      notifyListeners();
    }
    return ok;
  }

  void newGame() {
    _engine.reset();
    _history.clear();
    _fenStack.clear();
    _reviewPlyIndex = null;
    _lastMoveFrom = null;
    _lastMoveTo = null;
    _clearSelection(notify: false);
    notifyListeners();
  }
}
