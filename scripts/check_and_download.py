import requests
import os

SERVER_URL = "http://127.0.0.1:8188"
OUTPUT_DIR = r"C:\Users\Administrator\Desktop\pickstarpet\app\assets\images\pets"
ICON_DIR = r"C:\Users\Administrator\Desktop\pickstarpet\app\assets\images\icons"

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(ICON_DIR, exist_ok=True)

# 获取历史记录
resp = requests.get(f"{SERVER_URL}/history")
history = resp.json()

print(f"历史记录数量: {len(history)}\n")

for prompt_id, data in history.items():
    status = data.get("status", {})
    status_str = status.get("status_str", "unknown")

    outputs = data.get("outputs", {})
    for node_id, output in outputs.items():
        if "images" in output:
            for img in output["images"]:
                filename = img.get("filename", "")
                print(f"图像: {filename} | 状态: {status_str}")

                if status_str == "success" and filename:
                    # 下载图像
                    resp = requests.get(
                        f"{SERVER_URL}/view",
                        params={
                            "filename": filename,
                            "subfolder": "",
                            "type": "output",
                        },
                    )
                    if resp.status_code == 200:
                        save_path = os.path.join(OUTPUT_DIR, filename)
                        with open(save_path, "wb") as f:
                            f.write(resp.content)
                        print(f"  -> 已下载: {save_path}")
