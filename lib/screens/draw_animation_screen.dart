import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../blocs/draw_bloc.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class DrawAnimationScreen extends StatefulWidget {
  const DrawAnimationScreen({super.key});

  @override
  State<DrawAnimationScreen> createState() => _DrawAnimationScreenState();
}

class _DrawAnimationScreenState extends State<DrawAnimationScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _gridRotateController;
  final List<int> _gridNumbers = [];
  final List<int> _winnerIndices = [];
  final List<int> _foundWinnerIndices = [];
  int _highlightedIndex = -1;
  final math.Random _random = math.Random();
  
  final List<String> _suspenseTexts = [
    "RECHERCHE DANS LA MATRICE...",
    "SCAN DES POSSIBILITÉS...",
    "ALIGNEMENT DES PROBABILITÉS...",
    "EXTRACTION DES GAGNANTS...",
    "DESTIN EN COURS...",
  ];
  int _currentTextIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _gridRotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _startTextRotation();
  }

  void _startTextRotation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;
      setState(() {
        _currentTextIndex = (_currentTextIndex + 1) % _suspenseTexts.length;
      });
      return true;
    });
  }

  void _initializeGrid(int count, int min, int max, List<int> finalWinners) {
    if (_gridNumbers.isNotEmpty) return;

    const gridSize = 42;
    final range = max - min + 1;
    
    for (int i = 0; i < gridSize; i++) {
      _gridNumbers.add(min + _random.nextInt(range));
    }

    final List<int> availableIndices = List.generate(gridSize, (index) => index);
    availableIndices.shuffle();

    for (int i = 0; i < finalWinners.length && i < gridSize; i++) {
      final index = availableIndices[i];
      _gridNumbers[index] = finalWinners[i];
      _winnerIndices.add(index);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _gridRotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DrawBloc, DrawState>(
      listener: (context, state) {
        if (state.status == DrawStatus.completed && state.lastDraw != null) {
          HapticService().successVibration();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              settings: const RouteSettings(name: '/result'),
              builder: (_) => ResultScreen(draw: state.lastDraw!),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == DrawStatus.completed || state.animatingNumbers == null || state.finalNumbers == null) {
          // Show a brief loading only if not already completed (to avoid flicker)
          if (state.status == DrawStatus.completed) return const SizedBox.shrink();
          
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.goldColor),
                  SizedBox(height: 20),
                  Text(
                    'FINALISATION...',
                    style: TextStyle(color: Colors.white70, letterSpacing: 2),
                  ),
                ],
              ),
            ),
          );
        }

        if (_gridNumbers.isEmpty) {
          _initializeGrid(state.finalNumbers!.length, 1, 100, state.finalNumbers!);
        }

        _highlightedIndex = _random.nextInt(_gridNumbers.length);
        
        const totalTicks = 20.0;
        final progress = (state.tickCount / totalTicks).clamp(0.0, 1.0);
        
        final revealedWinnerCount = state.tickCount >= totalTicks 
            ? state.finalNumbers!.length 
            : ((progress * (state.finalNumbers!.length + 0.5))).floor()
                .clamp(0, state.finalNumbers!.length);
        
        for (int i = 0; i < revealedWinnerCount && i < _winnerIndices.length; i++) {
          if (!_foundWinnerIndices.contains(_winnerIndices[i])) {
            _foundWinnerIndices.add(_winnerIndices[i]);
            HapticService().mediumVibration();
          }
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              color: AppTheme.backgroundDark,
            ),
            child: Stack(
              children: [
                _buildAnimatedBackground(),
                SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildSuspenseText(),
                        const SizedBox(height: 40),
                        _buildScannerGrid(state),
                        const SizedBox(height: 40),
                        _buildProgressBar(progress, state.tickCount),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _gridRotateController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -150,
              right: -150,
              child: Transform.rotate(
                angle: _gridRotateController.value * 2 * math.pi,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryColor.withAlpha(20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.radar, color: AppTheme.goldColor, size: 40),
        const SizedBox(height: 12),
        Text(
          'SCAN EN COURS',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildSuspenseText() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        _suspenseTexts[_currentTextIndex],
        key: ValueKey(_currentTextIndex),
        style: GoogleFonts.outfit(
          color: AppTheme.primaryLight,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildScannerGrid(DrawState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 400,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: _gridNumbers.length,
        itemBuilder: (context, index) {
          final isHighlighted = index == _highlightedIndex;
          final isWinnerSlot = _winnerIndices.contains(index);
          final isFound = _foundWinnerIndices.contains(index);
          
          final isLastWinner = isFound && _foundWinnerIndices.last == index && state.status == DrawStatus.finishing;

          Widget cell = Center(
            child: Text(
              _gridNumbers[index].toString(),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isFound 
                    ? Colors.black 
                    : (isWinnerSlot ? AppTheme.goldColor.withAlpha(180) : (isHighlighted ? Colors.white : Colors.white24)),
              ),
            ),
          );

          if (isLastWinner) {
            cell = ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.2).animate(
                CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
              ),
              child: cell,
            );
          }
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: isFound 
                  ? AppTheme.goldColor 
                  : (isHighlighted ? Colors.white.withAlpha(50) : Colors.white.withAlpha(5)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isFound 
                    ? (isLastWinner ? Colors.white : Colors.white) 
                    : (isHighlighted ? AppTheme.primaryLight : Colors.white10),
                width: isFound || isHighlighted ? 2 : 1,
              ),
              boxShadow: isFound ? [
                BoxShadow(
                  color: isLastWinner 
                      ? Colors.white.withAlpha(200) 
                      : AppTheme.goldColor.withAlpha(100),
                  blurRadius: isLastWinner ? 25 : 15,
                  spreadRadius: isLastWinner ? 4 : 1,
                )
              ] : (isHighlighted ? [
                BoxShadow(
                  color: AppTheme.primaryLight.withAlpha(100),
                  blurRadius: 10,
                )
              ] : []),
            ),
            child: cell,
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(double progress, int tickCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tickCount >= 20 ? 'CAPTURÉ !' : 'SIGNAL: ${(progress * 100).toInt()}%',
            style: GoogleFonts.outfit(
              color: tickCount >= 20 ? AppTheme.goldColor : Colors.white30,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

