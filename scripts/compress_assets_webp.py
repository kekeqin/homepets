#!/usr/bin/env python3
"""Compress app image assets to WebP without dropping animation frames.

- Converts PNG/JPEG under app/assets to .webp (same basename)
- Does not change frame counts
- Does not resize sprite sheets that have a sibling .json atlas
- Optional mild max-edge clamp for oversized standalone images
- Deletes the source PNG/JPEG after a successful write
"""

from __future__ import annotations

import argparse
import sys
import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path

from PIL import Image

# Repo root = parent of scripts/
ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ASSET_ROOT = ROOT / "app" / "assets"

# Optional mild downscale for huge standalone bitmaps. Disabled by default
# (--no-resize) so hardcoded layout sizes in Flutter stay valid.
# Atlases (sibling .json) are never resized even when max-edge is set.
DEFAULT_MAX_EDGE_BY_PREFIX = {
    "images/pets/act/": 640,
    "images/pets/grow/": 1024,
    "images/ui/": 1600,
    "scenes/": 1600,
}

SKIP_DIR_NAMES = {"audio", "fonts"}


@dataclass(frozen=True)
class JobResult:
    src: str
    dst: str
    ok: bool
    orig_bytes: int
    new_bytes: int
    resized: bool
    message: str = ""


def _posix_rel(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def _is_atlas_sheet(path: Path) -> bool:
    """True if a TexturePacker-style JSON sits next to this image."""
    return path.with_suffix(".json").is_file()


def _max_edge_for(
    rel_posix: str,
    path: Path,
    *,
    allow_resize: bool,
    max_edge_by_prefix: dict[str, int],
) -> int | None:
    if not allow_resize:
        return None
    if _is_atlas_sheet(path):
        return None
    name = path.name.lower()
    if "sheet" in name and path.with_suffix(".json").exists():
        return None
    for prefix, edge in max_edge_by_prefix.items():
        if rel_posix.startswith(prefix):
            return edge
    return 1600


def _resize_if_needed(im: Image.Image, max_edge: int | None) -> tuple[Image.Image, bool]:
    if max_edge is None:
        return im, False
    w, h = im.size
    longest = max(w, h)
    if longest <= max_edge:
        return im, False
    scale = max_edge / longest
    nw = max(1, int(round(w * scale)))
    nh = max(1, int(round(h * scale)))
    return im.resize((nw, nh), Image.Resampling.LANCZOS), True


def convert_one(
    src_str: str,
    asset_root_str: str,
    quality: int,
    method: int,
    dry_run: bool,
    allow_resize: bool = False,
) -> JobResult:
    src = Path(src_str)
    asset_root = Path(asset_root_str)
    rel = _posix_rel(src, asset_root)
    dst = src.with_suffix(".webp")
    orig = src.stat().st_size

    try:
        with Image.open(src) as raw:
            im = raw.convert("RGBA")
            max_edge = _max_edge_for(
                rel,
                src,
                allow_resize=allow_resize,
                max_edge_by_prefix=DEFAULT_MAX_EDGE_BY_PREFIX,
            )
            im, resized = _resize_if_needed(im, max_edge)

            if dry_run:
                import io

                buf = io.BytesIO()
                im.save(buf, format="WEBP", quality=quality, method=method)
                new_size = len(buf.getvalue())
                return JobResult(
                    src=rel,
                    dst=dst.name,
                    ok=True,
                    orig_bytes=orig,
                    new_bytes=new_size,
                    resized=resized,
                    message="dry-run",
                )

            tmp = dst.with_suffix(".webp.tmp")
            im.save(tmp, format="WEBP", quality=quality, method=method)
            new_size = tmp.stat().st_size
            if dst.exists():
                dst.unlink()
            tmp.replace(dst)
            if src.resolve() != dst.resolve() and src.exists():
                src.unlink()
            return JobResult(
                src=rel,
                dst=_posix_rel(dst, asset_root),
                ok=True,
                orig_bytes=orig,
                new_bytes=new_size,
                resized=resized,
            )
    except Exception as exc:  # noqa: BLE001 - batch job boundary
        return JobResult(
            src=rel,
            dst=str(dst),
            ok=False,
            orig_bytes=orig,
            new_bytes=0,
            resized=False,
            message=str(exc),
        )


def iter_images(asset_root: Path) -> list[Path]:
    out: list[Path] = []
    for path in asset_root.rglob("*"):
        if not path.is_file():
            continue
        if any(part in SKIP_DIR_NAMES for part in path.parts):
            continue
        if path.suffix.lower() in {".png", ".jpg", ".jpeg"}:
            out.append(path)
    return sorted(out)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--asset-root",
        type=Path,
        default=DEFAULT_ASSET_ROOT,
        help="Asset root to compress (default: app/assets)",
    )
    parser.add_argument("--quality", type=int, default=82)
    parser.add_argument("--method", type=int, default=4, help="WebP effort 0-6")
    parser.add_argument("--workers", type=int, default=0, help="0 = cpu count")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--allow-resize",
        action="store_true",
        help="Enable mild max-edge downscale (off by default)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Only process first N files (debug)",
    )
    args = parser.parse_args()

    asset_root = args.asset_root.resolve()
    if not asset_root.is_dir():
        print(f"Asset root not found: {asset_root}", file=sys.stderr)
        return 1

    images = iter_images(asset_root)
    if args.limit > 0:
        images = images[: args.limit]

    if not images:
        print("No PNG/JPEG images found.")
        return 0

    import os

    workers = args.workers or min(8, os.cpu_count() or 4)

    print(
        f"Compressing {len(images)} images under {asset_root} "
        f"(quality={args.quality}, method={args.method}, workers={workers}, "
        f"allow_resize={args.allow_resize}, dry_run={args.dry_run})"
    )
    t0 = time.time()
    results: list[JobResult] = []

    with ProcessPoolExecutor(max_workers=workers) as pool:
        futures = [
            pool.submit(
                convert_one,
                str(p),
                str(asset_root),
                args.quality,
                args.method,
                args.dry_run,
                args.allow_resize,
            )
            for p in images
        ]
        done = 0
        for fut in as_completed(futures):
            results.append(fut.result())
            done += 1
            if done % 50 == 0 or done == len(futures):
                print(f"  progress {done}/{len(futures)}")

    ok = [r for r in results if r.ok]
    bad = [r for r in results if not r.ok]
    orig_total = sum(r.orig_bytes for r in ok)
    new_total = sum(r.new_bytes for r in ok)
    resized_n = sum(1 for r in ok if r.resized)

    print("\n=== Summary ===")
    print(f"OK: {len(ok)}  Failed: {len(bad)}")
    print(f"Resized (mild max-edge): {resized_n}")
    print(f"Original: {orig_total / (1024 * 1024):.2f} MB")
    print(f"WebP:     {new_total / (1024 * 1024):.2f} MB")
    if orig_total:
        print(f"Ratio:    {new_total / orig_total * 100:.1f}% of original")
    print(f"Elapsed:  {time.time() - t0:.1f}s")

    if bad:
        print("\nFailures:")
        for r in bad[:20]:
            print(f"  {r.src}: {r.message}")
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
