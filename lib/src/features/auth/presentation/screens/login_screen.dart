import 'package:gjamobile/src/config/app_environment.dart';
import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gjamobile/src/features/auth/presentation/widgets/login_view.dart';
import 'package:gjamobile/src/imports/core_imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = AppInjector.get<AuthController>();

  /// Toque secreto na logo: 3 toques seguidos (dentro da janela) abrem o
  /// seletor de ambiente. Estado transitório, não precisa de `setState`.
  static const Duration _tapWindow = Duration(milliseconds: 800);
  int _logoTapCount = 0;
  DateTime? _lastLogoTap;

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  void _onLogoTap() {
    final now = DateTime.now();
    final withinWindow =
        _lastLogoTap != null && now.difference(_lastLogoTap!) <= _tapWindow;
    _logoTapCount = withinWindow ? _logoTapCount + 1 : 1;
    _lastLogoTap = now;

    if (_logoTapCount >= 3) {
      _logoTapCount = 0;
      _lastLogoTap = null;
      _showEnvironmentPicker();
    }
  }

  /// Rótulo exibido no seletor. O ambiente LOCAL aparece como "DEV".
  static String _envLabel(AppEnvironment env) =>
      env == AppEnvironment.local ? 'DEV' : env.label;

  /// Nome por extenso, na linha de baixo do rótulo.
  static String _envDescription(AppEnvironment env) => switch (env) {
        AppEnvironment.local => 'Desenvolvimento',
        AppEnvironment.qas => 'Qualidade',
        AppEnvironment.prd => 'Produção',
      };

  Future<void> _showEnvironmentPicker() async {
    final current = AppConfig.environment.value;
    final selected = await showDialog<AppEnvironment>(
      context: context,
      builder: (dialogContext) {
        final cs = dialogContext.colors;
        final tt = dialogContext.textTheme;

        return Dialog(
          insetPadding: EdgeInsets.all(AppSpacing.md),
          // A borda é o que destaca o card no tema escuro: a cor do diálogo
          // ali é quase a da barreira.
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.dialog,
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: ConstrainedBox(
            // Largura de celular também no desktop: são três opções curtas, e
            // esticadas na tela larga ficariam soltas no meio do card.
            constraints: const BoxConstraints(maxWidth: 360),
            // Rolável: com o coletor deitado as três opções não cabem na
            // altura.
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Selecionar ambiente',
                    style: tt.headlineSmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Escolha o ambiente de acesso.',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  SizedBox(height: AppSpacing.ml),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.ms,
                    children: [
                      // Mostra todos os ambientes (inclusive DEV) em qualquer
                      // plataforma — este seletor é um atalho de
                      // desenvolvimento acessível na web também.
                      for (final env in AppEnvironment.values)
                        _EnvironmentOption(
                          label: _envLabel(env),
                          description: _envDescription(env),
                          selected: env == current,
                          onTap: () => Navigator.of(dialogContext).pop(env),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (selected == null || selected == current) return;

    await AppConfig.setEnvironment(selected);
    if (!mounted) return;
    showToast(
      context,
      message: 'Ambiente alterado para ${_envLabel(selected)}',
      status: 'success',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SeasonalConfetti(
      child: SeasonalFireworks(
        child: SeasonalSnowfall(
          child: LoginView(
            isLoading: _authController.isLoadingSignal,
            onSignIn: () =>
                _authController.signInWithMicrosoft(context: context),
            onLogoTap: _onLogoTap,
          ),
        ),
      ),
    );
  }
}

/// Card de um ambiente no seletor. Cores todas derivadas do `ColorScheme`, para
/// manter contraste tanto no light quanto no dark: o nome do ambiente fica em
/// `onSurface` (nunca no accent, que sobre o fundo tingido perderia nitidez) e
/// a descrição em `onSurfaceVariant`.
class _EnvironmentOption extends StatelessWidget {
  const _EnvironmentOption({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return Material(
      color: selected
          ? cs.primary.withValues(alpha: 0.12)
          : cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.md,
        side: BorderSide(
          color: selected ? cs.primary : cs.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.ms,
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? GjaIcons.circleTask2
                    : GjaIcons.circleTask,
                color: selected ? cs.primary : cs.outline,
                size: 24,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: tt.titleMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      description,
                      style:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
