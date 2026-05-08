import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/statistics_bloc.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    // Rafraîchissement automatique à l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StatisticsBloc>().add(RefreshStatistics());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          _buildBody(context),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.backgroundDark,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ANALYSE ELITE',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            Text(
              'TABLEAU DE BORD BIOMÉTRIQUE',
              style: GoogleFonts.outfit(
                fontSize: 7,
                fontWeight: FontWeight.w900,
                color: AppTheme.goldColor.withAlpha(150),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        background: Stack(
          children: [
            Container(decoration: const BoxDecoration(color: AppTheme.backgroundDark)),
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppTheme.primaryColor.withAlpha(15), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
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
            child: Center(child: CircularProgressIndicator(color: AppTheme.goldColor, strokeWidth: 2)),
          );
        }
        if (state is StatisticsEmpty) {
          return const SliverFillRemaining(child: _EmptyStats());
        }
        if (state is StatisticsLoaded) {
          return SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMainMetrics(state),
                const SizedBox(height: 24),
                _buildOverviewGrid(context, state),
                const SizedBox(height: 40),
                _buildSectionHeader('TOP 15 DES NUMÉROS CHANCEUX'),
                const SizedBox(height: 20),
                ...state.statistics.take(15).map((stat) => _buildTopNumberRow(context, stat, state.totalDraws)),
                const SizedBox(height: 100),
              ]),
            ),
          );
        }
        return const SliverFillRemaining(
          child: Center(child: Text('Erreur de chargement', style: TextStyle(color: Colors.white24))),
        );
      },
    );
  }

  Widget _buildMainMetrics(StatisticsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.surfaceDark, AppTheme.surfaceDark.withAlpha(150)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.goldColor.withAlpha(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem('TIRAGES', state.totalDraws.toString(), Icons.layers_outlined),
          Container(width: 1, height: 40, color: Colors.white.withAlpha(10)),
          _buildMetricItem('PLUS SORTI', state.mostFrequent?.number.toString() ?? '-', Icons.trending_up_rounded),
          Container(width: 1, height: 40, color: Colors.white.withAlpha(10)),
          _buildMetricItem('INDICE', 'ELITE', Icons.verified_outlined),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.goldColor.withAlpha(180), size: 18),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildOverviewGrid(BuildContext context, StatisticsLoaded state) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildSummaryCard(
          context, 
          'Uniques', 
          state.uniqueNumbers.toString(), 
          Icons.auto_awesome_outlined, 
          AppTheme.primaryLight,
          'Nombres différents sortis'
        ),
        _buildSummaryCard(
          context, 
          'Fréquence', 
          state.averageFrequency.toStringAsFixed(1), 
          Icons.show_chart_rounded, 
          Colors.cyan,
          'Moyenne de sorties'
        ),
        _buildSummaryCard(
          context, 
          'Moins sorti', 
          state.leastFrequent?.number.toString() ?? '-', 
          Icons.trending_down_rounded, 
          AppTheme.errorColor,
          'Le numéro le plus timide'
        ),
        _buildSummaryCard(
          context, 
          'Stabilité', 
          '99.9%', 
          Icons.security_rounded, 
          AppTheme.successColor,
          'Intégrité de l\'algorithme'
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                width: 4, height: 4, 
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withAlpha(100)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 1),
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
            fontSize: 12,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.backgroundDark, AppTheme.surfaceDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppTheme.goldColor.withAlpha(40)),
            ),
            child: Center(
              child: Text(
                stat.number.toString(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
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
                      '${stat.frequency} SORTIES',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(stat.frequency / total * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.outfit(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      height: 6,
                      width: (MediaQuery.of(context).size.width - 130) * percentage,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.goldColor, AppTheme.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(color: AppTheme.goldColor.withAlpha(50), blurRadius: 4)
                        ],
                      ),
                    ),
                  ],
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
            Icons.query_stats_rounded,
            size: 80,
            color: AppTheme.goldColor.withAlpha(20),
          ),
          const SizedBox(height: 24),
          Text(
            'MATRICE VIERGE',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white24,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'En attente de flux de données...',
            style: GoogleFonts.outfit(color: Colors.white10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
