// Vitrine dos componentes compartilhados com o tema GJA.
//
// Ferramenta de desenvolvimento: não passa pelo login, não chama o backend e
// não faz parte do build de produção (que usa lib/main.dart). Para abrir:
//
//   flutter run -d web-server --web-port=5001 -t lib/main_vitrine.dart
//
// e acesse http://localhost:5001.
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gjamobile/src/imports/core_imports.dart';
import 'package:gjamobile/src/shared/widgets/status_pill.dart';
import 'package:gjamobile/src/theme/gja_theme_bridge.dart';
import 'package:gja_ui/gja_ui.dart'
    show GjaLocalizations, GjaScreenSizeScope, GjaThemeScope;
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

void main() => runApp(const VitrineApp());

class VitrineApp extends StatefulWidget {
  const VitrineApp({super.key});

  @override
  State<VitrineApp> createState() => _VitrineAppState();
}

class _VitrineAppState extends State<VitrineApp> {
  static const _primaryLight = '#de3438';
  static const _primaryDark = '#cb454c';

  var _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilWrapper(
      child: MaterialApp(
        title: 'Vitrine GJA — Portal GJA',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(primaryColorHex: _primaryLight),
        darkTheme: buildDarkTheme(primaryColorHex: _primaryDark),
        themeMode: _mode,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GjaLocalizations.delegate,
        ],
        builder: (context, child) {
          final brightness = Theme.of(context).brightness;
          return GjaThemeScope(
            data: GjaThemeBridge.theme(
              brightness: brightness,
              primaryColorHex: brightness == Brightness.dark
                  ? _primaryDark
                  : _primaryLight,
            ),
            child: GjaScreenSizeScope(child: child!),
          );
        },
        home: _VitrinePage(
          dark: _mode == ThemeMode.dark,
          onToggleTheme: () => setState(() {
            _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          }),
        ),
      ),
    );
  }
}

class _VitrinePage extends StatefulWidget {
  const _VitrinePage({required this.dark, required this.onToggleTheme});

  final bool dark;
  final VoidCallback onToggleTheme;

  @override
  State<_VitrinePage> createState() => _VitrinePageState();
}

class _VitrinePageState extends State<_VitrinePage> {
  var _loading = false;
  var _check = true;
  var _switch = true;
  var _chip = 0;

