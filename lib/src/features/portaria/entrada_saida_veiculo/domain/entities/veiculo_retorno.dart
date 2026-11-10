import 'package:equatable/equatable.dart';
import 'package:xml/xml.dart';

class VeiculoRetorno extends Equatable {
  final int unidade;
  final String placa;
  final String frota;
  final int conferencia;
  final int codigoSaidaRetorno;
  final int empresa;
  final String carga;
  final String matriculaMotorista;
  final String nomeMotorista;
  final int empresaMatriculaMotorista;
  final int empresaMatriculaResponsavel;
  final String dataCarga;
  final String dataSaida;
  final String horaSaida;
  final int unidadeCarga;
  final int quilometragem;
  final bool digitarQuilometragem;
  final bool digitarTipoCargaLacrada;
  final int tipoCargaLacrada;
  final String tipoRetornoCargaUtilitario;
  final String motoristaProprioTerceiro;
  final int dataDeslocamento;
  final String horaDeslocamento;

  const VeiculoRetorno({
    required this.unidade,
    required this.placa,
    required this.frota,
    required this.conferencia,
    required this.codigoSaidaRetorno,
    required this.empresa,
    required this.carga,
    required this.matriculaMotorista,
    required this.nomeMotorista,
    required this.empresaMatriculaMotorista,
    required this.empresaMatriculaResponsavel,
    required this.dataCarga,
    required this.dataSaida,
    required this.horaSaida,
    required this.unidadeCarga,
    required this.quilometragem,
    required this.digitarQuilometragem,
    required this.digitarTipoCargaLacrada,
    required this.tipoCargaLacrada,
    required this.tipoRetornoCargaUtilitario,
    required this.motoristaProprioTerceiro,
    required this.dataDeslocamento,
    required this.horaDeslocamento,
  });

  factory VeiculoRetorno.fromXml(XmlElement xml) {
    return VeiculoRetorno(
      unidade: int.tryParse(xml.getElement('FRT_INT_Unidade')?.innerText ?? '0') ?? 0,
      placa: xml.getElement('FRT_STR_Placa')?.innerText ?? '',
      frota: xml.getElement('FRT_STR_Frota')?.innerText ?? '',
      conferencia: int.tryParse(xml.getElement('FRT_LNG_Conferencia')?.innerText ?? '0') ?? 0,
      codigoSaidaRetorno: int.tryParse(xml.getElement('FRT_LNG_Codigo_Saida_Retorno')?.innerText ?? '0') ?? 0,
      empresa: int.tryParse(xml.getElement('FRT_INT_Empresa')?.innerText ?? '0') ?? 0,
      carga: xml.getElement('FRT_STR_Carga')?.innerText ?? '',
      matriculaMotorista: xml.getElement('FRT_STR_Matricula_Motorista')?.innerText ?? '',
      nomeMotorista: xml.getElement('FRT_STR_Nome_Motorista')?.innerText ?? '',
      empresaMatriculaMotorista: int.tryParse(xml.getElement('FRT_INT_Empresa_Matricula_Motorista')?.innerText ?? '0') ?? 0,
      empresaMatriculaResponsavel: int.tryParse(xml.getElement('FRT_INT_Empresa_Matricula_Responsavel')?.innerText ?? '0') ?? 0,
      dataCarga: xml.getElement('FRT_STR_Data_Carga')?.innerText ?? '',
      dataSaida: xml.getElement('FRT_STR_Data_Saida')?.innerText ?? '',
      horaSaida: xml.getElement('FRT_STR_Hora_Saida')?.innerText ?? '',
      unidadeCarga: int.tryParse(xml.getElement('FRT_INT_Unidade_Carga')?.innerText ?? '0') ?? 0,
      quilometragem: int.tryParse(xml.getElement('FRT_LNG_Quilometragem')?.innerText ?? '0') ?? 0,
      digitarQuilometragem: (xml.getElement('FRT_BOO_Digitar_Quilometragem')?.innerText ?? '').toLowerCase() == 'true',
      digitarTipoCargaLacrada: (xml.getElement('FRT_BOO_Digitar_Tipo_Carga_Lacrada')?.innerText ?? '').toLowerCase() == 'true',
      tipoCargaLacrada: int.tryParse(xml.getElement('FRT_INT_Tipo_Carga_Lacrada')?.innerText ?? '0') ?? 0,
      tipoRetornoCargaUtilitario: xml.getElement('FRT_STR_Tipo_Retorno_Carga_Utilitario')?.innerText ?? '',
      motoristaProprioTerceiro: xml.getElement('FRT_STR_Motorista_Proprio_Terceiro')?.innerText ?? '',
      dataDeslocamento: int.tryParse(xml.getElement('FRT_INT_Data_Deslocamento')?.innerText ?? '0') ?? 0,
      horaDeslocamento: xml.getElement('FRT_STR_Hora_Deslocamento')?.innerText ?? '',
    );
  }

  @override
  List<Object?> get props => [
        unidade,
        placa,
        frota,
        conferencia,
        codigoSaidaRetorno,
        empresa,
        carga,
        matriculaMotorista,
        nomeMotorista,
        empresaMatriculaMotorista,
        empresaMatriculaResponsavel,
        dataCarga,
        dataSaida,
        horaSaida,
        unidadeCarga,
        quilometragem,
        digitarQuilometragem,
        digitarTipoCargaLacrada,
        tipoCargaLacrada,
        tipoRetornoCargaUtilitario,
        motoristaProprioTerceiro,
        dataDeslocamento,
        horaDeslocamento,
      ];
}
