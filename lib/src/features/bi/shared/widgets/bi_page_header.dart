import 'package:gjamobile/src/imports/imports.dart';

/// Cabeçalho de um dashboard do BI: título grande + subtítulo.
class BiPageHeader extends StatelessWidget {
  const BiPageHeader({super.key, required this.titulo, this.subtitulo});

  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          if (subtitulo != null && subtitulo!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.xxs),
            Text(subtitulo!,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
