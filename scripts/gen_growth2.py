"""拾星小宠 成长阶段生成器 v2"""

import requests
import time
import uuid
import os
import sys

from comfy_full_workflow_local import SERVER_URL, create_workflow as create_full_workflow, ensure_models_present
ASSETS_DIR = r"C:\Users\Administrator\Desktop\pickstarpet\app\assets\images\growth_v2"

os.makedirs(ASSETS_DIR, exist_ok=True)
ensure_models_present()

BASE = "cute cartoon, round face, big sparkling eyes, white background, kawaii style, high quality illustration, simple design, consistent style"

# 成长阶段提示词
PROMPTS = {
    # 猫
    "cat_baby": "tiny baby kitten, very small and adorable, innocent big eyes, soft fluffy orange tabby fur, tiny paws, curled up cute pose, "
    + BASE,
    "cat_teen": "young teenage cat, playful energetic pose, slightly bigger than kitten, orange tabby fur getting brighter, curious expression, chasing butterfly, "
    + BASE,
    "cat_young_adult": "young adult cat, confident pose, sleek orange tabby fur, elegant sitting position, alert ears, growing majestic look, "
    + BASE,
    "cat_adult": "fully grown majestic adult cat, beautiful shiny orange tabby fur, proud noble pose, wise eyes, strong confident expression, "
    + BASE,
    # 狗
    "dog_baby": "tiny baby golden retriever puppy, very small and adorable, innocent big eyes, soft fluffy golden fur, tiny floppy ears, wagging tiny tail, "
    + BASE,
    "dog_teen": "young teenage golden retriever, playful energetic pose, medium size, golden fur getting brighter, excited expression, tongue out, "
    + BASE,
    "dog_young_adult": "young adult golden retriever, confident pose, beautiful golden fur, loyal expression, strong build growing, "
    + BASE,
    "dog_adult": "fully grown majestic golden retriever, beautiful shiny golden fur, proud noble pose, wise loyal eyes, strong powerful build, "
    + BASE,
    # 兔子
    "rabbit_baby": "tiny baby bunny, very small and adorable, innocent big eyes, soft white fluffy fur, tiny pink nose, tiny ears, "
    + BASE,
    "rabbit_teen": "young teenage bunny, playful hopping pose, medium size, white fluffy fur getting longer, curious expression, ears growing, "
    + BASE,
    "rabbit_young_adult": "young adult bunny, confident pose, fluffy white fur, elegant sitting, long floppy ears developing, "
    + BASE,
    "rabbit_adult": "fully grown majestic bunny rabbit, beautiful long white fluffy fur, proud noble pose, long majestic ears, wise eyes, "
    + BASE,
    # 仓鼠
    "hamster_baby": "tiny baby hamster, very small and adorable, round chubby body, tiny paws, soft golden brown fur, innocent big eyes, "
    + BASE,
    "hamster_teen": "young teenage hamster, playful pose, slightly bigger, golden brown fur, curious expression, stuffing cheeks with food, "
    + BASE,
    "hamster_young_adult": "young adult hamster, confident pose, fluffy golden fur, alert sitting position, growing round body, "
    + BASE,
    "hamster_adult": "fully grown chubby adult hamster, beautiful fluffy golden brown fur, proud sitting pose, wise cute eyes, round majestic body, "
    + BASE,
    # 鸟
    "bird_baby": "tiny baby parakeet chick, very small and adorable, fluffy down feathers, innocent big eyes, tiny beak, green and yellow, "
    + BASE,
    "bird_teen": "young teenage parakeet, playful flapping pose, feathers growing, green and yellow colors getting brighter, curious expression, "
    + BASE,
    "bird_young_adult": "young adult parakeet, confident perched pose, colorful green and yellow feathers developing, proud look, "
    + BASE,
    "bird_adult": "fully grown majestic adult parakeet, beautiful vibrant green and yellow feathers, proud noble pose, wise bright eyes, "
    + BASE,
    # 鱼
    "fish_baby": "tiny baby goldfish, very small and adorable, tiny fins, innocent big eyes, pale orange scales, small bubbles around, "
    + BASE,
    "fish_teen": "young teenage goldfish, swimming playfully, fins getting longer, orange scales getting brighter, curious expression, "
    + BASE,
    "fish_young_adult": "young adult goldfish, graceful swimming pose, beautiful flowing fins developing, vibrant orange scales, "
    + BASE,
    "fish_adult": "fully grown majestic adult goldfish, beautiful long flowing fins, vibrant orange scales, proud swimming pose, wise eyes, "
    + BASE,
    # 乌龟
    "turtle_baby": "tiny baby turtle, very small and adorable, tiny green shell, innocent big eyes, tiny legs, cute small size, "
    + BASE,
    "turtle_teen": "young teenage turtle, playful pose, shell getting bigger, green pattern developing, curious expression, slightly bigger, "
    + BASE,
    "turtle_young_adult": "young adult turtle, confident pose, beautiful green shell pattern, wise expression developing, "
    + BASE,
    "turtle_adult": "fully grown majestic adult turtle, beautiful detailed green shell, wise ancient eyes, proud noble pose, strong legs, "
    + BASE,
    # 熊猫
    "panda_baby": "tiny baby panda, very small and adorable, round chubby body, innocent big eyes, black and white patches, tiny bamboo, "
    + BASE,
    "panda_teen": "young teenage panda, playful rolling pose, medium size, black and white patches, curious expression, eating bamboo, "
    + BASE,
    "panda_young_adult": "young adult panda, confident sitting pose, beautiful black and white fur, strong build developing, "
    + BASE,
    "panda_adult": "fully grown majestic adult panda, beautiful black and white fur, proud noble pose, wise gentle eyes, strong powerful build, "
    + BASE,
}


