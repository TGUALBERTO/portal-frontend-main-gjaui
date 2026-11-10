import 'package:gjamobile/src/config/app_environment.dart';
import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/confirm_dialog.dart';
import 'package:gjamobile/src/features/app_update/presentation/controllers/app_update_controller.dart';
import 'package:gjamobile/src/features/app_update/presentation/widgets/app_update_dialog.dart';
import 'package:gjamobile/src/features/auth/presentation/controllers/session_controller.dart';
import 'package:gjamobile/src/features/home/domain/feature_routes.dart';
import 'package:gjamobile/src/features/home/presentation/mappers/home_feature_mapper.dart';
import 'package:gjamobile/src/features/home/presentation/models/home_feature.dart';
import 'package:gjamobile/src/features/home/presentation/widgets/apps_group_widget.dart';
import 'package:gjamobile/src/features/home/presentation/widgets/home_app_button.dart';
import 'package:gjamobile/src/features/profile/presentation/widgets/app_bar_user_avatar.dart';
import 'package:gjamobile/src/imports/core_imports.dart';
import 'package:gjamobile/src/imports/packages_imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// A Home é o fim da pilha: daqui o voltar do Android sai do app. Confirmar
  /// antes existe porque o alvo é o coletor da doca, operado com luva — um
  /// toque acidental fechando o app no meio de uma conferência custa a
  /// releitura do check-in inteiro.
  ///
  /// `canPop: false` + fechar à mão, e não `canPop: true`: com `true` o sistema
  /// já teria encerrado a rota antes de o callback rodar, e o diálogo
  /// apareceria por cima de um app saindo.
  Future<void> _confirmarSaida(BuildContext context) async {
    final sair = await confirmDialog(
      context,
      title: 'Sair do aplicativo?',
      message: 'Você voltará para a tela inicial do dispositivo.',
      confirmLabel: 'Sair',
    );
    if (!sair) return;
    // SystemNavigator.pop, não Navigator.pop: não há rota abaixo da Home para
    // desempilhar — o que se pede aqui é ao sistema operacional.
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final session = AppInjector.get<SessionController>();
    final access = AppInjector.get<AccessController>();
    final appUpdate = AppInjector.get<AppUpdateController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmarSaida(context);
      },
      child: SeasonalConfetti(
        child: SeasonalFireworks(
          child: SeasonalSnowfall(
            child: AppPageScaffold(
              backgroundColor: colorScheme.surface,
              scrollable: false,
              appBar: AppTopBar(
                title: 'Home',
                showBackButton: false,
                actions: [
                  SignalBuilder(builder: (context) {
                    final user = session.userSignal.value;
                    return Padding(
                      padding: EdgeInsets.only(right: AppSpacing.md),
                      child: AppBarUserAvatar(
                        userId: user?.id ?? '',
                        name: user?.name ?? user?.email ?? '',
                        onTap: () => context.go(AppRoutes.me),
                      ),
                    );
                  }),
                ],
                titleWidget: SignalBuilder(builder: (context) {
                  final user = session.userSignal.value;
                  return Text(
                    user?.name ?? user?.email ?? 'Home',
                    style: theme.appBarTheme.titleTextStyle?.copyWith(
                          fontWeight: FontWeight.w600,
                        ) ??
                        textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  );
                }),
              ),
              body: SignalBuilder(builder: (context) {
                final status = access.statusSignal.value;

                if (status == AccessStatus.loading ||
                    status == AccessStatus.idle) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (status == AccessStatus.error) {
                  return _ErrorState(
                    message: access.errorSignal.value?.message ??
                        'Falha ao carregar permissões',
                    onRetry: access.load,
                    onLogout: () => _onLogoutPressed(context, session),
                  );
                }

                // Build one group per module from the user's enabled features. Dedup,
                // canRead filtering and sorting already happen in AccessController.
                final permsByModule = access.permissionsByModuleSignal.value;
                final featureGroups = <Widget>[];
                for (final entry in permsByModule.entries) {
                  final features = [
                    for (final perm in entry.value)
                      homeFeatureFromPermission(perm),
                  ];
                  if (features.isEmpty) continue;
                  featureGroups.add(
                    AppsGroupWidget(
                      title: entry.value.first.feature.module.label,
                      apps: [
                        for (final feature in features)
                          HomeAppButton(
                            onPressed: () =>
                                _onFeaturePressed(context, feature),
                            title: feature.title,
                            icon: feature.icon,
                          ),
                      ],
                    ),
                  );
                }

                // Deslogar é card fixo; sempre visível, mesmo quando o usuário não tem
                // acesso a nenhum recurso. Troca de ambiente é restrita a admins.
                final isAdmin = access.isAdminSignal.value;
                final hasUpdate = appUpdate.isUpdateAvailableSignal.value;
                final sessaoGroup = AppsGroupWidget(
                  title: 'Sessão',
                  apps: [
                    // Só existe com atualização pendente (Android). É o caminho
                    // de quem tocou em "Depois" no diálogo de abertura, e de
                    // quem recebeu a atualização com o app já aberto.
                    if (hasUpdate)
                      const HomeAppButton(
                        onPressed: showAppUpdateDialog,
                        title: 'Atualizar app',
                        icon: GjaIcons.downloadFromCloud,
                      ),
                    if (isAdmin)
                      SignalBuilder(builder: (context) {
                        final env = AppConfig.environment.value;
                        return HomeAppButton(
                          onPressed: () => _onEnvironmentPressed(context),
                          title: 'Ambiente: ${env.label}',
                          icon: GjaIcons.itHost,
                        );
                      }),
                    HomeAppButton(
                      onPressed: () => _onLogoutPressed(context, session),
                      title: 'Deslogar',
                      icon: GjaIcons.log,
                    ),
                  ],
                );

                return RefreshIndicator(
                  onRefresh: access.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 24,
                        children: [
                          if (featureGroups.isEmpty)
                            AppEmptyState(
                              icon: GjaIcons.grid,
                              title: 'Nenhum aplicativo disponível',
                              subtitle:
                                  'Você ainda não tem acesso a nenhum recurso. '
                                  'Fale com um administrador.',
                              actionLabel: 'Recarregar',
                              onAction: access.load,
                            )
                          else
                            ...featureGroups,
                          sessaoGroup,
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void _onFeaturePressed(BuildContext context, HomeFeature feature) {
    final route = feature.route;

    // No route registered yet for this feature code — surface as "coming soon".
    if (route == null) {
      showToast(
        context,
        message: 'Recurso "${feature.title}" em breve',
        status: 'info',
      );
      return;
    }

    // Admin-only features are gated here for UX; the backend also enforces it.
    if (adminOnlyFeatureCodes.contains(feature.code)) {
      final access = AppInjector.get<AccessController>();
      if (!access.isAdmin) {
        showToast(
          context,
          message: 'Acesso restrito a administradores',
          status: 'warning',
        );
        return;
      }
    }

    // `go` (não `push`): no go_router o push imperativo NÃO atualiza a barra de
    // URL — a tela troca mas o path fica no anterior. `go` reflete a rota no
    // path. O voltar continua funcionando: nas telas de seção canPop() é false,
    // então o AppTopBar cai no `go(home)` (e o back do browser também volta).
    context.go(route);
  }

  Future<void> _onEnvironmentPressed(BuildContext context) async {
    final current = AppConfig.environment.value;
    final selected = await showDialog<AppEnvironment>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Selecionar ambiente'),
        children: [
          for (final env in AppEnvironment.available)
            ListTile(
              leading: Icon(
                env == current
                    ? GjaIcons.circleTask2
                    : GjaIcons.circleTask,
              ),
              title: Text(env.label),
              subtitle: Text(
                [
                  for (final s in BackendService.values)
                    '${s.label}: ${s.baseUrlFor(env)}',
                ].join('\n'),
              ),
              onTap: () => Navigator.of(dialogContext).pop(env),
            ),
        ],
      ),
    );
    if (selected == null || selected == current) return;

    await AppConfig.setEnvironment(selected);
    // Recarrega permissões/dados contra o backend recém-selecionado.
    await AppInjector.get<AccessController>().load();
    if (!context.mounted) return;
    showToast(
      context,
      message: 'Ambiente alterado para ${selected.label}',
      status: 'success',
    );
  }

  Future<void> _onLogoutPressed(
    BuildContext context,
    SessionController session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deslogar'),
        content: const Text('Deseja realmente sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await session.logout();
    if (!context.mounted) return;
    GoRouter.of(context).go(AppRoutes.login);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onLogout,
  });

  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(GjaIcons.error, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(GjaIcons.log),
                label: const Text('Sair'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(GjaIcons.refresh),
                label: const Text('Tentar de novo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
