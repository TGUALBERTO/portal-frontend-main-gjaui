import 'package:dio/dio.dart';
import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/entities/checkin_motorista.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/enums/checkin_checkout_veiculo_mode.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/repositories/inbound_repository.dart';
import 'package:gjamobile/src/features/inbound/shared/data/sap_odata_client.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Fala DIRETO com o SAP Gateway da empresa do usuário (OData V2).
///
/// A mecânica de sessão, retry e envelope vive no [SapODataClient] — aqui fica
/// só o que é desta feature: qual serviço, qual entity set e o que cada resposta
/// significa.
class InboundRepositoryImpl implements InboundRepository {
  InboundRepositoryImpl(this._sap);

  final SapODataClient _sap;

  /// Serviço OData desta feature, no formato `<namespace>/<nome>` — o namespace
  /// nem sempre é `sap` (ex.: `GJAAUTO/MAIN_SRV`).
  ///
  /// É o MESMO valor mandado em `/sap/session?service=`, de propósito: assim a
  /// sessão é aberta contra o serviço que as chamadas de negócio consomem. Se
  /// divergissem, um 403 de `S_SERVICE` só apareceria no meio da operação.
  static const String _service = 'sap/ZGJAAUTO_GENERIC_SRV';

  /// Grafia do entity set no serviço — "MOTISTA" sem o "R" é como o SAP expõe.
  static const String _entitySet = 'IN100_CHECKIN_MOTISTA';

  @override
  AsyncAppResult<CheckinMotorista> getCheckin({
    required BackendService backend,
    required String checkin,
  }) {
    return runTask(() async {
      final Map<String, dynamic> data;
      try {
        data = await _sap.getEntity(
          backend: backend,
          service: _service,
          // A chave vai entre aspas simples, como manda o OData V2. O Dio
          // encoda para %27, que o Gateway aceita.
          path: "$_entitySet('$checkin')",
        );
      } on DioException catch (error) {
        // 404 aqui é "esse check-in não existe" — mensagem direta para o
        // segurança, em vez do "Recurso não encontrado" genérico.
        if (error.response?.statusCode == 404) {
          throw ValidationFailure(
            'Check-in $checkin não encontrado no SAP.',
          );
        }
        rethrow;
      }
      return CheckinMotorista.fromJson(data);
    }, requiresNetwork: true);
  }

  @override
  AsyncAppResult<bool> checkIn({
    required BackendService backend,
    required String checkin,
  }) =>
      _liberar(
        backend: backend,
        checkin: checkin,
        // Não-nulo por construção: só o modo `consulta` não posta.
        tipo: CheckinCheckoutVeiculoMode.checkIn.tipo!,
      );

  @override
  AsyncAppResult<bool> checkOut({
    required BackendService backend,
    required String checkin,
  }) =>
      _liberar(
        backend: backend,
        checkin: checkin,
        tipo: CheckinCheckoutVeiculoMode.checkOut.tipo!,
      );

  AsyncAppResult<bool> _liberar({
    required BackendService backend,
    required String checkin,
    required String tipo,
  }) {
    return runTask(() async {
      final response = await _sap.write(
        backend: backend,
        service: _service,
        method: 'POST',
        path: _entitySet,
        body: {'CHECKIN': checkin, 'TIPO': tipo},
      );

      // O Dio já lança em não-2xx; aqui sobra garantir que o 2xx é um dos que
      // o serviço usa para create (200 ou 201 no OData V2).
      final status = response.statusCode;
      if (status != 200 && status != 201) {
        throw ServerFailure(
          'O SAP respondeu $status ao liberar o check-in $checkin.',
        );
      }
      return true;
    }, requiresNetwork: true);
  }
}
