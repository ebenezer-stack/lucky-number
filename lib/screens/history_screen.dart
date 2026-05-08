import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/draw_bloc.dart';
import '../models/draw_model.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          _buildHistoryList(context),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppTheme.backgroundDark,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
        title: Text(
          'HISTORIQUE ELITE',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundDark,
              ),
            ),
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withAlpha(30),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.goldColor),
          onPressed: () => _showClearConfirmation(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    return BlocBuilder<DrawBloc, DrawState>(
      builder: (context, state) {
        if (state.isLoading && state.history.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppTheme.goldColor)),
          );
        }

        if (state.history.isEmpty) {
          return const SliverFillRemaining(
            child: _EmptyHistory(),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final draw = state.history[index];
                return _HistoryCard(draw: draw);
              },
              childCount: state.history.length,
            ),
          ),
        );
      },
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Tout effacer ?', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white)),
        content: Text(
          'Voulez-vous vraiment supprimer tout l\'historique des tirages ? Cette action est irréversible.',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('ANNULER', style: GoogleFonts.outfit(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              context.read<DrawBloc>().add(ClearAllDraws());
              Navigator.pop(dialogContext);
            },
            child: Text('EFFACER TOUT', style: GoogleFonts.outfit(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Draw draw;

  const _HistoryCard({required this.draw});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ResultScreen(draw: draw)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.goldColor.withAlpha(50)),
                ),
                child: const Center(
                  child: Icon(Icons.emoji_events_outlined, color: AppTheme.goldColor, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draw.winningNumbers.join(' • '),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: draw.mode == 'random' ? AppTheme.primaryColor.withAlpha(40) : AppTheme.goldColor.withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            draw.mode == 'random' ? 'ALÉATOIRE' : 'MANUEL',
                            style: GoogleFonts.outfit(
                              color: draw.mode == 'random' ? AppTheme.primaryLight : AppTheme.goldColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM • HH:mm').format(draw.date),
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white30, size: 20),
                onPressed: () => ShareService().shareDrawResult(draw),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 80,
            color: Colors.white.withAlpha(20),
          ),
          const SizedBox(height: 24),
          Text(
            'HISTORIQUE VIDE',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white24,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vos futurs tirages de chance apparaîtront ici.',
            style: GoogleFonts.outfit(color: Colors.white10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}


