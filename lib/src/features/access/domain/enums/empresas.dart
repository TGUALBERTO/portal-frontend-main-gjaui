/// Empresas do grupo, identificadas pelo `codigoEmpresa` que o backend devolve
/// junto da matrícula — no `GET /users/me` (dentro de `employeeLink`) e no
/// `GET /users` (admin).
///
/// O `codigo` é a chave de negócio (folha) — **nunca** use `index`, que segue a
/// ordem de declaração e não sobrevive a inserções.
enum Empresa {
  refrescosBandeirantes(1, 'REFRESCOS BANDEIRANTES IND. E COM. LTDA'),
  rebicEmbalagens(2, 'REBIC EMBALAGENS IND E COM LTDA'),
  rebica(3, 'REBICA INDUSTRIA E COMÉRCIO LTDA'),
  rebicComercial(4, 'REBIC COMERCIAL LIMITADA'),
  refrescosBandeirantesIndustria(
      5, 'REFRESCOS BANDEIRANTES INDUSTRIA E COMERCIO LTDA'),
  nel(6, 'N & L INDUSTRIA E COMERCIO LTDA'),
  atlantaLocadora(7, 'ATLANTA LOCADORA DE VEICULOS LTDA'),
  refrescosBandeirantesObra(8, 'REFRESCOS BANDEIRANTES IND COM LTDA-OBRA'),
  alvesFaria(9, 'CENTRO EDUCACIONAL ALVES FARIA LTDA'),
  jaNendoCom(10, 'J.A. NENDO COM. DE SUPERMERCADOS'),
  redWhiteSolutions(11, 'RED & WHITE SOLUTIONS IND INFORMATICA LTDA'),
  autonomosBandeirantes(12, 'AUTONOMOS - BANDEIRANTES'),
  jlRealEstate(13, 'J & L REAL ESTATE LTDA'),
  censfa(14, 'CENSFA CENTRO DE ENSINO NOSSA SENHORA DE FATIMA'),
  vitamedic(15, 'VITAMEDIC INDUSTRIA FARMACEUTICA LTDA'),
  autonomosVitamedic(16, 'AUTONOMOS - VITAMEDIC INDUSTRIA FARMACEUTICA LTDA'),
  autonomosRebicComercial(17, 'AUTONOMOS REBIC COMERCIAL'),
  autonomosNl(18, 'AUTONOMOS NL'),
  sevla3tSystems(19, 'SEVLA 3T SYSTEMS RASTREAMENTO MONITORAMENTO LTDA'),
  autonomosAlfa(20, 'AUTONOMOS ALFA'),
  autonomosFadisp(21, 'AUTONOMOS FADISP'),
  autonomosRw(22, 'AUTONOMOS RW'),
  jaNendoComercio(23, 'J.A. NENDO COMERCIO DE SUPERMERCADOS LTDA'),
  autonomosRembal(24, 'AUTONOMOS - REMBAL'),
  autonomosRebica(25, 'AUTONOMOS - REBICA'),
  rembal(26, 'REMBAL INDUSTRIA E COMERCIO DE EMBALAGENS LTDA');

  const Empresa(this.codigo, this.razaoSocial);

  /// Código da empresa na folha — o que trafega na API (`codigoEmpresa`).
  final int codigo;

  /// Razão social completa, usada como label na UI.
  final String razaoSocial;

  /// Resolve o enum pelo código do backend. Retorna `null` quando o código é
  /// ausente ou desconhecido (empresa nova ainda não mapeada aqui) — a UI trata
  /// como "sem empresa" em vez de quebrar.
  static Empresa? fromCodigo(int? codigo) {
    if (codigo == null) return null;
    for (final empresa in Empresa.values) {
      if (empresa.codigo == codigo) return empresa;
    }
    return null;
  }
}
