from __future__ import annotations

import json
import math
import re
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
UI_DIR = ROOT / "app" / "assets" / "images" / "ui"
SPRITE_DIR = UI_DIR / "sprites"

LINE = "#4A3A2A"
TEXT = "#4A3326"
GOLD = "#B77A12"
SOFT_BG = "#FFF8EA"
WARM = "#F6E6C8"
PANEL = "#FFFDF6"
CARD = "#FFF9EE"
GREEN = "#A9C68A"
CARD_LINE = "#D8BFA6"
SELECTED = "#D99A18"
CHEEK = "#F6A5A5"
CAT_ORANGE = "#DFA15E"
DOG_TAN = "#E8B96C"


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


def save(img: Image.Image, name: str, meta: dict[str, object]) -> None:
    SPRITE_DIR.mkdir(parents=True, exist_ok=True)
    output = SPRITE_DIR / name
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    pixels = img.load()
    width, height = img.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                pixels[x, y] = (0, 0, 0, 0)
            else:
                pixels[x, y] = (r, g, b, a)
    img.save(output)
    bbox = img.getbbox()
    meta[name] = {
        "width": width,
        "height": height,
        "bbox": list(bbox) if bbox else None,
    }


def crop_alpha(img: Image.Image, pad: int = 8) -> Image.Image:
    rgba = img.convert("RGBA")
    alpha = rgba.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return rgba
    left, top, right, bottom = bbox
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(rgba.width, right + pad)
    bottom = min(rgba.height, bottom + pad)
    return rgba.crop((left, top, right, bottom))


