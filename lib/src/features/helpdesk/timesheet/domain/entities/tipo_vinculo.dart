/// Papel do usuário em um chamado (`chamados_usuarios.tipo` no espelho do GLPI).
///
/// É o filtro central do painel "Meus chamados": o mesmo usuário aparece na
/// lista por motivos diferentes — porque abriu o chamado, porque atende, ou
/// porque só acompanha.
enum TipoVinculo {
  requerente(1, 'Requerente'),
  tecnico(2, 'Técnico'),
  observador(3, 'Observador');

  const TipoVinculo(this.codigo, this.label);

  /// Valor trafegado pela API (código do GLPI).
  final int codigo;

  /// Rótulo pt-BR exibido no selo do card.
  final String label;

  /// Código desconhecido devolve `null` — o card apenas não mostra o selo, em
  /// vez de quebrar a lista inteira por um tipo novo no GLPI.
  static TipoVinculo? fromCodigo(int? codigo) {
    for (final vinculo in TipoVinculo.values) {
      if (vinculo.codigo == codigo) return vinculo;
    }
    return null;
  }
}
