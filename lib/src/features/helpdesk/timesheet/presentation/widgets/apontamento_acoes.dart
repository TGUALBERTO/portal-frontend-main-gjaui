import 'package:gjamobile/src/features/access/presentation/widgets/confirm_dialog.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Ações secundárias de um apontamento, oferecidas no hover (bloco da agenda e
/// card da visão diária) e no menu de pressão longa / botão direito.
enum ApontamentoAcao { duplicar, excluir }

/// Menu de ações ancorado na posição do gesto.
///
/// [position] precisa ser calculada contra o **overlay**, não contra o widget
/// de origem — ver [apontamentoMenuPosition]. Devolve `null` quando o menu é
/// fechado sem escolha.
Future<ApontamentoAcao?> showApontamentoMenu(
  BuildContext context, {
  required RelativeRect position,
  bool podeDuplicar = true,
  bool podeExcluir = true,
}) {
  if (!podeDuplicar && !podeExcluir) return Future.value();
  final cs = context.colors;
  return showMenu<ApontamentoAcao>(
    context: context,
    position: position,
    items: [
      if (podeDuplicar)
        const PopupMenuItem(
          value: ApontamentoAcao.duplicar,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(GjaIcons.copy, size: 20),
            title: Text('Duplicar'),
          ),
        ),
      if (podeExcluir)
        PopupMenuItem(
          value: ApontamentoAcao.excluir,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(GjaIcons.delete, size: 20, color: cs.error),
            title: Text('Excluir', style: TextStyle(color: cs.error)),
          ),
        ),
    ],
  );
}

/// Converte a posição global de um gesto na [RelativeRect] que o [showMenu]
/// espera.
///
/// Os quatro lados são medidos a partir das bordas do **overlay**: usar o
/// `RenderBox` do próprio widget de origem (um bloco da agenda pode ter 38×28)
/// jogaria o menu para o canto da tela.
RelativeRect apontamentoMenuPosition(
  BuildContext context,
  Offset globalPosition,
) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  return RelativeRect.fromLTRB(
    globalPosition.dx,
    globalPosition.dy,
    overlay.size.width - globalPosition.dx,
    overlay.size.height - globalPosition.dy,
  );
}

/// Confirmação de exclusão de um apontamento.
///
/// Cópia única: o formulário e as ações rápidas apagam a mesma coisa no mesmo
/// lugar, e uma mudança de texto tem que valer para os dois caminhos.
Future<bool> confirmarExclusaoApontamento(BuildContext context) => confirmDialog(
      context,
      title: 'Excluir apontamento',
      message: 'O apontamento será removido do chamado no GLPI. '
          'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
