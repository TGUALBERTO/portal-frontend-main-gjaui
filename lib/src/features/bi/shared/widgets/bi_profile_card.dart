import 'package:gjamobile/src/features/profile/presentation/widgets/app_bar_user_avatar.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Cartão de perfil do colaborador (faixa escura, à esquerda dos KPIs no
/// Grafico6). Reaproveita o [AppBarUserAvatar]: quando o BFF traz o [email] do
/// colaborador, o avatar busca a foto dele no Microsoft Graph; sem e-mail (ou
/// sem foto/permissão) cai nas iniciais do nome.
class BiProfileCard extends StatelessWidget {
  const BiProfileCard({
    super.key,
    required this.userId,
    required this.nome,
    required this.squad,
    required this.empresa,
    required this.capacidadeMensalHoras,
    this.email = '',
  });

  final String userId;
  final String nome;
  final String squad;
  final String empresa;
  final int capacidadeMensalHoras;

  /// E-mail (UPN) do colaborador para buscar a foto no Graph; vazio → iniciais.
  final String email;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        borderRadius: AppBorders.lg,
        gradient: LinearGradient(
          colors: [FioriColors.grey9, FioriColors.grey11],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          AppBarUserAvatar(
            userId: userId,
            name: nome,
            photoUpn: email,
            fetchPhoto: false,
            radius: 28,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                SizedBox(height: AppSpacing.xs),
                _linha(context, GjaIcons.group, 'Squad', squad),
                _linha(context, GjaIcons.building, 'Empresa', empresa),
                _linha(context, GjaIcons.pending, 'Capacidade mensal',
                    '${capacidadeMensalHoras}h'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linha(BuildContext context, IconData icon, String rotulo, String valor) {
    if (valor.trim().isEmpty) return const SizedBox.shrink();
    final tt = context.textTheme;
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.white70),
          SizedBox(width: AppSpacing.xs),
          Text('$rotulo: ',
              style: tt.bodySmall?.copyWith(color: Colors.white54)),
          Expanded(
            child: Text(valor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
