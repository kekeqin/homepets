from __future__ import annotations

import argparse
import re
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


DENSITY_DIR_RE = re.compile(r"^\d+(?:\.\d+)?x$")
DEFAULT_DENSITIES = (1.0, 2.0, 3.0)
PNG_SUFFIX = ".png"


@dataclass(frozen=True)
class SourceImage:
    path: Path
    relative_path: Path


@dataclass(frozen=True)
class VariantPlan:
    density: float
    source_path: Path
    target_path: Path
    target_size: tuple[int, int]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Generate Flutter PNG resolution variants from high-resolution source images. "
            "The 1x image is written at the base path, and higher densities are written "
            "under sibling directories such as 2.0x/ and 3.0x/."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  python scripts/generate_flutter_density_variants.py "
            "generated/home_paywall_4x.png "
            "--output app/assets/images/ui/home/home_paywall.png --source-scale 4\n\n"
            "  python scripts/generate_flutter_density_variants.py "
            "app/assets/images/ui/home/home_paywall.png --source-scale 4 "
            "--overwrite --backup-overwritten\n\n"
            "  python scripts/generate_flutter_density_variants.py generated/home_icons "
            "--output-dir app/assets/images/ui/home --source-scale 3 --recursive\n"
        ),
    )
    parser.add_argument(
        "sources",
        nargs="+",
        type=Path,
        help="PNG source files or directories containing PNG source files.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Exact base 1x output path. Only valid with one source file.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help=(
            "Directory for base 1x outputs. Directory source paths keep their relative "
            "subdirectories under this directory."
        ),
    )
    parser.add_argument(
        "--source-scale",
        type=float,
        default=3.0,
        help="Density scale of the source image relative to the 1x asset. Default: 3.",
    )
    parser.add_argument(
        "--densities",
        nargs="+",
        type=float,
        default=list(DEFAULT_DENSITIES),
        help="Target densities to generate. Default: 1 2 3.",
    )
    parser.add_argument(
        "--filter",
        choices=("lanczos", "bicubic", "bilinear", "nearest"),
        default="lanczos",
        help="Resize filter. Default: lanczos.",
    )
    parser.add_argument(
        "--recursive",
        action="store_true",
        help="Read PNG files recursively when a source path is a directory.",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Allow replacing existing output files.",
    )
    parser.add_argument(
        "--backup-overwritten",
        action="store_true",
        help="Create a backup next to each overwritten file.",
    )
    parser.add_argument(
        "--allow-upscale",
        action="store_true",
        help="Allow target densities larger than --source-scale.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print planned outputs without writing files.",
    )
    return parser.parse_args()


def collect_sources(inputs: list[Path], recursive: bool) -> list[SourceImage]:
    sources: list[SourceImage] = []
    for raw_path in inputs:
        path = raw_path.resolve()
        if path.is_file():
            if path.suffix.lower() != PNG_SUFFIX:
                raise ValueError(f"Only PNG files are supported: {raw_path}")
            sources.append(SourceImage(path=path, relative_path=Path(path.name)))
            continue

        if path.is_dir():
            pattern = "**/*.png" if recursive else "*.png"
            for candidate in sorted(path.glob(pattern)):
                if is_inside_density_dir(candidate):
                    continue
                sources.append(
                    SourceImage(
                        path=candidate.resolve(),
                        relative_path=candidate.relative_to(path),
                    )
                )
            continue

        raise FileNotFoundError(f"Source path does not exist: {raw_path}")

    if not sources:
        raise ValueError("No PNG source files found.")
    return sources


def is_inside_density_dir(path: Path) -> bool:
    return any(DENSITY_DIR_RE.match(part) for part in path.parts)


def validate_args(args: argparse.Namespace, sources: list[SourceImage]) -> None:
    if args.output and args.output_dir:
        raise ValueError("Use either --output or --output-dir, not both.")
    if args.output and len(sources) != 1:
        raise ValueError("--output is only valid with exactly one source file.")
    if args.source_scale <= 0:
        raise ValueError("--source-scale must be greater than zero.")
    if any(density <= 0 for density in args.densities):
        raise ValueError("All --densities values must be greater than zero.")
    if not args.allow_upscale:
        largest_density = max(args.densities)
        if largest_density > args.source_scale:
            raise ValueError(
                f"Largest target density ({largest_density:g}x) is greater than "
                f"source scale ({args.source_scale:g}x). Use --allow-upscale if this "
                "is intentional."
            )


