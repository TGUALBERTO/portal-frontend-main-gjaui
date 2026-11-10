import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/entities/checkin_motorista.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Acesso ao check-in de motorista no SAP.
///
/// O [backend] (qual SAP Gateway) vem de fora: quem conhece a empresa do
/// usuário é a camada de apresentação, então a data layer não precisa depender
/// do `AccessController`.
///
/// O número do check-in é **String** — o SAP usa NUMC(10) e devolve zero-padded
/// (`'0000000009'`), que um `int` destruiria.
abstract class InboundRepository {
  AsyncAppResult<CheckinMotorista> getCheckin({
    required BackendService backend,
    required String checkin,
  });

  /// Libera a entrada do veículo (`TIPO: "IN"`).
  AsyncAppResult<bool> checkIn({
    required BackendService backend,
    required String checkin,
  });

  /// Libera a saída do veículo (`TIPO: "OUT"`).
  AsyncAppResult<bool> checkOut({
    required BackendService backend,
    required String checkin,
  });
}
