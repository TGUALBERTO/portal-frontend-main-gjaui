import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/domain/entities/access_group.dart';
import 'package:gjamobile/src/features/access/domain/enums/empresas.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/auth/presentation/controllers/session_controller.dart';
import 'package:gjamobile/src/features/profile/domain/entities/graph_profile.dart';
import 'package:gjamobile/src/features/profile/presentation/controllers/profile_controller.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela de perfil do usuário logado (`/me`). Combina os dados da sessão, o
/// perfil do Microsoft Graph (cargo, área, telefone) e o acesso do usuário
/// (grupos + vínculo de matrícula) já carregados em memória.
class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  final _session = AppInjector.get<SessionController>();
  final _profile = AppInjector.get<ProfileController>();
  final _access = AppInjector.get<AccessController>();

  @override
  void initState() {
    super.initState();
    _profile.ensurePhoto(_session.user?.id);
    _profile.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      appBar: AppTopBar(
        title: 'Meu perfil',
        onPressed: () => context.go(AppRoutes.home),
      ),
      body: SignalBuilder(builder: (context) {
        final user = _session.userSignal.value;
        final photo = _profile.photoSignal.value;
        final graph = _profile.profileSignal.value;
        final loadingProfile =
            _profile.statusSignal.value == ProfileStatus.loading;
        final groups = _access.groupsSignal.value;
        final link = _access.employeeLinkSignal.value;

        final name = graph?.displayName ?? user?.name ?? user?.email ?? '—';
        final email = user?.email ?? graph?.email ?? '';
        final graphError = _profile.graphErrorSignal.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(name: name, email: email, photoBytes: photo),
            if (photo == null && graphError != null) ...[
              SizedBox(height: AppSpacing.md),
              _GraphDiagnostic(message: graphError),
            ],
            SizedBox(height: AppSpacing.lg),
            _ProfileDetails(
              graph: graph,
              matricula: link?.matricula,
              empresa: link?.empresa,
              loading: loadingProfile,
            ),
            SizedBox(height: AppSpacing.lg),
            _GroupsCard(groups: groups),
          ],
        );
      }),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.photoBytes,
  });

  final String name;
  final String email;
  final Uint8List? photoBytes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        UserAvatar(name: name, imageBytes: photoBytes, radius: 44),
        SizedBox(height: AppSpacing.md),
        Text(
          name,
          style: context.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            email,
            style: context.textTheme.bodyMedium
                ?.copyWith(color: context.colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _GraphDiagnostic extends StatelessWidget {
  const _GraphDiagnostic({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return AppCard(
      color: cs.errorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(GjaIcons.information, size: 18, color: cs.onErrorContainer),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Foto do Microsoft Graph indisponível',
                  style: context.textTheme.labelLarge
                      ?.copyWith(color: cs.onErrorContainer),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          SelectableText(
            message,
            style: context.textTheme.bodySmall
                ?.copyWith(color: cs.onErrorContainer),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({
    required this.graph,
    required this.matricula,
    required this.empresa,
    required this.loading,
  });

  final GraphProfile? graph;
  final int? matricula;
  final Empresa? empresa;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      if (graph?.jobTitle != null)
        ProfileInfoTile(
            icon: GjaIcons.badge, label: 'Cargo', value: graph!.jobTitle!),
      if (graph?.department != null)
        ProfileInfoTile(
            icon: GjaIcons.building,
            label: 'Área',
            value: graph!.department!),
      if (graph?.officeLocation != null)
        ProfileInfoTile(
            icon: GjaIcons.map,
            label: 'Escritório',
            value: graph!.officeLocation!),
      if (graph?.phone != null)
        ProfileInfoTile(
            icon: GjaIcons.phone,
            label: 'Telefone',
            value: graph!.phone!),
      if (matricula != null)
        ProfileInfoTile(
            icon: GjaIcons.numberSign,
            label: 'Matrícula',
            value: matricula.toString()),
      if (empresa != null)
        ProfileInfoTile(
            icon: GjaIcons.building,
            label: 'Empresa',
            value: empresa!.razaoSocial),
    ];

    return AppCard(
      title: 'Informações',
      child: loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          : tiles.isEmpty
              ? const AppEmptyState(
                  icon: GjaIcons.information,
                  title: 'Sem informações adicionais',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: tiles,
                ),
    );
  }
}

class _GroupsCard extends StatelessWidget {
  const _GroupsCard({required this.groups});

  final List<AccessGroup> groups;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Grupos',
      child: groups.isEmpty
          ? const AppEmptyState(
              icon: GjaIcons.group,
              title: 'Nenhum grupo',
            )
          : Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final g in groups)
                  Chip(
                    label: Text(g.name),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
    );
  }
}