def density_dir_name(density: float) -> str:
    if density.is_integer():
        return f"{int(density)}.0x"
    return f"{density:g}x"


def is_one_x(density: float) -> bool:
    return abs(density - 1.0) < 0.0001


def target_path_for(base_path: Path, density: float) -> Path:
    if is_one_x(density):
        return base_path
    return base_path.parent / density_dir_name(density) / base_path.name


def base_output_path_for(
    source: SourceImage,
    output: Path | None,
    output_dir: Path | None,
) -> Path:
    if output is not None:
        return output.resolve()
    if output_dir is not None:
        return (output_dir / source.relative_path).resolve()
    return source.path


def resampling_filter(name: str) -> Image.Resampling:
    filters = {
        "lanczos": Image.Resampling.LANCZOS,
        "bicubic": Image.Resampling.BICUBIC,
        "bilinear": Image.Resampling.BILINEAR,
        "nearest": Image.Resampling.NEAREST,
    }
    return filters[name]


def target_size(
    source_size: tuple[int, int],
    source_scale: float,
    density: float,
) -> tuple[int, int]:
    width, height = source_size
    scale = density / source_scale
    return max(1, round(width * scale)), max(1, round(height * scale))


def normalize_transparent_pixels(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha == 0:
                pixels[x, y] = (0, 0, 0, 0)
            else:
                pixels[x, y] = (red, green, blue, alpha)
    return rgba


def build_plan(args: argparse.Namespace, sources: list[SourceImage]) -> list[VariantPlan]:
    plans: list[VariantPlan] = []
    for source in sources:
        with Image.open(source.path) as image:
            source_size = image.size

        base_path = base_output_path_for(source, args.output, args.output_dir)
        for density in sorted(set(args.densities)):
            plans.append(
                VariantPlan(
                    density=density,
                    source_path=source.path,
                    target_path=target_path_for(base_path, density),
                    target_size=target_size(source_size, args.source_scale, density),
                )
            )
    return plans


def preflight_writes(plans: list[VariantPlan], overwrite: bool) -> None:
    blocked = [
        plan.target_path
        for plan in plans
        if plan.target_path.exists() and not overwrite
    ]
    if blocked:
        formatted = "\n".join(f"  {path}" for path in blocked)
        raise FileExistsError(
            "Output files already exist. Re-run with --overwrite if intended:\n"
            f"{formatted}"
        )


def backup_path_for(path: Path) -> Path:
    stem = f"{path.stem}.backup-before-density-variants"
    candidate = path.with_name(f"{stem}{path.suffix}")
    index = 2
    while candidate.exists():
        candidate = path.with_name(f"{stem}-{index}{path.suffix}")
        index += 1
    return candidate


def write_variants(args: argparse.Namespace, sources: list[SourceImage]) -> None:
    filter_method = resampling_filter(args.filter)
    for source in sources:
        base_path = base_output_path_for(source, args.output, args.output_dir)
        with Image.open(source.path) as opened:
            source_image = opened.convert("RGBA")

        for density in sorted(set(args.densities)):
            output_path = target_path_for(base_path, density)
            size = target_size(source_image.size, args.source_scale, density)
            if source_image.size == size:
                variant = source_image.copy()
            else:
                variant = source_image.resize(size, filter_method)
            variant = normalize_transparent_pixels(variant)

            if args.backup_overwritten and output_path.exists():
                backup_path = backup_path_for(output_path)
                shutil.copy2(output_path, backup_path)
                print(f"backup  {output_path} -> {backup_path}")

            output_path.parent.mkdir(parents=True, exist_ok=True)
            variant.save(output_path, format="PNG", compress_level=9)
            print(f"write   {density:g}x {output_path} {size[0]}x{size[1]}")


def print_plan(plans: list[VariantPlan]) -> None:
    for plan in plans:
        print(
            "dry-run "
            f"{plan.density:g}x {plan.source_path} -> {plan.target_path} "
            f"{plan.target_size[0]}x{plan.target_size[1]}"
        )


def main() -> int:
    args = parse_args()
    try:
        sources = collect_sources(args.sources, args.recursive)
        validate_args(args, sources)
        plans = build_plan(args, sources)
        if args.dry_run:
            print_plan(plans)
            return 0
        preflight_writes(plans, args.overwrite)
        write_variants(args, sources)
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
