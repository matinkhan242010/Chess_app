import '../../engine/chess_engine.dart';

/// Unicode glyphs for each piece. Stage-1 placeholder rendering; the themes
/// stage can swap this for an SVG piece-set renderer without touching
/// callers, since they only ever ask for `glyphFor(piece)`.
String glyphFor(BoardPiece piece) {
  final white = piece.side == Side.white;
  switch (piece.kind) {
    case PieceKind.pawn:
      return white ? '♙' : '♟';
    case PieceKind.knight:
      return white ? '♘' : '♞';
    case PieceKind.bishop:
      return white ? '♗' : '♝';
    case PieceKind.rook:
      return white ? '♖' : '♜';
    case PieceKind.queen:
      return white ? '♕' : '♛';
    case PieceKind.king:
      return white ? '♔' : '♚';
  }
}
