# Lucide (fonte de ícones empacotada do GJA)

- **Biblioteca:** Lucide 1.61.0, de Lucide Icons and Contributors, <https://lucide.dev>
- **Licença:** ISC. A parte derivada do Feather está sob MIT, no mesmo arquivo. O texto integral está em [`LICENSE`](LICENSE).
- **Origem:** pacote npm `lucide-static@1.61.0`
  (`https://registry.npmjs.org/lucide-static/-/lucide-static-1.61.0.tgz`), baixado em 2026-10-25.
  - Integridade conferida com o registro npm:
    `sha512-yLAiQB3MWUJEstsEDAwenSA3m7vr1tdLvgnC16Q/XMxRRma0DWwMs8M2bWlvgShrIs1m2mWMJ+0AiahqQO4GrA==`.
  - SHA-256 do tarball: `62773cd2ee411ad2e37c1973d1e4c4b49f9a6c57da6b5d5d0abca08756ba75f1`.
- **Arquivos extraídos:** `package/font/lucide.ttf`, `package/font/codepoints.json` e `package/LICENSE`, sem modificação.
- **Situação:** escolha provisória do protótipo (spec `gja/foundation/iconography`). Ícones de marca substituem a
  fonte e os códigos de `GjaIcons`, sem mudar os nomes semânticos.

| Arquivo | Conteúdo | SHA-256 |
|---|---|---|
| lucide.ttf | fonte de ícones | `0b98954b05aba6a770306609847f2d2194395ab225288346c7841a4a50ce2300` |
| codepoints.json | mapa nome → código (fonte da verdade dos testes) | `4334dba4768d08a38f12caef18aa2818835f130a85f133f069f7ac5b161d6724` |
| LICENSE | licença ISC/MIT | `b495047bd93a9b06913511076f504daba17d5bbeb3e0650f3bb53a4220329c57` |

Para conferir: `sha256sum lucide.ttf codepoints.json LICENSE` nesta pasta.
