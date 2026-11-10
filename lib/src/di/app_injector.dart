import 'package:auto_injector/auto_injector.dart';
import 'package:gjamobile/src/config/app_config.dart';
import 'package:gjamobile/src/config/backend_service.dart';
import 'package:gjamobile/src/features/access/data/repositories/access_admin_repository.dart';
import 'package:gjamobile/src/features/access/data/repositories/access_repository.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/features_controller.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/groups_controller.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/modules_controller.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/users_controller.dart';
import 'package:gjamobile/src/features/app_update/data/app_update_dio.dart';
import 'package:gjamobile/src/features/app_update/data/installed_app_reader.dart';
import 'package:gjamobile/src/features/app_update/data/platform/method_channel_app_update_platform.dart';
import 'package:gjamobile/src/features/app_update/data/repositories/app_update_repository.dart';
import 'package:gjamobile/src/features/app_update/domain/services/app_update_platform.dart';
import 'package:gjamobile/src/features/app_update/presentation/controllers/app_update_controller.dart';
import 'package:gjamobile/src/features/auth/data/repositories/backend_user_repository.dart';
import 'package:gjamobile/src/features/auth/data/repositories/microsoft_auth_repository.dart';
import 'package:gjamobile/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:gjamobile/src/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gjamobile/src/features/auth/presentation/controllers/session_controller.dart';
import 'package:gjamobile/src/features/bi/capacity/data/repositories/capacity_repository.dart';
import 'package:gjamobile/src/features/bi/capacity/presentation/controllers/capacity_controller.dart';
import 'package:gjamobile/src/features/bi/company/data/repositories/company_repository.dart';
import 'package:gjamobile/src/features/bi/company/presentation/controllers/company_controller.dart';
import 'package:gjamobile/src/features/bi/executive/data/repositories/executive_repository.dart';
import 'package:gjamobile/src/features/bi/executive/presentation/controllers/executive_controller.dart';
import 'package:gjamobile/src/features/bi/quality/data/repositories/quality_repository.dart';
import 'package:gjamobile/src/features/bi/quality/presentation/controllers/quality_controller.dart';
import 'package:gjamobile/src/features/bi/sap/data/repositories/sap_repository.dart';
import 'package:gjamobile/src/features/bi/sap/presentation/controllers/sap_controller.dart';
import 'package:gjamobile/src/features/bi/shared/controllers/bi_filter_controller.dart';
import 'package:gjamobile/src/features/bi/shared/controllers/filtros_reference_controller.dart';
import 'package:gjamobile/src/features/bi/shared/data/filtros_repository.dart';
import 'package:gjamobile/src/features/bi/sla_backlog/data/repositories/sla_backlog_repository.dart';
import 'package:gjamobile/src/features/bi/sla_backlog/presentation/controllers/sla_backlog_controller.dart';
import 'package:gjamobile/src/features/bi/team/data/repositories/team_repository.dart';
import 'package:gjamobile/src/features/bi/team/presentation/controllers/team_controller.dart';
import 'package:gjamobile/src/features/bi/tipo_chamado/data/repositories/tipo_chamado_repository.dart';
import 'package:gjamobile/src/features/bi/user/data/repositories/user_repository.dart';
import 'package:gjamobile/src/features/bi/user/presentation/controllers/colaboradores_controller.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/data/repositories/meus_chamados_repository.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/data/repositories/timesheet_repository.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/controllers/apontamento_controller.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/controllers/meus_chamados_controller.dart';
import 'package:gjamobile/src/features/helpdesk/timesheet/presentation/controllers/timesheet_controller.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/data/repositories/inbound_repository_impl.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/repositories/inbound_repository.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/presentation/controllers/checkin_checkout_veiculo_controller.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/repositories/contagem_cega_repository_impl.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/repositories/contagem_cega_ecc_repository.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/data/repositories/contagem_cega_repository_router.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/repositories/contagem_cega_repository.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/controllers/contagem_cega_controller.dart';
import 'package:gjamobile/src/features/inbound/shared/data/sap_odata_client.dart';
import 'package:gjamobile/src/features/inbound/shared/data/sap_session_repository.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/sap_backend_resolver.dart';
import 'package:gjamobile/src/features/integracoes/data/repositories/integracoes_repository.dart';
import 'package:gjamobile/src/features/integracoes/presentation/controllers/integracoes_controller.dart';
import 'package:gjamobile/src/features/kba/data/repositories/kba_repository.dart';
import 'package:gjamobile/src/features/kba/presentation/controllers/kba_controller.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/data/repositories/portaria_repository.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/presentation/controllers/entrada_saida_veiculo_controller.dart';
import 'package:gjamobile/src/features/profile/presentation/controllers/profile_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/data/repositories/cadastros_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/data/repositories/estrutura_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/data/repositories/volume_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/caracteristicas_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/estrutura_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/parametros_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/volume_controller.dart';
import 'package:gjamobile/src/features/teamsbot/atas/data/repositories/atas_repository.dart';
import 'package:gjamobile/src/features/teamsbot/atas/presentation/controllers/atas_list_controller.dart';
import 'package:gjamobile/src/features/teamsbot/consulta/data/repositories/consulta_repository.dart';
import 'package:gjamobile/src/features/teamsbot/consulta/presentation/controllers/consulta_controller.dart';
import 'package:gjamobile/src/features/teamsbot/consulta/presentation/controllers/consulta_historico_controller.dart';
import 'package:gjamobile/src/features/teamsbot/custos/data/repositories/custos_repository.dart';
import 'package:gjamobile/src/features/teamsbot/custos/presentation/controllers/custos_controller.dart';
import 'package:gjamobile/src/features/teamsbot/fila/data/repositories/fila_repository.dart';
import 'package:gjamobile/src/features/teamsbot/fila/presentation/controllers/fila_controller.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/data/repositories/reunioes_repository.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/presentation/controllers/reunioes_list_controller.dart';
import 'package:gjamobile/src/services/backend_dio.dart';
import 'package:gjamobile/src/services/graph_service.dart';
import 'package:gjamobile/src/services/microsoft_auth_service.dart';
import 'package:gjamobile/src/services/token_storage.dart';

