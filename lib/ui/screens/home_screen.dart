import 'package:flutter/material.dart';

import '../../models/game_state.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _startGame(BuildContext context, GameMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(mode: mode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stadium, size: 72),
                const SizedBox(height: 12),
                Text('Offline Chess', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => _startGame(context, GameMode.twoPlayer),
                  icon: const Icon(Icons.people_alt),
                  label: const Text('2-Player (same device)'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: null, // enabled in Stage 3 once Stockfish is wired up
                  icon: const Icon(Icons.smart_toy),
                  label: const Text('vs Bot (coming in stage 3)'),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: null, // Stage 6
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
