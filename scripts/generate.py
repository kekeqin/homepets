"""拾星小宠 动物形象生成器 - Flux.2 API"""

import requests
import time
import uuid
import os
import sys

from comfy_full_workflow_local import SERVER_URL, create_workflow, ensure_models_present
ASSETS_DIR = r"C:\Users\Administrator\Desktop\pickstarpet\app\assets\images"

os.makedirs(os.path.join(ASSETS_DIR, "pets"), exist_ok=True)
os.makedirs(os.path.join(ASSETS_DIR, "icons"), exist_ok=True)
ensure_models_present()


def generate(prompt, name, size=512):
    print(f"[生成] {name} ({size}x{size})")

    workflow = create_workflow(prompt, size, size)
    prompt_id = str(uuid.uuid4())

    resp = requests.post(
        f"{SERVER_URL}/prompt", json={"prompt": workflow, "prompt_id": prompt_id}
    )
    if resp.status_code != 200:
        print(f"  提交失败: {resp.text[:200]}")
        return None

    print(f"  任务ID: {prompt_id}")

    for i in range(240):
        time.sleep(2)
        resp = requests.get(f"{SERVER_URL}/history/{prompt_id}")
        if resp.status_code == 200:
            history = resp.json()
            if prompt_id in history:
                status = history[prompt_id].get("status", {}).get("status_str", "")

                if status == "success":
                    for node_id, output in (
                        history[prompt_id].get("outputs", {}).items()
                    ):
                        if "images" in output:
                            for img in output["images"]:
                                filename = img["filename"]
                                img_resp = requests.get(
                                    f"{SERVER_URL}/view",
                                    params={
                                        "filename": filename,
                                        "subfolder": "",
                                        "type": "output",
                                    },
                                )
                                if img_resp.status_code == 200:
                                    save_dir = "icons" if size == 128 else "pets"
                                    save_path = os.path.join(
                                        ASSETS_DIR, save_dir, f"{name}.png"
                                    )
                                    with open(save_path, "wb") as f:
                                        f.write(img_resp.content)
                                    print(f"  已保存: {save_path}")
                                    return save_path

                elif status == "error":
                    print(f"  生成失败!")
                    return None

        if i % 10 == 0:
            print(f"  等待中... ({i * 2}秒)")

    print("  超时!")
    return None


# 动物主图 512x512
PETS = {
    "cat": "cute cartoon cat, round face, big sparkling eyes, orange tabby fur, friendly smile, sitting pose, white background, kawaii style, high quality illustration, simple design",
    "dog": "cute cartoon golden retriever puppy, round face, big happy eyes, fluffy golden fur, wagging tail, playful pose, white background, kawaii style, high quality illustration, simple design",
    "rabbit": "cute cartoon bunny rabbit, round face, long floppy ears, pink nose, white fluffy fur, cute pose, white background, kawaii style, high quality illustration, simple design",
    "hamster": "cute cartoon hamster, round chubby body, tiny ears, big sparkly eyes, golden brown fur, cute pose, white background, kawaii style, high quality illustration, simple design",
    "bird": "cute cartoon parakeet bird, round body, colorful green and yellow feathers, tiny beak, perched pose, white background, kawaii style, high quality illustration, simple design",
    "fish": "cute cartoon goldfish, round body, big eyes, flowing orange fins, swimming pose, bubbles, white background, kawaii style, high quality illustration, simple design",
    "turtle": "cute cartoon turtle, round shell, friendly smile, green pattern, tiny legs, white background, kawaii style, high quality illustration, simple design",
    "panda": "cute cartoon panda, round body, black and white patches, big eyes, bamboo, cute pose, white background, kawaii style, high quality illustration, simple design",
}

# UI 图标 128x128
ICONS = {
    "cat_icon": "simple flat cute cat face icon, minimal design, orange color, white background, app icon style, clean",
    "dog_icon": "simple flat cute dog face icon, minimal design, golden color, white background, app icon style, clean",
    "rabbit_icon": "simple flat cute rabbit face icon, minimal design, white color, white background, app icon style, clean",
    "hamster_icon": "simple flat cute hamster face icon, minimal design, brown color, white background, app icon style, clean",
    "bird_icon": "simple flat cute bird face icon, minimal design, green color, white background, app icon style, clean",
    "fish_icon": "simple flat cute fish icon, minimal design, orange color, white background, app icon style, clean",
    "turtle_icon": "simple flat cute turtle icon, minimal design, green color, white background, app icon style, clean",
    "panda_icon": "simple flat cute panda face icon, minimal design, black and white, white background, app icon style, clean",
    "food_icon": "simple flat pet food bowl icon, minimal design, blue color, white background, app icon style, clean",
    "task_icon": "simple flat checklist task icon, minimal design, green color, white background, app icon style, clean",
    "heart_icon": "simple flat heart love icon, minimal design, red color, white background, app icon style, clean",
    "star_icon": "simple flat star icon, minimal design, yellow color, white background, app icon style, clean",
}


if __name__ == "__main__":
    print("=" * 50)
    print("拾星小宠 动物形象生成器")
    print("=" * 50)
    print(f"服务器: {SERVER_URL}")
    print()

    resp = requests.get(f"{SERVER_URL}/system_stats")
    if resp.status_code != 200:
        print("服务器连接失败!")
        exit(1)
    print("服务器连接成功!\n")

    if len(sys.argv) > 1:
        name = sys.argv[1]
        if name == "all":
            for n, prompt in PETS.items():
                generate(prompt, n, 512)
                time.sleep(3)
            for n, prompt in ICONS.items():
                generate(prompt, n, 128)
                time.sleep(3)
        elif name == "pets":
            for n, prompt in PETS.items():
                generate(prompt, n, 512)
                time.sleep(3)
        elif name == "icons":
            for n, prompt in ICONS.items():
                generate(prompt, n, 128)
                time.sleep(3)
        elif name in PETS:
            generate(PETS[name], name, 512)
        elif name in ICONS:
            generate(ICONS[name], name, 128)
        else:
            print(f"未知: {name}")
    else:
        print("用法:")
        print("  python generate.py <名称>    # 生成单张")
        print("  python generate.py pets      # 生成所有动物")
        print("  python generate.py icons     # 生成所有图标")
        print("  python generate.py all       # 生成全部")
        print()
        print("动物: cat, dog, rabbit, hamster, bird, fish, turtle, panda")
        print(
            "图标: cat_icon, dog_icon, ... food_icon, task_icon, heart_icon, star_icon"
        )
