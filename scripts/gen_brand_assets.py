"""Gera os assets de marca (logo, ícones e splash) a partir das fontes em baixa
resolução mantidas em scripts/brand/.

Fonte única: scripts/brand/logo_320x98.png (logo horizontal, 320x98, RGBA).
O símbolo (triângulo vermelho + esfera azul) é recortado das colunas 0..86 dessa
imagem — é a versão de maior resolução do símbolo que existe no projeto
(logo32x32.png / logo16x16.png são pequenos demais para gerar ícones grandes).

Como não há vetor nem original em alta, o upscale é feito com Lanczos em alpha
premultiplicado e o canal alpha é "re-endurecido" para manter as bordas nítidas.
Quando o marketing entregar um SVG/PNG em alta, basta trocar a fonte e rodar de
novo (ou apontar os yaml direto para o arquivo novo e apagar este script).

Uso (na raiz do portal-frontend, requer Python 3 + Pillow + numpy):
    python scripts/gen_brand_assets.py
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create --path=flutter_native_splash.yaml

Saídas:
  assets/images/logo.png                 800x245  login (app) e splash web
  assets/images/logo_icon.png            512x512  launcher Android (legado), Windows, favicon
  assets/images/logo_icon_foreground.png 1024x1024 foreground do ícone adaptativo Android
  assets/images/splash_android.png       1152x1152 splash Android (legado e Android 12+)
  web/icons/Icon-192.png, Icon-512.png   ícones PWA
  web/icons/Icon-maskable-*.png          ícones PWA maskable (fundo branco, safe zone)
  web/favicon.png                        256x256 fallback do favicon
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "scripts" / "brand" / "logo_320x98.png"
IMAGES = ROOT / "assets" / "images"
WEB = ROOT / "web"
WEB_ICONS = WEB / "icons"

# Colunas 0..86 do logo horizontal contêm só o símbolo (87..88 são transparentes).
SYMBOL_BOX = (0, 0, 87, 98)


def upscale_rgba(im: Image.Image, size: tuple[int, int], edge_gain: float) -> Image.Image:
    """Redimensiona RGBA com alpha premultiplicado e re-endurece as bordas.

    edge_gain ~ fator de upscale: comprime a faixa de anti-aliasing (que o
    Lanczos espalha proporcionalmente ao fator) de volta para ~1px.
    """
    arr = np.asarray(im.convert("RGBA")).astype(np.float32) / 255.0
    rgb, a = arr[..., :3], arr[..., 3:4]
    pre = np.concatenate([rgb * a, a], axis=-1)
    pre_im = Image.fromarray((pre * 255).round().astype(np.uint8), "RGBA")
    up = np.asarray(pre_im.resize(size, Image.LANCZOS)).astype(np.float32) / 255.0
    a_up = up[..., 3:4]
    rgb_up = np.where(a_up > 1e-3, up[..., :3] / np.maximum(a_up, 1e-3), 0.0)
    rgb_up = np.clip(rgb_up, 0.0, 1.0)
    a_sharp = np.clip(0.5 + (a_up - 0.5) * edge_gain, 0.0, 1.0)
    out = np.concatenate([rgb_up, a_sharp], axis=-1)
    result = Image.fromarray((out * 255).round().astype(np.uint8), "RGBA")
    # Leve unsharp só na cor (bordas já estão nítidas via alpha).
    color = result.convert("RGB").filter(ImageFilter.UnsharpMask(radius=2, percent=50, threshold=2))
    result.paste(color, mask=None)
    result.putalpha(Image.fromarray((a_sharp[..., 0] * 255).round().astype(np.uint8), "L"))
    return result


def fit_scale_for_circle(symbol: Image.Image, canvas: int, circle_fraction: float) -> int:
    """Maior altura (px) para o símbolo caber num círculo de diâmetro
    canvas*circle_fraction centrado no canvas."""
    a = np.asarray(symbol.convert("RGBA"))[..., 3] > 8
    h, w = a.shape
    ys, xs = np.nonzero(a)
    # Distância máxima (normalizada pela altura) de um pixel opaco ao centro.
    cy, cx = (h - 1) / 2, (w - 1) / 2
    r_norm = np.sqrt((ys - cy) ** 2 + (xs - cx) ** 2).max() / h
    radius_px = canvas * circle_fraction / 2
    return int(math.floor(radius_px / r_norm))


def place_symbol(symbol: Image.Image, canvas: int, height: int, bg=(0, 0, 0, 0)) -> Image.Image:
    w, h = symbol.size
    target = (round(w * height / h), height)
    scaled = upscale_rgba(symbol, target, edge_gain=max(1.0, height / h))
    out = Image.new("RGBA", (canvas, canvas), bg)
    out.alpha_composite(scaled, ((canvas - target[0]) // 2, (canvas - target[1]) // 2))
    return out


def save(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, optimize=True)
    print(f"{path.relative_to(ROOT)}  {im.size[0]}x{im.size[1]}")


def main() -> None:
    src = Image.open(SRC).convert("RGBA")
    assert src.size == (320, 98), src.size
    symbol = src.crop(SYMBOL_BOX)

    # Logo horizontal 2.5x: 800x245 -> no splash web vira 200x61 css px (1x).
    logo = upscale_rgba(src, (800, 245), edge_gain=2.5)
    save(logo, IMAGES / "logo.png")

    # Símbolo quadrado (ícone): ocupa ~92% do canvas.
    icon = place_symbol(symbol, 512, round(512 * 0.92))
    save(icon, IMAGES / "logo_icon.png")

    # Foreground do ícone adaptativo: safe zone = círculo de 66/108 do canvas.
    fg_h = fit_scale_for_circle(symbol, 1024, 66 / 108 * 0.94)
    save(place_symbol(symbol, 1024, fg_h), IMAGES / "logo_icon_foreground.png")

    # Splash Android 12+: canvas 1152, ícone com fundo -> visível círculo de 768.
    sp_h = fit_scale_for_circle(symbol, 1152, 768 / 1152 * 0.90)
    save(place_symbol(symbol, 1152, sp_h), IMAGES / "splash_android.png")

    # PWA / favicon (web).
    for size in (192, 512):
        save(place_symbol(symbol, size, round(size * 0.84)), WEB_ICONS / f"Icon-{size}.png")
        # Maskable: safe zone = círculo de 80% do canvas, fundo branco.
        mh = fit_scale_for_circle(symbol, size, 0.80 * 0.92)
        save(place_symbol(symbol, size, mh, bg=(255, 255, 255, 255)), WEB_ICONS / f"Icon-maskable-{size}.png")
    save(place_symbol(symbol, 256, round(256 * 0.92)), WEB / "favicon.png")


if __name__ == "__main__":
    main()
