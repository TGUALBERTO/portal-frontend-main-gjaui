import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_mensagem_tipo.dart';

/// Aviso mostrado ao conferente logo depois de uma contagem — a faixa colorida
/// no topo da lista de itens ou dentro da tela de contagem.
///
/// É um banner e não um toast de propósito: no coletor a mão está ocupada com o
/// leitor e o material, e um toast some antes de ser lido.
class ContagemMensagem extends Equatable {
  const ContagemMensagem({required this.texto, required this.tipo});

  final String texto;
  final ContagemMensagemTipo tipo;

  @override
  List<Object?> get props => [texto, tipo];
}
