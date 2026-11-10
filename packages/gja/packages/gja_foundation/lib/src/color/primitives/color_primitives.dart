import 'dart:ui' show Color;

/// Escalas primitivas de cor do GJA (paleta provisória do protótipo).
///
/// Nível: primitivo.
///
/// Cada escala é nomeada por matiz e posição; a luminância decresce à medida
/// que a posição cresce. Paleta própria, sem cores da SAP. Widgets não leem
/// estes valores: eles usam os papéis de `GjaColorTokens`.
abstract final class GjaColorPrimitives {
  /// Branco opaco.
  static const white = Color(0xFFFFFFFF);

  /// Preto opaco.
  static const black = Color(0xFF000000);

  /// Totalmente transparente (bordas e fundos ausentes das famílias de
  /// controle).
  static const transparent = Color(0x00000000);

  /// Preto com opacidade de 16%.
  static const blackAlpha16 = Color(0x29000000);

  /// Preto com opacidade de 40%.
  static const blackAlpha40 = Color(0x66000000);

  /// Preto com opacidade de 60%.
  static const blackAlpha60 = Color(0x99000000);

  /// Neutro 50 (#F7F8FA).
  static const neutral50 = Color(0xFFF7F8FA);

  /// Neutro 100 (#EEF0F3).
  static const neutral100 = Color(0xFFEEF0F3);

  /// Neutro 200 (#DDE1E7).
  static const neutral200 = Color(0xFFDDE1E7);

  /// Neutro 300 (#C3C9D2).
  static const neutral300 = Color(0xFFC3C9D2);

  /// Neutro 400 (#9AA3B0).
  static const neutral400 = Color(0xFF9AA3B0);

  /// Neutro 500 (#737D8C).
  static const neutral500 = Color(0xFF737D8C);

  /// Neutro 600 (#586271).
  static const neutral600 = Color(0xFF586271);

  /// Neutro 700 (#424B58).
  static const neutral700 = Color(0xFF424B58);

  /// Neutro 800 (#2C333D).
  static const neutral800 = Color(0xFF2C333D);

  /// Neutro 900 (#1B2027).
  static const neutral900 = Color(0xFF1B2027);

  /// Neutro 950 (#11151A).
  static const neutral950 = Color(0xFF11151A);

  /// Azul 50 (#EEF4FF).
  static const blue50 = Color(0xFFEEF4FF);

  /// Azul 100 (#D9E6FF).
  static const blue100 = Color(0xFFD9E6FF);

  /// Azul 200 (#B3CCFF).
  static const blue200 = Color(0xFFB3CCFF);

  /// Azul 300 (#85ABFA).
  static const blue300 = Color(0xFF85ABFA);

  /// Azul 400 (#5788EE).
  static const blue400 = Color(0xFF5788EE);

  /// Azul 500 (#3468D9).
  static const blue500 = Color(0xFF3468D9);

  /// Azul 600 (#2453B8).
  static const blue600 = Color(0xFF2453B8);

  /// Azul 700 (#1C4294).
  static const blue700 = Color(0xFF1C4294);

  /// Azul 800 (#163370).
  static const blue800 = Color(0xFF163370);

  /// Azul 900 (#10244F).
  static const blue900 = Color(0xFF10244F);

  /// Verde 50 (#EDF8F1).
  static const green50 = Color(0xFFEDF8F1);

  /// Verde 100 (#D3EFDD).
  static const green100 = Color(0xFFD3EFDD);

  /// Verde 200 (#A6DEBB).
  static const green200 = Color(0xFFA6DEBB);

  /// Verde 300 (#70C793).
  static const green300 = Color(0xFF70C793);

  /// Verde 400 (#3FA96C).
  static const green400 = Color(0xFF3FA96C);

  /// Verde 500 (#258C52).
  static const green500 = Color(0xFF258C52);

  /// Verde 600 (#1B7142).
  static const green600 = Color(0xFF1B7142);

  /// Verde 700 (#165A35).
  static const green700 = Color(0xFF165A35);

  /// Verde 800 (#114428).
  static const green800 = Color(0xFF114428);

  /// Verde 900 (#0B2E1B).
  static const green900 = Color(0xFF0B2E1B);

  /// Âmbar 50 (#FFF7E8).
  static const amber50 = Color(0xFFFFF7E8);

  /// Âmbar 100 (#FDEBC4).
  static const amber100 = Color(0xFFFDEBC4);

  /// Âmbar 200 (#F9D488).
  static const amber200 = Color(0xFFF9D488);

  /// Âmbar 300 (#F2B84A).
  static const amber300 = Color(0xFFF2B84A);

  /// Âmbar 400 (#DE9A1E).
  static const amber400 = Color(0xFFDE9A1E);

  /// Âmbar 500 (#B87D10).
  static const amber500 = Color(0xFFB87D10);

  /// Âmbar 600 (#94630C).
  static const amber600 = Color(0xFF94630C);

  /// Âmbar 700 (#744D0A).
  static const amber700 = Color(0xFF744D0A);

  /// Âmbar 800 (#553808).
  static const amber800 = Color(0xFF553808);

  /// Âmbar 900 (#392505).
  static const amber900 = Color(0xFF392505);

  /// Vermelho 50 (#FDF0F0).
  static const red50 = Color(0xFFFDF0F0);

  /// Vermelho 100 (#FAD9D9).
  static const red100 = Color(0xFFFAD9D9);

  /// Vermelho 200 (#F3B0B0).
  static const red200 = Color(0xFFF3B0B0);

  /// Vermelho 300 (#EA8080).
  static const red300 = Color(0xFFEA8080);

