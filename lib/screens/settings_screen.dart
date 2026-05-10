import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings_bloc.dart';
import '../models/settings_model.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          'B-GLORY PROFIL',
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
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        if (state is! SettingsLoaded) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppTheme.goldColor)),
          );
        }

        final settings = state.settings;

        return SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              /*
              _buildSectionHeader('APPARENCE'),
              const SizedBox(height: 16),
              _buildThemeSelector(context, settings.theme),
              const SizedBox(height: 40),
              */
              _buildSectionHeader('VALEURS PAR DÉFAUT'),
              const SizedBox(height: 16),
              _buildDefaultValuesGrid(context, settings),
              _buildSettingCard(
                context,
                'DOUBLONS PAR DÉFAUT',
                'Autoriser les répétitions au démarrage',
                Icons.copy_rounded,
                settings.allowDuplicates,
                () => context.read<SettingsBloc>().add(ToggleDuplicates()),
              ),
              const SizedBox(height: 40),
              _buildSectionHeader('EXPÉRIENCE'),
              const SizedBox(height: 16),
              _buildSettingCard(
                context,
                'SONS B-GLORY',
                'Effets sonores immersifs',
                Icons.volume_up_outlined,
                settings.soundEnabled,
                () => context.read<SettingsBloc>().add(ToggleSound()),
              ),
              _buildSettingCard(
                context,
                'HAPTIQUE PREMIUM',
                'Retours tactiles précis',
                Icons.vibration_outlined,
                settings.vibrationEnabled,
                () => context.read<SettingsBloc>().add(ToggleVibration()),
              ),
              _buildSettingCard(
                context,
                'ANIMATIONS FLUIDES',
                'Transitions haute performance',
                Icons.auto_awesome_motion_outlined,
                settings.animationsEnabled,
                () => context.read<SettingsBloc>().add(ToggleAnimations()),
              ),
              _buildSettingCard(
                context,
                'MODE DISCRÉTION',
                'Masquer les interventions manuelles',
                Icons.security_outlined,
                settings.discreteModeEnabled,
                () => context.read<SettingsBloc>().add(ToggleDiscreteMode()),
              ),
              const SizedBox(height: 40),
              _buildSectionHeader('INFORMATIONS'),
              const SizedBox(height: 16),
              _buildInfoCard(context, 'VERSION', '1.0.0 "B-GLORY EDITION"'),
              _buildInfoCard(context, 'ÉDITION', 'PREMIUM'),
              const SizedBox(height: 100),
            ]),
          ),
        );
      },
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

  Widget _buildThemeSelector(BuildContext context, String currentTheme) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Row(
        children: [
          _buildThemeButton(context, 'light', 'CLAIR', Icons.light_mode_outlined, currentTheme == 'light'),
          _buildThemeButton(context, 'dark', 'SOMBRE', Icons.dark_mode_outlined, currentTheme == 'dark'),
          _buildThemeButton(context, 'system', 'AUTO', Icons.settings_suggest_outlined, currentTheme == 'system'),
        ],
      ),
    );
  }

  Widget _buildThemeButton(BuildContext context, String theme, String label, IconData icon, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<SettingsBloc>().add(UpdateTheme(theme)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected ? [
              BoxShadow(color: AppTheme.primaryColor.withAlpha(100), blurRadius: 10)
            ] : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : Colors.white38,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : Colors.white24,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, String title, String subtitle, IconData icon, bool value, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryColor.withAlpha(30)),
          ),
          child: Icon(icon, color: AppTheme.primaryLight, size: 24),
        ),
        title: Text(
          title, 
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800, 
            color: Colors.white,
            fontSize: 16,
          )
        ),
        subtitle: Text(
          subtitle, 
          style: GoogleFonts.outfit(
            fontSize: 12, 
            color: Colors.white38
          )
        ),
        trailing: Switch(
          value: value,
          onChanged: (_) => onTap(),
          activeColor: AppTheme.goldColor,
          activeTrackColor: AppTheme.goldColor.withAlpha(50),
          inactiveTrackColor: Colors.white10,
        ),
      ),
    );
  }

  Widget _buildDefaultValuesGrid(BuildContext context, AppSettings settings) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactNumericInput(
              context, 
              'MIN', 
              settings.minDefault.toString(),
              (val) => context.read<SettingsBloc>().add(UpdateMinRange(int.tryParse(val) ?? 1)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCompactNumericInput(
              context, 
              'MAX', 
              settings.maxDefault.toString(),
              (val) => context.read<SettingsBloc>().add(UpdateMaxRange(int.tryParse(val) ?? 100)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCompactNumericInput(
              context, 
              'GAGNANTS', 
              settings.defaultWinnersCount.toString(),
              (val) => context.read<SettingsBloc>().add(UpdateDefaultWinners(int.tryParse(val) ?? 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNumericInput(BuildContext context, String label, String value, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(5)),
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
              letterSpacing: 1
            )
          ),
          const SizedBox(height: 4),
          TextField(
            controller: TextEditingController(text: value)..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
            keyboardType: TextInputType.number,
            onSubmitted: onChanged,
            style: GoogleFonts.outfit(color: AppTheme.goldColor, fontWeight: FontWeight.w900, fontSize: 16),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900, 
              color: Colors.white30,
              fontSize: 12,
              letterSpacing: 1.5,
            )
          ),
          Text(
            value, 
            style: GoogleFonts.outfit(
              color: AppTheme.goldColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            )
          ),
        ],
      ),
    );
  }
}

