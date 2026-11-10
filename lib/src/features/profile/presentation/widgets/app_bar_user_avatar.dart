import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/profile/presentation/controllers/profile_controller.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gjamobile/src/services/graph_service.dart';

/// Avatar circular de um usuário, reutilizável em qualquer contexto (AppBar,
/// cartões do BI, telas futuras). A identidade vem por parâmetro ([userId] e
/// [name]) — o widget **não** lê o [SessionController], para poder representar
/// qualquer usuário, não só o logado.
///
/// Fontes da foto (em ordem de precedência):
/// - [photoUpn] informado → busca a foto **desse** usuário no Graph
///   (`/users/{upn}/photo`); requer permissão `User.Read.All`. Falta de foto,
///   de permissão ou qualquer erro caem nas iniciais de [name].
/// - senão, [fetchPhoto] `true` → foto do **usuário logado** (`/me`, cacheada
///   no [ProfileController]).
/// - senão → apenas as iniciais de [name].
///
/// [onTap]: ação ao tocar (ex.: abrir `/me`); quando `null`, não é clicável.
class AppBarUserAvatar extends StatefulWidget {
  const AppBarUserAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.photoUpn,
    this.fetchPhoto = true,
    this.onTap,
    this.radius = 18,
  });

  /// Identidade do usuário; usada como chave de cache da foto do logado.
  final String userId;

  /// Nome exibido no tooltip e usado para gerar as iniciais no fallback.
  final String name;

  /// UPN/e-mail (ou objectId) para buscar a foto de um usuário específico no
  /// Graph. Quando informado, tem precedência sobre [fetchPhoto].
  final String? photoUpn;

  /// Busca e exibe a foto do usuário logado (ignorado quando [photoUpn] existe).
  final bool fetchPhoto;

  /// Ação ao tocar; quando `null` o avatar não é clicável.
  final VoidCallback? onTap;

  /// Raio do avatar.
  final double radius;

  @override
  State<AppBarUserAvatar> createState() => _AppBarUserAvatarState();
}

class _AppBarUserAvatarState extends State<AppBarUserAvatar> {
  final _profile = AppInjector.get<ProfileController>();
  final _graph = AppInjector.get<GraphService>();

  /// Foto de um usuário específico (quando [AppBarUserAvatar.photoUpn] é usado);
  /// mantida em estado local para não colidir com a foto do logado (singleton).
  Uint8List? _photoUsuario;

  bool get _porUpn => (widget.photoUpn ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Dispara fora do frame de build (muta signals / setState).
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarFoto());
  }

  @override
  void didUpdateWidget(covariant AppBarUserAvatar old) {
    super.didUpdateWidget(old);
    if (old.photoUpn != widget.photoUpn) {
      _photoUsuario = null;
      _carregarFoto();
    }
  }

  Future<void> _carregarFoto() async {
    if (_porUpn) {
      final bytes = await _graph.fetchPhotoFor(widget.photoUpn!.trim());
      if (mounted) setState(() => _photoUsuario = bytes);
    } else if (widget.fetchPhoto) {
      _profile.ensurePhoto(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tooltip = widget.name.isEmpty ? 'Perfil' : widget.name;
    final Widget avatar = Tooltip(
      message: tooltip,
      child: _porUpn
          ? UserAvatar(
              name: widget.name,
              imageBytes: _photoUsuario,
              radius: widget.radius,
            )
          : SignalBuilder(builder: (context) {
              final photo = widget.fetchPhoto ? _profile.photoSignal.value : null;
              return UserAvatar(
                name: widget.name,
                imageBytes: photo,
                radius: widget.radius,
              );
            }),
    );

    final onTap = widget.onTap;
    if (onTap == null) return avatar;
    return InkWell(
      borderRadius: BorderRadius.circular(widget.radius + 2),
      onTap: onTap,
      child: avatar,
    );
  }
}
