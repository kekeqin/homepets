"""
Flux.2 Klein 4B 远程 API 调用脚本
用于生成 拾星小宠 项目的动物形象素材
"""

import requests
import json
import time
import uuid
import os

# 远程 ComfyUI 服务器
from comfy_full_workflow_local import SERVER_URL, create_workflow, ensure_models_present
OUTPUT_DIR = r"C:\Users\Administrator\Desktop\pickstarpet\app\assets\images\pets"

# 确保输出目录存在
os.makedirs(OUTPUT_DIR, exist_ok=True)
ensure_models_present()


def queue_prompt(workflow):
    prompt_id = str(uuid.uuid4())
    payload = {"prompt": workflow, "prompt_id": prompt_id}
    response = requests.post(
        f"{SERVER_URL}/prompt",
        json=payload,
        headers={"Content-Type": "application/json"},
    )
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception(f"Failed to queue prompt: {response.text}")


def wait_for_completion(prompt_id, timeout=900):
    start_time = time.time()
    while time.time() - start_time < timeout:
        response = requests.get(f"{SERVER_URL}/history/{prompt_id}")
        if response.status_code == 200:
            history = response.json()
            if prompt_id in history:
                outputs = history[prompt_id].get("outputs", {})
                for node_id, output in outputs.items():
                    if "images" in output:
                        return output["images"]
        time.sleep(1)
    raise Exception("Timeout waiting for image generation")


def download_image(filename, save_path):
    response = requests.get(
        f"{SERVER_URL}/view",
        params={"filename": filename, "subfolder": "", "type": "output"},
    )
    if response.status_code == 200:
        with open(save_path, "wb") as f:
            f.write(response.content)
        return save_path
    else:
        raise Exception(f"Failed to download image: {response.text}")


def generate_pet_image(prompt, filename, width=512, height=512):
    print(f"正在生成: {filename} ({width}x{height})")
    workflow = create_workflow(prompt, width, height)
    result = queue_prompt(workflow)
    prompt_id = result["prompt_id"]
    print(f"任务 ID: {prompt_id}")
    print("等待生成...")
    images = wait_for_completion(prompt_id)
    if images:
        image_info = images[0]
        save_path = os.path.join(OUTPUT_DIR, f"{filename}.png")
        download_image(image_info["filename"], save_path)
        print(f"已保存: {save_path}")
        return save_path
    return None


# 动物形象提示词 (512x512 素材用)
PET_PROMPTS_512 = {
    "cat": "cute cartoon cat character, round face, big sparkling eyes, soft fluffy fur, orange tabby pattern, friendly smile, sitting pose, clean white background, kawaii style, suitable for children app, high quality illustration",
    "dog": "cute cartoon golden retriever puppy, round face, big happy eyes, fluffy golden fur, wagging tail, playful pose, clean white background, kawaii style, suitable for children app, high quality illustration",
    "rabbit": "cute cartoon bunny rabbit, round face, long floppy ears, pink nose, white fluffy fur, clean white background, kawaii style, suitable for children app, high quality illustration",
    "hamster": "cute cartoon hamster, round chubby body, tiny ears, big sparkly eyes, golden brown fur, clean white background, kawaii style, suitable for children app, high quality illustration",
    "bird": "cute cartoon parakeet bird, round body, colorful green and yellow feathers, tiny beak, clean white background, kawaii style, suitable for children app, high quality illustration",
    "fish": "cute cartoon goldfish, round body, big eyes, flowing orange fins, clean white background, kawaii style, suitable for children app, high quality illustration",
    "turtle": "cute cartoon turtle, round shell, friendly smile, green pattern, clean white background, kawaii style, suitable for children app, high quality illustration",
    "panda": "cute cartoon panda, round body, black and white patches, big eyes, clean white background, kawaii style, suitable for children app, high quality illustration",
}

# UI 图标提示词 (128x128 小图标用)
ICON_PROMPTS_128 = {
    "cat_icon": "simple flat cat face icon, minimal design, orange color, white background, app icon style, 128x128",
    "dog_icon": "simple flat dog face icon, minimal design, golden color, white background, app icon style, 128x128",
    "rabbit_icon": "simple flat rabbit face icon, minimal design, white color, white background, app icon style, 128x128",
    "hamster_icon": "simple flat hamster face icon, minimal design, brown color, white background, app icon style, 128x128",
    "bird_icon": "simple flat bird face icon, minimal design, green color, white background, app icon style, 128x128",
    "fish_icon": "simple flat fish icon, minimal design, orange color, white background, app icon style, 128x128",
    "turtle_icon": "simple flat turtle icon, minimal design, green color, white background, app icon style, 128x128",
    "panda_icon": "simple flat panda face icon, minimal design, black and white, white background, app icon style, 128x128",
    "food_icon": "simple flat pet food bowl icon, minimal design, blue color, white background, app icon style, 128x128",
    "task_icon": "simple flat checklist icon, minimal design, green color, white background, app icon style, 128x128",
    "heart_icon": "simple flat heart icon, minimal design, red color, white background, app icon style, 128x128",
    "star_icon": "simple flat star icon, minimal design, yellow color, white background, app icon style, 128x128",
}


if __name__ == "__main__":
    print("=" * 50)
    print("Flux.2 Klein 4B 动物形象生成器")
    print("=" * 50)
    print(f"服务器: {SERVER_URL}")
    print(f"输出目录: {OUTPUT_DIR}")
    print()

    # 测试连接
    try:
        response = requests.get(f"{SERVER_URL}/system_stats")
        if response.status_code == 200:
            print("服务器连接成功！")
            stats = response.json()
            print(f"GPU: {stats['devices'][0]['name']}")
            print()
    except Exception as e:
        print(f"连接失败: {e}")
        exit(1)

    # 生成测试图像 (512x512)
    print("生成 512x512 测试图像...")
    generate_pet_image(PET_PROMPTS_512["cat"], "test_cat_512", 512, 512)

    # 生成测试图标 (128x128)
    print()
    print("生成 128x128 测试图标...")
    generate_pet_image(ICON_PROMPTS_128["cat_icon"], "test_cat_icon_128", 128, 128)

    print()
    print("测试完成！")
