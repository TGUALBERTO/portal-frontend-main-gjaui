import 'package:gja_checks/gja_checks.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('imports entre camadas', () {
    test('dependências na direção correta são aceitas', () {
      final repo = fixtureRepo({
        'packages/gja_foundation/lib/gja_foundation.dart':
            "import 'package:flutter/widgets.dart';\n",
        'packages/gja_core/lib/gja_core.dart':
            "import 'package:gja_foundation/gja_foundation.dart';\n",
        'packages/gja_widgets/lib/gja_widgets.dart':
            "import 'package:gja_core/gja_core.dart';\nimport 'package:gja_foundation/gja_foundation.dart';\n",
        'packages/gja_ui/lib/gja_ui.dart':
            "export 'package:gja_widgets/gja_widgets.dart';\n",
      });
      expect(checkImports(repo), isEmpty);
    });

    test('import proibido é detectado com arquivo e linha', () {
      final repo = fixtureRepo({
        'packages/gja_foundation/lib/src/tokens.dart':
            "import 'package:flutter/widgets.dart';\nimport 'package:gja_widgets/gja_widgets.dart';\n",
      });
      final violations = checkImports(repo);
      expect(violations, hasLength(1));
      expect(
        violations.single.path,
        'packages/gja_foundation/lib/src/tokens.dart',
      );
      expect(violations.single.line, 2);
      expect(
        violations.single.message,
        contains('não pode depender de gja_widgets'),
      );
    });
  });

  group('primitivos de gja_foundation', () {
    test(
      'Primitivos isolados da camada de widgets — Widget importa primitivos',
      () {
        final repo = fixtureRepo({
          'packages/gja_widgets/lib/src/actions/button/button.dart':
              "import 'package:flutter/widgets.dart';\nimport 'package:gja_foundation/gja_primitives.dart';\n",
        });
        final violations = checkImports(repo);
        expect(violations, hasLength(1));
        expect(
          violations.single.path,
          'packages/gja_widgets/lib/src/actions/button/button.dart',
        );
        expect(violations.single.line, 2);
        expect(violations.single.message, contains('gja_primitives.dart'));
      },
    );

    test('core importando src/ de gja_foundation é rejeitado', () {
      final repo = fixtureRepo({
        'packages/gja_core/lib/src/interaction/focus.dart':
            "import 'package:gja_foundation/src/tokens/lerp.dart';\n",
      });
      expect(messages(checkImports(repo)), [
        contains('restritos ao próprio pacote'),
      ]);
    });

    test(
      'Primitivos isolados da camada de widgets — Agregador não expõe primitivos',
      () {
        final repo = fixtureRepo({
          'packages/gja_ui/lib/gja_ui.dart':
              "export 'package:gja_foundation/gja_foundation.dart';\nexport 'package:gja_foundation/gja_primitives.dart';\n",
        });
        final violations = checkImports(repo);
        expect(violations, hasLength(1));
        expect(violations.single.line, 2);
        expect(violations.single.message, startsWith('export de'));
      },
    );

    test('gja_foundation pode importar os próprios primitivos', () {
      final repo = fixtureRepo({
        'packages/gja_foundation/lib/src/tokens/motion_tokens.dart':
            "import 'package:gja_foundation/gja_primitives.dart';\nimport 'package:gja_foundation/src/tokens/lerp.dart';\n",
      });
      expect(checkImports(repo), isEmpty);
    });
  });

  group('Material e Cupertino', () {
    test('import sem marcador de ADR é rejeitado', () {
      final repo = fixtureRepo({
        'packages/gja_widgets/lib/src/inputs/text_field/text_field.dart':
            "import 'package:flutter/material.dart';\n",
      });
      expect(messages(checkImports(repo)), [
        contains('sem marcador "// gja-adr: NNNN"'),
      ]);
    });

    test('import com marcador apontando para ADR existente é aceito', () {
      final repo = fixtureRepo({
        'docs/adr/0042-selecao-de-texto.md': '# ADR 0042\n',
        'packages/gja_widgets/lib/src/inputs/text_field/text_field.dart':
            "import 'package:flutter/material.dart' show TextSelectionTheme; // gja-adr: 0042\n",
      });
      expect(checkImports(repo), isEmpty);
    });

    test('marcador apontando para ADR inexistente é rejeitado', () {
      final repo = fixtureRepo({
        'packages/gja_widgets/lib/src/inputs/text_field/text_field.dart':
            "import 'package:flutter/cupertino.dart'; // gja-adr: 0099\n",
      });
      expect(checkImports(repo), hasLength(1));
    });

    test('reexportar Material é sempre rejeitado', () {
      final repo = fixtureRepo({
        'docs/adr/0042-x.md': '',
        'packages/gja_ui/lib/gja_ui.dart':
            "export 'package:flutter/material.dart'; // gja-adr: 0042\n",
      });
      expect(messages(checkImports(repo)), [contains('reexporta')]);
    });
  });

  group('ciclos entre módulos internos', () {
    test('ciclo entre widgets do mesmo pacote é rejeitado', () {
      final repo = fixtureRepo({
        'packages/gja_widgets/lib/src/actions/button/button.dart':
            "import '../../feedback/dialog/dialog.dart';\n",
        'packages/gja_widgets/lib/src/feedback/dialog/dialog.dart':
            "import 'package:gja_widgets/src/actions/button/button.dart';\n",
      });
      expect(messages(checkImports(repo)), [
        contains('actions/button -> feedback/dialog -> actions/button'),
      ]);
    });

    test('dependência em uma direção entre módulos é aceita', () {
      final repo = fixtureRepo({
        'packages/gja_widgets/lib/src/actions/button/button.dart':
            "import 'button_style.dart';\n",
        'packages/gja_widgets/lib/src/actions/button/button_style.dart': '',
        'packages/gja_widgets/lib/src/feedback/dialog/dialog.dart':
            "import '../../actions/button/button.dart';\n",
      });
      expect(checkImports(repo), isEmpty);
    });
  });

  group('API pública', () {
    test(
      'tipo Material em símbolo exportado é detectado',
      () async {
        final repo = fixtureRepo(resolvable: true, {
          'packages/gja_widgets/lib/gja_widgets.dart': '''
import 'package:flutter/material.dart';

class GjaLeaky {
  GjaLeaky(this.color);
  final MaterialColor color;
  ThemeData theme() => ThemeData();
}

typedef GjaBuilder = Widget Function(ScaffoldState state);
''',
        });
        final found = messages(await checkPublicApi(repo));
        expect(
          found,
          contains(contains('"GjaLeaky" referencia MaterialColor')),
        );
        expect(found, contains(contains('"GjaLeaky" referencia ThemeData')));
        expect(
          found,
          contains(contains('"GjaBuilder" referencia ScaffoldState')),
        );
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test(
      'API composta só com widgets.dart é aceita',
      () async {
        final repo = fixtureRepo(resolvable: true, {
          'packages/gja_widgets/lib/gja_widgets.dart': '''
import 'package:flutter/widgets.dart';

class GjaClean extends StatelessWidget {
  const GjaClean({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}
''',
        });
        expect(await checkPublicApi(repo), isEmpty);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}
