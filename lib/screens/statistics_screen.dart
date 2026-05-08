import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/statistics_bloc.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          _buildBody(context),
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
          'ANALYSE ELITE',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(color: AppTheme.backgroundDark),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_outlined, color: AppTheme.goldColor),
          onPressed: () => context.read<StatisticsBloc>().add(RefreshStatistics()),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<StatisticsBloc, StatisticsState>(
      builder: (context, state) {
        if (state is StatisticsLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppTheme.goldColor)),
          );
        }
        if (state is StatisticsEmpty) {
          return const SliverFillRemaining(
            child: _EmptyStats(),
          );
        }
        if (state is StatisticsLoaded) {
          return SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildOverviewGrid(context, state),
                const SizedBox(height: 40),
                _buildSectionHeader('CLASSEMENT DE CHANCE'),
                const SizedBox(height: 20),
                ...state.statistics.take(15).map((stat) => _buildTopNumberRow(context, stat, state.totalDraws)),
                const SizedBox(height: 100),
              ]),
            ),
          );
        }
        return const SliverFillRemaining(
          child: Center(child: Text('Erreur de chargement', style: TextStyle(color: Colors.white))),
        );
      },
    );
  }

  Widget _buildOverviewGrid(BuildContext context, StatisticsLoaded state) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildSummaryCard(context, 'Tirages', state.totalDraws.toString(), Icons.casino_outlined, AppTheme.primaryLight),
        _buildSummaryCard(context, 'Uniques', state.uniqueNumbers.toString(), Icons.auto_awesome_outlined, AppTheme.goldColor),
        _buildSummaryCard(context, 'Fréq. Moy', state.averageFrequency.toStringAsFixed(1), Icons.trending_up_outlined, Colors.cyan),
        _buildSummaryCard(context, 'Précision', '98%', Icons.verified_user_outlined, AppTheme.successColor),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white30,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: AppTheme.goldColor),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildTopNumberRow(BuildContext context, dynamic stat, int total) {
    final percentage = (stat.frequency / total).clamp(0.0, 1.0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.goldColor.withAlpha(30)),
            ),
            child: Center(
              child: Text(
                stat.number.toString(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppTheme.goldColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${stat.frequency} FOIS',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${stat.percentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.white.withAlpha(5),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 80,
            color: Colors.white.withAlpha(20),
          ),
          const SizedBox(height: 24),
          Text(
            'PAS DE DONNÉES',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white24,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Lancez des tirages pour voir l\'analyse.',
            style: GoogleFonts.outfit(color: Colors.white10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

