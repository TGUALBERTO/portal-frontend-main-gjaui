import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_header_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_nota_fiscal.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/enums/checkin_status.dart';

/// Check-in aberto para conferência: o cabeçalho vindo do SAP mais as notas.
///
/// O [status] vem junto de propósito. Quando ele não permite contagem a tela
/// precisa mostrar **quem** está na doca (motorista, placa) para o conferente
/// explicar o bloqueio ao motorista — devolver só um erro deixaria ele sem o que
/// dizer. Nesse caso [notas] vem vazia e nenhuma das leituras de enriquecimento
/// chega a ser disparada.
class ContagemCheckin extends Equatable {
  const ContagemCheckin({
    required this.checkin,
    required this.status,
    required this.motorista,
    required this.cpf,
    required this.placa,
    this.notas = const [],
    this.statusContagem = ContagemHeaderStatus.inexistente,
  });

  /// NUMC(10) zero-padded, como o SAP devolve.
  final String checkin;

  final CheckinStatus status;
  final String motorista;
  final String cpf;
  final String placa;
  final List<ContagemNotaFiscal> notas;

  /// `Status` do `INCContagemACegaHeader` deste check-in.
  ///
  /// Diferente de [status], que é do check-in de veículo: um caminhão pode estar
  /// em `'E'` (entregando) com a conferência já fechada em `'C'`/`'D'` — é
  /// exatamente o caso que o resumo precisa distinguir para não mandar um
  /// segundo `IN100FinalizaCC` para o mesmo check-in.
  final ContagemHeaderStatus statusContagem;

  ContagemCheckin comNotas(List<ContagemNotaFiscal> notas) => ContagemCheckin(
        checkin: checkin,
        status: status,
        motorista: motorista,
        cpf: cpf,
        placa: placa,
        notas: notas,
        statusContagem: statusContagem,
      );

  ContagemCheckin comStatusContagem(ContagemHeaderStatus statusContagem) =>
      ContagemCheckin(
        checkin: checkin,
        status: status,
        motorista: motorista,
        cpf: cpf,
        placa: placa,
        notas: notas,
        statusContagem: statusContagem,
      );

  @override
  List<Object?> get props =>
      [checkin, status, motorista, cpf, placa, notas, statusContagem];
}
