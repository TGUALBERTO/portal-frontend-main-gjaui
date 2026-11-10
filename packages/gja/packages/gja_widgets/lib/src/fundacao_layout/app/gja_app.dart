import 'dart:ui' show Brightness;

import 'package:flutter/widgets.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

import '../theme/gja_theme.dart';

/// Qual tema [GjaApp] publica.
enum GjaThemeMode {
  /// Segue o brilho do sistema operacional.
  system,

  /// Sempre o tema claro (`theme`).
  light,

  /// Sempre o tema escuro (`darkTheme`).
  dark,
}

/// Raiz de uma aplicação GJA, como o `sap.m.App` do SAPUI5.
///
/// Monta a aplicação sobre `WidgetsApp`, sem Material, e aplica numa única
/// declaração:
/// - o tema [theme] ou [darkTheme], escolhido por [themeMode] (no modo
///   `system`, pelo brilho do sistema), com a troca animada por [GjaTheme];
/// - a densidade [density] ou, sem ela, a recomendada pela plataforma;
/// - a localização do GJA, depois dos [localizationsDelegates] da
///   aplicação;
/// - o escopo de tela (`GjaScreenSizeScope`) e o fundo `background`;
/// - a transição de página: deslizamento a partir do lado final.
///
/// Aplicação mínima:
///
/// ```dart
/// void main() => runApp(
///   GjaApp(
///     title: 'Pedidos',
///     home: const PaginaInicial(),
///     routes: {'/detalhe': (_) => const PaginaDetalhe()},
///   ),
/// );
/// ```
///
/// Use [GjaApp.router] com `routerConfig` para aplicações com `Router`.
class GjaApp extends StatelessWidget {
  /// Cria a aplicação com navegação por rotas.
  const GjaApp({
    super.key,
    this.navigatorKey,
    this.home,
    this.routes = const <String, WidgetBuilder>{},
    this.initialRoute,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorObservers = const <NavigatorObserver>[],
    this.title = '',
    this.builder,
    this.locale,
    this.localizationsDelegates,
    this.supportedLocales,
    this.theme,
    this.darkTheme,
    this.themeMode = GjaThemeMode.system,
    this.density,
    this.debugShowCheckedModeBanner = true,
  }) : routerConfig = null;

  /// Cria a aplicação com navegação por `Router`, a partir de
  /// [routerConfig].
  const GjaApp.router({
    super.key,
    required RouterConfig<Object> this.routerConfig,
    this.title = '',
    this.builder,
    this.locale,
    this.localizationsDelegates,
    this.supportedLocales,
    this.theme,
    this.darkTheme,
    this.themeMode = GjaThemeMode.system,
    this.density,
    this.debugShowCheckedModeBanner = true,
  }) : navigatorKey = null,
       home = null,
       routes = const <String, WidgetBuilder>{},
       initialRoute = null,
       onGenerateRoute = null,
       onUnknownRoute = null,
       navigatorObservers = const <NavigatorObserver>[];

  /// Ver `WidgetsApp.navigatorKey`.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Ver `WidgetsApp.home`.
  final Widget? home;

  /// Ver `WidgetsApp.routes`.
  final Map<String, WidgetBuilder> routes;

  /// Ver `WidgetsApp.initialRoute`.
  final String? initialRoute;

  /// Ver `WidgetsApp.onGenerateRoute`.
  final RouteFactory? onGenerateRoute;

  /// Ver `WidgetsApp.onUnknownRoute`.
  final RouteFactory? onUnknownRoute;

  /// Ver `WidgetsApp.navigatorObservers`.
  final List<NavigatorObserver> navigatorObservers;

  /// Configuração de `Router` de [GjaApp.router], ou nula.
  final RouterConfig<Object>? routerConfig;

  /// Título da aplicação para o sistema operacional.
  final String title;

  /// Envolve o conteúdo de navegação, abaixo do tema e do escopo de tela.
  final TransitionBuilder? builder;

