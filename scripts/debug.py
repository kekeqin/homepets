import requests
import uuid
import time
import json

from comfy_full_workflow_local import SERVER_URL, create_workflow, ensure_models_present

# 创建一个简单的工作流
ensure_models_present()

workflow = create_workflow("cute cartoon cat, kawaii style", 512, 512, 12345)

prompt_id = str(uuid.uuid4())
payload = {"prompt": workflow, "prompt_id": prompt_id}

print("提交任务...")
resp = requests.post(f"{SERVER_URL}/prompt", json=payload)
print(f"状态码: {resp.status_code}")
print(f"响应: {resp.text[:500]}")

if resp.status_code == 200:
    print(f"\n任务ID: {prompt_id}")
    print("\n等待生成...")

    for i in range(60):
        time.sleep(2)
        resp = requests.get(f"{SERVER_URL}/history/{prompt_id}")
        if resp.status_code == 200:
            history = resp.json()
            if prompt_id in history:
                data = history[prompt_id]
                status = data.get("status", {}).get("status_str", "unknown")
                print(f"状态: {status}")

                if status in ["success", "error"]:
                    print("\n完整响应:")
                    print(json.dumps(data, indent=2))
                    break

        if i % 5 == 0:
            print(f"  等待中... ({i * 2}秒)")
