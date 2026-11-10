import 'package:flutter/widgets.dart' show IconData;

import 'primitives/icon_primitives.dart';

/// Catálogo de ícones do GJA, com os nomes do IconPool do SAPUI5.
///
/// Nível: semântico.
///
/// Cada ícone aponta para a fonte Lucide empacotada; o nome de origem está no
/// dartdoc e o código é conferido por teste contra
/// `fonts/lucide/codepoints.json`. Ícones direcionais são espelhados quando
/// o texto é da direita para a esquerda. Use [all] só onde for preciso
/// listar o catálogo (galeria, testes): ele mantém todos os glifos no build.
abstract final class GjaIcons {
  /// Adicionar um item. Lucide: `plus`; IconPool: `sap-icon://add`.
  static const add = IconData(
    0xe13d,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Fechar ou descartar. Lucide: `x`; IconPool: `sap-icon://decline`.
  static const decline = IconData(
    0xe1b2,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Buscar. Lucide: `search`; IconPool: `sap-icon://search`.
  static const search = IconData(
    0xe151,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Confirmar ou marcar como feito. Lucide: `check`; IconPool: `sap-icon://accept`.
  static const accept = IconData(
    0xe06c,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Recolher ou mover para cima. Lucide: `chevron-up`; IconPool: `sap-icon://slim-arrow-up`.
  static const slimArrowUp = IconData(
    0xe070,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Expandir ou abrir uma lista. Lucide: `chevron-down`; IconPool: `sap-icon://slim-arrow-down`.
  static const slimArrowDown = IconData(
    0xe06d,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Anterior (espelhado em RTL). Lucide: `chevron-left`; IconPool: `sap-icon://slim-arrow-left`.
  static const slimArrowLeft = IconData(
    0xe06e,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
    matchTextDirection: true,
  );

  /// Próximo ou avançar (espelhado em RTL). Lucide: `chevron-right`; IconPool: `sap-icon://slim-arrow-right`.
  static const slimArrowRight = IconData(
    0xe06f,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
    matchTextDirection: true,
  );

  /// Voltar (espelhado em RTL). Lucide: `arrow-left`; IconPool: `sap-icon://nav-back`.
  static const navBack = IconData(
    0xe048,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
    matchTextDirection: true,
  );

  /// Seguir (espelhado em RTL). Lucide: `arrow-right`; IconPool: `sap-icon://navigation-right-arrow`.
  static const navigationRightArrow = IconData(
    0xe049,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
    matchTextDirection: true,
  );

  /// Abrir o menu de navegação. Lucide: `menu`; IconPool: `sap-icon://menu2`.
  static const menu2 = IconData(
    0xe115,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Mais ações, em barra horizontal. Lucide: `ellipsis`; IconPool: `sap-icon://overflow`.
  static const overflow = IconData(
    0xe0b6,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Editar. Lucide: `pencil`; IconPool: `sap-icon://edit`.
  static const edit = IconData(
    0xe1f9,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Excluir. Lucide: `trash-2`; IconPool: `sap-icon://delete`.
  static const delete = IconData(
    0xe18e,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Informação. Lucide: `info`; IconPool: `sap-icon://information`.
  static const information = IconData(
    0xe0f9,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Alerta. Lucide: `triangle-alert`; IconPool: `sap-icon://warning`.
  static const warning = IconData(
    0xe193,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Erro. Lucide: `circle-x`; IconPool: `sap-icon://error`.
  static const error = IconData(
    0xe084,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Sucesso. Lucide: `circle-check`; IconPool: `sap-icon://sys-enter-2`.
  static const sysEnter2 = IconData(
    0xe226,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Ajuda. Lucide: `circle-question-mark`; IconPool: `sap-icon://sys-help`.
  static const sysHelp = IconData(
    0xe082,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Data. Lucide: `calendar`; IconPool: `sap-icon://calendar`.
  static const calendar = IconData(
    0xe063,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Hora. Lucide: `clock`; IconPool: `sap-icon://pending`.
  static const pending = IconData(
    0xe087,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Usuário ou perfil. Lucide: `user`; IconPool: `sap-icon://person-placeholder`.
  static const personPlaceholder = IconData(
    0xe19f,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Filtrar. Lucide: `funnel`; IconPool: `sap-icon://filter`.
  static const filter = IconData(
    0xe0dc,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Ordenar. Lucide: `arrow-up-down`; IconPool: `sap-icon://sort`.
  static const sort = IconData(
    0xe37d,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Enviar arquivo. Lucide: `upload`; IconPool: `sap-icon://upload`.
  static const upload = IconData(
    0xe19e,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Baixar arquivo. Lucide: `download`; IconPool: `sap-icon://download`.
  static const download = IconData(
    0xe0b2,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Atualizar. Lucide: `refresh-cw`; IconPool: `sap-icon://refresh`.
  static const refresh = IconData(
    0xe145,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Configurações. Lucide: `settings`; IconPool: `sap-icon://action-settings`.
  static const actionSettings = IconData(
    0xe154,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Página inicial. Lucide: `house`; IconPool: `sap-icon://home`.
  static const home = IconData(
    0xe0f5,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Abrir fora da aplicação (espelhado em RTL). Lucide: `external-link`; IconPool: `sap-icon://popup-window`.
  static const popupWindow = IconData(
    0xe0b9,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
    matchTextDirection: true,
  );

  /// Mostrar conteúdo oculto. Lucide: `eye`; IconPool: `sap-icon://show`.
  static const show = IconData(
    0xe0ba,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Ocultar conteúdo. Lucide: `eye-off`; IconPool: `sap-icon://hide`.
  static const hide = IconData(
    0xe0bb,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Copiar. Lucide: `copy`; IconPool: `sap-icon://copy`.
  static const copy = IconData(
    0xe09e,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Sair da aplicação (espelhado em RTL). Lucide: `log-out`; IconPool: `sap-icon://log`.
  static const log = IconData(
    0xe10e,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
    matchTextDirection: true,
  );

  /// Notificações. Lucide: `bell`; IconPool: `sap-icon://bell`.
  static const bell = IconData(
    0xe059,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Arquivo. Lucide: `file`; IconPool: `sap-icon://document`.
  static const document = IconData(
    0xe0c0,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Pasta. Lucide: `folder`; IconPool: `sap-icon://folder-blank`.
  static const folderBlank = IconData(
    0xe0d7,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Seletor de produtos. Lucide: `grip`; IconPool: `sap-icon://grid`.
  static const grid = IconData(
    0xe3b1,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Sincronizar dados. Lucide: `refresh-ccw`; IconPool: `sap-icon://synchronize`.
  static const synchronize = IconData(
    0xe144,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Falha ou ausência de sincronização. Lucide: `refresh-cw-off`; IconPool: `sap-icon://unsynchronize`.
  static const unsynchronize = IconData(
    0xe498,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Busca sem resultado. Lucide: `search-x`; IconPool: `sap-icon://sys-find`.
  static const sysFind = IconData(
    0xe4ad,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Grupo de pessoas. Lucide: `users`; IconPool: `sap-icon://group`.
  static const group = IconData(
    0xe1a4,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Procurar pessoa. Lucide: `user-search`; IconPool: `sap-icon://employee-lookup`.
  static const employeeLookup = IconData(
    0xe579,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Adicionar pessoa. Lucide: `user-plus`; IconPool: `sap-icon://add-employee`.
  static const addEmployee = IconData(
    0xe1a2,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Pessoa indisponível ou removida. Lucide: `user-x`; IconPool: `sap-icon://employee-rejections`.
  static const employeeRejections = IconData(
    0xe1a3,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Administração de usuários. Lucide: `user-cog`; IconPool: `sap-icon://user-settings`.
  static const userSettings = IconData(
    0xe342,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Crachá ou matrícula. Lucide: `id-card`; IconPool: `sap-icon://badge`.
  static const badge = IconData(
    0xe617,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Evento ou compromisso. Lucide: `calendar-days`; IconPool: `sap-icon://appointment`.
  static const appointment = IconData(
    0xe2b9,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Visão de um dia. Lucide: `calendar-1`; IconPool: `sap-icon://appointment-2`.
  static const appointment2 = IconData(
    0xe630,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Visão de uma semana ou período. Lucide: `calendar-range`; IconPool: `sap-icon://timesheet`.
  static const timesheet = IconData(
    0xe2bd,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Dia sem registros. Lucide: `calendar-x`; IconPool: `sap-icon://time-off`.
  static const timeOff = IconData(
    0xe2be,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Notas ou ata. Lucide: `notebook-pen`; IconPool: `sap-icon://notes`.
  static const notes = IconData(
    0xe596,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Duração ou cronômetro. Lucide: `timer`; IconPool: `sap-icon://fob-watch`.
  static const fobWatch = IconData(
    0xe1e0,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Aguardando. Lucide: `hourglass`; IconPool: `sap-icon://busy`.
  static const busy = IconData(
    0xe296,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Histórico. Lucide: `history`; IconPool: `sap-icon://history`.
  static const history = IconData(
    0xe1f5,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Bloqueado ou protegido por senha. Lucide: `lock`; IconPool: `sap-icon://locked`.
  static const locked = IconData(
    0xe10b,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Desbloqueado. Lucide: `lock-open`; IconPool: `sap-icon://unlocked`.
  static const unlocked = IconData(
    0xe10c,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Segurança ou privacidade. Lucide: `shield`; IconPool: `sap-icon://shield`.
  static const shield = IconData(
    0xe158,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Verificado ou dentro do acordo de nível de serviço. Lucide: `badge-check`; IconPool: `sap-icon://verified`.
  static const verified = IconData(
    0xe241,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Caixa de entrada vazia. Lucide: `inbox`; IconPool: `sap-icon://inbox`.
  static const inbox = IconData(
    0xe0f7,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Limpar filtros. Lucide: `funnel-x`; IconPool: `sap-icon://clear-filter`.
  static const clearFilter = IconData(
    0xe3b5,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Ajustes e personalização. Lucide: `sliders-horizontal`; IconPool: `sap-icon://customize`.
  static const customize = IconData(
    0xe29a,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Documento de texto. Lucide: `file-text`; IconPool: `sap-icon://document-text`.
  static const documentText = IconData(
    0xe0cc,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Arquivo PDF. Lucide: `file-type`; IconPool: `sap-icon://pdf-attachment`.
  static const pdfAttachment = IconData(
    0xe329,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Chamado. Lucide: `ticket`; IconPool: `sap-icon://incident`.
  static const incident = IconData(
    0xe20f,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Código ou número. Lucide: `hash`; IconPool: `sap-icon://number-sign`.
  static const numberSign = IconData(
    0xe0ef,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Entrada ou acesso (espelhado em RTL). Lucide: `log-in`; IconPool: `sap-icon://journey-arrive`.
  static const journeyArrive = IconData(
    0xe10d,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
    matchTextDirection: true,
  );

  /// Indicadores e tendências. Lucide: `trending-up`; IconPool: `sap-icon://trend-up`.
  static const trendUp = IconData(
    0xe191,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Veículo. Lucide: `car`; IconPool: `sap-icon://car-rental`.
  static const carRental = IconData(
    0xe1d5,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Transporte de carga. Lucide: `truck`; IconPool: `sap-icon://shipping-status`.
  static const shippingStatus = IconData(
    0xe194,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Tarefa ou atribuição. Lucide: `clipboard-list`; IconPool: `sap-icon://task`.
  static const task = IconData(
    0xe086,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Lista de verificação ou qualidade. Lucide: `list-checks`; IconPool: `sap-icon://checklist`.
  static const checklist = IconData(
    0xe1d0,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Fila de trabalho. Lucide: `layers`; IconPool: `sap-icon://workflow-tasks`.
  static const workflowTasks = IconData(
    0xe529,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Para cima ou ordem crescente. Lucide: `arrow-up`; IconPool: `sap-icon://arrow-top`.
  static const arrowTop = IconData(
    0xe04a,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Para baixo ou ordem decrescente. Lucide: `arrow-down`; IconPool: `sap-icon://arrow-bottom`.
  static const arrowBottom = IconData(
    0xe042,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Primeira página (espelhado em RTL). Lucide: `chevrons-left`; IconPool: `sap-icon://sys-first-page`.
  static const sysFirstPage = IconData(
    0xe072,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
    matchTextDirection: true,
  );

  /// Última página (espelhado em RTL). Lucide: `chevrons-right`; IconPool: `sap-icon://sys-last-page`.
  static const sysLastPage = IconData(
    0xe073,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
    matchTextDirection: true,
  );

  /// Recomeçar. Lucide: `rotate-ccw`; IconPool: `sap-icon://reset`.
  static const reset = IconData(
    0xe148,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Opção não selecionada. Lucide: `circle`; IconPool: `sap-icon://circle-task`.
  static const circleTask = IconData(
    0xe076,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Opção selecionada. Lucide: `circle-dot`; IconPool: `sap-icon://circle-task-2`.
  static const circleTask2 = IconData(
    0xe345,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Remover item de uma lista. Lucide: `circle-minus`; IconPool: `sap-icon://sys-minus`.
  static const sysMinus = IconData(
    0xe07e,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Diminuir. Lucide: `minus`; IconPool: `sap-icon://less`.
  static const less = IconData(
    0xe11c,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Bloqueado ou não permitido. Lucide: `ban`; IconPool: `sap-icon://cancel`.
  static const cancel = IconData(
    0xe051,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Conversa. Lucide: `messages-square`; IconPool: `sap-icon://discussion`.
  static const discussion = IconData(
    0xe40d,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Comentário ou mensagem. Lucide: `message-square`; IconPool: `sap-icon://comment`.
  static const comment = IconData(
    0xe117,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Inteligência artificial. Lucide: `sparkles`; IconPool: `sap-icon://ai`.
  static const ai = IconData(
    0xe412,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Valor em dinheiro. Lucide: `dollar-sign`; IconPool: `sap-icon://currency`.
  static const currency = IconData(
    0xe0b1,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Pagamentos e custos. Lucide: `banknote`; IconPool: `sap-icon://money-bills`.
  static const moneyBills = IconData(
    0xe052,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Reunião online. Lucide: `video`; IconPool: `sap-icon://video`.
  static const video = IconData(
    0xe1a5,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Reunião sem vídeo (presencial). Lucide: `video-off`; IconPool: `sap-icon://unwired`.
  static const unwired = IconData(
    0xe1a6,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Transcrição ou legenda. Lucide: `captions`; IconPool: `sap-icon://text`.
  static const text = IconData(
    0xe3a4,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Sem transcrição. Lucide: `captions-off`; IconPool: `sap-icon://strikethrough`.
  static const strikethrough = IconData(
    0xe5c1,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Capacidade ou desempenho. Lucide: `gauge`; IconPool: `sap-icon://performance`.
  static const performance = IconData(
    0xe1bf,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Salvar. Lucide: `save`; IconPool: `sap-icon://save`.
  static const save = IconData(
    0xe14d,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Refeição ou intervalo. Lucide: `utensils`; IconPool: `sap-icon://meal`.
  static const meal = IconData(
    0xe2f6,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Recibo ou comprovante. Lucide: `receipt`; IconPool: `sap-icon://receipt`.
  static const receipt = IconData(
    0xe3d3,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Código QR. Lucide: `qr-code`; IconPool: `sap-icon://qr-code`.
  static const qrCode = IconData(
    0xe1df,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Leitura de código de barras. Lucide: `scan-barcode`; IconPool: `sap-icon://bar-code`.
  static const barCode = IconData(
    0xe535,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Executar. Lucide: `play`; IconPool: `sap-icon://media-play`.
  static const mediaPlay = IconData(
    0xe13c,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Dica ou sugestão. Lucide: `lightbulb`; IconPool: `sap-icon://lightbulb`.
  static const lightbulb = IconData(
    0xe1c2,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Estoque ou volume. Lucide: `package`; IconPool: `sap-icon://inventory`.
  static const inventory = IconData(
    0xe129,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Conjunto de aplicações. Lucide: `layout-grid`; IconPool: `sap-icon://widgets`.
  static const widgets = IconData(
    0xe0ff,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Empresa ou unidade. Lucide: `building-2`; IconPool: `sap-icon://building`.
  static const building = IconData(
    0xe290,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Painel. Lucide: `layout-dashboard`; IconPool: `sap-icon://overview-chart`.
  static const overviewChart = IconData(
    0xe1c1,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Gráfico de barras. Lucide: `chart-column`; IconPool: `sap-icon://vertical-bar-chart`.
  static const verticalBarChart = IconData(
    0xe2a3,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Estrutura hierárquica. Lucide: `network`; IconPool: `sap-icon://org-chart`.
  static const orgChart = IconData(
    0xe125,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Pesquisa ampla ou internet. Lucide: `globe`; IconPool: `sap-icon://globe`.
  static const globe = IconData(
    0xe0e8,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Tabela. Lucide: `table`; IconPool: `sap-icon://table-view`.
  static const tableView = IconData(
    0xe17d,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Mudança ou troca. Lucide: `arrow-left-right`; IconPool: `sap-icon://journey-change`.
  static const journeyChange = IconData(
    0xe24a,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Telefone. Lucide: `phone`; IconPool: `sap-icon://phone`.
  static const phone = IconData(
    0xe133,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Localização. Lucide: `map-pin`; IconPool: `sap-icon://map`.
  static const map = IconData(
    0xe111,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Vincular. Lucide: `link`; IconPool: `sap-icon://chain-link`.
  static const chainLink = IconData(
    0xe102,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Desvincular. Lucide: `unlink`; IconPool: `sap-icon://broken-link`.
  static const brokenLink = IconData(
    0xe19c,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Tema claro. Lucide: `sun`; IconPool: `sap-icon://light-mode`.
  static const lightMode = IconData(
    0xe178,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Tema escuro. Lucide: `moon`; IconPool: `sap-icon://dark-mode`.
  static const darkMode = IconData(
    0xe11e,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Lanterna ou ação rápida. Lucide: `zap`; IconPool: `sap-icon://accelerated`.
  static const accelerated = IconData(
    0xe1b4,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Marcação. Lucide: `flag`; IconPool: `sap-icon://flag`.
  static const flag = IconData(
    0xe0d1,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Funcionalidade ou extensão. Lucide: `puzzle`; IconPool: `sap-icon://puzzle`.
  static const puzzle = IconData(
    0xe29c,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Desenvolvimento ou engenharia. Lucide: `hard-hat`; IconPool: `sap-icon://developer-settings`.
  static const developerSettings = IconData(
    0xe0ee,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Suporte. Lucide: `headset`; IconPool: `sap-icon://headset`.
  static const headset = IconData(
    0xe5bd,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Código-fonte. Lucide: `code`; IconPool: `sap-icon://source-code`.
  static const sourceCode = IconData(
    0xe093,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Enviar para a nuvem. Lucide: `cloud-upload`; IconPool: `sap-icon://upload-to-cloud`.
  static const uploadToCloud = IconData(
    0xe091,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Atualização disponível. Lucide: `cloud-download`; IconPool: `sap-icon://download-from-cloud`.
  static const downloadFromCloud = IconData(
    0xe089,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Sincronização com a nuvem. Lucide: `cloud-sync`; IconPool: `sap-icon://cloud`.
  static const cloud = IconData(
    0xe6e3,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Enviado para a nuvem. Lucide: `cloud-check`; IconPool: `sap-icon://cloud-check`.
  static const cloudCheck = IconData(
    0xe66e,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Sem conexão com a nuvem. Lucide: `cloud-off`; IconPool: `sap-icon://disconnected`.
  static const disconnected = IconData(
    0xe08d,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Categoria. Lucide: `shapes`; IconPool: `sap-icon://product`.
  static const product = IconData(
    0xe4b3,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Trocar de câmera. Lucide: `switch-camera`; IconPool: `sap-icon://camera`.
  static const camera = IconData(
    0xe17c,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Negócio ou cliente. Lucide: `briefcase`; IconPool: `sap-icon://suitcase`.
  static const suitcase = IconData(
    0xe062,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Manutenção ou ferramenta. Lucide: `wrench`; IconPool: `sap-icon://wrench`.
  static const wrench = IconData(
    0xe1b1,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Imagem indisponível. Lucide: `image-off`; IconPool: `sap-icon://picture`.
  static const picture = IconData(
    0xe1c0,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Rota alternativa ou desvio. Lucide: `split`; IconPool: `sap-icon://split`.
  static const split = IconData(
    0xe440,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Servidor ou ambiente. Lucide: `server`; IconPool: `sap-icon://it-host`.
  static const itHost = IconData(
    0xe153,
    fontFamily: GjaIconPrimitives.fontFamily,
    fontPackage: GjaIconPrimitives.fontPackage,
  );

  /// Nome de origem na Lucide de cada ícone do catálogo.
  static const lucideNames = <String, String>{
    'add': 'plus',
    'decline': 'x',
    'search': 'search',
    'accept': 'check',
    'slimArrowUp': 'chevron-up',
    'slimArrowDown': 'chevron-down',
    'slimArrowLeft': 'chevron-left',
    'slimArrowRight': 'chevron-right',
    'navBack': 'arrow-left',
    'navigationRightArrow': 'arrow-right',
    'menu2': 'menu',
    'overflow': 'ellipsis',
    'edit': 'pencil',
    'delete': 'trash-2',
    'information': 'info',
    'warning': 'triangle-alert',
    'error': 'circle-x',
    'sysEnter2': 'circle-check',
    'sysHelp': 'circle-question-mark',
    'calendar': 'calendar',
    'pending': 'clock',
    'personPlaceholder': 'user',
    'filter': 'funnel',
    'sort': 'arrow-up-down',
    'upload': 'upload',
    'download': 'download',
    'refresh': 'refresh-cw',
    'actionSettings': 'settings',
    'home': 'house',
    'popupWindow': 'external-link',
    'show': 'eye',
    'hide': 'eye-off',
    'copy': 'copy',
    'log': 'log-out',
    'bell': 'bell',
    'document': 'file',
    'folderBlank': 'folder',
    'grid': 'grip',
    'synchronize': 'refresh-ccw',
    'unsynchronize': 'refresh-cw-off',
    'sysFind': 'search-x',
    'group': 'users',
    'employeeLookup': 'user-search',
    'addEmployee': 'user-plus',
    'employeeRejections': 'user-x',
    'userSettings': 'user-cog',
    'badge': 'id-card',
    'appointment': 'calendar-days',
    'appointment2': 'calendar-1',
    'timesheet': 'calendar-range',
    'timeOff': 'calendar-x',
    'notes': 'notebook-pen',
    'fobWatch': 'timer',
    'busy': 'hourglass',
    'history': 'history',
    'locked': 'lock',
    'unlocked': 'lock-open',
    'shield': 'shield',
    'verified': 'badge-check',
    'inbox': 'inbox',
    'clearFilter': 'funnel-x',
    'customize': 'sliders-horizontal',
    'documentText': 'file-text',
    'pdfAttachment': 'file-type',
    'incident': 'ticket',
    'numberSign': 'hash',
    'journeyArrive': 'log-in',
    'trendUp': 'trending-up',
    'carRental': 'car',
    'shippingStatus': 'truck',
    'task': 'clipboard-list',
    'checklist': 'list-checks',
    'workflowTasks': 'layers',
    'arrowTop': 'arrow-up',
    'arrowBottom': 'arrow-down',
    'sysFirstPage': 'chevrons-left',
    'sysLastPage': 'chevrons-right',
    'reset': 'rotate-ccw',
    'circleTask': 'circle',
    'circleTask2': 'circle-dot',
    'sysMinus': 'circle-minus',
    'less': 'minus',
    'cancel': 'ban',
    'discussion': 'messages-square',
    'comment': 'message-square',
    'ai': 'sparkles',
    'currency': 'dollar-sign',
    'moneyBills': 'banknote',
    'video': 'video',
    'unwired': 'video-off',
    'text': 'captions',
    'strikethrough': 'captions-off',
    'performance': 'gauge',
    'save': 'save',
    'meal': 'utensils',
    'receipt': 'receipt',
    'qrCode': 'qr-code',
    'barCode': 'scan-barcode',
    'mediaPlay': 'play',
    'lightbulb': 'lightbulb',
    'inventory': 'package',
    'widgets': 'layout-grid',
    'building': 'building-2',
    'overviewChart': 'layout-dashboard',
    'verticalBarChart': 'chart-column',
    'orgChart': 'network',
    'globe': 'globe',
    'tableView': 'table',
    'journeyChange': 'arrow-left-right',
    'phone': 'phone',
    'map': 'map-pin',
    'chainLink': 'link',
    'brokenLink': 'unlink',
    'lightMode': 'sun',
    'darkMode': 'moon',
    'accelerated': 'zap',
    'flag': 'flag',
    'puzzle': 'puzzle',
    'developerSettings': 'hard-hat',
    'headset': 'headset',
    'sourceCode': 'code',
    'uploadToCloud': 'cloud-upload',
    'downloadFromCloud': 'cloud-download',
    'cloud': 'cloud-sync',
    'cloudCheck': 'cloud-check',
    'disconnected': 'cloud-off',
    'product': 'shapes',
    'camera': 'switch-camera',
    'suitcase': 'briefcase',
    'wrench': 'wrench',
    'picture': 'image-off',
    'split': 'split',
    'itHost': 'server',
  };

  /// Nome de cada ícone no IconPool do SAPUI5 (`sap-icon://<nome>`). O nome
  /// do catálogo é este nome em camelCase: sem hífens, com a letra seguinte
  /// maiúscula (`slim-arrow-down` → `slimArrowDown`, `menu2` → `menu2`).
  static const iconPoolNames = <String, String>{
    'add': 'add',
    'decline': 'decline',
    'search': 'search',
    'accept': 'accept',
    'slimArrowUp': 'slim-arrow-up',
    'slimArrowDown': 'slim-arrow-down',
    'slimArrowLeft': 'slim-arrow-left',
    'slimArrowRight': 'slim-arrow-right',
    'navBack': 'nav-back',
    'navigationRightArrow': 'navigation-right-arrow',
    'menu2': 'menu2',
    'overflow': 'overflow',
    'edit': 'edit',
    'delete': 'delete',
    'information': 'information',
    'warning': 'warning',
    'error': 'error',
    'sysEnter2': 'sys-enter-2',
    'sysHelp': 'sys-help',
    'calendar': 'calendar',
    'pending': 'pending',
    'personPlaceholder': 'person-placeholder',
    'filter': 'filter',
    'sort': 'sort',
    'upload': 'upload',
    'download': 'download',
    'refresh': 'refresh',
    'actionSettings': 'action-settings',
    'home': 'home',
    'popupWindow': 'popup-window',
    'show': 'show',
    'hide': 'hide',
    'copy': 'copy',
    'log': 'log',
    'bell': 'bell',
    'document': 'document',
    'folderBlank': 'folder-blank',
    'grid': 'grid',
    'synchronize': 'synchronize',
    'unsynchronize': 'unsynchronize',
    'sysFind': 'sys-find',
    'group': 'group',
    'employeeLookup': 'employee-lookup',
    'addEmployee': 'add-employee',
    'employeeRejections': 'employee-rejections',
    'userSettings': 'user-settings',
    'badge': 'badge',
    'appointment': 'appointment',
    'appointment2': 'appointment-2',
    'timesheet': 'timesheet',
    'timeOff': 'time-off',
    'notes': 'notes',
    'fobWatch': 'fob-watch',
    'busy': 'busy',
    'history': 'history',
    'locked': 'locked',
    'unlocked': 'unlocked',
    'shield': 'shield',
    'verified': 'verified',
    'inbox': 'inbox',
    'clearFilter': 'clear-filter',
    'customize': 'customize',
    'documentText': 'document-text',
    'pdfAttachment': 'pdf-attachment',
    'incident': 'incident',
    'numberSign': 'number-sign',
    'journeyArrive': 'journey-arrive',
    'trendUp': 'trend-up',
    'carRental': 'car-rental',
    'shippingStatus': 'shipping-status',
    'task': 'task',
    'checklist': 'checklist',
    'workflowTasks': 'workflow-tasks',
    'arrowTop': 'arrow-top',
    'arrowBottom': 'arrow-bottom',
    'sysFirstPage': 'sys-first-page',
    'sysLastPage': 'sys-last-page',
    'reset': 'reset',
    'circleTask': 'circle-task',
    'circleTask2': 'circle-task-2',
    'sysMinus': 'sys-minus',
    'less': 'less',
    'cancel': 'cancel',
    'discussion': 'discussion',
    'comment': 'comment',
    'ai': 'ai',
    'currency': 'currency',
    'moneyBills': 'money-bills',
    'video': 'video',
    'unwired': 'unwired',
    'text': 'text',
    'strikethrough': 'strikethrough',
    'performance': 'performance',
    'save': 'save',
    'meal': 'meal',
    'receipt': 'receipt',
    'qrCode': 'qr-code',
    'barCode': 'bar-code',
    'mediaPlay': 'media-play',
    'lightbulb': 'lightbulb',
    'inventory': 'inventory',
    'widgets': 'widgets',
    'building': 'building',
    'overviewChart': 'overview-chart',
    'verticalBarChart': 'vertical-bar-chart',
    'orgChart': 'org-chart',
    'globe': 'globe',
    'tableView': 'table-view',
    'journeyChange': 'journey-change',
    'phone': 'phone',
    'map': 'map',
    'chainLink': 'chain-link',
    'brokenLink': 'broken-link',
    'lightMode': 'light-mode',
    'darkMode': 'dark-mode',
    'accelerated': 'accelerated',
    'flag': 'flag',
    'puzzle': 'puzzle',
    'developerSettings': 'developer-settings',
    'headset': 'headset',
    'sourceCode': 'source-code',
    'uploadToCloud': 'upload-to-cloud',
    'downloadFromCloud': 'download-from-cloud',
    'cloud': 'cloud',
    'cloudCheck': 'cloud-check',
    'disconnected': 'disconnected',
    'product': 'product',
    'camera': 'camera',
    'suitcase': 'suitcase',
    'wrench': 'wrench',
    'picture': 'picture',
    'split': 'split',
    'itHost': 'it-host',
  };

  /// Todos os ícones do catálogo, pelo nome.
  static const all = <String, IconData>{
    'add': add,
    'decline': decline,
    'search': search,
    'accept': accept,
    'slimArrowUp': slimArrowUp,
    'slimArrowDown': slimArrowDown,
    'slimArrowLeft': slimArrowLeft,
    'slimArrowRight': slimArrowRight,
    'navBack': navBack,
    'navigationRightArrow': navigationRightArrow,
    'menu2': menu2,
    'overflow': overflow,
    'edit': edit,
    'delete': delete,
    'information': information,
    'warning': warning,
    'error': error,
    'sysEnter2': sysEnter2,
    'sysHelp': sysHelp,
    'calendar': calendar,
    'pending': pending,
    'personPlaceholder': personPlaceholder,
    'filter': filter,
    'sort': sort,
    'upload': upload,
    'download': download,
    'refresh': refresh,
    'actionSettings': actionSettings,
    'home': home,
    'popupWindow': popupWindow,
    'show': show,
    'hide': hide,
    'copy': copy,
    'log': log,
    'bell': bell,
    'document': document,
    'folderBlank': folderBlank,
    'grid': grid,
    'synchronize': synchronize,
    'unsynchronize': unsynchronize,
    'sysFind': sysFind,
    'group': group,
    'employeeLookup': employeeLookup,
    'addEmployee': addEmployee,
    'employeeRejections': employeeRejections,
    'userSettings': userSettings,
    'badge': badge,
    'appointment': appointment,
    'appointment2': appointment2,
    'timesheet': timesheet,
    'timeOff': timeOff,
    'notes': notes,
    'fobWatch': fobWatch,
    'busy': busy,
    'history': history,
    'locked': locked,
    'unlocked': unlocked,
    'shield': shield,
    'verified': verified,
    'inbox': inbox,
    'clearFilter': clearFilter,
    'customize': customize,
    'documentText': documentText,
    'pdfAttachment': pdfAttachment,
    'incident': incident,
    'numberSign': numberSign,
    'journeyArrive': journeyArrive,
    'trendUp': trendUp,
    'carRental': carRental,
    'shippingStatus': shippingStatus,
    'task': task,
    'checklist': checklist,
    'workflowTasks': workflowTasks,
    'arrowTop': arrowTop,
    'arrowBottom': arrowBottom,
    'sysFirstPage': sysFirstPage,
    'sysLastPage': sysLastPage,
    'reset': reset,
    'circleTask': circleTask,
    'circleTask2': circleTask2,
    'sysMinus': sysMinus,
    'less': less,
    'cancel': cancel,
    'discussion': discussion,
    'comment': comment,
    'ai': ai,
    'currency': currency,
    'moneyBills': moneyBills,
    'video': video,
    'unwired': unwired,
    'text': text,
    'strikethrough': strikethrough,
    'performance': performance,
    'save': save,
    'meal': meal,
    'receipt': receipt,
    'qrCode': qrCode,
    'barCode': barCode,
    'mediaPlay': mediaPlay,
    'lightbulb': lightbulb,
    'inventory': inventory,
    'widgets': widgets,
    'building': building,
    'overviewChart': overviewChart,
    'verticalBarChart': verticalBarChart,
    'orgChart': orgChart,
    'globe': globe,
    'tableView': tableView,
    'journeyChange': journeyChange,
    'phone': phone,
    'map': map,
    'chainLink': chainLink,
    'brokenLink': brokenLink,
    'lightMode': lightMode,
    'darkMode': darkMode,
    'accelerated': accelerated,
    'flag': flag,
    'puzzle': puzzle,
    'developerSettings': developerSettings,
    'headset': headset,
    'sourceCode': sourceCode,
    'uploadToCloud': uploadToCloud,
    'downloadFromCloud': downloadFromCloud,
    'cloud': cloud,
    'cloudCheck': cloudCheck,
    'disconnected': disconnected,
    'product': product,
    'camera': camera,
    'suitcase': suitcase,
    'wrench': wrench,
    'picture': picture,
    'split': split,
    'itHost': itHost,
  };
}
