import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';
import 'package:gja_foundation/gja_foundation.dart';

const _pt = GjaLocalizationsPtBr();
const _en = GjaLocalizationsEn();

/// Troca espaços especiais do CLDR (ex.: U+202F antes de "PM") por espaço.
String _normalize(String s) => s.replaceAll(RegExp(r'[  ]'), ' ');

class _Es extends GjaLocalizations {
  const _Es() : super(const Locale('es'));

  @override
  String get ok => 'Aceptar';
  @override
  String get cancel => 'Cancelar';
  @override
  String get close => 'Cerrar';
  @override
  String get search => 'Buscar';
  @override
  String get clear => 'Borrar';
  @override
  String get noData => 'Sin datos';
  @override
  String get loading => 'Cargando';
  @override
  String get more => 'Más';
  @override
  String get required => 'Obligatorio';
  @override
  String get navigation => 'Navegación';
  @override
  String get back => 'Volver';
  @override
  String get menu => 'Menú';
  @override
  String get logo => 'Logotipo';
  @override
  String get notifications => 'Notificaciones';
  @override
  String get profile => 'Perfil';
  @override
  String get products => 'Mis productos';
  @override
  String get shellBar => 'Barra de shell';
  @override
  String get selectAll => 'Seleccionar todo';
  @override
  String get selectItem => 'Seleccionar elemento';
  @override
  String get previous => 'Anterior';
  @override
  String get next => 'Siguiente';
  @override
  String get today => 'Hoy';
  @override
  String valueState(GjaValueState state) => state.name;
  @override
  String selectedItems(int count) => '$count';
}

class _EsDelegate extends LocalizationsDelegate<GjaLocalizations> {
  const _EsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'es';

  @override
  Future<GjaLocalizations> load(Locale locale) =>
      SynchronousFuture(const _Es());

  @override
  bool shouldReload(_EsDelegate old) => false;
}

/// Monta um `WidgetsApp` com [locale] e guarda os textos lidos.
Future<GjaLocalizations> _pumpApp(
  WidgetTester tester, {
  Locale? locale,
  List<LocalizationsDelegate<dynamic>> delegates = const [
    GjaLocalizations.delegate,
  ],
  List<Locale> supportedLocales = GjaLocalizations.supportedLocales,
}) async {
  late GjaLocalizations read;
  if (locale != null) {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  }
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      localizationsDelegates: delegates,
      supportedLocales: supportedLocales,
      builder: (context, _) {
        read = GjaLocalizations.of(context);
        return const SizedBox();
      },
    ),
  );
  return read;
}

