import 'package:flutter/widgets.dart';
import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/domain/enums/checkin_checkout_veiculo_mode.dart';
import 'package:gjamobile/src/features/inbound/checkin_checkout_veiculo/presentation/screens/checkin_checkout_veiculo_screen.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/contagem_item/presentation/screens/contagem_item_screen.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/itens_nota/presentation/screens/itens_nota_screen.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/notas_fiscais/presentation/screens/notas_fiscais_screen.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/presentation/controllers/contagem_cega_controller.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/resumo_checkin/presentation/screens/resumo_checkin_screen.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/scan_checkin/presentation/screens/scan_checkin_screen.dart';
import 'package:gjamobile/src/routing/app_routes.dart';
import 'package:gjamobile/src/routing/home_child_path.dart';
import 'package:go_router/go_router.dart';

/// As telas internas da contagem cega só fazem sentido dentro de uma sessão de
/// conferência. Entrar por link direto (ou recarregar a aba depois de a sessão
/// ter sido reiniciada) volta para a leitura do check-in em vez de mostrar uma
/// tela vazia.
String? _contagemCegaGuard(BuildContext context, GoRouterState state) {
  final controller = AppInjector.get<ContagemCegaController>();
  if (controller.checkinSignal.value == null) {
    return AppRoutes.gjaautoInboundContagemCega;
  }
  return null;
}

/// Índice de path que não veio ou veio inválido cai em 0 — a tela ainda mostra
/// o estado vazio se o índice não existir na sessão.
int _indice(GoRouterState state, String chave) =>
    int.tryParse(state.pathParameters[chave] ?? '') ?? 0;

/// Inbound (check-in/out de veículos e contagem cega de recebimento).
///
/// Todas as rotas são **filhas da Home** (ver `app_router.dart`), por isso os
/// paths são relativos via [homeChild]/[subRota]. É o que faz o Navigator
/// empilhar Home → feature e o voltar do Android desempilhar em vez de fechar
/// o app.
final List<RouteBase> inboundRoutes = <RouteBase>[
  GoRoute(
    path: homeChild(AppRoutes.gjaautoInboundCheckInVeiculo),
    name: 'gjaauto-in-entrada-veiculo',
    builder: (context, state) => const CheckinCheckoutVeiculoScreen(
        mode: CheckinCheckoutVeiculoMode.checkIn),
  ),
  GoRoute(
    path: homeChild(AppRoutes.gjaautoInboundCheckOutVeiculo),
    name: 'gjaauto-in-saida-veiculo',
    builder: (context, state) => const CheckinCheckoutVeiculoScreen(
        mode: CheckinCheckoutVeiculoMode.checkOut),
  ),
  GoRoute(
    path: homeChild(AppRoutes.gjaautoInboundConsultaCheckin),
    name: 'gjaauto-in-consulta-checkin',
    // Mesma tela das outras duas: a consulta é a busca sem a liberação.
    builder: (context, state) => const CheckinCheckoutVeiculoScreen(
        mode: CheckinCheckoutVeiculoMode.consulta),
  ),

  // ── Contagem cega ─────────────────────────────────────────────────────────
  // As cinco telas são um fluxo, e agora também são uma **hierarquia**: cada
  // uma é filha da anterior. Isso é o que reconstrói a pilha inteira num
  // deep-link (ou num refresh na web) — sem o aninhamento o voltar pularia da
  // contagem de um item direto para a Home, em vez de recuar uma tela por vez.
  GoRoute(
    path: homeChild(AppRoutes.gjaautoInboundContagemCega),
    name: 'gjaauto-in-contagem-cega',
    builder: (context, state) => const ScanCheckinScreen(),
    routes: <RouteBase>[
      // Rotas estáticas antes das dinâmicas: `resumo` não pode ser capturado
      // como `:nota`.
      GoRoute(
        path: subRota(
          AppRoutes.gjaautoInboundContagemCegaResumo,
          AppRoutes.gjaautoInboundContagemCega,
        ),
        name: 'gjaauto-in-contagem-cega-resumo',
        redirect: _contagemCegaGuard,
        builder: (context, state) => const ResumoCheckinScreen(),
      ),
      GoRoute(
        path: subRota(
          AppRoutes.gjaautoInboundContagemCegaNotas,
          AppRoutes.gjaautoInboundContagemCega,
        ),
        name: 'gjaauto-in-contagem-cega-notas',
        redirect: _contagemCegaGuard,
        builder: (context, state) => const NotasFiscaisScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: subRota(
              AppRoutes.gjaautoInboundContagemCegaItens,
              AppRoutes.gjaautoInboundContagemCegaNotas,
            ),
            name: 'gjaauto-in-contagem-cega-itens',
            redirect: _contagemCegaGuard,
            builder: (context, state) => ItensNotaScreen(
              notaIndex: _indice(state, 'nota'),
            ),
            routes: <RouteBase>[
              GoRoute(
                path: subRota(
                  AppRoutes.gjaautoInboundContagemCegaContagem,
                  AppRoutes.gjaautoInboundContagemCegaItens,
                ),
                name: 'gjaauto-in-contagem-cega-contagem',
                redirect: _contagemCegaGuard,
                builder: (context, state) => ContagemItemScreen(
                  notaIndex: _indice(state, 'nota'),
                  itemIndex: _indice(state, 'item'),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
