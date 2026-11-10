/// Códigos das features do RH Processo no RBAC do portal (módulo `RH`,
/// cadastradas no `AccessSeeder` do backend core).
///
/// São os mesmos de `Features.java` da `rhprocesso-api`, que autoriza cada
/// endpoint por eles. Aqui servem para a Home, os guards de rota e para
/// esconder ações — o backend reforça a permissão em toda chamada.
abstract final class RhprocessoFeatures {
  RhprocessoFeatures._();

  /// Consulta de volume x NF, DANFE em PDF e planilha.
  static const String volume = 'rhprocesso_volume';

  /// Estrutura comercial: importação do Workflow e manutenção de rotas.
  static const String estrutura = 'rhprocesso_estrutura';

  /// Características de produto.
  static const String caracteristicas = 'rhprocesso_caracteristicas';

  /// Parâmetros gerais.
  static const String parametros = 'rhprocesso_parametros';
}
