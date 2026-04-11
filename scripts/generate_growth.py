"""HomePets 动物成长阶段生成器"""

import requests
import time
import uuid
import os

from comfy_full_workflow_local import SERVER_URL, create_workflow as create_full_workflow, ensure_models_present
ASSETS_DIR = r"C:\Users\Administrator\Desktop\homepets\app\assets\images\growth"

os.makedirs(ASSETS_DIR, exist_ok=True)
ensure_models_present()


def create_workflow(prompt, seed=None):
    return create_full_workflow(prompt, 512, 512, seed)

def generate(prompt, save_path):
    print(f"  生成: {os.path.basename(save_path)}")

    workflow = create_workflow(prompt)
    prompt_id = str(uuid.uuid4())

    resp = requests.post(
        f"{SERVER_URL}/prompt", json={"prompt": workflow, "prompt_id": prompt_id}
    )
    if resp.status_code != 200:
        print(f"    提交失败!")
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
                                print(f"    已保存!")
                                return True

                elif status == "error":
                    print(f"    失败!")
                    return False

        if i % 10 == 0:
            print(f"    等待中... ({i * 2}秒)")

    print("    超时!")
    return False


# 动物成长阶段提示词模板
BASE_STYLE = "cute cartoon, round face, big sparkling eyes, white background, kawaii style, high quality illustration, simple design"

STAGES = {
    "baby": "tiny adorable baby {animal}, very small and cute, innocent expression, soft fluffy fur, sitting shyly, {extra}",
    "runner": "energetic young {animal} running playfully, happy excited expression, dynamic pose, speed lines effect, {extra}",
    "troublemaker": "mischievous {animal}, cheeky grinning expression, causing trouble, playful naughty pose, devilish cute look, {extra}",
    "demon_king": "powerful majestic {animal}, wearing tiny crown, confident boss expression, heroic pose, glowing aura effect, tiny cape, {extra}",
}

# 动物特定描述
ANIMALS = {
    "cat": {
        "name": "cat",
        "extra": "orange tabby fur",
        "baby_extra": "tiny paws, big eyes",
        "runner_extra": "tail up, running fast",
        "troublemaker_extra": "knocked over vase, innocent look",
        "demon_king_extra": "sharp eyes, majestic fur",
    },
    "dog": {
        "name": "golden retriever puppy",
        "extra": "golden fluffy fur",
        "baby_extra": "tiny floppy ears, wagging tail",
        "runner_extra": "tongue out, ears flying",
        "troublemaker_extra": "chewing shoe, guilty look",
        "demon_king_extra": "strong pose, loyal eyes",
    },
    "rabbit": {
        "name": "bunny rabbit",
        "extra": "white fluffy fur",
        "baby_extra": "tiny ears, pink nose",
        "runner_extra": "hopping fast, ears back",
        "troublemaker_extra": "eating carrots, mischievous",
        "demon_king_extra": "long majestic ears, regal pose",
    },
    "hamster": {
        "name": "hamster",
        "extra": "golden brown fur",
        "baby_extra": "round chubby, tiny paws",
        "runner_extra": "running on wheel, happy",
        "troublemaker_extra": "stuffing cheeks, sneaky look",
        "demon_king_extra": "tiny crown on head, puffed chest",
    },
    "bird": {
        "name": "parakeet bird",
        "extra": "green and yellow feathers",
        "baby_extra": "tiny fluffy, learning to fly",
        "runner_extra": "flying fast, wings spread",
        "troublemaker_extra": "stealing food, cheeky pose",
        "demon_king_extra": "colorful majestic feathers, proud pose",
    },
    "fish": {
        "name": "goldfish",
        "extra": "orange scales",
        "baby_extra": "tiny fins, bubble around",
        "runner_extra": "swimming fast, water splash",
        "troublemaker_extra": "hiding in castle, peeking out",
        "demon_king_extra": "flowing majestic fins, golden crown",
    },
    "turtle": {
        "name": "turtle",
        "extra": "green shell",
        "baby_extra": "tiny shell, cute legs",
        "runner_extra": "running surprisingly fast",
        "troublemaker_extra": "hiding in shell, peeking",
        "demon_king_extra": "ancient wise look, glowing shell",
    },
    "panda": {
        "name": "panda",
        "extra": "black and white patches",
        "baby_extra": "tiny round, bamboo",
        "runner_extra": "rolling around, playful",
        "troublemaker_extra": "covered in bamboo mess",
        "demon_king_extra": "kung fu pose, powerful aura",
    },
}


if __name__ == "__main__":
    print("=" * 50)
    print("HomePets 动物成长阶段生成器")
    print("=" * 50)
    print(f"服务器: {SERVER_URL}")
    print(f"输出目录: {ASSETS_DIR}")
    print()

    resp = requests.get(f"{SERVER_URL}/system_stats")
    if resp.status_code != 200:
        print("服务器连接失败!")
        exit(1)
    print("服务器连接成功!\n")

    stage_names = {
        "baby": "幼崽期",
        "runner": "跑跑怪",
        "troublemaker": "捣蛋鬼",
        "demon_king": "大魔王",
    }

    for animal_key, animal_data in ANIMALS.items():
        animal_name = animal_data["name"]
        print(f"[{animal_key.upper()}]")

        for stage_key, stage_name in stage_names.items():
            # 构建提示词
            prompt = STAGES[stage_key].format(
                animal=animal_name, extra=animal_data["extra"]
            )
            # 添加阶段特定描述
            extra_key = f"{stage_key}_extra"
            if extra_key in animal_data:
                prompt += f", {animal_data[extra_key]}"

            prompt += f", {BASE_STYLE}"

            # 生成文件名
            filename = f"{animal_key}_{stage_key}.png"
            save_path = os.path.join(ASSETS_DIR, filename)

            print(f"  [{stage_name}]")
            generate(prompt, save_path)
            time.sleep(2)

        print()

    print("=" * 50)
    print("全部生成完成!")
