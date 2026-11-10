import 'package:equatable/equatable.dart';
import 'package:xml/xml.dart';

class VeiculoSaida extends Equatable {
  final int unidade;
  final String frota;
  final int quantidadeAjudante;
  final String placa;
  final String marca;
  final String modelo;
  final String ano;
  final String empresa;
  final int conferencia;
  final int carregamento;
  final String dataCarga;
  final int quantidadeCarrinho;
  final String carga;
  final String matriculaMotorista;
  final String nomeMotorista;
  final String tipoFuncionario;
  final int quilometragem;
  final int empresaMatriculaMotorista;
  final int empresaMatriculaResponsavel;
  final String matriculaConferente;
  final int unidadeDestino;
  final String tipoSaidaCargaUtilitario;
  final String motoristaProprioTerceiro;
  final int codigo35;
  final String mensagemErro;
  final String mensagemErroAcao;
  final String comSemLiberacao;

  const VeiculoSaida({
    required this.unidade,
    required this.frota,
    required this.quantidadeAjudante,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.empresa,
    required this.conferencia,
    required this.carregamento,
    required this.dataCarga,
    required this.quantidadeCarrinho,
    required this.carga,
    required this.matriculaMotorista,
    required this.nomeMotorista,
    required this.tipoFuncionario,
    required this.quilometragem,
    required this.empresaMatriculaMotorista,
    required this.empresaMatriculaResponsavel,
    required this.matriculaConferente,
    required this.unidadeDestino,
    required this.tipoSaidaCargaUtilitario,
    required this.motoristaProprioTerceiro,
    required this.codigo35,
    required this.mensagemErro,
    required this.mensagemErroAcao,
    required this.comSemLiberacao,
  });

  factory VeiculoSaida.fromXml(XmlElement xml) {
    return VeiculoSaida(
      unidade: int.tryParse(xml.getElement('FRO_INT_Unidade')?.innerText ?? '0') ?? 0,
      frota: xml.getElement('FRO_STR_Frota')?.innerText ?? '',
      quantidadeAjudante: int.tryParse(
              xml.getElement('FRO_INT_Quantidade_Ajudante')?.innerText ?? '0') ??
          0,
      placa: xml.getElement('FRO_STR_Placa')?.innerText ?? '',
      marca: xml.getElement('FRO_STR_Marca')?.innerText ?? '',
      modelo: xml.getElement('FRO_STR_Modelo')?.innerText ?? '',
      ano: xml.getElement('FRO_STR_Ano')?.innerText ?? '',
      empresa: xml.getElement('FRO_STR_Empresa')?.innerText ?? '',
      conferencia:
          int.tryParse(xml.getElement('FRO_LNG_Conferencia')?.innerText ?? '0') ??
              0,
      carregamento:
          int.tryParse(xml.getElement('FRO_LNG_Carregamento')?.innerText ?? '0') ??
              0,
      dataCarga: xml.getElement('FRO_STR_Data_Carga')?.innerText ?? '',
      quantidadeCarrinho: int.tryParse(
              xml.getElement('FRO_INT_Quantidade_Carrinho')?.innerText ?? '0') ??
          0,
      carga: xml.getElement('FRO_STR_Carga')?.innerText ?? '',
      matriculaMotorista:
          xml.getElement('FRO_STR_Matricula_Motorista')?.innerText ?? '',
      nomeMotorista:
          xml.getElement('FRO_STR_Nome_Motorista')?.innerText ?? '',
      tipoFuncionario:
          xml.getElement('FRO_STR_Tipo_Funcionario')?.innerText ?? '',
      quilometragem: int.tryParse(
              xml.getElement('FRO_LNG_Quilometragem')?.innerText ?? '0') ??
          0,
      empresaMatriculaMotorista: int.tryParse(
              xml.getElement('FRO_INT_Empresa_Matricula_Motorista')?.innerText ??
                  '0') ??
          0,
      empresaMatriculaResponsavel: int.tryParse(
              xml.getElement('FRO_INT_Empresa_Matricula_Responsavel')?.innerText ??
                  '0') ??
          0,
      matriculaConferente:
          xml.getElement('FRO_STR_Matricula_Conferente')?.innerText ?? '',
      unidadeDestino:
          int.tryParse(xml.getElement('FRO_INT_Unidade_Destino')?.innerText ?? '0') ??
              0,
      tipoSaidaCargaUtilitario:
          xml.getElement('FRO_STR_Tipo_Saida_Carga_Utilitario')?.innerText ?? '',
      motoristaProprioTerceiro:
          xml.getElement('FRO_STR_Motorista_Proprio_Terceiro')?.innerText ?? '',
      codigo35:
          int.tryParse(xml.getElement('FRO_LNG_Codigo_35')?.innerText ?? '0') ??
              0,
      mensagemErro:
          xml.getElement('FRO_STR_Mensagem_Erro')?.innerText ?? '',
      mensagemErroAcao:
          xml.getElement('FRO_STR_Mensagem_Erro_Acao')?.innerText ?? '',
      comSemLiberacao:
          xml.getElement('FRO_STR_Com_Sem_Liberacao')?.innerText ?? '',
    );
  }

  @override
  List<Object?> get props => [
        unidade,
        frota,
        quantidadeAjudante,
        placa,
        marca,
        modelo,
        ano,
        empresa,
        conferencia,
        carregamento,
        dataCarga,
        quantidadeCarrinho,
        carga,
        matriculaMotorista,
        nomeMotorista,
        tipoFuncionario,
        quilometragem,
        empresaMatriculaMotorista,
        empresaMatriculaResponsavel,
        matriculaConferente,
        unidadeDestino,
        tipoSaidaCargaUtilitario,
        motoristaProprioTerceiro,
        codigo35,
        mensagemErro,
        mensagemErroAcao,
        comSemLiberacao,
      ];
}