/// Global dependency injector. Call [AppInjector.setup] once during app
/// bootstrap (in `main`) before building the widget tree.
class AppInjector {
  AppInjector._();

  static final AutoInjector _instance = AutoInjector(
    tag: 'app',
    on: (i) {
      // Services
      i.addInstance<MicrosoftAuthService>(MicrosoftAuthService.instance);
      i.addInstance<TokenStorage>(TokenStorage.instance);
      i.addLazySingleton<GraphService>(() => GraphService());

      // Per-backend Dios, marker-typed so auto_injector can tell them apart.
      // Resolved here after AppConfig.init() (called earlier in main).
      i.addInstance<CoreDio>(CoreDio(AppConfig.dioFor(BackendService.core)));

      i.addInstance<TeamsbotDio>(
        TeamsbotDio(AppConfig.dioFor(BackendService.teamsbot)),
      );
      i.addInstance<PortariaDio>(
        PortariaDio(AppConfig.dioFor(BackendService.portaria)),
      );
      i.addInstance<RhprocessoDio>(
        RhprocessoDio(AppConfig.dioFor(BackendService.rhprocesso)),
      );
      // SAP Gateways: sem interceptor de auth Microsoft (ver AppConfig) — a
      // autenticação vai por request, com a sessão emitida pelo backend core.
      i.addInstance<SapBandeirantesDio>(
        SapBandeirantesDio(AppConfig.dioFor(BackendService.sapBandeirantes)),
      );
      i.addInstance<SapNelDio>(
        SapNelDio(AppConfig.dioFor(BackendService.sapNel)),
      );
      i.addInstance<SapVitamedicDio>(
        SapVitamedicDio(AppConfig.dioFor(BackendService.sapVitamedic)),
      );

      // Atualização do app (só age no Android). O canal é conteúdo estático do
      // site de produção, não um backend: Dio próprio, sem o interceptor de
      // auth. Fábricas explícitas porque os construtores têm parâmetros
      // opcionais (relógio, intervalo, raiz do cache) que só os testes passam.
      i.addInstance<AppUpdateDio>(AppUpdateDio.create());
      i.addLazySingleton<AppUpdatePlatform>(
        () => const MethodChannelAppUpdatePlatform(),
      );
      i.addLazySingleton<AppUpdateRepository>(
        () => AppUpdateRepository(dio: i.get<AppUpdateDio>()),
      );
      // App-scoped: o estado da atualização (oferta, download, arquivo pronto)
      // atravessa as telas e é lido pela Home e pelo diálogo.
      i.addLazySingleton<AppUpdateController>(
        () => AppUpdateController(
          repository: i.get<AppUpdateRepository>(),
          platform: i.get<AppUpdatePlatform>(),
          installedApp: readInstalledApp,
        ),
      );

      // Repositories
      i.addLazySingleton<BackendUserRepository>(BackendUserRepository.new);
      i.addLazySingleton<AuthRepository>(MicrosoftAuthRepository.new);
      i.addLazySingleton<AccessRepository>(AccessRepository.new);
      i.addLazySingleton<AccessAdminRepository>(AccessAdminRepository.new);
      i.addLazySingleton<KbaRepository>(KbaRepository.new);
      i.addLazySingleton<TimesheetRepository>(TimesheetRepository.new);
      i.addLazySingleton<MeusChamadosRepository>(MeusChamadosRepository.new);
      // Gerenciamento de Deltas (admin) — lê o backend `core`.
      i.addLazySingleton<IntegracoesRepository>(IntegracoesRepository.new);

      // TeamsBot repositories (todos falam com o backend `teamsbot`).
      i.addLazySingleton<AtasRepository>(AtasRepository.new);
      i.addLazySingleton<ConsultaRepository>(ConsultaRepository.new);
      i.addLazySingleton<CustosRepository>(CustosRepository.new);
      i.addLazySingleton<ReunioesRepository>(ReunioesRepository.new);
      i.addLazySingleton<FilaRepository>(FilaRepository.new);

      // Controllers (session + access + admin lists are app-scoped; auth and
      // group-edit controllers are screen-scoped — built by their screens)
      i.addLazySingleton<AccessController>(AccessController.new);
      i.addLazySingleton<SessionController>(SessionController.new);
      i.addLazySingleton<GroupsController>(GroupsController.new);
      i.addLazySingleton<FeaturesController>(FeaturesController.new);
      i.addLazySingleton<ModulesController>(ModulesController.new);
      i.addLazySingleton<UsersController>(UsersController.new);
      i.addLazySingleton<ProfileController>(ProfileController.new);
      // App-scoped: a tela usa AppInjector.get e não dá dispose; manter o
      // estado evita recarregar a lista a cada volta para a tela.
      i.addLazySingleton<IntegracoesController>(IntegracoesController.new);
      i.addLazySingleton<TimesheetController>(TimesheetController.new);
      // App-scoped como o TimesheetController: a tela usa BaseState, que
      // resolve pelo injector e nunca chama dispose.
      i.addLazySingleton<MeusChamadosController>(MeusChamadosController.new);

      // TeamsBot controllers app-scoped (as abas do shell). Os controllers de
      // detalhe (ATA/reunião) são screen-scoped, criados pelas próprias telas.
      i.addLazySingleton<AtasListController>(AtasListController.new);
      i.addLazySingleton<ConsultaController>(ConsultaController.new);
      i.addLazySingleton<ConsultaHistoricoController>(
          ConsultaHistoricoController.new);
      i.addLazySingleton<CustosController>(CustosController.new);
      i.addLazySingleton<ReunioesListController>(ReunioesListController.new);
      i.addLazySingleton<FilaController>(FilaController.new);

      // BI (Business Intelligence) — leem o backend `core` (CoreDio). O filtro é
      // global (compartilhado entre os dashboards).
      i.addLazySingleton<BiFilterController>(BiFilterController.new);
      i.addLazySingleton<FiltrosRepository>(FiltrosRepository.new);
      i.addLazySingleton<FiltrosReferenceController>(
          FiltrosReferenceController.new);
      i.addLazySingleton<ExecutiveRepository>(ExecutiveRepository.new);
      i.addLazySingleton<ExecutiveController>(ExecutiveController.new);
      i.addLazySingleton<CompanyRepository>(CompanyRepository.new);
      i.addLazySingleton<CompanyController>(CompanyController.new);
      i.addLazySingleton<SlaBacklogRepository>(SlaBacklogRepository.new);
      i.addLazySingleton<SlaBacklogController>(SlaBacklogController.new);
      i.addLazySingleton<SapRepository>(SapRepository.new);
      i.addLazySingleton<SapController>(SapController.new);
      i.addLazySingleton<TeamRepository>(TeamRepository.new);
      i.addLazySingleton<TeamController>(TeamController.new);
      i.addLazySingleton<CapacityRepository>(CapacityRepository.new);
      i.addLazySingleton<CapacityController>(CapacityController.new);
      i.addLazySingleton<QualityRepository>(QualityRepository.new);
      i.addLazySingleton<QualityController>(QualityController.new);
      // Repos com controller screen-scoped (criado pela tela): tipo de chamado
      // (Incidentes/Requisições/Mudanças, com path por tela) e Performance
      // Individual (com userId da rota).
      i.addLazySingleton<TipoChamadoRepository>(TipoChamadoRepository.new);
      i.addLazySingleton<UserRepository>(UserRepository.new);
      i.addLazySingleton<ColaboradoresController>(ColaboradoresController.new);

      i.add<AuthController>(AuthController.new);
      i.add<KbaController>(KbaController.new);
      // Screen-scoped: criado pelo sheet de novo apontamento, que dá dispose().
      i.add<ApontamentoController>(ApontamentoController.new);

      // RH Processo — lê a rhprocesso-api (RhprocessoDio). Fábricas explícitas:
      // os repositórios têm o parâmetro opcional `exigeRede`, que só os testes
      // passam. Controllers app-scoped: a última consulta continua na tela ao
      // voltar para ela.
      i.addLazySingleton<VolumeRepository>(
        () => VolumeRepository(i.get<RhprocessoDio>()),
      );
      i.addLazySingleton<EstruturaRepository>(
        () => EstruturaRepository(i.get<RhprocessoDio>()),
      );
      i.addLazySingleton<CadastrosRepository>(
        () => CadastrosRepository(i.get<RhprocessoDio>()),
      );
      i.addLazySingleton<VolumeController>(
        () => VolumeController(repository: i.get<VolumeRepository>()),
      );
      i.addLazySingleton<EstruturaController>(EstruturaController.new);
      i.addLazySingleton<CaracteristicasController>(
          CaracteristicasController.new);
      i.addLazySingleton<ParametrosController>(ParametrosController.new);

      // Portaria (entrada/saída de veículos) — lê o backend `portaria` (PortariaDio).
      i.addLazySingleton<PortariaRepository>(PortariaRepository.new);
      // Screen-scoped: criado pela tela de entrada/saída de veículos, que dá
      // dispose().
      i.add<EntradaSaidaVeiculoController>(EntradaSaidaVeiculoController.new);

      // Inbound: a sessão SAP vem do backend `core` e as chamadas de negócio vão
      // DIRETO no SAP da empresa do usuário. Ambos singletons — o
      // SapSessionRepository guarda o cache de sessões por (host, serviço), e o
      // cliente é compartilhado pelos submódulos (veículos e contagem cega
      // consomem serviços OData diferentes do mesmo sistema).
      i.addLazySingleton<SapSessionRepository>(SapSessionRepository.new);
      i.addLazySingleton<SapODataClient>(SapODataClient.new);
      i.addLazySingleton<InboundRepository>(InboundRepositoryImpl.new);
      i.addLazySingleton<SapBackendResolver>(AccessSapBackendResolver.new);
      // Screen-scoped: criado pela tela de check-in/out, que dá dispose().
      i.add<CheckinCheckoutVeiculoController>(
          () => CheckinCheckoutVeiculoController(
                repository: i.get<InboundRepository>(),
                backends: i.get<SapBackendResolver>(),
                access: i.get<AccessController>(),
              ));

      // Contagem cega: outro serviço OData no mesmo sistema SAP, então reusa os
      // Dios e o SapODataClient acima. O contrato muda com a PLATAFORMA —
      // S/4HANA (NEL, Vitamedic) consome o ZGJAAUTO_SB_GENERIC gerado por CDS;
      // ECC (Bandeirantes) não tem CDS e é atendido pelo ZGJAAUTO_GENERIC_SRV
      // construído com SEGW. O router escolhe pelo backend de cada chamada,
      // que o perfil funcional pode trocar com a tela aberta.
      //
      // As duas implementações são singletons próprios: cada uma tem a sua
      // ContagemSequencia, e a marca d'água de um sistema não pode vazar para
      // o outro.
      i.addLazySingleton<ContagemCegaRepositoryImpl>(
          ContagemCegaRepositoryImpl.new);
      i.addLazySingleton<ContagemCegaEccRepository>(
          ContagemCegaEccRepository.new);
      // Lambda e não `.new`: as duas dependências têm o mesmo tipo declarado
      // (a interface), e o auto_injector resolve por tipo.
      i.addLazySingleton<ContagemCegaRepository>(
        () => ContagemCegaRepositoryRouter(
          s4hana: i.get<ContagemCegaRepositoryImpl>(),
          ecc: i.get<ContagemCegaEccRepository>(),
        ),
      );
      // App-scoped porque a sessão de conferência atravessa as cinco rotas do
      // fluxo — um controller por tela perderia a contagem a cada navegação.
      // Quem zera é `reiniciar()`, não o dispose de uma tela.
      i.addLazySingleton<ContagemCegaController>(() => ContagemCegaController(
            repository: i.get<ContagemCegaRepository>(),
            backends: i.get<SapBackendResolver>(),
            access: i.get<AccessController>(),
          ));
    },
  );

  static bool _committed = false;

  static void setup() {
    if (_committed) return;
    _instance.commit();
    _committed = true;
  }

  static T get<T extends Object>() => _instance.get<T>();
}
