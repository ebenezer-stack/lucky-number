import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/draw_bloc.dart';
import 'blocs/settings_bloc.dart';
import 'blocs/statistics_bloc.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const LuckyEliteApp());
}

class LuckyEliteApp extends StatelessWidget {
  const LuckyEliteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc()..add(LoadSettings()),
        ),
        BlocProvider<DrawBloc>(
          create: (_) => DrawBloc(),
        ),
        BlocProvider<StatisticsBloc>(
          create: (_) => StatisticsBloc(),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          ThemeMode themeMode = ThemeMode.system;
          
          if (state is SettingsLoaded) {
            switch (state.settings.theme) {
              case 'light':
                themeMode = ThemeMode.light;
                break;
              case 'dark':
                themeMode = ThemeMode.dark;
                break;
              default:
                themeMode = ThemeMode.system;
            }
          }

          return MaterialApp(
            title: 'Lucky Elite',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
