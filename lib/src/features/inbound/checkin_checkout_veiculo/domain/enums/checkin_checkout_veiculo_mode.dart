import 'package:gjamobile/src/features/inbound/shared/domain/enums/checkin_status.dart';

/// O que a tela de check-in de veículos faz com o check-in encontrado.
///
/// As três rotas de `inbound_routes.dart` apontam para a MESMA tela,
/// diferenciada só por este modo: duas liberam um movimento na portaria e a
/// terceira só mostra os dados.
enum CheckinCheckoutVeiculoMode {
  /// Liberação da entrada do caminhão na empresa.
  checkIn,

  /// Liberação da saída do caminhão da empresa.
  checkOut,

  /// Somente leitura: mostra os dados do check-in e para por aí. Não libera
  /// movimento, não grava nada no SAP e não tem painel de sucesso.
  consulta;

  /// Se o modo grava alguma coisa no SAP. Em [consulta] a tela não renderiza
  /// botão de ação nem bloco de "não autorizado" — não há o que autorizar.
  bool get temAcao => this != consulta;

  /// Valor do campo `TIPO` no POST de liberação do SAP. `null` em [consulta],
  /// que não posta.
  String? get tipo => switch (this) {
        checkIn => 'IN',
        checkOut => 'OUT',
        consulta => null,
      };

  /// Label do botão de liberação.
  String get acaoLabel => switch (this) {
        checkIn => 'Liberar Entrada',
        checkOut => 'Liberar Saída',
        consulta => '',
      };

  /// Título da tela.
  String get tituloTela => switch (this) {
        checkIn => 'Entrada de Veículos',
        checkOut => 'Saída de Veículos',
        consulta => 'Consulta de Check-in',
      };

  /// Trecho usado nas mensagens de erro de autorização.
  String get movimentoLabel => switch (this) {
        checkIn => 'entrada na empresa',
        checkOut => 'saída da empresa',
        consulta => '',
      };

  /// Só o substantivo do movimento, para compor frases curtas.
  String get movimentoCurto => switch (this) {
        checkIn => 'entrada',
        checkOut => 'saída',
        consulta => '',
      };

  /// Mensagem de sucesso após a liberação.
  String get sucessoLabel => switch (this) {
        checkIn => 'Entrada liberada com sucesso',
        checkOut => 'Saída liberada com sucesso',
        consulta => '',
      };

  /// Título do painel de sucesso — curto, para ser lido de longe no coletor.
  String get sucessoTitulo => switch (this) {
        checkIn => 'Entrada liberada!',
        checkOut => 'Saída liberada!',
        consulta => '',
      };

  /// Label do botão que reinicia a tela para a próxima leitura.
  String get novaOperacaoLabel => switch (this) {
        checkIn => 'Fazer outro check-in',
        checkOut => 'Fazer outro check-out',
        consulta => 'Consultar outro check-in',
      };
}

/// Regra de autorização por modo da tela.
///
/// Vive aqui, e não no [CheckinStatus], porque o status é compartilhado por
/// todos os submódulos do inbound e não pode conhecer a tela de veículos — só
/// esta feature sabe o que é "entrada" e o que é "saída".
extension CheckinStatusModeX on CheckinStatus {
  /// Lista de permitidos por modo da tela. [CheckinCheckoutVeiculoMode.consulta]
  /// nunca autoriza movimento — não é uma restrição, é que ela não move nada.
  bool permitePara(CheckinCheckoutVeiculoMode mode) => switch (mode) {
        CheckinCheckoutVeiculoMode.checkIn => permiteEntrada,
        CheckinCheckoutVeiculoMode.checkOut => permiteSaida,
        CheckinCheckoutVeiculoMode.consulta => false,
      };
}
