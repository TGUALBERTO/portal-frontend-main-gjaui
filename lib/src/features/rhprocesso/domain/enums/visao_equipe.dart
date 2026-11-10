/// As duas visões da consulta de volume: o consultor (as rotas dele) ou o
/// supervisor (todas as rotas da equipe). Cada uma é um recurso da API.
enum VisaoEquipe {
  consultor(rotulo: 'Consultor', recurso: 'consultores'),
  supervisor(rotulo: 'Supervisor', recurso: 'supervisores');

  const VisaoEquipe({required this.rotulo, required this.recurso});

  final String rotulo;

  /// Segmento da rota na API: `/api/v1/<recurso>/{matricula}/...`.
  final String recurso;
}
