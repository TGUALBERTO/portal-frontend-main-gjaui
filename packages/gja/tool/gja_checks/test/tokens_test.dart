import 'package:gja_checks/gja_checks.dart';
import 'package:test/test.dart';

import 'support.dart';

const _file = 'packages/gja_widgets/lib/src/actions/button/button.dart';

void main() {
  group('literais proibidos', () {
    for (final (name, line) in [
      ('cor literal', 'final c = Color(0xFF0A6ED1);'),
      ('cor literal', 'final c = Color.fromARGB(255, 1, 2, 3);'),
      ('espaçamento literal', 'padding: EdgeInsets.all(8),'),
      (
        'espaçamento literal',
        'padding: EdgeInsets.symmetric(horizontal: tokens.x, vertical: 4),',
      ),
      ('raio literal', 'borderRadius: BorderRadius.circular(4),'),
      ('raio literal', 'radius: Radius.circular(2.5),'),
      ('duração literal', 'duration: Duration(milliseconds: 200),'),
      ('estilo de texto literal', 'style: TextStyle(fontSize: 14),'),
      ('dimensão literal', 'SizedBox(width: 12)'),
      ('dimensão literal', 'height: 1.5,'),
    ]) {
      test('$name: "$line"', () {
        final repo = fixtureRepo({_file: 'void f() {\n  $line\n}\n'});
        final violations = checkTokens(repo);
        expect(violations, isNotEmpty);
        expect(violations.first.message, startsWith(name));
        expect(violations.first.line, 2);
      });
    }
  });

  group('Uso sem literais nos widgets', () {
    test(
      'Uso sem literais nos widgets — Widget usa espaçamento sem literal',
      () {
        final repo = fixtureRepo({
          _file: '''
Widget build(BuildContext context) {
  return Padding(
    padding: EdgeInsets.all(spacing.m),
    child: Row(children: [icon, SizedBox(width: spacing.inlineGap), label]),
  );
}
''',
        });
        expect(checkTokens(repo), isEmpty);
      },
    );

    test('Uso sem literais nos widgets — Widget com espaçamento literal', () {
      final repo = fixtureRepo({
        _file:
            'Widget build(BuildContext context) {\n  return SizedBox(width: 8);\n}\n',
      });
      final violations = checkTokens(repo);
      expect(violations, hasLength(1));
      expect(violations.single.path, _file);
      expect(violations.single.line, 2);
    });
  });

  group('Uso de raios sem literais nos widgets', () {
    test(
      'Uso de raios sem literais nos widgets — Widget usa raio sem literal',
      () {
        final repo = fixtureRepo({
          _file: '''
BoxDecoration decoration() {
  return BoxDecoration(borderRadius: BorderRadius.circular(radius.button));
}
''',
        });
        expect(checkTokens(repo), isEmpty);
      },
    );

    test('Uso de raios sem literais nos widgets — Widget com raio literal', () {
      final repo = fixtureRepo({
        _file:
            'BoxDecoration decoration() {\n  return BoxDecoration(borderRadius: BorderRadius.circular(6));\n}\n',
      });
      final violations = checkTokens(repo);
      expect(violations, hasLength(1));
      expect(violations.single.path, _file);
      expect(violations.single.line, 2);
      expect(violations.single.message, startsWith('raio literal'));
    });
  });

  group('Uso de sombras sem literais nos widgets', () {
    test(
      'Uso de sombras sem literais nos widgets — Widget usa sombra dos tokens',
      () {
        final repo = fixtureRepo({
          _file: '''
BoxDecoration decoration() {
  return BoxDecoration(
    boxShadow: shadows.boxShadows(shadows.card, colors.shadow),
  );
}
''',
        });
        expect(checkTokens(repo), isEmpty);
      },
    );

    test(
      'Uso de sombras sem literais nos widgets — Widget com sombra literal',
      () {
        final repo = fixtureRepo({
          _file:
              'List<BoxShadow> shadows() {\n  return [BoxShadow(blurRadius: 8)];\n}\n',
        });
        final violations = checkTokens(repo);
        expect(violations, hasLength(1));
        expect(violations.single.path, _file);
        expect(violations.single.line, 2);
        expect(violations.single.message, startsWith('dimensão literal'));
      },
    );
  });

  test('uso de tokens, zero e comentários são aceitos', () {
    final repo = fixtureRepo({
      _file: '''
// Exemplo em comentário: Color(0xFF000000), EdgeInsets.all(8)
/* bloco
   SizedBox(width: 12)
*/
void f() {
  padding: EdgeInsets.all(tokens.spacing.m),
  borderRadius: BorderRadius.circular(tokens.radius.s),
  duration: tokens.motion.short,
  SizedBox(width: 0)
  SizedBox(width: tokens.spacing2)
}
''',
    });
    expect(checkTokens(repo), isEmpty);
  });

  test('somente o código dos widgets é verificado', () {
    final repo = fixtureRepo({
      'packages/gja_foundation/lib/src/palette.dart':
          'const blue = Color(0xFF0A6ED1);\n',
    });
    expect(checkTokens(repo), isEmpty);
  });

  group('exceções', () {
    test('exceção justificada ignora a linha', () {
      final repo = fixtureRepo({
        _file: 'void f() {\n  duration: Duration(milliseconds: 0),\n}\n',
        tokenExceptionsFile:
            '''
exceptions:
  - file: $_file
    contains: "Duration(milliseconds: 0)"
    reason: "Ausência de animação é semântica."
''',
      });
      expect(checkTokens(repo), isEmpty);
    });

    test('exceção sem justificativa é rejeitada', () {
      final repo = fixtureRepo({
        tokenExceptionsFile:
            '''
exceptions:
  - file: $_file
    contains: "x"
    reason: ""
''',
      });
      expect(messages(checkTokens(repo)), [contains('"reason" não vazio')]);
    });
  });
}
