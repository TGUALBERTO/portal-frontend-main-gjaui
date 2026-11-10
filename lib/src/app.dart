import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gjamobile/src/features/app_update/presentation/widgets/app_update_listener.dart';
import 'package:gjamobile/src/imports/core_imports.dart';
import 'package:gjamobile/src/theme/gja_theme_bridge.dart';
import 'package:gja_ui/gja_ui.dart'
    show GjaLocalizations, GjaScreenSizeScope, GjaThemeScope;

class App extends StatelessWidget {
  const App({super.key});

  /// Cor da marca do portal, por modo.
  static const _primaryLight = '#de3438';
  static const _primaryDark = '#cb454c';

  @override
  Widget build(BuildContext context) {
    Widget current = _buildMaterialApp(context);

    current = ScreenUtilWrapper(child: current);

    return current;
  }

  Widget _buildMaterialApp(BuildContext context) {
    return MaterialApp.router(
      title: 'Portal GJA',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(primaryColorHex: _primaryLight),
      darkTheme: buildDarkTheme(primaryColorHex: _primaryDark),
      themeMode: ThemeMode.system,
      // App é pt-BR: sem os delegates o Material cai no inglês e os widgets de
      // data/hora (calendário do Timesheet, showTimePicker) saem em "September"
      // e "S M T W T F S". Locale fixo — não há troca de idioma no Portal.
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // Textos dos widgets GJA ("Carregando", "Fechar"...), em pt-BR.
        GjaLocalizations.delegate,
      ],
      routerConfig: appRouter,
      builder: (context, child) {
        Widget current = child!;
        current = SkeletonWrapper(child: current);
        current = SessionListenerWrapper(child: current);
        // Atualização do app pelo canal do pipeline. Inerte fora do Android.
        current = AppUpdateListener(child: current);
        // Tema GJA (packages/gja) para os widgets GJA, com a mesma marca
        // e o mesmo modo claro/escuro do tema Material.
        final brightness = Theme.of(context).brightness;
        // Classe de tamanho de tela para os widgets responsivos do GJA.
        current = GjaScreenSizeScope(child: current);
        current = GjaThemeScope(
          data: GjaThemeBridge.theme(
            brightness: brightness,
            primaryColorHex: brightness == Brightness.dark
                ? _primaryDark
                : _primaryLight,
          ),
          child: current,
        );
        return current;
      },
    );
  }
}