void main() {
  group('Textos do framework', () {
    test('Textos do framework — Textos em pt-BR', () {
      expect(_pt.cancel, 'Cancelar');
      expect(_pt.noData, 'Sem dados');
      expect(_pt.valueState(GjaValueState.error), 'Valor inválido');
    });

    test('Textos do framework — Textos em en', () {
      expect(_en.cancel, 'Cancel');
      expect(_en.noData, 'No data');
      expect(_en.valueState(GjaValueState.error), 'Invalid value');
    });

    test('Textos do framework — Contagem de selecionados', () {
      expect([0, 1, 1000].map(_pt.selectedItems), [
        'Nenhum item selecionado',
        '1 item selecionado',
        '1.000 itens selecionados',
      ]);
      expect([0, 1, 1000].map(_en.selectedItems), [
        'No items selected',
        '1 item selected',
        '1,000 items selected',
      ]);
    });

    test('Textos do framework — Estado sem texto', () {
      for (final l in const <GjaLocalizations>[_pt, _en]) {
        for (final state in GjaValueState.values) {
          expect(
            l.valueState(state).isEmpty,
            state == GjaValueState.none,
            reason: '${l.locale}/${state.name}',
          );
        }
      }
    });

    test('Textos do framework — Texto da navegação', () {
      expect(_pt.navigation, 'Navegação');
      expect(_en.navigation, 'Navigation');
    });

    test('Textos do framework — Texto de voltar', () {
      expect(_pt.back, 'Voltar');
      expect(_en.back, 'Back');
    });

    test('Textos do framework — Textos da barra', () {
      expect(
        [_pt.menu, _pt.logo, _pt.notifications, _pt.profile, _pt.products],
        ['Menu', 'Logotipo', 'Notificações', 'Perfil', 'Meus produtos'],
      );
      expect(_pt.shellBar, 'Barra de shell');
      expect(
        [_en.menu, _en.logo, _en.notifications, _en.profile, _en.products],
        ['Menu', 'Logo', 'Notifications', 'Profile', 'My products'],
      );
      expect(_en.shellBar, 'Shell Bar');
    });

    test('Textos do framework — Textos da tabela', () {
      expect(
        [_pt.selectAll, _pt.selectItem],
        ['Selecionar tudo', 'Selecionar item'],
      );
      expect([_en.selectAll, _en.selectItem], ['Select All', 'Select Item']);
    });

    test('Datas do calendário — Textos do calendário', () {
      expect([_pt.previous, _pt.next], ['Anterior', 'Próximo']);
      expect([_en.previous, _en.next], ['Previous', 'Next']);
    });

    test('Datas do calendário — Ler e escrever datas', () {
      expect(_pt.parseDate('05/03/2026'), DateTime(2026, 3, 5));
      expect(_pt.parseDate('31/02/2026'), isNull);
      expect(_pt.parseDate('abc'), isNull);
      final date = DateTime(2026, 3, 5);
      expect(_pt.formatMonthYear(date), 'março de 2026');
      expect(_pt.formatLongDate(date), 'quinta-feira, 5 de março de 2026');
    });

    test('Datas do calendário — Semana do calendário', () {
      expect(_pt.firstDayOfWeek, DateTime.sunday);
      expect(_en.firstDayOfWeek, DateTime.sunday);
      expect(_pt.shortWeekdays.first, 'dom.');
      expect(_en.shortWeekdays.first, 'Sun');
      expect(_pt.shortWeekdays, hasLength(7));
      expect(_pt.datePattern, 'dd/MM/y');
      expect(_en.datePattern, 'M/d/y');
    });

    test('Meses e anos do calendário — Meses, ano e hoje', () {
      final date = DateTime(2026, 3, 5);
      expect(_pt.monthNames.first, 'janeiro');
      expect(_en.monthNames.first, 'January');
      expect(_pt.monthNames, hasLength(12));
      expect([_pt.formatYear(date), _en.formatYear(date)], ['2026', '2026']);
      expect([_pt.today, _en.today], ['Hoje', 'Today']);
    });

    test('todos os textos simples existem nos dois idiomas', () {
      for (final l in const <GjaLocalizations>[_pt, _en]) {
        final texts = [
          l.ok,
          l.cancel,
          l.close,
          l.search,
          l.clear,
          l.noData,
          l.loading,
          l.more,
          l.required,
          l.navigation,
          l.back,
          l.menu,
          l.logo,
          l.notifications,
          l.profile,
          l.products,
          l.shellBar,
          l.selectAll,
          l.selectItem,
          l.previous,
          l.next,
          l.today,
        ];
        expect(texts.every((t) => t.isNotEmpty), isTrue, reason: '${l.locale}');
      }
    });
  });

  testWidgets('Idiomas e resolução — Região sem tradução própria', (
    tester,
  ) async {
    for (final (device, expected) in [
      (const Locale('pt', 'PT'), GjaLocalizations.defaultLocale),
      (const Locale('en', 'GB'), const Locale('en')),
      (const Locale('fr', 'FR'), GjaLocalizations.defaultLocale),
    ]) {
      final l = await _pumpApp(tester, locale: device);
      expect(l.locale, expected, reason: '$device');
    }
  });

  testWidgets('Acesso sem delegate — Árvore sem o delegate', (tester) async {
    final l = await _pumpApp(
      tester,
      delegates: const [],
      supportedLocales: const [Locale('en', 'US')],
    );
    expect(l.cancel, 'Cancelar');
    expect(l.formatDecimal(1.5), '1,50');
  });

  testWidgets('Extensão por idioma da aplicação — Idioma da aplicação', (
    tester,
  ) async {
    final l = await _pumpApp(
      tester,
      locale: const Locale('es', 'ES'),
      delegates: const [_EsDelegate(), GjaLocalizations.delegate],
      supportedLocales: const [
        ...GjaLocalizations.supportedLocales,
        Locale('es'),
      ],
    );
    expect(l, isA<_Es>());
    expect(l.cancel, 'Cancelar');
    expect(l.formatDecimal(1234.5, decimals: 1), contains(',5'));
  });

  group('Formatação de números e datas', () {
    test('Formatação de números e datas — Números', () {
      expect(_pt.formatDecimal(1234567.891), '1.234.567,89');
      expect(_pt.formatInteger(1234567), '1.234.567');
      expect(_en.formatDecimal(1234567.891), '1,234,567.89');
      expect(_en.formatInteger(1234567), '1,234,567');
    });

    test('Formatação de números e datas — Datas e horas', () {
      final when = DateTime(2026, 3, 5, 14, 30);
      expect(_pt.formatDate(when), '05/03/2026');
      expect(_pt.formatTime(when), '14:30');
      expect(_en.formatDate(when), '3/5/2026');
      expect(_normalize(_en.formatTime(when)), '2:30 PM');
      expect(_normalize(_pt.formatDateTime(when)), '05/03/2026 14:30');
    });
  });
}
