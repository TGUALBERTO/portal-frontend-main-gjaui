import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_item_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_nf_status.dart';
import 'package:gjamobile/src/imports/imports.dart';

/// Como a tag é pintada. O design usa uma única rampa de azul para tudo; aqui
/// as situações que exigem ação do conferente (devolução, divergência) saem em
/// `error` e as conferidas em `success`, que é a leitura que o resto do portal
/// já usa.
enum ContagemTagVariante {
  /// Conferido / recebido.
  sucesso,

  /// Devolver / divergente — fundo cheio, para não passar batido.
  alerta,

  /// Pendente / bloqueado.
  neutro,

  /// Contorno — informativo (contagem de NFs, tentativa, "Contar").
  contorno,
}

/// Selo compacto de situação usado nos cards e nos cabeçalhos.
class ContagemTag extends StatelessWidget {
  const ContagemTag({
    super.key,
    required this.label,
    this.variante = ContagemTagVariante.neutro,
  });

  /// Selo da situação de uma NF-e.
  factory ContagemTag.nota(ContagemNfStatus status, {bool resumo = false}) {
    return ContagemTag(
      label: resumo ? status.labelResumo : status.label,
      variante: switch (status) {
        ContagemNfStatus.ok => ContagemTagVariante.sucesso,
        ContagemNfStatus.devolver => ContagemTagVariante.alerta,
        ContagemNfStatus.pendente => ContagemTagVariante.neutro,
      },
    );
  }

  /// Selo da situação de um item. [bloqueado] cobre o item que não será mais
  /// contado porque a nota inteira já foi condenada.
  factory ContagemTag.item(ContagemItemStatus status,
      {bool bloqueado = false}) {
    if (bloqueado) {
      return const ContagemTag(
        label: 'Bloqueado',
        variante: ContagemTagVariante.neutro,
      );
    }
    return ContagemTag(
      label: status.label,
      variante: switch (status) {
        ContagemItemStatus.ok => ContagemTagVariante.sucesso,
        ContagemItemStatus.divergente => ContagemTagVariante.alerta,
        ContagemItemStatus.pendente => ContagemTagVariante.contorno,
      },
    );
  }

  final String label;
  final ContagemTagVariante variante;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final appColors = context.appColors;

    final (fundo, texto, borda) = switch (variante) {
      ContagemTagVariante.sucesso => (
          appColors.successContainer ??
              appColors.success.withValues(alpha: 0.12),
          appColors.success,
          null,
        ),
      ContagemTagVariante.alerta => (cs.error, cs.onError, null),
      // Fundo derivado do próprio texto em vez de `surfaceContainerHighest`:
      // no tema escuro esse token é MAIS claro que a superfície (grey6), e a
      // tag ficava com contraste de 3,5:1. Derivar garante os dois temas.
      ContagemTagVariante.neutro => (
          cs.onSurfaceVariant.withValues(alpha: 0.12),
          cs.onSurfaceVariant,
          null,
        ),
      ContagemTagVariante.contorno => (
          Colors.transparent,
          cs.primary,
          cs.primary,
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: AppBorders.full,
        border: borda == null ? null : Border.all(color: borda),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: texto,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
