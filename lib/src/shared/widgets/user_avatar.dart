import 'package:gja_ui/gja_ui.dart' show GjaAvatar, GjaAvatarSize;

import '../../imports/core_imports.dart';

/// Avatar circular do usuário, desenhado pelo [GjaAvatar]. Mostra a foto
/// (bytes, ex.: vinda do Microsoft Graph) quando disponível; senão as
/// iniciais do nome, nas cores do GJA (fundo de seleção, texto na marca).
///
/// O GJA só tem tamanhos fixos (32, 48, 64, 80 e 112). Para manter o
/// [radius] que as telas já usam, o avatar é desenhado no tamanho do GJA
/// mais próximo e redimensionado para o diâmetro pedido.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageBytes,
    this.radius = 20,
  });

  /// Nome usado para gerar as iniciais no fallback e anunciado ao leitor de
  /// tela.
  final String name;

  /// Bytes da foto; quando nulo mostra as iniciais.
  final Uint8List? imageBytes;

  final double radius;

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;
    final diameter = radius * 2;

    return SizedBox.square(
      dimension: diameter,
      child: FittedBox(
        child: GjaAvatar(
          image: bytes != null && bytes.isNotEmpty ? MemoryImage(bytes) : null,
          initials: _initials(name),
          size: _size(diameter),
          semanticLabel: name.trim().isEmpty ? null : name,
        ),
      ),
    );
  }

  /// Tamanho do GJA mais próximo do [diameter], para o texto das iniciais
  /// sofrer o mínimo de redimensionamento.
  static GjaAvatarSize _size(double diameter) {
    const sides = {
      GjaAvatarSize.xs: 32.0,
      GjaAvatarSize.s: 48.0,
      GjaAvatarSize.m: 64.0,
      GjaAvatarSize.l: 80.0,
      GjaAvatarSize.xl: 112.0,
    };
    return sides.entries
        .reduce((a, b) =>
            (a.value - diameter).abs() <= (b.value - diameter).abs() ? a : b)
        .key;
  }

  static String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
