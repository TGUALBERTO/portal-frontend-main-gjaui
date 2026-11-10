enum TipoVeiculo {
  diretoria(code: 'D'),
  terceiro(code: 'T');

  final String code;

  const TipoVeiculo({required this.code});
}
