import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Textos e formatos do framework GJA em um idioma.
///
/// Equivale aos *resource bundles* de biblioteca do SAPUI5: os widgets do
/// framework leem daqui todo texto que exibem ou anunciam, com
/// `GjaLocalizations.of(context)`. O GJA fornece pt-BR (padrão) e en. Para
/// outro idioma, ou para trocar textos, a aplicação estende esta classe (ou
/// uma das fornecidas) e registra um delegate próprio antes de [delegate].
///
/// A formatação de números e datas é concreta e segue o [locale] da
/// instância, com os dados do CLDR de `package:intl`.
abstract class GjaLocalizations {
  /// Cria os textos de [locale].
  const GjaLocalizations(this.locale);

  /// Idioma destes textos e formatos.
  final Locale locale;

  /// Idioma padrão, usado quando nenhum outro se aplica.
  static const defaultLocale = Locale('pt', 'BR');

  /// Idiomas fornecidos pelo GJA, com o padrão em primeiro, para
  /// `WidgetsApp.supportedLocales`.
  static const supportedLocales = <Locale>[defaultLocale, Locale('en')];

  /// Delegate dos idiomas fornecidos, para `WidgetsApp.localizationsDelegates`.
  ///
  /// Aceita qualquer região de `pt` (carrega pt-BR) e de `en`.
  static const LocalizationsDelegate<GjaLocalizations> delegate =
      _GjaLocalizationsDelegate();

  /// Textos do contexto, ou os de pt-BR quando nenhum delegate de
  /// [GjaLocalizations] está registrado.
  static GjaLocalizations of(BuildContext context) {
    return Localizations.of<GjaLocalizations>(context, GjaLocalizations) ??
        const GjaLocalizationsPtBr();
  }

  /// Confirmação ("OK").
  String get ok;

  /// Cancelar uma ação.
  String get cancel;

  /// Fechar um painel, diálogo ou mensagem.
  String get close;

  /// Pesquisar.
  String get search;

  /// Limpar um valor ou filtro.
  String get clear;

  /// Lista ou tabela sem dados.
  String get noData;

  /// Conteúdo em carregamento.
  String get loading;

  /// Mais itens ou ações ocultos.
  String get more;

  /// Campo obrigatório.
  String get required;

  /// Área de navegação da aplicação (ex.: rótulo do botão que a expande).
  String get navigation;

  /// Voltar à página anterior (ex.: rótulo do botão de voltar).
  String get back;

  /// Menu da aplicação (ex.: botão de menu da barra superior).
  String get menu;

  /// Logotipo da aplicação (ex.: dica do ícone inicial da barra superior).
  String get logo;

  /// Notificações (ex.: botão de notificações da barra superior).
  String get notifications;

  /// Perfil do usuário (ex.: rótulo do avatar da barra superior).
  String get profile;

  /// Seletor de produtos (ex.: botão de produtos da barra superior).
  String get products;

  /// Barra superior da aplicação, como o rótulo do `sap.f.ShellBar`.
  String get shellBar;

  /// Caixa que escolhe todas as linhas de uma tabela.
  String get selectAll;

  /// Caixa que escolhe uma linha de uma tabela.
  String get selectItem;

  /// Ir para o anterior (ex.: mês anterior no calendário).
  String get previous;

  /// Ir para o próximo (ex.: mês seguinte no calendário).
  String get next;

  /// A data de hoje (ex.: o botão "Hoje" do calendário).
  String get today;

  /// Texto de [state] para leitores de tela; vazio para
  /// [GjaValueState.none].
  String valueState(GjaValueState state);

  /// Contagem de itens selecionados, com [count] formatado no idioma.
  String selectedItems(int count);

  /// Nome do idioma para `package:intl` (ex.: `pt_BR`, `en`).
  String get intlLocale => Intl.canonicalizedLocale(locale.toLanguageTag());

  /// [value] como decimal com [decimals] casas.
  String formatDecimal(num value, {int decimals = 2}) {
    return NumberFormat.decimalPatternDigits(
      locale: intlLocale,
      decimalDigits: decimals,
    ).format(value);
  }

  /// [value] como inteiro, com agrupamento de milhares.
  String formatInteger(int value) =>
      NumberFormat.decimalPattern(intlLocale).format(value);

  /// Data curta de [date] (ex.: 05/03/2026 em pt-BR).
  String formatDate(DateTime date) {
    _ensureDateData();
    return DateFormat.yMd(intlLocale).format(date);
  }

  /// Data curta lida de [text] no formato de [formatDate], ou nula quando
  /// [text] não é uma data válida (ex.: 31/02/2026).
  DateTime? parseDate(String text) {
    _ensureDateData();
    try {
      return DateFormat.yMd(intlLocale).parseStrict(text.trim());
    } on FormatException {
      return null;
    }
  }

  /// Padrão da data curta (ex.: dd/MM/y em pt-BR), para dicas de campo.
  String get datePattern {
    _ensureDateData();
    return DateFormat.yMd(intlLocale).pattern ?? '';
  }

  /// Mês e ano de [date] (ex.: março de 2026 em pt-BR).
  String formatMonthYear(DateTime date) {
    _ensureDateData();
    return DateFormat.yMMMM(intlLocale).format(date);
  }

  /// Data por extenso, com o dia da semana (ex.: quinta-feira, 5 de março de
  /// 2026 em pt-BR), para leitores de tela.
  String formatLongDate(DateTime date) {
    _ensureDateData();
    return DateFormat.yMMMMEEEEd(intlLocale).format(date);
  }

