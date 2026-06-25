"""单张成长阶段生成"""

import requests
import time
import uuid
import os
import sys

from comfy_full_workflow_local import SERVER_URL, create_workflow as create_full_workflow, ensure_models_present
ASSETS_DIR = r"C:\Users\Administrator\Desktop\pickstarpet\app\assets\images\growth"

BASE = "cute cartoon, round face, big sparkling eyes, white background, kawaii style, high quality illustration, simple design"

PROMPTS = {
    # 狗
    "dog_baby": "tiny adorable baby golden retriever puppy, very small and cute, innocent expression, soft fluffy golden fur, tiny floppy ears, wagging tail, sitting shyly, "
    + BASE,
    "dog_troublemaker": "mischievous golden retriever puppy, cheeky grinning expression, chewing shoe, guilty look, naughty pose, devilish cute look, golden fluffy fur, "
    + BASE,
    "dog_demon_king": "powerful majestic golden retriever puppy, wearing tiny crown, confident boss expression, heroic pose, glowing aura effect, tiny cape, strong pose, loyal eyes, golden fur, "
    + BASE,
    # 兔子
    "rabbit_baby": "tiny adorable baby bunny rabbit, very small and cute, innocent expression, soft white fluffy fur, tiny ears, pink nose, sitting shyly, "
    + BASE,
    "rabbit_runner": "energetic young bunny rabbit hopping playfully, happy excited expression, dynamic pose, speed lines effect, ears back, white fluffy fur, "
    + BASE,
    "rabbit_troublemaker": "mischievous bunny rabbit, cheeky grinning expression, eating carrots, naughty pose, devilish cute look, white fluffy fur, "
    + BASE,
    "rabbit_demon_king": "powerful majestic bunny rabbit, wearing tiny crown, confident boss expression, heroic pose, glowing aura effect, long majestic ears, regal pose, white fur, "
    + BASE,
    # 仓鼠
    "hamster_baby": "tiny adorable baby hamster, very small and cute, innocent expression, round chubby body, tiny paws, golden brown fur, sitting shyly, "
    + BASE,
    "hamster_runner": "energetic young hamster running on wheel playfully, happy excited expression, dynamic pose, speed lines effect, golden brown fur, "
    + BASE,
    "hamster_troublemaker": "mischievous hamster, cheeky grinning expression, stuffing cheeks with seeds, sneaky look, naughty pose, golden brown fur, "
    + BASE,
    "hamster_demon_king": "powerful majestic hamster, wearing tiny crown, confident boss expression, heroic pose, glowing aura effect, puffed chest, golden brown fur, "
    + BASE,
    # 鸟
    "bird_baby": "tiny adorable baby parakeet bird, very small and cute, innocent expression, fluffy green and yellow feathers, learning to fly pose, "
    + BASE,
    "bird_runner": "energetic young parakeet bird flying fast, happy excited expression, dynamic pose, wings spread, speed lines effect, green and yellow feathers, "
    + BASE,
    "bird_troublemaker": "mischievous parakeet bird, cheeky grinning expression, stealing food, naughty pose, devilish cute look, green and yellow feathers, "
    + BASE,
    "bird_demon_king": "powerful majestic parakeet bird, wearing tiny crown, confident boss expression, heroic pose, glowing aura effect, colorful majestic feathers, proud pose, "
    + BASE,
    # 鱼
    "fish_baby": "tiny adorable baby goldfish, very small and cute, innocent expression, tiny fins, bubbles around, orange scales, swimming shyly, "
    + BASE,
    "fish_runner": "energetic young goldfish swimming fast, happy excited expression, dynamic pose, water splash effect, orange scales, "
    + BASE,
    "fish_troublemaker": "mischievous goldfish, cheeky grinning expression, hiding in castle, peeking out, naughty pose, orange scales, "
    + BASE,
    "fish_demon_king": "powerful majestic goldfish, wearing tiny crown, confident boss expression, heroic pose, glowing aura effect, flowing majestic fins, golden crown, orange scales, "
    + BASE,
    # 乌龟
    "turtle_baby": "tiny adorable baby turtle, very small and cute, innocent expression, tiny shell, cute little legs, green shell pattern, sitting shyly, "
    + BASE,
    "turtle_runner": "energetic young turtle running surprisingly fast, happy excited expression, dynamic pose, speed lines effect, green shell, "
    + BASE,
    "turtle_troublemaker": "mischievous turtle, cheeky grinning expression, hiding in shell, peeking out, naughty pose, green shell, "
    + BASE,
    "turtle_demon_king": "powerful majestic turtle, wearing tiny crown, confident boss expression, heroic pose, glowing aura effect, ancient wise look, glowing shell, "
    + BASE,
    # 熊猫
    "panda_baby": "tiny adorable baby panda, very small and cute, innocent expression, round chubby body, black and white patches, tiny bamboo, sitting shyly, "
    + BASE,
    "panda_runner": "energetic young panda rolling around playfully, happy excited expression, dynamic pose, speed lines effect, black and white patches, "
    + BASE,
    "panda_troublemaker": "mischievous panda, cheeky grinning expression, covered in bamboo mess, naughty pose, devilish cute look, black and white patches, "
    + BASE,
    "panda_demon_king": "powerful majestic panda, wearing tiny crown, confident boss expression, kung fu pose, glowing aura effect, powerful aura, black and white patches, "
    + BASE,
}


def create_workflow(prompt, seed=None):
    return create_full_workflow(prompt, 512, 512, seed)

def generate(name):
    if name not in PROMPTS:
        print(f"未知: {name}")
        return False

    prompt = PROMPTS[name]
    save_path = os.path.join(ASSETS_DIR, f"{name}.png")

    print(f"[生成] {name}")

    workflow = create_workflow(prompt)
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
    if len(sys.argv) > 1:
        name = sys.argv[1]
        if name == "all":
            for n in PROMPTS.keys():
                if not os.path.exists(os.path.join(ASSETS_DIR, f"{n}.png")):
                    generate(n)
                    time.sleep(2)
        else:
            generate(name)
    else:
        print("用法: python gen_one.py <名称|all>")
        print("\n需要生成:")
        for n in PROMPTS.keys():
            exists = os.path.exists(os.path.join(ASSETS_DIR, f"{n}.png"))
            status = "✓" if exists else "○"
            print(f"  {status} {n}")
