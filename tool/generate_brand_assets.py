"""Generate every brand asset for the FIZ Price app from a single source logo.

Run from the project root:  python tool/generate_brand_assets.py
"""

from __future__ import annotations

import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "logo.png")

UPSCALE = 8  # master resolution multiplier (source logo is tiny: 118x132)


def load_master() -> Image.Image:
    """Upscale the small source logo once, with a good resampling filter."""
    src = Image.open(SOURCE).convert("RGBA")
    return src.resize(
        (src.width * UPSCALE, src.height * UPSCALE), Image.Resampling.LANCZOS
    )


def square(master: Image.Image, size: int, fill_ratio: float) -> Image.Image:
    """Center the logo on a white square, occupying `fill_ratio` of the side."""
    canvas = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    target_h = int(size * fill_ratio)
    scale = target_h / master.height
    target_w = max(1, int(round(master.width * scale)))
    logo = master.resize((target_w, target_h), Image.Resampling.LANCZOS)
    canvas.paste(logo, ((size - target_w) // 2, (size - target_h) // 2), logo)
    return canvas


def ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def main() -> None:
    master = load_master()

    assets = os.path.join(ROOT, "assets")
    ensure_dir(os.path.join(assets, "images"))
    ensure_dir(os.path.join(assets, "icon"))
    ensure_dir(os.path.join(ROOT, "web", "icons"))

    # In-app logo (app bar, landing page). ~3x of the source, keeps small assets light.
    in_app = master.resize((118 * 3, 132 * 3), Image.Resampling.LANCZOS)
    in_app.save(os.path.join(assets, "images", "logo.png"), optimize=True)

    # Legacy / fallback launcher icon + Play Store listing icon.
    square(master, 1024, 0.70).convert("RGB").save(
        os.path.join(assets, "icon", "app_icon.png"), optimize=True
    )

    # Adaptive icon foreground: logo inside the 66dp safe zone of the 108dp viewport.
    square(master, 1024, 0.55).convert("RGB").save(
        os.path.join(assets, "icon", "app_icon_foreground.png"), optimize=True
    )

    # Android 12+ splash icon (drawn inside a circular mask, needs extra padding).
    square(master, 1152, 0.52).convert("RGB").save(
        os.path.join(assets, "images", "splash_logo.png"), optimize=True
    )

    # Android 12 splash icon must be transparent for the circular mask.
    splash_transparent = Image.new("RGBA", (1152, 1152), (0, 0, 0, 0))
    inner = square(master, 1152, 0.52).convert("RGBA")
    mask = Image.new("L", (1152, 1152), 0)
    mask.paste(inner.getchannel("A"))
    splash_transparent.paste(inner, (0, 0), inner)
    splash_transparent.save(
        os.path.join(assets, "images", "splash_icon.png"), optimize=True
    )

    # Web / PWA icons.
    square(master, 32, 0.92).convert("RGB").save(
        os.path.join(ROOT, "web", "favicon.png"), optimize=True
    )
    for size in (192, 512):
        square(master, size, 0.72).convert("RGB").save(
            os.path.join(ROOT, "web", "icons", f"Icon-{size}.png"), optimize=True
        )
        # Maskable icons must fill the whole square, logo kept inside the 80% safe zone.
        square(master, size, 0.58).convert("RGB").save(
            os.path.join(ROOT, "web", "icons", f"Icon-maskable-{size}.png"), optimize=True
        )

    print("Brand assets generated.")


if __name__ == "__main__":
    main()
