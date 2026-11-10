import 'package:dio/dio.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/entrada_saida_veiculo_mode.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/frota_veiculo.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/ocupante.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/tipo_veiculo.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/user_commav.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/veiculo.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/veiculo_retorno.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/veiculo_saida.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/utils/utils.dart';
import 'package:xml/xml.dart';

/// Data source da Portaria (entrada/saída de veículos). Sem contrato
/// abstrato — única implementação, mesmo padrão de `AccessRepository`.
class PortariaRepository {
  PortariaRepository(this._portaria);

  final PortariaDio _portaria;

  AsyncAppResult<UserCommav> getUserCommav(String matricula) {
    return runTask(() async {
      final response = await _portaria.dio.get<String>(
        '/wsv_bandeirantes/WSV_Bandeirantes.asmx/Verificar_Acesso_Matricula',
        queryParameters: {
          'STRP_Matricula': matricula,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/xml',
            'Accept': 'application/xml',
          },
          responseType: ResponseType.plain,
        ),
      );
      return UserCommav.fromXml(_parseXmlRoot(response.data));
    }, requiresNetwork: true);
  }

  /// Frotas de diretoria/flutuante/terceiro da unidade — veículos sem QR Code,
  /// pesquisáveis pela placa na tela.
  AsyncAppResult<List<FrotaVeiculo>> getFrotas({required String unidade, required TipoVeiculo tipo, required EntradaSaidaVeiculoMode mode}) {
    return runTask(() async {
      final response = await _portaria.dio.get<dynamic>(
        mode == EntradaSaidaVeiculoMode.S
            ? '/wsv_bandeirantes/WSV_Bandeirantes.asmx/Carregar_Lista_Frotas_Diretoria_Flutuante_Terceiro_Saida_Veiculo'
            : '/wsv_bandeirantes/WSV_Bandeirantes.asmx/Carregar_Lista_Frotas_Diretoria_Flutuante_Terceiro_Retorno_Frota',
        queryParameters: {
          'INTP_Identificador_Unidade': unidade,
          'STRP_Tipo_Frota_Diretoria_Terceiro': tipo.code,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/xml',
            'Accept': 'application/xml',
          },
          responseType: ResponseType.plain,
        ),
      );
      return _parseXmlRoot(response.data).findAllElements('CLA_Frota_Terceiro').map(FrotaVeiculo.fromXml).toList(growable: false);
    }, requiresNetwork: true);
  }

  /// Os webservices .asmx respondem `text/xml`, que o Dio entrega como String.
  XmlElement _parseXmlRoot(dynamic data) {
    if (data is XmlElement) return data;
    if (data is String) return XmlDocument.parse(data).rootElement;
    throw const FormatException('Resposta XML inválida do COMMAV');
  }

  AsyncAppResult<VeiculoRetorno> getVeiculoRetorno({required String strpUnidade, required String strpFrota}) {
    return runTask(() async {
      final response = await _portaria.dio.get<dynamic>(
        '/wsv_bandeirantes/WSV_Bandeirantes.asmx/Obter_Frotas_Retorno_Por_Identificador_Unidade_E_Frota',
        queryParameters: {
          'INTP_Identificador_Unidade': strpUnidade,
          'STRP_Identificador_Frota_Retorno': strpFrota,
          'STRP_Tipo_Situacao': 'S',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/xml',
            'Accept': 'application/xml',
          },
          responseType: ResponseType.plain,
        ),
      );

      return _parseXmlRoot(response.data).findAllElements('CLA_Frota_Retorno').map(VeiculoRetorno.fromXml).toList(growable: false).first;
    }, requiresNetwork: true);
  }

  AsyncAppResult<VeiculoSaida> getVeiculoSaida({required String strpUnidade, required String strpFrota}) {
    return runTask(() async {
      final response = await _portaria.dio.get<dynamic>(
        '/wsv_bandeirantes/WSV_Bandeirantes.asmx/Obter_Frotas_Por_Identificador_Unidade_E_Frota',
        queryParameters: {
          'INTP_Identificador_Unidade': strpUnidade,
          'STRP_Identificador_Frota_Retorno': strpFrota,
          'STRP_Tipo_Situacao': 'R',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/xml',
            'Accept': 'application/xml',
          },
          responseType: ResponseType.plain,
        ),
      );

      return _parseXmlRoot(response.data).findAllElements('CLA_Frota_Saida').map(VeiculoSaida.fromXml).toList(growable: false).first;
    }, requiresNetwork: true);
  }

  AsyncAppResult<Veiculo> createEntrada({
    required String codigo,
    required List<Ocupante> ocupantes,
  }) =>
      _postMovimento('/veiculos/entrada', codigo: codigo, ocupantes: ocupantes);

  AsyncAppResult<Veiculo> createSaida({
    required String codigo,
    required List<Ocupante> ocupantes,
  }) =>
      _postMovimento('/veiculos/saida', codigo: codigo, ocupantes: ocupantes);

  AsyncAppResult<Veiculo> _postMovimento(
    String path, {
    required String codigo,
    required List<Ocupante> ocupantes,
  }) {
    return runTask(() async {
      final response = await _portaria.dio.post<dynamic>(
        path,
        data: {
          'codigo': codigo,
          'matriculas': ocupantes.map((o) => o.matricula).toList(growable: false),
        },
      );
      return _parseVeiculo(response.data, path);
    }, requiresNetwork: true);
  }

  Veiculo _parseVeiculo(dynamic data, String context) {
    if (data is! Map<String, dynamic>) {
      throw FormatException('Invalid $context response');
    }
    return Veiculo.fromJson(data);
  }
/*
  String _normalizarFrota(String strpFrota) {
    var varlFrota = strpFrota.trim().toUpperCase();

    if (varlFrota.isEmpty) {
      return '';
    }

    final numero = int.tryParse(varlFrota);

    if (numero != null) {
      return numero.toString();
    }

    varlFrota = varlFrota.replaceFirst(RegExp(r'[^A-Z0-9]'), '');

    return varlFrota;
  }
  */
}
