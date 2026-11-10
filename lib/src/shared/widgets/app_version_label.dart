import '../../imports/imports.dart';

/// Rótulo discreto com a versão do build (`v2026.09.24.09.47-qas`: data e
/// hora do build e branch), para o rodapé de telas públicas como o login. Fica vazio enquanto carrega e se a
/// leitura falhar: sem versão é melhor do que um erro no rodapé.
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key, this.prefix});

  /// Texto antes da versão, separado por ` · ` (`Grupo José Alves · v2026…`).
  /// Ao contrário da versão, aparece desde o primeiro frame, e sozinho se a
  /// leitura falhar.
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return FutureBuilder<AppResult<String>>(
      future: AppVersionService.instance.label,
      builder: (context, snapshot) {
        final version = snapshot.data?.getOrNull();
        final parts = [
          if (prefix != null) prefix!,
          if (version != null) 'v$version',
        ];
        if (parts.isEmpty) return const SizedBox.shrink();
        return Text(
          parts.join(' · '),
          textAlign: TextAlign.center,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        );
      },
    );
  }
}
