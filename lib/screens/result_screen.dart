import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/draw_model.dart';
import '../theme/app_theme.dart';
import '../services/share_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultScreen extends StatefulWidget {
  final Draw draw;

  const ResultScreen({super.key, required this.draw});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _entranceController;
  final List<Animation<double>> _staggeredAnimations = [];

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    final count = widget.draw.winningNumbers.length;
    for (int i = 0; i < count; i++) {
      final start = (i * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      _staggeredAnimations.add(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(start, end, curve: Curves.elasticOut),
        ),
      );
    }

    _entranceController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundDark,
        ),
        child: Stack(
          children: [
            _buildAnimatedBackground(),
            _buildConfettiLayer(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 10),
                  _buildHeader(context),
                  const SizedBox(height: 40),
                  Expanded(
                    child: _buildResultsList(context),
                  ),
                  _buildFooter(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _confettiController,
        builder: (context, child) {
          return CustomPaint(
            painter: BackgroundPainter(
              color: AppTheme.primaryColor.withAlpha(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfettiLayer() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _confettiController,
        builder: (context, child) {
          return CustomPaint(
            painter: ConfettiPainter(
              progress: _confettiController.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white70),
            onPressed: () => ShareService().shareDrawResult(widget.draw),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FadeTransition(
      opacity: _entranceController,
      child: Column(
        children: [
          ScaleTransition(
            scale: _entranceController,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.goldGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withAlpha(80),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'MAGNIFIQUE !',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'VOS NUMÉROS DE CHANCE',
            style: GoogleFonts.outfit(
              color: AppTheme.goldColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: List.generate(widget.draw.winningNumbers.length, (index) {
          final number = widget.draw.winningNumbers[index];
          return ScaleTransition(
            scale: _staggeredAnimations[index],
            child: Container(
              width: 75,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.goldColor.withAlpha(120),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withAlpha(30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.star,
                      size: 10,
                      color: AppTheme.goldColor.withAlpha(80),
                    ),
                  ),
                  Center(
                    child: Text(
                      number.toString(),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
      )),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(5),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem('MODE', widget.draw.mode == 'random' ? 'AUTO' : 'FORCÉ'),
                  _buildInfoItem('PLAGE', '${widget.draw.minRange}-${widget.draw.maxRange}'),
                  _buildInfoItem('HEURE', DateFormat('HH:mm').format(widget.draw.date)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 70,
              child: FilledButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.goldColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 10,
                  shadowColor: AppTheme.goldColor.withAlpha(100),
                ),
                child: Text(
                  'TENTER À NOUVEAU',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Confetto> _confetti;

  ConfettiPainter({required this.progress}) : _confetti = List.generate(50, (i) => Confetto(i));

  @override
  void paint(Canvas canvas, Size size) {
    for (var confetto in _confetti) {
      confetto.paint(canvas, size, progress);
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

class Confetto {
  final int index;
  late double seedX;
  late double speedY;
  late double rotationSpeed;
  late Color color;
  late double confettoSize;

  Confetto(this.index) {
    final random = math.Random(index);
    seedX = random.nextDouble();
    speedY = 1.0 + random.nextDouble() * 2.0;
    rotationSpeed = random.nextDouble() * 5.0;
    confettoSize = 4.0 + random.nextDouble() * 6.0;
    color = [
      AppTheme.goldColor,
      AppTheme.primaryLight,
      Colors.white,
      const Color(0xFFFFD700),
    ][random.nextInt(4)];
  }

  void paint(Canvas canvas, Size size, double progress) {
    final paint = Paint()..color = color.withAlpha(150);
    final x = seedX * size.width;
    final y = ((progress * speedY * size.height) % size.height);
    
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(progress * rotationSpeed);
    canvas.drawRect(Rect.fromLTWH(0, 0, confettoSize, confettoSize), paint);
    canvas.restore();
  }
}

class BackgroundPainter extends CustomPainter {
  final Color color;
  BackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 150, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 200, paint);
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => false;
}
