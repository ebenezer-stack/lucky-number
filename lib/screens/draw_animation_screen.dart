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
  late AnimationController _radarController;
  late AnimationController _scanLineController;
  
  final List<int> _gridNumbers = [];
  final List<int> _winnerIndices = [];
  final List<int> _foundWinnerIndices = [];
  final Map<int, int> _revealTicks = {}; // index -> tickCount quand trouvé
  final List<int> _alreadyRevealedIndices = []; // index déjà révélés (après suspense)
  int _highlightedIndex = -1;
  final math.Random _random = math.Random();
  
  final List<String> _suspenseTexts = [
    "INTERROGATION DE LA MATRICE...",
    "FLUX DE DONNÉES EN COURS...",
    "CALCUL DES PROBABILITÉS...",
    "EXTRACTION DES GAGNANTS...",
    "DESTIN ÉLITE ACTIVÉ...",
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

    _radarController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
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
    _radarController.dispose();
    _scanLineController.dispose();
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
          if (state.status == DrawStatus.completed) return const SizedBox.shrink();
          
          return const Scaffold(
            backgroundColor: AppTheme.backgroundDark,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.goldColor),
                  SizedBox(height: 20),
                  Text(
                    'OPTIMISATION DES DONNÉES...',
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

        const totalTicks = 300.0;
        final progress = (state.tickCount / totalTicks).clamp(0.0, 1.0);
        
        final totalWinners = state.finalNumbers!.length;
        int revealedWinnerCount;
        
        if (totalWinners <= 0) {
          revealedWinnerCount = 0;
        } else if (totalWinners == 1) {
          revealedWinnerCount = state.tickCount >= 266 ? 1 : 0;
        } else {
          if (state.tickCount >= 266) {
            revealedWinnerCount = totalWinners;
          } else {
            final subProgress = (state.tickCount / 200.0).clamp(0.0, 1.0);
            revealedWinnerCount = (subProgress * (totalWinners - 0.5)).floor().clamp(0, totalWinners - 1);
          }
        }
        
        final lastWinnerIdx = _winnerIndices.isNotEmpty ? _winnerIndices.last : -1;

        // Mise à jour des gagnants trouvés
        for (int i = 0; i < revealedWinnerCount && i < _winnerIndices.length; i++) {
          final idx = _winnerIndices[i];
          if (!_foundWinnerIndices.contains(idx)) {
            _foundWinnerIndices.add(idx);
            _revealTicks[idx] = state.tickCount;
            HapticService().mediumVibration();
          }
        }

        // Vibrations de verrouillage
        for (final idx in _foundWinnerIndices) {
          final foundAtTick = _revealTicks[idx];
          final isLast = idx == lastWinnerIdx;
          final requiredTicks = isLast ? 34 : 15;
          
          if (foundAtTick != null && (state.tickCount - foundAtTick >= requiredTicks) && !_alreadyRevealedIndices.contains(idx)) {
            _alreadyRevealedIndices.add(idx);
            HapticService().successVibration();
          }
        }

        // Calcul du compte à rebours
        int? countdown;
        if (_foundWinnerIndices.contains(lastWinnerIdx) && !_alreadyRevealedIndices.contains(lastWinnerIdx)) {
          final elapsed = state.tickCount - _revealTicks[lastWinnerIdx]!;
          countdown = 5 - (elapsed / 6.8).floor();
          if (countdown < 0) countdown = 0;
        }

        // Gestion du focus du scan (gel si décompte actif ou dernier numéro révélé)
        if (countdown != null || (lastWinnerIdx != -1 && _alreadyRevealedIndices.contains(lastWinnerIdx))) {
          _highlightedIndex = lastWinnerIdx;
        } else {
          _highlightedIndex = _random.nextInt(_gridNumbers.length);
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          body: Container(
            decoration: const BoxDecoration(
              color: AppTheme.backgroundDark,
            ),
            child: Stack(
              children: [
                _buildAnimatedBackground(),
                _buildRadarOverlay(),
                if (countdown != null) _buildCountdownOverlay(countdown),
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
                        AppTheme.primaryColor.withAlpha(15),
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

  Widget _buildRadarOverlay() {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: RadarPainter(
              progress: _radarController.value,
              color: AppTheme.primaryLight.withAlpha(30),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            const Icon(Icons.radar_rounded, color: AppTheme.goldColor, size: 45),
            const SizedBox(height: 12),
            Text(
              'SCAN ELITE EN COURS',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 8,
              ),
            ),
          ],
        ),
        // Scan line animation
        AnimatedBuilder(
          animation: _scanLineController,
          builder: (context, child) {
            return Positioned(
              top: 40 + (_scanLineController.value * 60),
              child: Container(
                width: 300,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTheme.goldColor.withAlpha(150),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
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
          color: AppTheme.goldColor.withAlpha(150),
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildScannerGrid(DrawState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: _gridNumbers.length,
        itemBuilder: (context, index) {
          final isHighlighted = index == _highlightedIndex;
          final isFound = _foundWinnerIndices.contains(index);
          
          // Effet de suspense : si trouvé depuis moins de 15 ticks (ou 34 pour le dernier), on continue de faire défiler intensément
          final foundAtTick = _revealTicks[index];
          final isLast = _winnerIndices.isNotEmpty && index == _winnerIndices.last;
          final requiredTicks = isLast ? 34 : 15;
          
          final isRevealing = foundAtTick != null && (state.tickCount - foundAtTick < requiredTicks);
          final isRevealed = foundAtTick != null && (state.tickCount - foundAtTick >= requiredTicks || state.status == DrawStatus.finishing);
          
          final displayNumber = isRevealed ? _gridNumbers[index] : (_random.nextInt(99) + 1);
          
          final isWinnerSlot = _winnerIndices.contains(index);
          final isLastWinner = isFound && _foundWinnerIndices.last == index && state.status == DrawStatus.finishing;

          Widget cell = Center(
            child: Text(
              displayNumber.toString(),
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isFound 
                    ? Colors.black 
                    : (isHighlighted ? Colors.white : Colors.white10),
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
              color: isRevealed
                  ? AppTheme.goldColor 
                  : (isRevealing ? Colors.white : (isHighlighted ? Colors.white.withAlpha(20) : Colors.white.withAlpha(2))),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isRevealed
                    ? Colors.white 
                    : (isRevealing ? AppTheme.goldColor : (isHighlighted ? AppTheme.goldColor.withAlpha(100) : Colors.white.withAlpha(5))),
                width: isRevealed || isRevealing || isHighlighted ? 2 : 1,
              ),
              boxShadow: isRevealed ? [
                BoxShadow(
                  color: isLastWinner 
                      ? Colors.white.withAlpha(200) 
                      : AppTheme.goldColor.withAlpha(150),
                  blurRadius: isLastWinner ? 30 : 15,
                  spreadRadius: isLastWinner ? 4 : 1,
                )
              ] : (isRevealing ? [
                BoxShadow(
                  color: Colors.white.withAlpha(200),
                  blurRadius: 20,
                  spreadRadius: 2,
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
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(10)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white.withAlpha(5),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tickCount >= 300 ? 'DESTIN CAPTURÉ !' : 'INTÉGRITÉ DU SIGNAL: ${(progress * 100).toInt()}%',
            style: GoogleFonts.outfit(
              color: tickCount >= 300 ? AppTheme.goldColor : Colors.white24,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownOverlay(int count) {
    return Container(
      color: Colors.black.withAlpha(100),
      child: Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(count),
          tween: Tween(begin: 1.0, end: 2.0),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) {
            return Opacity(
              opacity: (2.0 - value).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: value,
                child: Text(
                  count.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 180,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.goldColor,
                    shadows: [
                      const Shadow(color: Colors.white, blurRadius: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final double progress;
  final Color color;

  RadarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.8;
    
    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: (progress * 2 * math.pi) - 0.5,
        endAngle: progress * 2 * math.pi,
        colors: [Colors.transparent, color],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
    
    // Draw concentric circles
    final circlePaint = Paint()
      ..color = color.withAlpha(10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    canvas.drawCircle(center, radius * 0.3, circlePaint);
    canvas.drawCircle(center, radius * 0.6, circlePaint);
    canvas.drawCircle(center, radius, circlePaint);
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => oldDelegate.progress != progress;
}