  /// Vermelho 400 (#DC5656).
  static const red400 = Color(0xFFDC5656);

  /// Vermelho 500 (#C43939).
  static const red500 = Color(0xFFC43939);

  /// Vermelho 600 (#A12C2C).
  static const red600 = Color(0xFFA12C2C);

  /// Vermelho 700 (#7F2323).
  static const red700 = Color(0xFF7F2323);

  /// Vermelho 800 (#5E1A1A).
  static const red800 = Color(0xFF5E1A1A);

  /// Vermelho 900 (#3F1111).
  static const red900 = Color(0xFF3F1111);

  /// Ciano 50 (#ECF8FB).
  static const cyan50 = Color(0xFFECF8FB);

  /// Ciano 100 (#CDEDF5).
  static const cyan100 = Color(0xFFCDEDF5);

  /// Ciano 200 (#9DDAEA).
  static const cyan200 = Color(0xFF9DDAEA);

  /// Ciano 300 (#63C1DA).
  static const cyan300 = Color(0xFF63C1DA);

  /// Ciano 400 (#2FA3C2).
  static const cyan400 = Color(0xFF2FA3C2);

  /// Ciano 500 (#1A86A3).
  static const cyan500 = Color(0xFF1A86A3);

  /// Ciano 600 (#146B83).
  static const cyan600 = Color(0xFF146B83);

  /// Ciano 700 (#105467).
  static const cyan700 = Color(0xFF105467);

  /// Ciano 800 (#0C3F4D).
  static const cyan800 = Color(0xFF0C3F4D);

  /// Ciano 900 (#082A34).
  static const cyan900 = Color(0xFF082A34);

  /// Magenta 50 (#FCEFF6).
  static const magenta50 = Color(0xFFFCEFF6);

  /// Magenta 100 (#F9D7E8).
  static const magenta100 = Color(0xFFF9D7E8);

  /// Magenta 200 (#F2AFD2).
  static const magenta200 = Color(0xFFF2AFD2);

  /// Magenta 300 (#EA82B8).
  static const magenta300 = Color(0xFFEA82B8);

  /// Magenta 400 (#DD559C).
  static const magenta400 = Color(0xFFDD559C);

  /// Magenta 500 (#C4307F).
  static const magenta500 = Color(0xFFC4307F);

  /// Magenta 600 (#A81A68).
  static const magenta600 = Color(0xFFA81A68);

  /// Magenta 700 (#861453).
  static const magenta700 = Color(0xFF861453);

  /// Magenta 800 (#640F3E).
  static const magenta800 = Color(0xFF640F3E);

  /// Magenta 900 (#430A2A).
  static const magenta900 = Color(0xFF430A2A);

  /// Escala neutro, da posição mais clara para a mais escura.
  static const neutral = <String, Color>{
    'neutral50': neutral50,
    'neutral100': neutral100,
    'neutral200': neutral200,
    'neutral300': neutral300,
    'neutral400': neutral400,
    'neutral500': neutral500,
    'neutral600': neutral600,
    'neutral700': neutral700,
    'neutral800': neutral800,
    'neutral900': neutral900,
    'neutral950': neutral950,
  };

  /// Escala azul, da posição mais clara para a mais escura.
  static const blue = <String, Color>{
    'blue50': blue50,
    'blue100': blue100,
    'blue200': blue200,
    'blue300': blue300,
    'blue400': blue400,
    'blue500': blue500,
    'blue600': blue600,
    'blue700': blue700,
    'blue800': blue800,
    'blue900': blue900,
  };

  /// Escala verde, da posição mais clara para a mais escura.
  static const green = <String, Color>{
    'green50': green50,
    'green100': green100,
    'green200': green200,
    'green300': green300,
    'green400': green400,
    'green500': green500,
    'green600': green600,
    'green700': green700,
    'green800': green800,
    'green900': green900,
  };

  /// Escala âmbar, da posição mais clara para a mais escura.
  static const amber = <String, Color>{
    'amber50': amber50,
    'amber100': amber100,
    'amber200': amber200,
    'amber300': amber300,
    'amber400': amber400,
    'amber500': amber500,
    'amber600': amber600,
    'amber700': amber700,
    'amber800': amber800,
    'amber900': amber900,
  };

  /// Escala vermelho, da posição mais clara para a mais escura.
  static const red = <String, Color>{
    'red50': red50,
    'red100': red100,
    'red200': red200,
    'red300': red300,
    'red400': red400,
    'red500': red500,
    'red600': red600,
    'red700': red700,
    'red800': red800,
    'red900': red900,
  };

  /// Escala ciano, da posição mais clara para a mais escura.
  static const cyan = <String, Color>{
    'cyan50': cyan50,
    'cyan100': cyan100,
    'cyan200': cyan200,
    'cyan300': cyan300,
    'cyan400': cyan400,
    'cyan500': cyan500,
    'cyan600': cyan600,
    'cyan700': cyan700,
    'cyan800': cyan800,
    'cyan900': cyan900,
  };

  /// Escala magenta, da posição mais clara para a mais escura.
  static const magenta = <String, Color>{
    'magenta50': magenta50,
    'magenta100': magenta100,
    'magenta200': magenta200,
    'magenta300': magenta300,
    'magenta400': magenta400,
    'magenta500': magenta500,
    'magenta600': magenta600,
    'magenta700': magenta700,
    'magenta800': magenta800,
    'magenta900': magenta900,
  };

  /// Todas as escalas, por matiz.
  static const scales = <String, Map<String, Color>>{
    'neutral': neutral,
    'blue': blue,
    'green': green,
    'amber': amber,
    'red': red,
    'cyan': cyan,
    'magenta': magenta,
  };
}
