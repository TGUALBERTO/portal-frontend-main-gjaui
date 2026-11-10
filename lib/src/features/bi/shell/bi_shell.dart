import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Item de navegação do BI.
class _BiDest {
  const _BiDest(this.route, this.label, this.icon);
  final String route;
  final String label;
  final IconData icon;
}

/// Ordem espelha a barra lateral dos PNGs (§17.1 do BI_GUIDE).
const List<_BiDest> _biDestinations = [
  _BiDest(AppRoutes.biExecutive, 'Home Executiva', GjaIcons.home),
  _BiDest(AppRoutes.biCompany, 'Comparativo por Empresa', GjaIcons.verticalBarChart),
  _BiDest(AppRoutes.biIncidents, 'Incidentes', GjaIcons.warning),
  _BiDest(AppRoutes.biRequests, 'Requisições', GjaIcons.task),
  _BiDest(AppRoutes.biImprovements, 'Melhorias e Projetos', GjaIcons.lightbulb),
  _BiDest(AppRoutes.biSla, 'SLA e Backlog', GjaIcons.verified),
  _BiDest(AppRoutes.biCapacity, 'Capacity', GjaIcons.performance),
  _BiDest(AppRoutes.biSap, 'SAP e Multiplataforma', GjaIcons.widgets),
  _BiDest(AppRoutes.biChange, 'Mudanças/GMUD', GjaIcons.journeyChange),
  _BiDest(AppRoutes.biQuality, 'Qualidade', GjaIcons.checklist),
  _BiDest(AppRoutes.biTeam, 'Performance do Time', GjaIcons.trendUp),
  _BiDest(AppRoutes.biUser, 'Performance Individual', GjaIcons.personPlaceholder),
  _BiDest(AppRoutes.biDesenvolvimento, 'Desenvolvimento', GjaIcons.developerSettings),
  _BiDest(AppRoutes.biRiscos, 'Riscos e Recomendações', GjaIcons.warning),
];

/// Casca do módulo BI: barra lateral escura (fiel aos PNGs) em telas largas
/// (≥ 900px) e `Drawer` no mobile. As telas filhas fornecem só o corpo.
class BiShell extends StatelessWidget {
  const BiShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  _BiDest get _ativo => _biDestinations.firstWhere(
        (d) => location == d.route || location.startsWith('${d.route}/'),
        orElse: () => _biDestinations.first,
      );

  void _ir(BuildContext context, String route) {
    if (route != location) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = context.width >= 900;
    if (isWide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              _Sidebar(
                ativo: _ativo.route,
                onSelect: (r) => _ir(context, r),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_ativo.label)),
      drawer: Drawer(
        child: _Sidebar(
          ativo: _ativo.route,
          onSelect: (r) {
            Navigator.of(context).pop();
            _ir(context, r);
          },
        ),
      ),
      body: child,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.ativo, required this.onSelect});

  final String ativo;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 252,
      color: FioriColors.grey11,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
            child: Row(
              children: [
                Icon(GjaIcons.trendUp, color: FioriColors.blue5, size: 22.sp),
                SizedBox(width: AppSpacing.sm),
                Text('Business Intelligence',
                    style: context.textTheme.titleSmall
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
              children: [
                for (final d in _biDestinations)
                  _SidebarItem(
                    dest: d,
                    selected: ativo == d.route,
                    onTap: () => onSelect(d.route),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          _HomeButton(onTap: () => context.go(AppRoutes.home)),
          SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.dest,
    required this.selected,
    required this.onTap,
  });

  final _BiDest dest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final bg = selected ? cs.primary : Colors.transparent;
    final fg = selected ? Colors.white : Colors.white70;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      child: Material(
        color: bg,
        borderRadius: AppBorders.sm,
        child: InkWell(
          borderRadius: AppBorders.sm,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(dest.icon, size: 18.sp, color: fg),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    dest.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                        color: fg,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(GjaIcons.home, size: 18, color: Colors.white70),
        label: const Text('Início do portal',
            style: TextStyle(color: Colors.white70)),
        style: TextButton.styleFrom(alignment: Alignment.centerLeft),
      ),
    );
  }
}
