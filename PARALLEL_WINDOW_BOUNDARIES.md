# 拾星小宠 并行 Codex 窗口边界清单

适用目录：

- 主控：`C:\Users\Administrator\Desktop\pickstarpet`
- backend：`C:\Users\Administrator\Desktop\pickstarpet-backend`
- auth/family：`C:\Users\Administrator\Desktop\pickstarpet-auth-family`
- home/pet：`C:\Users\Administrator\Desktop\pickstarpet-home-pet`
- tasks/shop/tests：`C:\Users\Administrator\Desktop\pickstarpet-tasks-shop-tests`

---

## 1. 五个窗口的职责

### 主控窗口

只负责：

- 查看全局 git 状态
- 比较各分支差异
- 合并分支
- 解决冲突
- 运行最终检查
- 处理共享文件

不要负责：

- 大规模业务功能开发
- 与其他窗口重复修改业务文件

---

### backend 窗口

允许修改：

- `backend/app/api/**`
- `backend/app/services/**`
- `backend/app/models/**`
- `backend/app/schemas/**`
- `backend/app/tests/**`
- `backend/app/core/dependencies.py`
- `backend/app/core/security.py`
- `backend/app/core/exceptions.py`

尽量不要修改：

- `backend/app/main.py`
- `backend/app/core/config.py`
- `.gitignore`
- `README.md`

---

### auth/family 窗口

允许修改：

- `app/lib/screens/auth/**`
- `app/lib/screens/family/**`
- `app/lib/providers/**` 中 auth/family 直接相关文件
- `app/lib/services/**` 中 auth/family 直接相关文件
- `app/test/**` 中 auth/family 直接相关测试

不要修改：

- `app/lib/screens/home/**`
- `app/lib/screens/pet/**`
- `app/lib/screens/tasks/**`
- `app/lib/screens/shop/**`
- `backend/**`

---

### home/pet 窗口

允许修改：

- `app/lib/screens/home/**`
- `app/lib/screens/pet/**`
- `app/lib/widgets/**` 中 home/pet 专属组件
- `app/lib/models/**` 中 home/pet 直接相关模型
- `app/test/**` 中 home/pet 直接相关测试

不要修改：

- `app/lib/screens/auth/**`
- `app/lib/screens/family/**`
- `app/lib/screens/tasks/**`
- `app/lib/screens/shop/**`
- `backend/**`

---

### tasks/shop/tests 窗口

允许修改：

- `app/lib/screens/tasks/**`
- `app/lib/screens/shop/**`
- `app/test/**`
- 与 tasks/shop 直接相关的 widget/provider/service

不要修改：

- `app/lib/screens/auth/**`
- `app/lib/screens/family/**`
- `app/lib/screens/home/**`
- `app/lib/screens/pet/**`
- `backend/**`

---

## 2. 共享文件：统一只让主控窗口处理

下面这些文件容易冲突，默认只允许主控窗口改：

- `.gitignore`
- `AGENTS.md`
- `README.md`
- `plan.md`
- `app/pubspec.yaml`
- `app/lib/main.dart`
- `app/lib/core/router.dart`
- `app/lib/core/api_client.dart`
- `backend/app/main.py`
- `backend/app/core/config.py`
- `backend/app/core/database.py`

规则：

1. 工作窗口发现必须改共享文件时，先停止。
2. 把要改的内容发给主控窗口。
3. 由主控窗口统一修改并合并。

---

## 3. 高风险“容易撞文件”清单

以下文件即使不在共享文件列表中，也容易被多个窗口同时碰到：

- `app/lib/providers/auth_provider.dart`
- `app/lib/services/auth_service.dart`
- `app/lib/models/pet.dart`
- `app/lib/widgets/pet_avatar.dart`
- `app/lib/widgets/user_avatar.dart`
- `backend/app/models/__init__.py`
- `backend/app/tests/conftest.py`

建议：

- 修改前先看主控窗口有没有把这个文件分配出去
- 一个文件同一时间只给一个窗口负责

---

## 4. 每个窗口开始前先做的事

进入自己的 worktree 后先执行：

```powershell
git status
git branch --show-current
```

确认自己在正确目录、正确分支：

- 主控：`main`
- backend：`feat/backend`
- auth/family：`feat/auth-family`
- home/pet：`feat/home-pet`
- tasks/shop/tests：`feat/tasks-shop-tests`

---

## 5. 每个窗口交付前检查

### backend 窗口

```powershell
cd backend
uv run ruff check .
uv run ruff format .
uv run pytest
```

### 前端窗口

```powershell
cd app
flutter analyze
flutter test
```

提交前执行：

```powershell
git status
git add -A
git commit -m "你的提交说明"
```

---

## 6. 主控窗口的合并顺序

建议顺序：

1. `feat/backend`
2. `feat/auth-family`
3. `feat/home-pet`
4. `feat/tasks-shop-tests`

命令：

```powershell
git checkout main
git pull origin main
git merge --no-ff feat/backend
git merge --no-ff feat/auth-family
git merge --no-ff feat/home-pet
git merge --no-ff feat/tasks-shop-tests
```

---

## 7. 合并前的冲突预检查

主控窗口可用下面的命令提前看哪些文件会重叠：

```powershell
git diff --name-only main..feat/backend
git diff --name-only main..feat/auth-family
git diff --name-only main..feat/home-pet
git diff --name-only main..feat/tasks-shop-tests
```

如果想看两个功能分支是否撞文件：

```powershell
git diff --name-only feat/auth-family..feat/home-pet
```

更稳的方式是分别导出文件列表后人工比对。

---

## 8. 最短操作说明

### 启动 5 个 Warp + Codex

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start_warp_codex_parallel.ps1
```

### 只生成 Warp 配置，不立刻启动

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start_warp_codex_parallel.ps1 -NoLaunch
```

---

## 9. 一句话原则

### 可以并行

- 不同目录
- 不同功能
- 不同文件

### 不要并行

- 同一个文件
- 同一组全局配置
- 同一个路由/入口文件
- 同一个 provider/service/model
