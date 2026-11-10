import 'package:equatable/equatable.dart';

/// Identificação de uma NF-e dentro da automação de entrada.
///
/// São **dois** campos porque o SAP chaveia assim: a `Accesskey` (44 dígitos) é
/// a chave fiscal da nota, e a `Chave` (20) é a chave da automação que a
/// processou. Todos os entity sets a jusante
/// (`IN100AutomationHeader`, `IN100AutomationItems`, `IN100XmlItemsConsumByItemPO`,
/// `IN100Vars`) pedem o par — filtrar só pela `Accesskey` casaria a mesma nota
/// processada em duas automações diferentes.
///
/// Existe como value object para servir de chave de `Map` no mapper, onde as
/// seis respostas do SAP são cruzadas.
class NotaChave extends Equatable {
  const NotaChave({required this.chave, required this.accesskey});

  /// `Chave` — chave da automação, CHAR(20).
  final String chave;

  /// `Accesskey` — chave de acesso da NF-e, 44 dígitos.
  final String accesskey;

  /// Par na ordem que `odataAnyOfPairs` espera.
  (String, String) get par => (chave, accesskey);

  @override
  List<Object?> get props => [chave, accesskey];
}