  /// Nomes completos dos doze meses, na forma independente (ex.: janeiro
  /// em pt-BR), de janeiro a dezembro.
  List<String> get monthNames {
    _ensureDateData();
    return DateFormat.yMd(intlLocale).dateSymbols.STANDALONEMONTHS;
  }

  /// Ano de [date], sem separador de milhar (ex.: 2026).
  String formatYear(DateTime date) {
    _ensureDateData();
    return DateFormat.y(intlLocale).format(date);
  }

  /// Primeiro dia da semana no idioma, como [DateTime.weekday] (7 = domingo).
  int get firstDayOfWeek {
    _ensureDateData();
    // No CLDR, 0 é segunda-feira.
    return DateFormat.yMd(intlLocale).dateSymbols.FIRSTDAYOFWEEK + 1;
  }

  /// Nomes curtos dos dias da semana, a partir de [firstDayOfWeek].
  List<String> get shortWeekdays {
    _ensureDateData();
    // No CLDR, a lista começa no domingo.
    final names = DateFormat.yMd(intlLocale).dateSymbols.SHORTWEEKDAYS;
    final start = firstDayOfWeek % 7;
    return [for (var i = 0; i < 7; i++) names[(start + i) % 7]];
  }

  /// Hora de [time], em 24 h ou 12 h conforme o idioma.
  String formatTime(DateTime time) {
    _ensureDateData();
    return DateFormat.jm(intlLocale).format(time);
  }

  /// Data curta e hora de [dateTime].
  String formatDateTime(DateTime dateTime) {
    _ensureDateData();
    return DateFormat.yMd(intlLocale).add_jm().format(dateTime);
  }
}

bool _dateDataReady = false;

// Os dados de data são locais: a inicialização termina antes de retornar.
void _ensureDateData() {
  if (_dateDataReady) return;
  initializeDateFormatting();
  _dateDataReady = true;
}

/// Textos e formatos em português do Brasil, o idioma padrão.
class GjaLocalizationsPtBr extends GjaLocalizations {
  /// Cria os textos em pt-BR.
  const GjaLocalizationsPtBr() : super(GjaLocalizations.defaultLocale);

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Fechar';

  @override
  String get search => 'Pesquisar';

  @override
  String get clear => 'Limpar';

  @override
  String get noData => 'Sem dados';

  @override
  String get loading => 'Carregando';

  @override
  String get more => 'Mais';

  @override
  String get required => 'Obrigatório';

  @override
  String get navigation => 'Navegação';

  @override
  String get back => 'Voltar';

  @override
  String get menu => 'Menu';

  @override
  String get logo => 'Logotipo';

  @override
  String get notifications => 'Notificações';

  @override
  String get profile => 'Perfil';

  @override
  String get products => 'Meus produtos';

  @override
  String get shellBar => 'Barra de shell';

  @override
  String get selectAll => 'Selecionar tudo';

  @override
  String get selectItem => 'Selecionar item';

  @override
  String get previous => 'Anterior';

  @override
  String get next => 'Próximo';

  @override
  String get today => 'Hoje';

  @override
  String valueState(GjaValueState state) => switch (state) {
    GjaValueState.none => '',
    GjaValueState.success => 'Valor válido',
    GjaValueState.warning => 'Aviso',
    GjaValueState.error => 'Valor inválido',
    GjaValueState.information => 'Informação',
  };

  @override
  String selectedItems(int count) => switch (count) {
    0 => 'Nenhum item selecionado',
    1 => '1 item selecionado',
    _ => '${formatInteger(count)} itens selecionados',
  };
}

/// Textos e formatos em inglês.
class GjaLocalizationsEn extends GjaLocalizations {
  /// Cria os textos em en.
  const GjaLocalizationsEn() : super(const Locale('en'));

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get clear => 'Clear';

  @override
  String get noData => 'No data';

  @override
  String get loading => 'Loading';

  @override
  String get more => 'More';

  @override
  String get required => 'Required';

  @override
  String get navigation => 'Navigation';

  @override
  String get back => 'Back';

  @override
  String get menu => 'Menu';

  @override
  String get logo => 'Logo';

  @override
  String get notifications => 'Notifications';

  @override
  String get profile => 'Profile';

  @override
  String get products => 'My products';

  @override
  String get shellBar => 'Shell Bar';

  @override
  String get selectAll => 'Select All';

  @override
  String get selectItem => 'Select Item';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get today => 'Today';

  @override
  String valueState(GjaValueState state) => switch (state) {
    GjaValueState.none => '',
    GjaValueState.success => 'Valid value',
    GjaValueState.warning => 'Warning',
    GjaValueState.error => 'Invalid value',
    GjaValueState.information => 'Information',
  };

  @override
  String selectedItems(int count) => switch (count) {
    0 => 'No items selected',
    1 => '1 item selected',
    _ => '${formatInteger(count)} items selected',
  };
}

class _GjaLocalizationsDelegate
    extends LocalizationsDelegate<GjaLocalizations> {
  const _GjaLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'pt' || locale.languageCode == 'en';

  @override
  Future<GjaLocalizations> load(Locale locale) {
    return SynchronousFuture(
      locale.languageCode == 'en'
          ? const GjaLocalizationsEn()
          : const GjaLocalizationsPtBr(),
    );
  }

  @override
  bool shouldReload(_GjaLocalizationsDelegate old) => false;
}
