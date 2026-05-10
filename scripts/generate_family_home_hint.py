from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
UI_DIR = ROOT / "app" / "assets" / "images" / "ui"
SOURCE = Path("C:/Users/Administrator/AppData/Local/Temp/ScreenShot_2026-05-06_004208_984.png")

LINE = "#4A3A2A"
TEXT = "#4A3326"
GOLD = "#D99A18"
GREEN = "#A9C68A"
SOFT = "#FFF8EA"
PINK = "#F6A5A5"
PANEL = "#FFFDF6"
SHADOW = (74, 58, 42, 68)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        "C:/Windows/Fonts/msyhbd.ttc" if bold else "C:/Windows/Fonts/msyh.ttc",
        "C:/Windows/Fonts/simhei.ttf" if bold else "C:/Windows/Fonts/simsun.ttc",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


def normalize_transparent(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                pixels[x, y] = (0, 0, 0, 0)
            else:
                pixels[x, y] = (r, g, b, a)
    return rgba


def wrap_text(text: str, max_chars: int) -> list[str]:
    lines: list[str] = []
    current = ""
    for char in text:
        if len(current) >= max_chars:
            lines.append(current)
            current = char
        else:
            current += char
    if current:
        lines.append(current)
    return lines


def bubble(
    overlay: Image.Image,
    xy: tuple[int, int],
    size: tuple[int, int],
    step: str,
    title: str,
    body: str,
    pointer: str,
    accent: str = GREEN,
) -> None:
    x, y = xy
    w, h = size
    layer = Image.new("RGBA", overlay.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    draw.rounded_rectangle((x + 3, y + 5, x + w + 3, y + h + 5), radius=18, fill=SHADOW)
    draw.rounded_rectangle((x, y, x + w, y + h), radius=18, fill=PANEL, outline=LINE, width=2)
    draw.rounded_rectangle((x + 12, y + 12, x + 42, y + 42), radius=12, fill=accent, outline=LINE, width=2)
    step_font = font(18, True)
    step_bbox = draw.textbbox((0, 0), step, font=step_font)
    draw.text(
        (x + 27 - (step_bbox[2] - step_bbox[0]) / 2, y + 27 - (step_bbox[3] - step_bbox[1]) / 2 - 2),
        step,
        font=step_font,
        fill=TEXT,
    )
    draw.text((x + 50, y + 10), title, font=font(18, True), fill=TEXT)
    line_y = y + 42
    for line in wrap_text(body, 11):
        draw.text((x + 18, line_y), line, font=font(14, True), fill=TEXT)
        line_y += 22
    if pointer == "down":
        points = [(x + w // 2 - 12, y + h - 1), (x + w // 2 + 12, y + h - 1), (x + w // 2, y + h + 22)]
    elif pointer == "left":
        points = [(x + 1, y + h // 2 - 12), (x + 1, y + h // 2 + 12), (x - 22, y + h // 2)]
    elif pointer == "right":
        points = [(x + w - 1, y + h // 2 - 12), (x + w - 1, y + h // 2 + 12), (x + w + 22, y + h // 2)]
    else:
        points = [(x + w // 2 - 12, y + 1), (x + w // 2 + 12, y + 1), (x + w // 2, y - 22)]
    draw.polygon(points, fill=PANEL, outline=LINE)
    overlay.alpha_composite(layer)


def highlighter(overlay: Image.Image, box: tuple[int, int, int, int], color: str = GOLD) -> None:
    x1, y1, x2, y2 = box
    glow = Image.new("RGBA", overlay.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.rounded_rectangle((x1 - 3, y1 - 3, x2 + 3, y2 + 3), radius=18, outline=color, width=10)
    glow = glow.filter(ImageFilter.GaussianBlur(3))
    overlay.alpha_composite(glow)
    draw = ImageDraw.Draw(overlay)
    draw.rounded_rectangle((x1, y1, x2, y2), radius=18, outline=color, width=4)


def arrow(overlay: Image.Image, start: tuple[int, int], end: tuple[int, int], color: str = LINE) -> None:
    draw = ImageDraw.Draw(overlay)
    sx, sy = start
    ex, ey = end
    mx = (sx + ex) // 2
    my = (sy + ey) // 2
    # Hand-drawn looking two-segment arrow with a slight bend.
    bend = (mx + int(math.sin((sx + sy) * 0.05) * 8), my - 8)
    draw.line((sx, sy, bend[0], bend[1], ex, ey), fill=color, width=4, joint="curve")
    angle = math.atan2(ey - bend[1], ex - bend[0])
    length = 13
    left = (ex - length * math.cos(angle - 0.55), ey - length * math.sin(angle - 0.55))
    right = (ex - length * math.cos(angle + 0.55), ey - length * math.sin(angle + 0.55))
    draw.polygon([(ex, ey), left, right], fill=color)


def dim_background(base: Image.Image, cutouts: list[tuple[int, int, int, int]]) -> Image.Image:
    bg = base.convert("RGBA")
    dim = Image.new("RGBA", bg.size, (68, 52, 34, 92))
    mask = Image.new("L", bg.size, 255)
    draw = ImageDraw.Draw(mask)
    for box in cutouts:
        draw.rounded_rectangle(box, radius=20, fill=0)
    mask = mask.filter(ImageFilter.GaussianBlur(2))
    dim.putalpha(mask)
    bg.alpha_composite(dim)
    return bg


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    scale = 2
    base = source.resize((source.width * scale, source.height * scale), Image.Resampling.LANCZOS)
    w, h = base.size

    # Coordinates are based on the current family page screenshot after 2x scaling.
    family_title = (58, 92, 360, 152)
    stats = (64, 158, 376, 208)
    add_member = (62, 218, 356, 306)
    child_card = (402, 430, 738, 780)
    pager = (290, 1166, 490, 1218)

    preview = dim_background(base, [family_title, stats, add_member, child_card, pager])
    overlay = Image.new("RGBA", preview.size, (0, 0, 0, 0))

    highlighter(overlay, family_title, GREEN)
    highlighter(overlay, stats, GREEN)
    highlighter(overlay, add_member, GOLD)
    highlighter(overlay, child_card, "#F2D27B")
    highlighter(overlay, pager, PINK)

    bubble(overlay, (405, 42), (300, 118), "1", "家庭概览", "家庭名旁可编辑；下方查看成员、宠物和星星", "left", GREEN)
    bubble(overlay, (382, 188), (312, 112), "2", "添加成员", "邀请家人加入，一起照顾宠物", "left", GOLD)
    bubble(overlay, (70, 474), (292, 124), "3", "点击卡片", "进入成员详情，查看任务和宠物成长", "right", "#F2D27B")
    bubble(overlay, (218, 1032), (320, 110), "4", "左右切换", "滑动查看更多家庭成员", "down", PINK)

    arrow(overlay, (406, 100), (342, 120), GREEN)
    arrow(overlay, (382, 246), (342, 260), GOLD)
    arrow(overlay, (360, 536), (430, 520), LINE)
    arrow(overlay, (374, 1138), (386, 1188), PINK)

    draw = ImageDraw.Draw(overlay)
    draw.rounded_rectangle((64, 30, 210, 76), radius=23, fill="#FFF8EA", outline=LINE, width=2)
    draw.text((86, 42), "新手引导", font=font(20, True), fill=TEXT)

    preview.alpha_composite(overlay)

    UI_DIR.mkdir(parents=True, exist_ok=True)
    preview = normalize_transparent(preview)
    overlay = normalize_transparent(overlay)
    preview.save(UI_DIR / "family_home_operation_hint_preview.png")
    overlay.save(UI_DIR / "family_home_operation_hint_overlay.png")


if __name__ == "__main__":
    main()