def create_workflow(prompt, seed=None):
    return create_full_workflow(prompt, 512, 512, seed)

def generate(name):
    if name not in PROMPTS:
        print(f"未知: {name}")
        return False

    save_path = os.path.join(ASSETS_DIR, f"{name}.png")
    if os.path.exists(save_path):
        print(f"  已存在，跳过")
        return True

    print(f"[生成] {name}")

    workflow = create_workflow(PROMPTS[name])
    prompt_id = str(uuid.uuid4())

    resp = requests.post(
        f"{SERVER_URL}/prompt", json={"prompt": workflow, "prompt_id": prompt_id}
    )
    if resp.status_code != 200:
        print(f"  提交失败!")
        return False

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
                            filename = output["images"][0]["filename"]
                            img_resp = requests.get(
                                f"{SERVER_URL}/view",
                                params={
                                    "filename": filename,
                                    "subfolder": "",
                                    "type": "output",
                                },
                            )
                            if img_resp.status_code == 200:
                                with open(save_path, "wb") as f:
                                    f.write(img_resp.content)
                                print(f"  已保存!")
                                return True

                elif status == "error":
                    print(f"  失败!")
                    return False

        if i % 10 == 0:
            print(f"  等待中... ({i * 2}秒)")

    print("  超时!")
    return False


if __name__ == "__main__":
    print("=" * 50)
    print("拾星小宠 成长阶段生成器 v2")
    print("=" * 50)

    resp = requests.get(f"{SERVER_URL}/system_stats")
    if resp.status_code != 200:
        print("服务器连接失败!")
        exit(1)
    print("服务器连接成功!\n")

    if len(sys.argv) > 1:
        if sys.argv[1] == "all":
            for name in PROMPTS.keys():
                generate(name)
                time.sleep(2)
        else:
            generate(sys.argv[1])
    else:
        print("用法: python gen_growth2.py <名称|all>")
        print("\n状态:")
        for name in PROMPTS.keys():
            exists = os.path.exists(os.path.join(ASSETS_DIR, f"{name}.png"))
            print(f"  {'OK' if exists else '--'} {name}")
