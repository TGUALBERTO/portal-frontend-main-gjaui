import 'package:gjamobile/src/features/inbound/shared/presentation/widgets/alvo_qr_code.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela de entrada padrão de **todos** os submódulos do inbound: o operador
/// informa o número do check-in — lendo o QR Code gerado na portaria, pelo
/// leitor físico do coletor ou digitando — e o módulo segue a partir dele.
///
/// Existe porque contagem cega, entrada, saída e consulta pedem exatamente a
/// mesma coisa na primeira tela. Antes cada uma montava o próprio alvo, o
/// próprio separador e o próprio bloco de erro, e as três divergiram. Aqui a
/// tela só diz **o que muda**: título, kicker e o que fazer com o número.
///
/// A câmera **não** abre sozinha — no coletor o leitor físico digita no campo e
/// o Enter dispara [onConfirmar], sem toque na tela. O bloco de leitura por
/// câmera só existe onde há câmera ([PlatformInfo.isMobile]); na web e no
/// Windows o fluxo completa inteiro pelo campo de texto.
class LeituraCheckinView extends StatelessWidget {
  const LeituraCheckinView({
    super.key,
    required this.titulo,
    required this.controller,
    required this.focusNode,
    required this.onConfirmar,
    required this.onScan,
    required this.carregando,
    this.kicker = 'Inbound · Recebimento',
    this.labelConfirmar = 'Confirmar',
    this.erro,
    this.empresaField,
  });

  /// Título exibido no corpo, abaixo do [kicker]. A `AppBar` fica com a tela.
  final String titulo;

  /// Linha de contexto acima do título.
  final String kicker;

  /// Label do botão de confirmação — "Confirmar" na contagem, "Buscar" na
  /// portaria e na consulta.
  final String labelConfirmar;

  /// Campo do número do check-in. Vive no controller da feature — a view não
  /// cria nem descarta nada.
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Disparado pelo botão de confirmação e pelo Enter do coletor.
  final Future<void> Function() onConfirmar;

  /// Abre o scanner de QR Code. Só é usado em Android/iOS.
  final Future<void> Function() onScan;

  /// Bloqueia os dois botões e põe o de confirmação em loading.
  final bool carregando;

  /// Bloco de erro, renderizado **abaixo** do campo — o operador precisa
  /// continuar vendo o número que digitou para corrigir um dígito. Sem
  /// `onRetry`: o botão de confirmação logo acima já é o retry, e dois botões
  /// de tentar de novo confundem no coletor.
  final Widget? erro;

  final Widget? empresaField;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InboundKicker(kicker),
        SizedBox(height: AppSpacing.xxs),
        Text(
          titulo,
          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.lg),
        if (empresaField != null) ...[
          empresaField!,
          SizedBox(height: AppSpacing.md),
        ],
        if (PlatformInfo.isMobile) ...[
          const AlvoQrCode(),
          SizedBox(height: AppSpacing.md),
          Text(
            'Aponte para o QR-Code do Check-in gerado na portaria',
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Ler QR-Code',
            height: ButtonSize.large,
            isFullWidth: true,
            prefixIcon: const Icon(GjaIcons.qrCode),
            onPressed: carregando ? null : onScan,
          ),
          SizedBox(height: AppSpacing.ml),
          const SeparadorOuDigite(),
          SizedBox(height: AppSpacing.ml),
        ],
        AppTextField(
          label: 'Nº do Check-in',
          hint: 'Ex.: 3',
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.search,
          onFieldSubmitted: (_) => onConfirmar(),
        ),
        SizedBox(height: AppSpacing.md),
        AppButton(
          label: labelConfirmar,
          // No mobile o primary é o "Ler QR-Code" logo acima; aqui o outline
          // marca a alternativa. Sem câmera este é o único caminho, então vira
          // o primary.
          variant: PlatformInfo.isMobile
              ? ButtonVariant.outline
              : ButtonVariant.primary,
          isFullWidth: true,
          isLoading: carregando,
          onPressed: carregando ? null : onConfirmar,
        ),
        if (erro != null)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: erro,
          ),
      ],
    );
  }
}

/// "———— ou digite ————"
class SeparadorOuDigite extends StatelessWidget {
  const SeparadorOuDigite({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: AppDivider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.ms),
          child: Text(
            'ou digite',
            style: context.textTheme.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ),
        const Expanded(child: AppDivider()),
      ],
    );
  }
}

/// Linha de contexto acima do título — o *kicker* do design.
class InboundKicker extends StatelessWidget {
  const InboundKicker(this.texto, {super.key, this.align = TextAlign.start});

  final String texto;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      textAlign: align,
      style: context.textTheme.labelMedium?.copyWith(
        color: context.colors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
