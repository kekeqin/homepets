from __future__ import annotations

import os
import time
from pathlib import Path

SERVER_URL = os.getenv("COMFYUI_SERVER_URL", "http://127.0.0.1:8188")
COMFYUI_ROOT = Path(os.getenv("COMFYUI_ROOT", r"F:\AI_Tools\ComfyUI"))

UNET_NAME = "flux-2-klein-base-4b-fp8.safetensors"
CLIP_NAME = "qwen_3_4b_fp4_flux2.safetensors"
VAE_NAME = "flux2-vae.safetensors"

# HomePets 素材以统一、干净、偏平面卡通为主，默认参数偏向稳定和出图速度。
DEFAULT_STEPS = int(os.getenv("COMFYUI_FULL_STEPS", "28"))
DEFAULT_CFG = float(os.getenv("COMFYUI_FULL_CFG", "4.0"))
DEFAULT_SAMPLER = os.getenv("COMFYUI_FULL_SAMPLER", "euler")
DEFAULT_NEGATIVE_PROMPT = os.getenv(
    "COMFYUI_NEGATIVE_PROMPT",
    "blurry, low quality, low detail, deformed, bad anatomy, extra limbs, extra fingers, text, watermark, logo, messy background",
)

MODEL_PATHS = {
    "unet": COMFYUI_ROOT / "models" / "diffusion_models" / UNET_NAME,
    "clip": COMFYUI_ROOT / "models" / "text_encoders" / CLIP_NAME,
    "vae": COMFYUI_ROOT / "models" / "vae" / VAE_NAME,
}


def ensure_models_present() -> None:
    missing = [str(path) for path in MODEL_PATHS.values() if not path.exists()]
    if missing:
        raise FileNotFoundError(
            "Missing required local ComfyUI models:\n" + "\n".join(missing)
        )


def _round_to_multiple(value: int, base: int = 64) -> int:
    return max(base, ((int(value) + base - 1) // base) * base)


def _internal_generation_size(width: int, height: int) -> tuple[int, int]:
    target_max = max(width, height)
    target_min = min(width, height)

    if target_max <= 128:
        internal_max = 768
    elif target_max <= 512:
        internal_max = 1536
    elif target_max <= 768:
        internal_max = 1536
    else:
        internal_max = _round_to_multiple(int(target_max * 1.25))

    scale = internal_max / float(target_max)
    gen_width = _round_to_multiple(max(int(round(width * scale)), target_min))
    gen_height = _round_to_multiple(max(int(round(height * scale)), target_min))
    return gen_width, gen_height


def create_workflow(prompt: str, width: int = 512, height: int = 512, seed: int | None = None) -> dict:
    if seed is None:
        seed = int(time.time()) % 1_000_000

    gen_width, gen_height = _internal_generation_size(width, height)

    return {
        "6": {
            "inputs": {"text": prompt, "clip": ["11", 0]},
            "class_type": "CLIPTextEncode",
            "_meta": {"title": "CLIP Text Encode (Positive Prompt)"},
        },
        "7": {
            "inputs": {"text": DEFAULT_NEGATIVE_PROMPT, "clip": ["11", 0]},
            "class_type": "CLIPTextEncode",
            "_meta": {"title": "CLIP Text Encode (Negative Prompt)"},
        },
        "8": {
            "inputs": {"samples": ["13", 0], "vae": ["10", 0]},
            "class_type": "VAEDecode",
            "_meta": {"title": "VAE Decode"},
        },
        "9": {
            "inputs": {"filename_prefix": "flux2_pet", "images": ["14", 0]},
            "class_type": "SaveImage",
            "_meta": {"title": "Save Image"},
        },
        "10": {
            "inputs": {"vae_name": VAE_NAME},
            "class_type": "VAELoader",
            "_meta": {"title": "Load VAE"},
        },
        "11": {
            "inputs": {
                "clip_name": CLIP_NAME,
                "type": "flux2",
                "device": "default",
            },
            "class_type": "CLIPLoader",
            "_meta": {"title": "Load CLIP"},
        },
        "12": {
            "inputs": {
                "unet_name": UNET_NAME,
                "weight_dtype": "default",
            },
            "class_type": "UNETLoader",
            "_meta": {"title": "Load Diffusion Model"},
        },
        "13": {
            "inputs": {
                "noise": ["25", 0],
                "guider": ["22", 0],
                "sampler": ["16", 0],
                "sigmas": ["17", 0],
                "latent_image": ["27", 0],
            },
            "class_type": "SamplerCustomAdvanced",
            "_meta": {"title": "SamplerCustomAdvanced"},
        },
        "14": {
            "inputs": {
                "image": ["8", 0],
                "upscale_method": "lanczos",
                "width": width,
                "height": height,
                "crop": "disabled",
            },
            "class_type": "ImageScale",
            "_meta": {"title": "Resize To Target"},
        },
        "16": {
            "inputs": {"sampler_name": DEFAULT_SAMPLER},
            "class_type": "KSamplerSelect",
            "_meta": {"title": "KSamplerSelect"},
        },
        "17": {
            "inputs": {
                "steps": DEFAULT_STEPS,
                "width": gen_width,
                "height": gen_height,
            },
            "class_type": "Flux2Scheduler",
            "_meta": {"title": "Flux2Scheduler"},
        },
        "22": {
            "inputs": {
                "model": ["12", 0],
                "positive": ["6", 0],
                "negative": ["7", 0],
                "cfg": DEFAULT_CFG,
            },
            "class_type": "CFGGuider",
            "_meta": {"title": "CFGGuider"},
        },
        "25": {
            "inputs": {"noise_seed": seed},
            "class_type": "RandomNoise",
            "_meta": {"title": "RandomNoise"},
        },
        "27": {
            "inputs": {"width": gen_width, "height": gen_height, "batch_size": 1},
            "class_type": "EmptyFlux2LatentImage",
            "_meta": {"title": "Empty Flux2 Latent Image"},
        },
    }
