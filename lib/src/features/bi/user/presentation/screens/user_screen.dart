import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/auth/presentation/controllers/session_controller.dart';
import 'package:gjamobile/src/imports/imports.dart';

import '../../../shared/controllers/bi_filter_controller.dart';
import '../../../shared/widgets/bi_filter_bar.dart';
import '../../../shared/widgets/bi_page_header.dart';
import '../../../shared/widgets/bi_panel.dart';
import '../../../shared/widgets/bi_profile_card.dart';
import '../../../shared/widgets/charts/bi_donut_chart.dart';
import '../../../shared/widgets/charts/bi_line_chart.dart';
import '../../../shared/widgets/insights_list.dart';
import '../../../shared/widgets/kpi_banner.dart';
import '../../data/models/user_dashboard.dart';
import '../../data/repositories/user_repository.dart';
import '../controllers/colaboradores_controller.dart';
import '../controllers/user_controller.dart';
import '../widgets/colaborador_picker.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Painel "Performance Individual" (`/bi/user`, Grafico6.png). Tem um seletor de
/// colaborador que **vem pré-selecionado com o colaborador que está acessando**:
/// match pelo e-mail do usuário logado na lista de colaboradores e, sem match,
/// resolução do id GLPI via `findByEmail` (mesmo caminho do timesheet). Sem
/// resolução — ou sem colaborador escolhido — o seletor fica em "Selecione um
/// funcional" e a tela fica zerada. A rota com `:id` (drill-down) pré-seleciona
/// aquele colaborador. A lista de colaboradores é best-effort: falha vira um
/// aviso com retry no lugar do seletor, sem bloquear o painel.
class UserScreen extends StatefulWidget {
  const UserScreen({super.key, this.userId});

  final int? userId;

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  late final ColaboradoresController _colabs;
  late final BiFilterController _filtro;

  int? _selectedId;
  UserController? _user;

  @override
  void initState() {
    super.initState();
    _colabs = AppInjector.get<ColaboradoresController>();
    _filtro = AppInjector.get<BiFilterController>();
    _init();
  }

  Future<void> _init() async {
    await _colabs.load();
    if (!mounted) return;
    // Prioridade: id da rota (drill-down) → colaborador do usuário logado
    // (match local pelo e-mail) → id GLPI via `findByEmail`, como no timesheet.
    final rotaId = (widget.userId ?? 0) > 0 ? widget.userId : null;
    final atual = rotaId ??
        _colabs.porEmail(_emailAtual())?.id ??
        await _usuarioIdPorEmail();
    if (!mounted) return;
    if (atual != null) {
      _selecionar(atual);
    } else {
      setState(() {});
    }
  }

  /// E-mail do usuário logado. Como no timesheet, prefere o e-mail do portal
  /// (`/users/me`, via [AccessController]) — é ele que existe no GLPI; o da
  /// sessão Microsoft é só fallback enquanto o access não carregou.
  String? _emailAtual() {
    final portal =
        AppInjector.get<AccessController>().accessSignal.value?.user.email;
    if (portal != null && portal.trim().isNotEmpty) return portal;
    return AppInjector.get<SessionController>().user?.email;
  }

  /// Resolve o id do usuário no GLPI a partir do e-mail (mesmo caminho do
  /// timesheet) quando a lista de colaboradores não tem match. Sem conta
  /// helpdesk (404) ou falha, resolve como nulo — a tela fica em
  /// "Selecione um funcional".
  Future<int?> _usuarioIdPorEmail() async {
    final email = _emailAtual();
    if (email == null || email.trim().isEmpty) return null;
    final result =
        await AppInjector.get<UserRepository>().fetchUsuarioId(email: email);
    return result.getOrNull();
  }

  void _selecionar(int id) {
    if (_selectedId == id && _user != null) return;
    _user?.dispose();
    _user = UserController(
      repository: AppInjector.get<UserRepository>(),
      filtro: _filtro,
      userId: id,
    )..load();
    setState(() => _selectedId = id);
  }

