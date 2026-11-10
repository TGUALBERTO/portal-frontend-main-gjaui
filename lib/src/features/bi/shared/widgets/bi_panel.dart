import 'package:gjamobile/src/imports/imports.dart';

/// "Quadro" numerado de um dashboard ("N. Título") sobre um [AppCard], com uma
/// ação opcional à direita (ex.: "Ver todos") e altura fixa opcional (para
/// gráficos, que precisam de altura limitada).
class BiPanel extends StatelessWidget {
  const BiPanel({
    super.key,
    required this.numero,
    required this.titulo,
    required this.child,
    this.acao,
    this.altura,
  });

  final int numero;
  final String titulo;
  final Widget child;
  final Widget? acao;
  final double? altura;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('$numero. $titulo',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (acao != null) acao!,
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          if (altura != null) SizedBox(height: altura, child: child) else child,
        ],
      ),
    );
  }
}