  /// Idioma fixo; nulo usa o do dispositivo.
  final Locale? locale;

  /// Delegates da aplicação, registrados antes do delegate do GJA.
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;

  /// Idiomas suportados; nulos usam os do GJA (pt-BR e en).
  final Iterable<Locale>? supportedLocales;

  /// Tema claro; nulo usa o claro de referência.
  final GjaThemeData? theme;

  /// Tema escuro; nulo usa o escuro de referência.
  final GjaThemeData? darkTheme;

  /// Qual tema é publicado.
  final GjaThemeMode themeMode;

  /// Densidade da aplicação; nula usa a recomendada pela plataforma
  /// (`GjaResponsive.recommendedDensity`).
  final GjaDensity? density;

  /// Ver `WidgetsApp.debugShowCheckedModeBanner`.
  final bool debugShowCheckedModeBanner;

  static final _light = GjaThemeData.light();
  static final _dark = GjaThemeData.dark();

  GjaThemeData _effectiveTheme(BuildContext context) {
    final useDark = switch (themeMode) {
      GjaThemeMode.light => false,
      GjaThemeMode.dark => true,
      GjaThemeMode.system =>
        (MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light) ==
            Brightness.dark,
    };
    final base = useDark ? darkTheme ?? _dark : theme ?? _light;
    return base.withDensity(density ?? GjaResponsive.recommendedDensity());
  }

  Widget _wrap(GjaThemeData data, BuildContext context, Widget? child) {
    return GjaTheme(
      data: data,
      child: GjaScreenSizeScope(
        child: Builder(
          builder: (context) => ColoredBox(
            color: GjaTheme.of(context).colors.background,
            child: builder?.call(context, child) ?? child ?? const SizedBox(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _effectiveTheme(context);
    final delegates = <LocalizationsDelegate<dynamic>>[
      ...?localizationsDelegates,
      GjaLocalizations.delegate,
    ];
    final locales = supportedLocales ?? GjaLocalizations.supportedLocales;
    final config = routerConfig;
    if (config != null) {
      return WidgetsApp.router(
        routerConfig: config,
        title: title,
        color: data.colors.brand,
        locale: locale,
        localizationsDelegates: delegates,
        supportedLocales: locales,
        debugShowCheckedModeBanner: debugShowCheckedModeBanner,
        builder: (context, child) => _wrap(data, context, child),
      );
    }
    return WidgetsApp(
      navigatorKey: navigatorKey,
      home: home,
      routes: routes,
      initialRoute: initialRoute,
      onGenerateRoute: onGenerateRoute,
      onUnknownRoute: onUnknownRoute,
      navigatorObservers: navigatorObservers,
      title: title,
      color: data.colors.brand,
      locale: locale,
      localizationsDelegates: delegates,
      supportedLocales: locales,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          _GjaPageRoute<T>(settings: settings, builder: builder),
      builder: (context, child) => _wrap(data, context, child),
    );
  }
}

/// Rota de página do GJA: desliza a partir do lado final, com a duração
/// `medium` e a curva `standard` do tema; imediata com movimento reduzido.
class _GjaPageRoute<T> extends PageRoute<T> {
  _GjaPageRoute({required this.builder, super.settings});

  final WidgetBuilder builder;

  /// Tema do contexto do `Navigator`, sem criar dependência nele.
  GjaThemeData get _theme {
    final context = navigator?.context;
    if (context == null) return GjaThemeData.light();
    final data =
        context.getInheritedWidgetOfExactType<GjaThemeScope>()?.data ??
        GjaThemeData.light();
    final reduce =
        context
            .getInheritedWidgetOfExactType<MediaQuery>()
            ?.data
            .disableAnimations ??
        false;
    return data.resolve(disableAnimations: reduce);
  }

  @override
  Duration get transitionDuration => _theme.motion.medium;

  @override
  Duration get reverseTransitionDuration => _theme.motion.medium;

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: Offset(rtl ? -1 : 1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: _theme.motion.standard)),
      ),
      child: child,
    );
  }
}
