import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/teamsbot/atas/presentation/controllers/atas_list_controller.dart';
import 'package:gjamobile/src/features/teamsbot/atas/presentation/widgets/gerar_ata_dialog.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Destino de navegação do Portal de ATAs (TeamsBot).
class _Dest {
  const _Dest(this.route, this.label, this.icon, this.selectedIcon);
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = <_Dest>[
  _Dest(AppRoutes.teamsbotAtas, 'ATAs', GjaIcons.documentText,
      GjaIcons.documentText),
  _Dest(AppRoutes.teamsbotConsultar, 'Consultar',
      GjaIcons.globe, GjaIcons.globe),
  _Dest(AppRoutes.teamsbotCustos, 'Custos', GjaIcons.moneyBills,
      GjaIcons.moneyBills),
  _Dest(AppRoutes.teamsbotReunioes, 'Reuniões', GjaIcons.group,
      GjaIcons.group),
  _Dest(AppRoutes.teamsbotFila, 'Fila', GjaIcons.workflowTasks,
      GjaIcons.workflowTasks),
];

/// Casca responsiva do TeamsBot: [NavigationRail] em telas largas (≥ 840px) e
/// [NavigationBar] no mobile. Possui a [AppBar] e o FAB "Gerar ATA" (apenas na
/// aba de ATAs); as telas filhas fornecem só o corpo.
///
/// A aba "Custos" (informação sensível de IA) só aparece para administradores.
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  int _selectedIndex(List<_Dest> dests) {
    for (var i = 0; i < dests.length; i++) {
      if (location == dests[i].route) return i;
    }
    return 0;
  }

  void _onSelect(BuildContext context, List<_Dest> dests, int index) {
    final route = dests[index].route;
    if (route != location) context.go(route);
  }

  void _irParaHome(BuildContext context) => context.go(AppRoutes.home);

  Future<void> _gerarAta(BuildContext context) async {
    final controller = AppInjector.get<AtasListController>();
    final req = await showGerarAtaDialog();
    if (req != null) await controller.gerar(req);
  }

  @override
  Widget build(BuildContext context) {
    final access = AppInjector.get<AccessController>();

    return SignalBuilder(builder: (context) {
      final isAdmin = access.isAdminSignal.value;
      final dests = [
        for (final d in _destinations)
          if (isAdmin || d.route != AppRoutes.teamsbotCustos) d,
      ];

      final isWide = context.width >= 840;
      final index = _selectedIndex(dests);
      final showFab = dests[index].route == AppRoutes.teamsbotAtas;

      final fab = showFab
          ? FloatingActionButton.extended(
              onPressed: () => _gerarAta(context),
              icon: const Icon(GjaIcons.add),
              label: const Text('Gerar ATA'),
            )
          : null;

      if (isWide) {
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (i) => _onSelect(context, dests, i),
                  labelType: NavigationRailLabelType.all,
                  // Volta para a tela principal do portal.
                  leading: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: IconButton(
                      tooltip: 'Início do portal',
                      icon: Icon(GjaIcons.home,
                          color: context.colors.primary),
                      onPressed: () => _irParaHome(context),
                    ),
                  ),
                  destinations: [
                    for (final d in dests)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          ),
          // floatingActionButton: fab,
        );
      }

      return Scaffold(
        body: child,
        floatingActionButton: fab,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => _onSelect(context, dests, i),
          destinations: [
            for (final d in dests)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    });
  }
}
