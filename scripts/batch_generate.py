"""
批量生成 HomePets 动物形象素材
- 512x512 动物主图
- 128x128 UI 图标
"""

import requests
import json
import time
import uuid
import os

from comfy_full_workflow_local import SERVER_URL, create_workflow, ensure_models_present
OUTPUT_DIR = r"C:\Users\Administrator\Desktop\homepets\app\assets\images\pets"
ICON_DIR = r"C:\Users\Administrator\Desktop\homepets\app\assets\images\icons"

os.makedirs(OUTPUT_DIR, exist_ok=True)
ensure_models_present()
os.makedirs(ICON_DIR, exist_ok=True)


def queue_prompt(workflow):
    prompt_id = str(uuid.uuid4())
    payload = {"prompt": workflow, "prompt_id": prompt_id}
    response = requests.post(f"{SERVER_URL}/prompt", json=payload)
    if response.status_code == 200:
        return response.json()
    raise Exception(f"Queue failed: {response.text}")


def wait_for_completion(prompt_id, timeout=900):
    start = time.time()
    while time.time() - start < timeout:
        resp = requests.get(f"{SERVER_URL}/history/{prompt_id}")
        if resp.status_code == 200:
            history = resp.json()
            if prompt_id in history:
                for node_id, output in history[prompt_id].get("outputs", {}).items():
                    if "images" in output:
                        return output["images"]
        time.sleep(2)
    raise Exception("Timeout")


def download_image(filename, save_path):
    resp = requests.get(
        f"{SERVER_URL}/view",
        params={"filename": filename, "subfolder": "", "type": "output"},
    )
    if resp.status_code == 200:
        with open(save_path, "wb") as f:
            f.write(resp.content)
        return True
    return False


def generate(prompt, filename, width, height, output_dir):
    print(f"  生成: {filename} ({width}x{height})")
    workflow = create_workflow(prompt, width, height)
    result = queue_prompt(workflow)
    prompt_id = result["prompt_id"]
    print(f"  任务ID: {prompt_id}")
    images = wait_for_completion(prompt_id)
    if images:
        save_path = os.path.join(output_dir, f"{filename}.png")
        download_image(images[0]["filename"], save_path)
        print(f"  已保存: {save_path}")
        return save_path
    return None


# 动物主图 512x512
PETS_512 = {
    "cat": "cute cartoon cat, round face, big sparkling eyes, orange tabby fur, friendly smile, sitting, white background, kawaii style, high quality",
    "dog": "cute cartoon golden retriever puppy, round face, big happy eyes, golden fur, wagging tail, white background, kawaii style, high quality",
    "rabbit": "cute cartoon bunny, round face, long floppy ears, pink nose, white fluffy fur, white background, kawaii style, high quality",
    "hamster": "cute cartoon hamster, round chubby body, tiny ears, big sparkly eyes, golden brown fur, white background, kawaii style, high quality",
    "bird": "cute cartoon parakeet, round body, green and yellow feathers, tiny beak, white background, kawaii style, high quality",
    "fish": "cute cartoon goldfish, round body, big eyes, orange fins, bubbles, white background, kawaii style, high quality",
    "turtle": "cute cartoon turtle, round shell, friendly smile, green pattern, white background, kawaii style, high quality",
    "panda": "cute cartoon panda, round body, black and white patches, big eyes, white background, kawaii style, high quality",
}

# UI 图标 128x128
ICONS_128 = {
    "cat_icon": "simple flat cat face icon, minimal, orange, white background, app icon",
    "dog_icon": "simple flat dog face icon, minimal, golden, white background, app icon",
    "rabbit_icon": "simple flat rabbit face icon, minimal, white, white background, app icon",
    "hamster_icon": "simple flat hamster face icon, minimal, brown, white background, app icon",
    "bird_icon": "simple flat bird face icon, minimal, green, white background, app icon",
    "fish_icon": "simple flat fish icon, minimal, orange, white background, app icon",
    "turtle_icon": "simple flat turtle icon, minimal, green, white background, app icon",
    "panda_icon": "simple flat panda face icon, minimal, black and white, white background, app icon",
    "food_icon": "simple flat pet food bowl icon, minimal, blue, white background, app icon",
    "task_icon": "simple flat checklist icon, minimal, green, white background, app icon",
    "heart_icon": "simple flat heart icon, minimal, red, white background, app icon",
    "star_icon": "simple flat star icon, minimal, yellow, white background, app icon",
}


if __name__ == "__main__":
    print("=" * 50)
    print("HomePets 批量素材生成")
    print("=" * 50)

    # 测试连接
    resp = requests.get(f"{SERVER_URL}/system_stats")
    if resp.status_code != 200:
        print("服务器连接失败!")
        exit(1)
    print("服务器连接成功!\n")

    # 生成动物主图
    print("[1/2] 生成 512x512 动物主图")
    print("-" * 40)
    for name, prompt in PETS_512.items():
        try:
            generate(prompt, name, 512, 512, OUTPUT_DIR)
            time.sleep(2)
        except Exception as e:
            print(f"  失败: {name} - {e}")

    print()

    # 生成 UI 图标
    print("[2/2] 生成 128x128 UI 图标")
    print("-" * 40)
    for name, prompt in ICONS_128.items():
        try:
            generate(prompt, name, 128, 128, ICON_DIR)
            time.sleep(2)
        except Exception as e:
            print(f"  失败: {name} - {e}")

    print()
    print("=" * 50)
    print("生成完成!")
    print(f"动物主图: {OUTPUT_DIR}")
    print(f"UI 图标: {ICON_DIR}")