  @override
  Widget build(BuildContext context) {
    final tt = context.theme.textTheme;
    final cs = context.theme.colorScheme;

    Widget secao(String titulo, List<Widget> filhos) => Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...filhos,
            ],
          ),
        );

    return Scaffold(
      // Fundo base e sombra de cabeçalho do GJA, pelo appBarTheme (o
      // AppTopBar exige GoRouter, que a vitrine não tem).
      appBar: AppBar(
        title: const Text('Vitrine GJA'),
        actions: [
          IconButton(
            tooltip: widget.dark ? 'Tema claro' : 'Tema escuro',
            icon: Icon(widget.dark ? GjaIcons.lightMode : GjaIcons.darkMode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              secao('AppButton → GjaButton', [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final v in ButtonVariant.values)
                      AppButton(label: v.name, variant: v, onPressed: () {}),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppButton(
                      label: 'Com ícone',
                      prefixIcon: const Icon(GjaIcons.save),
                      onPressed: () {},
                    ),
                    const AppButton(label: 'Desabilitado'),
                    AppButton(
                      label: _loading ? 'Carregando' : 'Clique: carregar',
                      isLoading: _loading,
                      onPressed: () {
                        setState(() => _loading = true);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) setState(() => _loading = false);
                        });
                      },
                    ),
                    AppButton(
                      label: 'Pequeno',
                      height: ButtonSize.small,
                      onPressed: () {},
                    ),
                    AppButton(
                      label: 'Grande',
                      height: ButtonSize.large,
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Largura total',
                  isFullWidth: true,
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                Text(
                  'Fallback Material (cor customizada / ícone à direita):',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 12, children: [
                  AppButton(
                    label: 'Cor própria',
                    color: Colors.teal,
                    onPressed: () {},
                  ),
                  AppButton(
                    label: 'Próximo',
                    suffixIcon: const Icon(GjaIcons.navigationRightArrow, size: 18),
                    onPressed: () {},
                  ),
                ]),
              ]),
              secao('AppCard', [
                AppCard(
                  title: 'Cartão com cabeçalho',
                  subtitle: 'Borda, raio 16 e superfície base do GJA',
                  trailing: TextButton(onPressed: () {}, child: const Text('Ver')),
                  child: const Text('Conteúdo do cartão.'),
                ),
                const SizedBox(height: 12),
                AppCard(
                  showShadow: true,
                  onTap: () {},
                  child: const Text('Cartão com a sombra "card" do GJA e toque.'),
                ),
              ]),
              secao('AppLoading → GjaBusyIndicator', [
                const SizedBox(
                  height: 96,
                  child: AppLoading(message: 'Buscando dados...'),
                ),
              ]),
              secao('AppEmptyState / AppErrorWidget → GjaIllustratedMessage', [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppCard(
                        child: AppEmptyState(
                          title: 'Nada por aqui',
                          subtitle: 'Ícone padrão → ilustração noData',
                          actionLabel: 'Atualizar',
                          onAction: () {},
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppCard(
                        child: AppEmptyState(
                          icon: GjaIcons.shippingStatus,
                          title: 'Nenhum check-in',
                          subtitle: 'Ícone da tela, no estilo GJA',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppCard(
                        child: AppErrorWidget(
                          message: 'Falha ao carregar os dados.',
                          onRetry: () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
              secao('Toast (cores de estado do GJA)', [
                Wrap(spacing: 12, runSpacing: 12, children: [
                  for (final s in ['success', 'error', 'warning', 'info'])
                    AppButton(
                      label: s,
                      variant: ButtonVariant.secondary,
                      onPressed: () =>
                          showToast(context, message: 'Toast $s', status: s),
                    ),
                ]),
              ]),
              secao('StatusPill → etiqueta do GjaObjectStatus invertido', [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final t in BadgeTone.values)
                      StatusPill.tone(context, label: t.name, tone: t),
                    StatusPill.tone(
                      context,
                      label: 'Executando',
                      tone: BadgeTone.info,
                      spinner: true,
                    ),
                    StatusPill(
                      label: 'v3 (cor avulsa)',
                      background: cs.secondaryContainer,
                      foreground: cs.onSecondaryContainer,
                    ),
                  ],
                ),
              ]),
              secao('UserAvatar → GjaAvatar', [
                const Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    UserAvatar(name: 'Maria Barros', radius: 16),
                    UserAvatar(name: 'Maria Barros'),
                    UserAvatar(name: 'João', radius: 28),
                    UserAvatar(name: 'Ana Clara Souza', radius: 44),
                  ],
                ),
              ]),
              secao('Campos e controles Material (tema GJA)', [
                const AppTextField(label: 'Nome', hint: 'Digite o nome'),
                const SizedBox(height: 12),
                const AppTextField(label: 'Desabilitado', enabled: false),
                const SizedBox(height: 12),
                AppFilterDropdown<String>(
                  rotulo: 'Situação',
                  todosLabel: 'Todas',
                  todosValue: '',
                  valor: '',
                  opcoes: const [
                    (valor: 'a', label: 'Aberta'),
                    (valor: 'f', label: 'Fechada'),
                  ],
                  onChanged: (_) {},
                ),
                const SizedBox(height: 12),
                const AppTextField(label: 'Senha', obscureText: true),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      ChoiceChip(
                        label: Text('Filtro ${i + 1}'),
                        selected: _chip == i,
                        onSelected: (_) => setState(() => _chip = i),
                      ),
                    Checkbox(
                      value: _check,
                      onChanged: (v) => setState(() => _check = v!),
                    ),
                    Switch(
                      value: _switch,
                      onChanged: (v) => setState(() => _switch = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Abrir diálogo',
                  variant: ButtonVariant.outline,
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Diálogo'),
                      content: const Text('Raio "element" (12) do GJA.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
