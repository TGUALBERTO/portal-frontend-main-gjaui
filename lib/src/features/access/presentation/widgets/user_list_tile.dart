import 'package:gjamobile/src/features/access/domain/entities/portal_user.dart';
import 'package:gjamobile/src/imports/core_imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// A row in the users list. Shows avatar, name, email, matricula/KBA badges
/// and the "Grupos" / "Vincular matrícula" / "Desbloquear KBA" actions.
class UserListTile extends StatelessWidget {
  const UserListTile({
    super.key,
    required this.user,
    required this.groupCount,
    required this.onManageGroups,
    this.onTap,
    this.onUnlockKba,
    this.onLinkKba,
  });

  final PortalUser user;
  final int groupCount;
  final VoidCallback onManageGroups;

  /// Abre o detalhe do usuário ao tocar no card.
  final VoidCallback? onTap;

  /// Ação de desbloqueio do KBA; o botão só aparece quando o usuário está
  /// bloqueado e o callback foi fornecido.
  final VoidCallback? onUnlockKba;

  /// Vínculo manual de matrícula; o botão só aparece quando o usuário ainda
  /// não está vinculado e o callback foi fornecido.
  final VoidCallback? onLinkKba;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(child: Text(_initials(user.displayName))),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.displayName,
                        style: context.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.matricula != null) ...[
                      SizedBox(width: AppSpacing.xs),
                      _MatriculaBadge(matricula: user.matricula!),
                    ],
                    if (user.kbaBloqueado) ...[
                      SizedBox(width: AppSpacing.xs),
                      _KbaBlockedBadge(),
                    ],
                  ],
                ),
                Text(
                  user.email,
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!user.isLinked && onLinkKba != null)
            TextButton.icon(
              onPressed: onLinkKba,
              icon: const Icon(GjaIcons.badge, size: 18),
              label: const Text('Vincular matrícula'),
            ),
          if (user.kbaBloqueado && onUnlockKba != null)
            TextButton.icon(
              onPressed: onUnlockKba,
              style: TextButton.styleFrom(foregroundColor: cs.error),
              icon: const Icon(GjaIcons.unlocked, size: 18),
              label: const Text('Desbloquear KBA'),
            ),
          TextButton.icon(
            onPressed: onManageGroups,
            icon: const Icon(GjaIcons.group, size: 18),
            label: Text('Grupos${groupCount > 0 ? ' ($groupCount)' : ''}'),
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _MatriculaBadge extends StatelessWidget {
  const _MatriculaBadge({required this.matricula});

  final int matricula;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Matrícula $matricula',
        style: context.textTheme.labelSmall?.copyWith(
          color: cs.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _KbaBlockedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'KBA bloqueado',
        style: context.textTheme.labelSmall?.copyWith(
          color: cs.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
