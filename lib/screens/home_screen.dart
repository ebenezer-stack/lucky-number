import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../blocs/draw_bloc.dart';
import '../blocs/settings_bloc.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import 'draw_animation_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeScreenContent();
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _minController = TextEditingController(text: '1');
  final _maxController = TextEditingController(text: '100');
  final _winnersController = TextEditingController(text: '1');
  final _persoNumbersController = TextEditingController();
  bool _allowDuplicates = false;
  String _drawMode = 'random';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _winnersController.dispose();
    _persoNumbersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsLoaded) {
          _minController.text = state.settings.minDefault.toString();
          _maxController.text = state.settings.maxDefault.toString();
          _winnersController.text = state.settings.defaultWinnersCount.toString();
          _allowDuplicates = state.settings.allowDuplicates;
          _drawMode = state.settings.drawMode;
        }
      },
      child: BlocListener<DrawBloc, DrawState>(
        listenWhen: (previous, current) => 
            previous.status != current.status || 
            previous.lastDraw != current.lastDraw ||
            previous.error != current.error,
        listener: (context, state) {
          if (state.status == DrawStatus.starting) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DrawAnimationScreen()),
            );
          } else if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildModeSelector(),
                    const SizedBox(height: 32),
                    _buildTabs(),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 220,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPlageFixe(),
                          _buildPlagePerso(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildWinnersInput(),
                    const SizedBox(height: 24),
                    _buildOptions(),
                    const SizedBox(height: 48),
                    _buildDrawButton(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          'LUCKY NUMBERS',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.casino,
                  size: 200,
                  color: Colors.white.withAlpha(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TYPE DE TIRAGE',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withAlpha(20)),
          ),
          child: Row(
            children: [
              _buildModeButton('random', 'Automatique', Icons.auto_awesome),
              _buildModeButton('manual', 'Manuel (Force)', Icons.touch_app),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton(String mode, String label, IconData icon) {
    final isSelected = _drawMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService().selectionClick();
          setState(() => _drawMode = mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withAlpha(50),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withAlpha(20))),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Colors.grey,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14),
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'PLAGE FIXE'),
          Tab(text: 'PLAGE PERSO'),
        ],
      ),
    );
  }

  Widget _buildPlageFixe() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildInputCard(
              controller: _minController,
              label: 'MINIMUM',
              icon: Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildInputCard(
              controller: _maxController,
              label: 'MAXIMUM',
              icon: Icons.arrow_upward,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlagePerso() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: AppTheme.mediumBorderRadius,
          border: Border.all(color: Colors.grey.withAlpha(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LISTE DE NOMBRES',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.grey.shade500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _persoNumbersController,
                maxLines: 4,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Ex: 5, 12, 45, 67...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                  border: InputBorder.none,
                ),
              ),
            ),
            Text(
              'Séparez les nombres par des virgules ou des espaces',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnersInput() {
    return _buildInputCard(
      controller: _winnersController,
      label: 'NOMBRE DE GAGNANTS',
      icon: Icons.emoji_events,
    );
  }

  Widget _buildInputCard({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppTheme.mediumBorderRadius,
        border: Border.all(color: Colors.grey.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade500,
              letterSpacing: 1,
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 8),
              icon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppTheme.mediumBorderRadius,
        border: Border.all(color: Colors.grey.withAlpha(20)),
      ),
      child: SwitchListTile(
        title: const Text(
          'Autoriser les doublons',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Un même numéro peut être tiré plusieurs fois',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
        value: _allowDuplicates,
        activeColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) {
          HapticService().selectionClick();
          setState(() => _allowDuplicates = value);
        },
      ),
    );
  }

  Widget _buildDrawButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FilledButton(
        onPressed: _onLancerTirage,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome),
            const SizedBox(width: 12),
            Text(
              'LANCER LE TIRAGE',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onLancerTirage() {
    HapticService().mediumVibration();
    
    if (_drawMode == 'manual') {
      _showManualWinnersDialog();
    } else {
      _performDraw();
    }
  }

  void _showManualWinnersDialog() {
    final winnersCount = int.tryParse(_winnersController.text) ?? 1;
    final winnersControllers = List.generate(winnersCount, (_) => TextEditingController());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.backgroundDark,
        title: Text(
          'CHOISIR LES GAGNANTS',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Saisissez les numéros qui doivent sortir pour ce tirage.',
                style: GoogleFonts.outfit(color: Colors.white.withAlpha(150), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: winnersCount,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: winnersControllers[index],
                      keyboardType: TextInputType.number,
                      autofocus: index == 0,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Gagnant #${index + 1}',
                        labelStyle: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w500),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppTheme.primaryLight),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ANNULER'),
          ),
          FilledButton(
            onPressed: () {
              final winners = winnersControllers
                  .map((c) => int.tryParse(c.text))
                  .whereType<int>()
                  .toList();
              
              if (winners.length < winnersCount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez saisir tous les numéros')),
                );
                return;
              }
              
              Navigator.pop(dialogContext);
              _performManualForcedDraw(winners);
            },
            child: const Text('CONFIRMER'),
          ),
        ],
      ),
    );
  }

  void _performDraw() {
    final winners = int.tryParse(_winnersController.text) ?? 1;
    
    if (_tabController.index == 0) {
      // Plage Fixe
      final min = int.tryParse(_minController.text) ?? 1;
      final max = int.tryParse(_maxController.text) ?? 100;
      
      if (min >= max) {
        _showError('Le minimum doit être inférieur au maximum');
        return;
      }
      
      context.read<DrawBloc>().add(PerformRandomDraw(
        min: min,
        max: max,
        winnersCount: winners,
        allowDuplicates: _allowDuplicates,
      ));
    } else {
      // Plage Perso
      final text = _persoNumbersController.text;
      final pool = text
          .split(RegExp(r'[,\s]+'))
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList();
      
      if (pool.isEmpty) {
        _showError('Veuillez saisir une liste de nombres');
        return;
      }
      
      context.read<DrawBloc>().add(PerformRandomDraw(
        min: pool.reduce((a, b) => a < b ? a : b),
        max: pool.reduce((a, b) => a > b ? a : b),
        winnersCount: winners,
        allowDuplicates: _allowDuplicates,
        candidatePool: pool,
      ));
    }
  }

  void _performManualForcedDraw(List<int> winners) {
    final min = int.tryParse(_minController.text) ?? 1;
    final max = int.tryParse(_maxController.text) ?? 100;
    
    context.read<DrawBloc>().add(PerformForcedDraw(
      winners: winners,
      min: min,
      max: max,
    ));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}



