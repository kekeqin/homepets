"""单张图像生成脚本 - 用于测试和逐步生成"""

import requests
import time
import uuid
import os
import sys

from comfy_full_workflow_local import SERVER_URL, create_workflow, ensure_models_present

# 输出目录
DIRS = {
    "512": r"C:\Users\Administrator\Desktop\pickstarpet\app\assets\images\pets",
    "128": r"C:\Users\Administrator\Desktop\pickstarpet\app\assets\images\icons",
}

for d in DIRS.values():
    os.makedirs(d, exist_ok=True)

ensure_models_present()


def submit(prompt, width, height):
    """提交生成任务，返回 prompt_id"""
    workflow = create_workflow(prompt, width, height)
    prompt_id = str(uuid.uuid4())
    payload = {"prompt": workflow, "prompt_id": prompt_id}
    resp = requests.post(f"{SERVER_URL}/prompt", json=payload)
    if resp.status_code == 200:
        return resp.json().get("prompt_id", prompt_id)
    raise Exception(f"提交失败: {resp.text}")


def check(prompt_id):
    """检查任务状态，返回 (status, images)"""
    resp = requests.get(f"{SERVER_URL}/history/{prompt_id}")
    if resp.status_code == 200:
        history = resp.json()
        if prompt_id in history:
            data = history[prompt_id]
            status = data.get("status", {}).get("status_str", "unknown")
            images = []
            for node_id, output in data.get("outputs", {}).items():
                if "images" in output:
                    images.extend([img["filename"] for img in output["images"]])
            return status, images
    return "pending", []


def download(filename, save_dir):
    """下载图像"""
    resp = requests.get(
        f"{SERVER_URL}/view",
        params={"filename": filename, "subfolder": "", "type": "output"},
    )
    if resp.status_code == 200:
        save_path = os.path.join(save_dir, filename)
        with open(save_path, "wb") as f:
            f.write(resp.content)
        return save_path
    return None


def generate(prompt, name, size):
    """生成单张图像"""
    width = height = size
    output_dir = DIRS[str(size)]

    print(f"提交任务: {name} ({size}x{size})")
    prompt_id = submit(prompt, width, height)
    print(f"任务ID: {prompt_id}")

    print("等待生成...")
    for i in range(240):  # 最多等待4分钟
        time.sleep(2)
        status, images = check(prompt_id)

        if status == "success" and images:
            print(f"生成成功!")
            for img in images:
                path = download(img, output_dir)
                if path:
                    print(f"已保存: {path}")
            return True
        elif status == "error":
            print("生成失败!")
            return False
        elif i % 10 == 0:
            print(f"  等待中... ({i * 2}秒)")

    print("超时!")
    return False


# 预设提示词
PROMPTS = {
    # 512x512 动物主图
    "cat": (
        "cute cartoon cat, round face, big sparkling eyes, orange tabby fur, friendly smile, sitting, white background, kawaii style, high quality",
        512,
    ),
    "dog": (
        "cute cartoon golden retriever puppy, round face, big happy eyes, golden fur, wagging tail, white background, kawaii style, high quality",
        512,
    ),
    "rabbit": (
        "cute cartoon bunny, round face, long floppy ears, pink nose, white fluffy fur, white background, kawaii style, high quality",
        512,
    ),
    "hamster": (
        "cute cartoon hamster, round chubby body, tiny ears, big sparkly eyes, golden brown fur, white background, kawaii style, high quality",
        512,
    ),
    "bird": (
        "cute cartoon parakeet, round body, green and yellow feathers, tiny beak, white background, kawaii style, high quality",
        512,
    ),
    "fish": (
        "cute cartoon goldfish, round body, big eyes, orange fins, bubbles, white background, kawaii style, high quality",
        512,
    ),
    "turtle": (
        "cute cartoon turtle, round shell, friendly smile, green pattern, white background, kawaii style, high quality",
        512,
    ),
    "panda": (
        "cute cartoon panda, round body, black and white patches, big eyes, white background, kawaii style, high quality",
        512,
    ),
    # 128x128 图标
    "cat_icon": (
        "simple flat cat face icon, minimal, orange, white background, app icon",
        128,
    ),
    "dog_icon": (
        "simple flat dog face icon, minimal, golden, white background, app icon",
        128,
    ),
    "food_icon": (
        "simple flat pet food bowl icon, minimal, blue, white background, app icon",
        128,
    ),
    "heart_icon": (
        "simple flat heart icon, minimal, red, white background, app icon",
        128,
    ),
}


if __name__ == "__main__":
    if len(sys.argv) > 1:
        name = sys.argv[1]
        if name in PROMPTS:
            prompt, size = PROMPTS[name]
            generate(prompt, name, size)
        elif name == "all":
            for name, (prompt, size) in PROMPTS.items():
                generate(prompt, name, size)
                time.sleep(3)
        else:
            print(f"未知名称: {name}")
            print(f"可用: {', '.join(PROMPTS.keys())}, all")
    else:
        print("用法:")
        print("  python generate_one.py <名称>")
        print("  python generate_one.py all")
        print()
        print("可用名称:")
        for name, (_, size) in PROMPTS.items():
            print(f"  {name} ({size}x{size})")