  @override
  void dispose() {
    _user?.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _colabs.load(force: true);
    if (!mounted) return;
    if (_user == null) {
      // Nada selecionado ainda (ex.: a lista havia falhado): refaz a resolução.
      await _init();
    } else {
      await _user?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: SignalBuilder(builder: (context) {
          final colabs = _colabs.itens.value;
          final colabsLoading = _colabs.isLoading.value;
          final colabsError = _colabs.error.value;

          if (colabsLoading && colabs.isEmpty) {
            return const AppLoading(message: 'Carregando colaboradores…');
          }

          return ListView(
            padding: EdgeInsets.all(AppSpacing.md),
            children: [
              const BiPageHeader(
                titulo: 'Performance Individual',
                subtitulo: 'Análise detalhada do colaborador',
              ),
              // A lista de colaboradores é best-effort: se falhar, o painel do
              // usuário logado ainda carrega (id resolvido por e-mail) e o
              // seletor dá lugar a um aviso com retry — como o aviso parcial
              // do timesheet.
              if (colabsError != null && colabs.isEmpty)
                _ColaboradoresErrorBanner(
                  message: colabsError.message,
                  onRetry: _refresh,
                )
              else
                ColaboradorPicker(
                  colaboradores: colabs,
                  selectedId: _selectedId,
                  onChanged: _selecionar,
                ),
              BiFilterBar(controller: _filtro, onApply: () => _user?.load()),
              _corpo(context),
            ],
          );
        }),
      ),
    );
  }

  Widget _corpo(BuildContext context) {
    final user = _user;
    if (user == null) {
      // Nenhum colaborador selecionado: tela zerada.
      return Padding(
        padding: EdgeInsets.only(top: context.height * 0.06),
        child: const AppEmptyState(
          icon: GjaIcons.employeeLookup,
          title: 'Selecione um funcional',
          subtitle: 'Escolha um colaborador no seletor acima para ver os dados.',
        ),
      );
    }

    final data = user.data.value;
    final isLoading = user.isLoading.value;
    final error = user.error.value;

    if (isLoading && data == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: AppLoading(message: 'Carregando dashboard…'),
      );
    }
    if (error != null && data == null) {
      return AppErrorWidget(
        title: 'Não foi possível carregar o dashboard',
        message: error.message,
        onRetry: user.load,
      );
    }
    if (data == null) {
      return const AppEmptyState(
        icon: GjaIcons.personPlaceholder,
        title: 'Sem dados',
        subtitle: 'Nenhum dado para os filtros selecionados.',
      );
    }

    return Column(
      children: [
        if (data.perfil != null)
          BiProfileCard(
            userId: data.perfil!.id.toString(),
            nome: data.perfil!.nome,
            squad: data.perfil!.squad,
            empresa: data.perfil!.empresa,
            capacidadeMensalHoras: data.perfil!.capacidadeMensalHoras,
            email: data.perfil!.email,
          ),
        KpiBanner(cards: data.cards),
        _Grade(data: data),
      ],
    );
  }
}

/// Aviso não-bloqueante: a lista de colaboradores falhou, mas o painel do
/// usuário logado ainda pode carregar. Mostra a mensagem e um retry.
class _ColaboradoresErrorBanner extends StatelessWidget {
  const _ColaboradoresErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          Icon(GjaIcons.warning,
              size: 20, color: cs.onErrorContainer),
          SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Text(
              'Não foi possível carregar os colaboradores: $message',
              style: context.textTheme.bodySmall
                  ?.copyWith(color: cs.onErrorContainer),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: cs.onErrorContainer),
            child: const Text('Tentar de novo'),
          ),
        ],
      ),
    );
  }
}

class _Grade extends StatelessWidget {
  const _Grade({required this.data});

  final UserDashboard data;

  @override
  Widget build(BuildContext context) {
    const chartH = 280.0;
    final panels = <Widget>[
      BiPanel(
        numero: 1,
        titulo: 'Distribuição das Demandas por Tipo',
        altura: chartH,
        child: BiDonutChart(fatias: data.distribuicaoPorTipo),
      ),
      BiPanel(
        numero: 2,
        titulo: 'Evolução Mensal de Horas',
        altura: chartH,
        child: BiLineChart(series: data.evolucaoHoras),
      ),
      BiPanel(
        numero: 3,
        titulo: 'Direcionamento Sugerido',
        child: InsightsList(insights: data.insights),
      ),
    ];

    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 1100 ? 3 : (c.maxWidth >= 700 ? 2 : 1);
      final gap = AppSpacing.md;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final p in panels) SizedBox(width: w, child: p),
        ],
      );
    });
  }
}
