import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/game_state.dart';
import '../widgets/chess_board_widget.dart';
import '../widgets/move_history_panel.dart';

class GameScreen extends StatelessWidget {
  final GameMode mode;
  const GameScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState(mode: mode),
      child: const _GameView(),
    );
  }
}

class _GameView extends StatelessWidget {
  const _GameView();

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(gameState.mode == GameMode.twoPlayer
            ? '2-Player Game'
            : 'vs Bot'),
        actions: [
          IconButton(
            tooltip: 'Flip board',
            onPressed: gameState.toggleManualFlip,
            icon: const Icon(Icons.flip_camera_android),
          ),
          IconButton(
            tooltip: 'Undo',
            onPressed: gameState.history.isEmpty ? null : gameState.undo,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'New game',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Start a new game?'),
                  content: const Text('This will discard the current game.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        gameState.newGame();
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('New game'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;
            final board = Padding(
              padding: const EdgeInsets.all(16),
              child: const ChessBoardWidget(),
            );
            final statusBar = _StatusBar(gameState: gameState);
            final historyPanel = const Padding(
              padding: EdgeInsets.all(16),
              child: MoveHistoryPanel(),
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        statusBar,
                        Expanded(child: Center(child: board)),
                      ],
                    ),
                  ),
                  SizedBox(width: 320, child: historyPanel),
                ],
              );
            }

            return Column(
              children: [
                statusBar,
                board,
                Expanded(child: historyPanel),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final GameState gameState;
  const _StatusBar({required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        gameState.statusText,
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
