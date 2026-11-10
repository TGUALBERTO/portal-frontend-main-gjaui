import 'package:gjamobile/src/features/helpdesk/timesheet/domain/entities/chamado_resumo.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/chamado_origem_button.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/widgets/chamado_resumo_card.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/utils/timesheet_dates.dart';
import 'package:gjamobile/src/imports/imports.dart';

/// Detalhes de um chamado, somente leitura, com atalho para apontar horas.
///
/// Fecha com `pop(true)` quando o usuário escolhe apontar — quem abriu é que
/// dispara o formulário. Abrir um sheet por cima deste deixaria dois modais
/// empilhados no navigator raiz, e o de baixo ficaria pendurado.
class ChamadoDetalheSheet extends StatelessWidget {
  const ChamadoDetalheSheet({super.key, required this.chamado});

  final ChamadoResumo chamado;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: AppBorders.bottomSheet,
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Chamado #${chamado.origemId}',
                  style: tt.labelLarge?.copyWith(color: cs.primary),
                ),
                SizedBox(width: AppSpacing.xxs),
                ChamadoOrigemButton(origemId: chamado.origemId),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              chamado.titulo,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (chamado.vinculos.isNotEmpty) ...[
              SizedBox(height: AppSpacing.ms),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final vinculo in chamado.vinculos)
                    VinculoBadge(vinculo: vinculo),
                ],
              ),
            ],
            SizedBox(height: AppSpacing.md),
            _Campo(rotulo: 'Empresa', valor: chamado.empresaNome),
            _Campo(rotulo: 'Categoria', valor: chamado.categoria),
            _Campo(rotulo: 'Status', valor: chamado.statusLabel),
            _Campo(rotulo: 'Tipo', valor: chamado.tipoLabel),
            _Campo(rotulo: 'Urgência', valor: chamado.urgenciaLabel),
            _Campo(rotulo: 'Prioridade', valor: chamado.prioridadeLabel),
            _Campo(rotulo: 'Aberto em', valor: _dataHora(chamado.dataCriacao)),
            _Campo(
              rotulo: 'Prazo de solução',
              valor: _dataHora(chamado.prazoSolucao),
              alerta: chamado.atrasado,
            ),
            _Campo(
              rotulo: 'Solucionado em',
              valor: _dataHora(chamado.dataSolucao),
            ),
            SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Apontar horas',
              isFullWidth: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }

  /// `14/08/2026 09:31`; nulo some do detalhe (ver [_Campo]).
  static String? _dataHora(DateTime? data) {
    if (data == null) return null;
    return '${dayLabelPt(data)} ${timeHm(data)}';
  }
}

/// Linha rótulo/valor. Campo sem valor não é renderizado — um detalhe cheio de
/// travessões esconde o que de fato existe.
class _Campo extends StatelessWidget {
  const _Campo({required this.rotulo, required this.valor, this.alerta = false});

  final String rotulo;
  final String? valor;

  /// Destaca o valor (usado no prazo vencido).
  final bool alerta;

  @override
  Widget build(BuildContext context) {
    final texto = valor?.trim();
    if (texto == null || texto.isEmpty) return const SizedBox.shrink();

    final cs = context.colors;
    final tt = context.textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              rotulo,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              texto,
              style: tt.bodyMedium?.copyWith(
                color: alerta ? cs.error : cs.onSurface,
                fontWeight: alerta ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
