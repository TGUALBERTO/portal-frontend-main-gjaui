import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_mensagem.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_mensagem_tipo.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Faixa de retorno da última contagem.
///
/// Banner e não toast de propósito: no coletor a mão está no leitor e no
/// material, e um aviso que some sozinho passa despercebido — principalmente o
/// de recontagem, que é uma instrução, não uma notificação.
class ContagemBanner extends StatelessWidget {
  const ContagemBanner({super.key, required this.mensagem});

  final ContagemMensagem mensagem;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final appColors = context.appColors;

    final (fundo, frente, borda, icone) = switch (mensagem.tipo) {
      ContagemMensagemTipo.sucesso => (
          appColors.successContainer ??
              appColors.success.withValues(alpha: 0.12),
          appColors.success,
          null,
          GjaIcons.accept,
        ),
      ContagemMensagemTipo.devolucao => (
          cs.error,
          cs.onError,
          null,
          GjaIcons.warning,
        ),
      ContagemMensagemTipo.reconte => (
          appColors.warningContainer ??
              appColors.warning.withValues(alpha: 0.12),
          appColors.warning,
          appColors.warning,
          GjaIcons.warning,
        ),
      // Ícone diferente do `devolucao` de propósito: devolução é um desfecho do
      // processo, isto é um problema técnico. O conferente precisa distinguir
      // num relance para saber se chama o supervisor ou toca "Confirmar" de
      // novo.
      ContagemMensagemTipo.erro => (
          cs.errorContainer,
          cs.onErrorContainer,
          cs.error,
          GjaIcons.unsynchronize,
        ),
    };

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.ms,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: AppBorders.sm,
        border: borda == null ? null : Border.all(color: borda),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: frente),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              mensagem.texto,
              style: context.textTheme.bodySmall?.copyWith(color: frente),
            ),
          ),
        ],
      ),
    );
  }
}
