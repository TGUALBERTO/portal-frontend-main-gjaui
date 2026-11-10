import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Placeholder de um dashboard ainda não implementado (nav registrada, tela por
/// vir). Nunca mostra dado inventado — apenas um estado vazio.
class BiEmBreveScreen extends StatelessWidget {
  const BiEmBreveScreen({super.key, required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveContainer(
      child: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          BiPageHeaderFallback(titulo: titulo),
          SizedBox(height: context.height * 0.1),
          const AppEmptyState(
            icon: GjaIcons.trendUp,
            title: 'Em breve',
            subtitle: 'Este dashboard ainda será implementado.',
          ),
        ],
      ),
    );
  }
}

/// Título simples reutilizado pelo placeholder (evita import cruzado do header).
class BiPageHeaderFallback extends StatelessWidget {
  const BiPageHeaderFallback({super.key, required this.titulo});
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Text(
      titulo,
      style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}
