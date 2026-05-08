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

class _HomeScreenContentState extends State<_HomeScreenContent> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _buttonPulseController;
  
  final _minController = TextEditingController(text: '1');
  final _maxController = TextEditingController(text: '100');
  final _winnersController = TextEditingController(text: '1');
  final _persoNumbersController = TextEditingController();
  bool _allowDuplicates = false;
  String _drawMode = 'random';
  List<int>? _bufferedManualWinners;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _buttonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Initialisation immédiate avec les réglages actuels
    final settingsState = context.read<SettingsBloc>().state;
    if (settingsState is SettingsLoaded) {
      _minController.text = settingsState.settings.minDefault.toString();
      _maxController.text = settingsState.settings.maxDefault.toString();
      _winnersController.text = settingsState.settings.defaultWinnersCount.toString();
      _allowDuplicates = settingsState.settings.allowDuplicates;
      _drawMode = settingsState.settings.drawMode;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buttonPulseController.dispose();
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
          backgroundColor: AppTheme.backgroundDark,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildModeSelector(),
                    const SizedBox(height: 32),
                    _buildTabs(),
                    const SizedBox(height: 20),
                    _buildConfigurationGrid(),
                    const SizedBox(height: 20),
                    _buildOptions(),
                    const SizedBox(height: 40),
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
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.backgroundDark,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LUCKY ELITE',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 3,
                color: Colors.white,
              ),
            ),
            Text(
              'PARAMÉTRAGE DES FLUX',
              style: GoogleFonts.outfit(
                fontSize: 7,
                fontWeight: FontWeight.w900,
                color: AppTheme.goldColor.withAlpha(120),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        background: Stack(
          children: [
            Container(decoration: const BoxDecoration(color: AppTheme.backgroundDark)),
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppTheme.primaryColor.withAlpha(20), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 2, height: 12, color: AppTheme.goldColor),
            const SizedBox(width: 8),
            Text(
              'MÉTHODE DE TIRAGE',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white24,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(5)),
          ),
          child: Row(
            children: [
              _buildModeButton('random', 'AUTO', Icons.bolt_rounded),
              _buildModeButton('manual', 'MANUEL', Icons.lock_open_rounded),
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
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withAlpha(40) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppTheme.goldColor.withAlpha(50) : Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppTheme.goldColor : Colors.white10),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1,
                  color: isSelected ? Colors.white : Colors.white10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      dividerColor: Colors.transparent,
      labelColor: AppTheme.goldColor,
      unselectedLabelColor: Colors.white12,
      labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5),
      indicatorColor: AppTheme.goldColor,
      indicatorWeight: 2,
      indicatorSize: TabBarIndicatorSize.label,
      tabs: const [
        Tab(text: 'INTERVALLE'),
        Tab(text: 'SÉLECTION'),
      ],
    );
  }

  Widget _buildConfigurationGrid() {
    return SizedBox(
      height: 180,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildPlageFixeGrid(),
          _buildPlagePerso(),
        ],
      ),
    );
  }

  Widget _buildPlageFixeGrid() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputCard(
                  controller: _minController,
                  label: 'MIN',
                  icon: Icons.keyboard_arrow_down,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputCard(
                  controller: _maxController,
                  label: 'MAX',
                  icon: Icons.keyboard_arrow_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputCard(
                  controller: _winnersController,
                  label: 'GAGNANTS',
                  icon: Icons.stars_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlagePerso() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LISTE PERSONNALISÉE',
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppTheme.goldColor.withAlpha(150),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _persoNumbersController,
                maxLines: 3,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700, 
                  fontSize: 20, 
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Séparez vos numéros par des espaces ou virgules...',
                  hintStyle: GoogleFonts.outfit(
                    color: Colors.white24, 
                    fontSize: 14, 
                    fontWeight: FontWeight.w400
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.white24,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: AppTheme.goldColor.withAlpha(80), size: 14),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          'AUTORISER LES DOUBLONS',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white70, fontSize: 12, letterSpacing: 0.5),
        ),
        value: _allowDuplicates,
        activeColor: AppTheme.goldColor,
        activeTrackColor: AppTheme.goldColor.withAlpha(30),
        inactiveTrackColor: Colors.white.withAlpha(5),
        onChanged: (value) {
          HapticService().selectionClick();
          setState(() => _allowDuplicates = value);
        },
      ),
    );
  }

  Widget _buildDrawButton() {
    return AnimatedBuilder(
      animation: _buttonPulseController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withAlpha((40 + (30 * _buttonPulseController.value)).toInt()),
                blurRadius: 15 + (10 * _buttonPulseController.value),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FilledButton(
            onPressed: _onLancerTirage,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              'LANCER LE TIRAGE',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  void _onLancerTirage() {
    HapticService().mediumVibration();
    
    // Si on a des gagnants mis en réserve (mode discret) et qu'on est en mode AUTO, on les utilise
    if (_drawMode == 'random' && _bufferedManualWinners != null && _bufferedManualWinners!.isNotEmpty) {
      final winners = _bufferedManualWinners!;
      _bufferedManualWinners = null; // On vide la réserve
      final min = int.tryParse(_minController.text) ?? 1;
      final max = int.tryParse(_maxController.text) ?? 100;
      context.read<DrawBloc>().add(PerformForcedDraw(winners: winners, min: min, max: max));
      return;
    }

    if (_drawMode == 'manual') {
      _showManualWinnersDialog();
    } else {
      _performDraw();
    }
  }

  void _showManualWinnersDialog() {
    final winnersCount = int.tryParse(_winnersController.text) ?? 1;
    List<int> pool = [];
    
    if (_tabController.index == 0) {
      final min = int.tryParse(_minController.text) ?? 1;
      final max = int.tryParse(_maxController.text) ?? 100;
      
      if (min >= max) {
        _showError('Le minimum doit être inférieur au maximum');
        return;
      }
      
      if (winnersCount > (max - min + 1) && !_allowDuplicates) {
        _showError('Pas assez de numéros pour $winnersCount gagnants sans doublons');
        return;
      }

      if (max - min > 500) {
        _showError('Plage trop large pour la sélection manuelle (max 500)');
        return;
      }
      pool = List.generate(max - min + 1, (i) => min + i);
    } else {
      final text = _persoNumbersController.text;
      pool = text.split(RegExp(r'[,\s]+')).map((s) => int.tryParse(s.trim())).whereType<int>().toList();
      
      if (pool.isEmpty) {
        _showError('Veuillez saisir une liste de nombres');
        return;
      }
      
      if (winnersCount > pool.length && !_allowDuplicates) {
        _showError('Pas assez de numéros dans votre liste ($winnersCount gagnants demandés)');
        return;
      }
    }

    final List<int> selectedWinners = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final isReady = selectedWinners.length == winnersCount;

          return AlertDialog(
            backgroundColor: AppTheme.backgroundDark,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: Colors.white.withAlpha(10)),
            ),
            title: Column(
              children: [
                Text(
                  'SÉLECTION MANUELLE',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  'CHOISISSEZ $winnersCount GAGNANT${winnersCount > 1 ? 'S' : ''}',
                  style: GoogleFonts.outfit(color: AppTheme.goldColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: pool.length,
                      itemBuilder: (context, index) {
                        final number = pool[index];
                        final isSelected = selectedWinners.contains(number);
                        
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                selectedWinners.remove(number);
                              } else if (selectedWinners.length < winnersCount) {
                                selectedWinners.add(number);
                                HapticService().selectionClick();
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.goldColor : AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.white.withAlpha(10),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(color: AppTheme.goldColor.withAlpha(100), blurRadius: 10)
                              ] : [],
                            ),
                            child: Center(
                              child: Text(
                                number.toString(),
                                style: GoogleFonts.outfit(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('ANNULER', style: GoogleFonts.outfit(color: Colors.white24, fontWeight: FontWeight.w900)),
              ),
              FilledButton(
                onPressed: isReady ? () {
                  Navigator.pop(dialogContext);
                  _performManualForcedDraw(selectedWinners);
                } : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  disabledBackgroundColor: Colors.white.withAlpha(5),
                ),
                child: Text(
                  'CONFIRMER (${selectedWinners.length}/$winnersCount)',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _performDraw() {
    final winners = int.tryParse(_winnersController.text) ?? 1;
    if (winners <= 0) {
      _showError('Le nombre de gagnants doit être au moins 1');
      return;
    }

    if (_tabController.index == 0) {
      final min = int.tryParse(_minController.text) ?? 1;
      final max = int.tryParse(_maxController.text) ?? 100;
      
      if (min >= max) {
        _showError('Le minimum doit être inférieur au maximum');
        return;
      }

      if (winners > (max - min + 1) && !_allowDuplicates) {
        _showError('Impossible de tirer $winners gagnants sans doublons dans cette plage');
        return;
      }

      context.read<DrawBloc>().add(PerformRandomDraw(
        min: min, max: max, winnersCount: winners, allowDuplicates: _allowDuplicates,
      ));
    } else {
      final text = _persoNumbersController.text;
      final pool = text.split(RegExp(r'[,\s]+')).map((s) => int.tryParse(s.trim())).whereType<int>().toList();
      
      if (pool.isEmpty) {
        _showError('Veuillez saisir une liste de nombres');
        return;
      }

      if (winners > pool.length && !_allowDuplicates) {
        _showError('Votre liste est trop courte pour $winners gagnants sans doublons');
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
    final settingsState = context.read<SettingsBloc>().state;
    final isDiscreteMode = settingsState is SettingsLoaded && settingsState.settings.discreteModeEnabled;

    if (isDiscreteMode) {
      setState(() {
        _bufferedManualWinners = winners;
        _drawMode = 'random';
        _tabController.animateTo(0);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuration AUTO appliquée avec succès', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          backgroundColor: AppTheme.successColor.withAlpha(200),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final min = int.tryParse(_minController.text) ?? 1;
      final max = int.tryParse(_maxController.text) ?? 100;
      context.read<DrawBloc>().add(PerformForcedDraw(winners: winners, min: min, max: max));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating),
    );
  }
}