def square_crop(img: Image.Image, size: int = 512) -> Image.Image:
    rgba = crop_alpha(img, 4)
    side = max(rgba.width, rgba.height)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.alpha_composite(rgba, ((side - rgba.width) // 2, (side - rgba.height) // 2))
    return canvas.resize((size, size), Image.Resampling.LANCZOS)


def crop_non_black(img: Image.Image, pad: int = 8) -> Image.Image:
    rgba = img.convert("RGBA")
    alpha = rgba.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return rgba
    left, top, right, bottom = bbox
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(rgba.width, right + pad)
    bottom = min(rgba.height, bottom + pad)
    return rgba.crop((left, top, right, bottom))


def make_text_png(text: str, size: int, color: str = TEXT, bold: bool = True, pad: int = 12) -> Image.Image:
    fnt = font(size, bold)
    probe = Image.new("RGBA", (1, 1))
    draw = ImageDraw.Draw(probe)
    bbox = draw.textbbox((0, 0), text, font=fnt)
    width = bbox[2] - bbox[0] + pad * 2
    height = bbox[3] - bbox[1] + pad * 2
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.text((pad - bbox[0], pad - bbox[1]), text, font=fnt, fill=color)
    return crop_alpha(img, 2)


def rounded_rect(size: tuple[int, int], radius: int, fill: str, outline: str, width: int) -> Image.Image:
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    inset = width // 2 + 1
    draw.rounded_rectangle(
        (inset, inset, size[0] - inset - 1, size[1] - inset - 1),
        radius=radius,
        fill=fill,
        outline=outline,
        width=width,
    )
    return img


def pill(size: tuple[int, int], fill: str, outline: str, width: int) -> Image.Image:
    return rounded_rect(size, size[1] // 2, fill, outline, width)


def center_text(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], text: str, fnt: ImageFont.ImageFont, fill: str) -> None:
    bbox = draw.textbbox((0, 0), text, font=fnt)
    x = box[0] + (box[2] - box[0] - (bbox[2] - bbox[0])) / 2 - bbox[0]
    y = box[1] + (box[3] - box[1] - (bbox[3] - bbox[1])) / 2 - bbox[1]
    draw.text((x, y), text, font=fnt, fill=fill)


def compose_avatar_card(avatar: Image.Image, label: str, selected: bool = False) -> Image.Image:
    img = rounded_rect(
        (220, 260),
        34,
        "#FFF8EB",
        SELECTED if selected else CARD_LINE,
        5 if selected else 3,
    )
    draw = ImageDraw.Draw(img)
    avatar_img = avatar.resize((150, 150), Image.Resampling.LANCZOS)
    img.alpha_composite(avatar_img, (35, 22))
    fnt = font(36, True)
    center_text(draw, (12, 185, 208, 245), label, fnt, TEXT)
    return img


def make_circle_frame(size: int, fill: str = WARM, outline: str = LINE, width: int = 4) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    inset = width // 2 + 2
    draw.ellipse((inset, inset, size - inset - 1, size - inset - 1), fill=fill, outline=outline, width=width)
    return img


def make_level_badge() -> Image.Image:
    img = pill((146, 54), "#D7D98E", "#99A65A", 4)
    draw = ImageDraw.Draw(img)
    center_text(draw, (0, 0, 146, 54), "Lv. 3", font(26, True), TEXT)
    return img


def make_change_avatar_button() -> Image.Image:
    img = rounded_rect((290, 94), 36, "#FFF8EC", LINE, 4)
    draw = ImageDraw.Draw(img)
    center_text(draw, (0, 0, 290, 94), "更换头像", font(38, True), TEXT)
    return img


def make_bottom_sheet_panel() -> Image.Image:
    size = (941, 1138)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((-2, 0, 943, 1142), radius=82, fill=PANEL, outline=LINE, width=4)
    return img


def make_divider() -> Image.Image:
    img = Image.new("RGBA", (852, 12), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    y = 6
    x = 0
    while x < 852:
        draw.line((x, y, min(x + 16, 852), y), fill="#E0B46D", width=2)
        x += 22
    return img


def make_simple_cat() -> Image.Image:
    img = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse((72, 68, 440, 432), fill="#FFF9E9", outline=LINE, width=5)
    draw.polygon([(128, 150), (162, 72), (203, 153)], fill="#F7C7AA", outline=LINE)
    draw.line([(128, 150), (162, 72), (203, 153)], fill=LINE, width=5, joint="curve")
    draw.polygon([(309, 153), (351, 72), (386, 150)], fill="#F7C7AA", outline=LINE)
    draw.line([(309, 153), (351, 72), (386, 150)], fill=LINE, width=5, joint="curve")
    draw.pieslice((105, 40, 295, 248), 190, 342, fill=CAT_ORANGE)
    draw.pieslice((248, 40, 420, 245), 202, 350, fill=CAT_ORANGE)
    draw.ellipse((137, 262, 185, 306), fill=CHEEK)
    draw.ellipse((327, 262, 375, 306), fill=CHEEK)
    draw.ellipse((181, 206, 213, 246), fill=LINE)
    draw.ellipse((300, 206, 332, 246), fill=LINE)
    draw.polygon([(251, 253), (269, 253), (260, 266)], fill=LINE)
    draw.arc((232, 254, 260, 294), 20, 130, fill=LINE, width=4)
    draw.arc((260, 254, 288, 294), 50, 160, fill=LINE, width=4)
    for y in (244, 270):
        draw.line((88, y, 153, y + 6), fill=LINE, width=4)
        draw.line((359, y + 6, 424, y), fill=LINE, width=4)
    draw.arc((75, 70, 438, 433), 0, 360, fill=LINE, width=5)
    return img.filter(ImageFilter.SMOOTH_MORE)


def make_simple_dog() -> Image.Image:
    img = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse((84, 96, 428, 420), fill="#FFF5DD", outline=LINE, width=5)
    draw.ellipse((84, 120, 194, 295), fill=DOG_TAN, outline=LINE, width=5)
    draw.ellipse((318, 120, 428, 295), fill=DOG_TAN, outline=LINE, width=5)
    draw.rectangle((132, 118, 380, 245), fill="#FFF5DD")
    draw.pieslice((101, 86, 260, 265), 160, 345, fill=DOG_TAN)
    draw.pieslice((253, 86, 411, 265), 195, 20, fill=DOG_TAN)
    draw.ellipse((142, 263, 190, 306), fill="#F8D6B3")
    draw.ellipse((322, 263, 370, 306), fill="#F8D6B3")
    draw.ellipse((181, 214, 213, 254), fill=LINE)
    draw.ellipse((300, 214, 332, 254), fill=LINE)
    draw.ellipse((240, 260, 276, 286), fill=LINE)
    draw.arc((226, 274, 260, 315), 20, 130, fill=LINE, width=4)
    draw.arc((260, 274, 294, 315), 50, 160, fill=LINE, width=4)
    draw.arc((84, 96, 428, 420), 0, 360, fill=LINE, width=5)
    return img.filter(ImageFilter.SMOOTH_MORE)


def make_simple_rabbit() -> Image.Image:
    img = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((126, 35, 188, 255), radius=31, fill="#FFFDF4", outline=LINE, width=5)
    draw.rounded_rectangle((324, 35, 386, 255), radius=31, fill="#FFFDF4", outline=LINE, width=5)
    draw.rounded_rectangle((145, 70, 172, 212), radius=14, fill="#F8B7A8")
    draw.rounded_rectangle((340, 70, 367, 212), radius=14, fill="#F8B7A8")
    draw.ellipse((82, 142, 430, 430), fill="#FFFDF4", outline=LINE, width=5)
    draw.ellipse((142, 272, 190, 315), fill="#F8D6C7")
    draw.ellipse((322, 272, 370, 315), fill="#F8D6C7")
    draw.ellipse((177, 230, 209, 270), fill=LINE)
    draw.ellipse((303, 230, 335, 270), fill=LINE)
    draw.polygon([(247, 282), (265, 282), (256, 295)], fill=LINE)
    draw.arc((229, 292, 256, 326), 20, 130, fill=LINE, width=4)
    draw.arc((256, 292, 283, 326), 50, 160, fill=LINE, width=4)
    draw.rounded_rectangle((342, 336, 456, 374), radius=18, fill="#F2B1A6", outline=LINE, width=4)
    draw.polygon([(399, 354), (458, 318), (462, 392)], fill="#F2B1A6", outline=LINE)
    return img.filter(ImageFilter.SMOOTH_MORE)


def transparent_from_avatar_screen() -> dict[str, Image.Image]:
    source = Image.open(UI_DIR / "avatar_edit_screen.png").convert("RGBA")
    crops = {
        "pet_cat_head": (348, 800, 586, 946),
        "pet_dog_head": (632, 830, 838, 945),
        "pet_rabbit_head": (112, 1064, 295, 1206),
    }
    result: dict[str, Image.Image] = {}
    for key, box in crops.items():
        crop = source.crop(box).convert("RGBA")
        pixels = crop.load()
        for y in range(crop.height):
            for x in range(crop.width):
                r, g, b, a = pixels[x, y]
                if r > 238 and g > 226 and b > 205:
                    pixels[x, y] = (0, 0, 0, 0)
                else:
                    pixels[x, y] = (r, g, b, a)
        crop = crop.filter(ImageFilter.SMOOTH)
        crop = crop_alpha(crop, 16)
        result[key] = square_crop(crop, 512)
    return result


def make_pet_avatar(name: str, fallback: Image.Image) -> Image.Image:
    # The pet heads in the older full-screen mockup sit on textured card backgrounds,
    # which leaves noisy matte residue when extracted. Use clean rebuilt heads instead.
    return fallback


def make_card_label_texts(labels: list[str]) -> dict[str, Image.Image]:
    return {label: make_text_png(label, 42, TEXT, True, 6) for label in labels}


def make_profile_header(avatar: Image.Image) -> Image.Image:
    img = Image.new("RGBA", (760, 370), (0, 0, 0, 0))
    large = avatar.resize((300, 300), Image.Resampling.LANCZOS)
    img.alpha_composite(large, (45, 20))
    img.alpha_composite(make_text_png("小宝", 64, TEXT, True), (410, 70))
    img.alpha_composite(make_level_badge(), (410, 158))
    img.alpha_composite(make_change_avatar_button(), (404, 250))
    return crop_alpha(img, 12)


def make_large_selected_avatar(avatar: Image.Image) -> Image.Image:
    img = Image.new("RGBA", (340, 340), (0, 0, 0, 0))
    img.alpha_composite(avatar.resize((316, 316), Image.Resampling.LANCZOS), (12, 12))
    return crop_alpha(img, 4)


def make_manifest(meta: dict[str, object]) -> None:
    manifest = {
        "source": "Derived from HomePets avatar artwork and rebuilt UI sprites for the user-provided avatar picker reference.",
        "style": {
            "line": LINE,
            "line_width": "2-4px equivalent at mobile scale",
            "palette": [WARM, GREEN, "#C79B6E", CHEEK, "#F2D27B", "#E9E9E9", CARD_LINE, "#8FAF7A"],
            "negative": (
                "vector graphic, perfect geometry, perfect circle, perfect ellipse, perfect rectangle, "
                "clean vector line, geometric precision, 3D render, realistic lighting, photorealistic, "
                "complex shading, high detail rendering, sharp edges, hard mechanical shapes, SVG icon style, "
                "gradient, dramatic contrast, realistic texture, industrial design, overly detailed background, "
                "burrs, jagged edges, pixelated edges, frayed line edges, spiky artifacts, noisy outlines, "
                "cutout fringe, fuzzy halo, leftover background pixels, white outer rim, unwanted white outline, "
                "outer glow, hidden RGB fringe, chroma-key contamination"
            ),
        },
        "assets": meta,
    }
    (SPRITE_DIR / "avatar_edit_parts_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def make_preview(asset_names: list[str]) -> None:
    thumbs: list[tuple[str, Image.Image]] = []
    for name in asset_names:
        path = SPRITE_DIR / name
        if not path.exists():
            continue
        img = Image.open(path).convert("RGBA")
        img.thumbnail((136, 136), Image.Resampling.LANCZOS)
        thumbs.append((name.removeprefix("avatar_edit_").removesuffix(".png"), img.copy()))

    cols = 5
    cell_w = 190
    cell_h = 184
    rows = math.ceil(len(thumbs) / cols)
    preview = Image.new("RGBA", (cols * cell_w, rows * cell_h), "#FFF6E8")
    draw = ImageDraw.Draw(preview)
    label_font = font(15, False)
    for index, (label, thumb) in enumerate(thumbs):
        col = index % cols
        row = index // cols
        x = col * cell_w
        y = row * cell_h
        draw.rounded_rectangle(
            (x + 8, y + 8, x + cell_w - 8, y + cell_h - 8),
            radius=18,
            fill="#FFFCF3",
            outline="#E2CBAA",
            width=2,
        )
        checker = Image.new("RGBA", (136, 136), (0, 0, 0, 0))
        cd = ImageDraw.Draw(checker)
        for cy in range(0, 136, 16):
            for cx in range(0, 136, 16):
                cd.rectangle(
                    (cx, cy, cx + 15, cy + 15),
                    fill="#F0DFC7" if (cx // 16 + cy // 16) % 2 else "#FFF8EA",
                )
        px = x + (cell_w - 136) // 2
        py = y + 18
        preview.alpha_composite(checker, (px, py))
        preview.alpha_composite(thumb, (x + (cell_w - thumb.width) // 2, py + (136 - thumb.height) // 2))
        label = re.sub(r"[_-]+", " ", label)
        if len(label) > 20:
            label = label[:19] + "…"
        bbox = draw.textbbox((0, 0), label, font=label_font)
        draw.text(
            (x + (cell_w - (bbox[2] - bbox[0])) / 2, y + 158),
            label,
            font=label_font,
            fill=TEXT,
        )
    preview.convert("RGB").save(SPRITE_DIR / "avatar_edit_parts_preview.png")


def main() -> None:
    meta: dict[str, object] = {}
    asset_names: list[str] = []

    avatars = {
        "default": square_crop(Image.open(UI_DIR / "avatar_boy_green_shirt.png")),
        "dad": square_crop(Image.open(UI_DIR / "avatar_adult_male_glasses.png")),
        "mom": square_crop(Image.open(UI_DIR / "avatar_adult_female_apron.png")),
        "boy": square_crop(Image.open(UI_DIR / "avatar_boy_blue_hoodie.png")),
        "girl": square_crop(Image.open(UI_DIR / "avatar_girl_braids.png")),
        "cat": make_pet_avatar("pet_cat_head", make_simple_cat()),
        "dog": make_pet_avatar("pet_dog_head", make_simple_dog()),
        "rabbit": make_pet_avatar("pet_rabbit_head", make_simple_rabbit()),
    }

    for name, avatar in avatars.items():
        asset_name = f"avatar_edit_{name}_avatar.png"
        save(avatar, asset_name, meta)
        asset_names.append(asset_name)

    labels = {
        "default": "默认",
        "dad": "爸爸",
        "mom": "妈妈",
        "boy": "男孩",
        "girl": "女孩",
        "cat": "猫猫",
        "dog": "狗狗",
        "rabbit": "兔兔",
    }
    for key, label in labels.items():
        asset_name = f"avatar_edit_label_{key}.png"
        save(make_text_png(label, 42, TEXT, True, 6), asset_name, meta)
        asset_names.append(asset_name)
        asset_name = f"avatar_edit_card_{key}.png"
        save(
            compose_avatar_card(avatars[key], label, selected=key == "default"),
            asset_name,
            meta,
        )
        asset_names.append(asset_name)

    extras = [
        ("avatar_edit_profile_header_xiaobao.png", make_profile_header(avatars["default"])),
        ("avatar_edit_selected_avatar_large.png", make_large_selected_avatar(avatars["default"])),
        ("avatar_edit_level_badge_lv3.png", make_level_badge()),
        ("avatar_edit_change_avatar_button.png", make_change_avatar_button()),
        ("avatar_edit_bottom_sheet_panel.png", make_bottom_sheet_panel()),
        ("avatar_edit_dashed_divider.png", make_divider()),
        ("avatar_edit_action_cancel.png", make_text_png("取消", 44, TEXT, True)),
        ("avatar_edit_title_change_avatar.png", make_text_png("更换头像", 48, TEXT, True)),
        ("avatar_edit_action_save.png", make_text_png("保存", 44, GOLD, True)),
        ("avatar_edit_profile_name_xiaobao.png", make_text_png("小宝", 64, TEXT, True)),
    ]
    for asset_name, image in extras:
        save(image, asset_name, meta)
        asset_names.append(asset_name)

    make_manifest(meta)
    make_preview(asset_names)


if __name__ == "__main__":
    main()
