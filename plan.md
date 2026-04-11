# HomePets 实施计划

## 项目概述

家庭宠物养成系统，通过任务机制促进亲子互动。本阶段只实现核心功能，跳过商店和抽奖。

---

## 核心规则确认

| 决策项 | 结论 |
|--------|------|
| 宠物升级 | 简单模型：每种宠物 3-5 级，每级不同形态（占位图），积分达标自动升级 |
| 任务完成 | 管理员设置任务清单 → 成员完成 → 管理员确认 → 宠物加分 |
| 商店/抽奖 | 本次跳过，后续迭代 |
| 添加成员 | 管理员直接创建子账号（昵称），不需要真实手机号注册 |

---

## 数据模型设计

### User
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int (PK) | |
| phone | str (unique, nullable) | 手机号，管理员必填 |
| password_hash | str (nullable) | 密码哈希，管理员必填 |
| nickname | str | 显示名称 |
| role | enum | `admin` / `child` |
| avatar_url | str (nullable) | 头像 URL |
| family_id | int (FK, nullable) | 所属家庭组 |

### Family
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int (PK) | |
| name | str | 家庭组名称 |
| created_at | datetime | |

### Pet
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int (PK) | |
| name | str | 宠物昵称 |
| pet_type | str | 宠物种类（如 cat, dog, rabbit） |
| level | int | 当前等级（默认 1） |
| experience | int | 当前经验值（默认 0） |
| image_url | str (nullable) | 当前形态图片 |
| owner_id | int (FK) | 所属用户 |
| family_id | int (FK) | 所属家庭组 |

### Task
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int (PK) | |
| title | str | 任务名称 |
| description | str (nullable) | 任务描述 |
| points | int | 完成后获得的积分 |
| family_id | int (FK) | 所属家庭组 |
| is_active | bool | 是否启用（默认 True） |

### TaskCompletion
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int (PK) | |
| task_id | int (FK) | 关联任务 |
| member_id | int (FK) | 完成者 |
| status | enum | `pending` / `approved` / `rejected` |
| created_at | datetime | 提交时间 |
| reviewed_at | datetime (nullable) | 审核时间 |

---

## 实施步骤

### 第一阶段：后端基础搭建 (backend scaffold)

- [ ] 1.1 初始化 Python 项目（uv init, pyproject.toml 配置）
- [ ] 1.2 添加核心依赖（fastapi, sqlmodel, uvicorn, psycopg2, passlib, python-jose, pydantic-settings）
- [ ] 1.3 创建目录结构：`app/api/`, `app/models/`, `app/schemas/`, `app/services/`, `app/core/`, `app/tests/`
- [ ] 1.4 配置数据库连接（core/config.py, core/database.py）
- [ ] 1.5 编写 Dockerfile + docker-compose.yml（PostgreSQL + backend）
- [ ] 1.6 编写核心依赖项（core/dependencies.py — DB session, 当前用户）

### 第二阶段：用户认证 (auth)

- [ ] 2.1 编写 User model + schemas
- [ ] 2.2 实现密码哈希工具（core/security.py）
- [ ] 2.3 实现 JWT token 签发与验证
- [ ] 2.4 编写注册接口 POST `/api/auth/register`（管理员手机号注册）
- [ ] 2.5 编写登录接口 POST `/api/auth/login`（手机号+密码）
- [ ] 2.6 编写获取当前用户接口 GET `/api/auth/me`
- [ ] 2.7 编写认证相关测试

### 第三阶段：家庭组 (family)

- [ ] 3.1 编写 Family model + schemas
- [ ] 3.2 实现创建家庭组 POST `/api/families`（管理员创建，自动成为 owner）
- [ ] 3.3 实现查看家庭组 GET `/api/families/{id}`
- [ ] 3.4 实现添加子成员 POST `/api/families/{id}/members`（直接创建昵称账号）
- [ ] 3.5 实现删除成员 DELETE `/api/families/{id}/members/{member_id}`
- [ ] 3.6 实现查看成员列表 GET `/api/families/{id}/members`
- [ ] 3.7 编写家庭组相关测试

### 第四阶段：宠物系统 (pet)

- [ ] 4.1 编写 Pet model + 宠物等级配置（每种宠物的等级阈值和形态映射）
- [ ] 4.2 实现添加宠物 POST `/api/pets`（管理员为成员添加）
- [ ] 4.3 实现查看家庭宠物列表 GET `/api/families/{id}/pets`
- [ ] 4.4 实现宠物喂养逻辑（经验增加 → 自动升级判断）
- [ ] 4.5 编写宠物相关测试

### 第五阶段：任务系统 (task)

- [ ] 5.1 编写 Task + TaskCompletion models
- [ ] 5.2 实现管理员创建任务 POST `/api/tasks`
- [ ] 5.3 实现查看任务列表 GET `/api/families/{id}/tasks`
- [ ] 5.4 实现更新/删除任务 PUT/DELETE `/api/tasks/{id}`
- [ ] 5.5 实现成员提交任务完成 POST `/api/tasks/{id}/completions`
- [ ] 5.6 实现管理员审核任务 PUT `/api/completions/{id}/review`（通过→宠物加分）
- [ ] 5.7 编写任务相关测试

### 第六阶段：后端个人账号信息 (profile)

- [ ] 6.1 实现查看个人信息 GET `/api/users/{id}`
- [ ] 6.2 实现修改昵称/头像 PUT `/api/users/{id}`
- [ ] 6.3 编写个人信息相关测试

### 第七阶段：后端全量测试与收尾

- [ ] 7.1 运行所有后端测试，确保通过
- [ ] 7.2 运行 lint + typecheck（ruff check + mypy）
- [ ] 7.3 编写 API 集成测试（完整流程：注册→创建家庭→添加成员→创建任务→提交→审核→喂养）
- [ ] 7.4 确认 Swagger 文档可用

---

### 第八阶段：Flutter 项目搭建

- [ ] 8.1 创建 Flutter 项目（flutter create），清理默认模板
- [ ] 8.2 添加核心依赖：riverpod, flutter_riverpod, dio, go_router, shared_preferences, cached_network_image
- [ ] 8.3 目录结构搭建：
  ```
  lib/
    main.dart
    app.dart
    core/
      api_client.dart        # Dio 封装 + token 拦截器
      router.dart            # go_router 路由配置
      constants.dart         # API base URL 等常量
    models/                  # 数据模型（与后端对应）
    services/                # API 调用服务层
    providers/               # Riverpod providers
    screens/
      auth/
      onboarding/
      home/
      family/
      tasks/
      pet/
      profile/
    widgets/                 # 可复用组件
  test/
  ```
- [ ] 8.4 配置 API client（Dio + token 自动注入 + 错误拦截）
- [ ] 8.5 配置路由（go_router，含登录守卫）

### 第九阶段：Flutter 认证页面

- [ ] 9.1 编写 models：User
- [ ] 9.2 编写 AuthService（login, register, getMe）
- [ ] 9.3 编写 AuthProvider（Riverpod StateNotifier，管理登录状态 + token 持久化）
- [ ] 9.4 编写登录页 `LoginScreen`（手机号 + 密码）
- [ ] 9.5 编写注册页 `RegisterScreen`（手机号 + 密码 + 昵称）
- [ ] 9.6 编写认证相关 widget 测试

### 第十阶段：Flutter Onboarding 页面

- [ ] 10.1 编写 OnboardingScreen（3-5 页引导，带滑动动画）
- [ ] 10.2 用 shared_preferences 标记是否已看过，首次打开显示
- [ ] 10.3 编写 Onboarding widget 测试

### 第十一阶段：Flutter 主界面 (Home)

- [ ] 11.1 编写 models：Pet, Family
- [ ] 11.2 编写 FamilyService + PetService
- [ ] 11.3 编写 HomeProvider（加载家庭成员 + 各自的宠物）
- [ ] 11.4 编写 HomeScreen：展示所有家庭成员的宠物卡片和喂养进度
- [ ] 11.5 编写 PetCard widget（显示宠物图片、等级、经验进度条）
- [ ] 11.6 底部导航栏：主页 / 任务 / 家庭管理 / 个人中心
- [ ] 11.7 编写 Home 相关 widget 测试

### 第十二阶段：Flutter 家庭管理页面

- [ ] 12.1 编写 FamilyManagementScreen（查看家庭成员列表）
- [ ] 12.2 编写 AddMemberDialog（输入昵称，直接创建子账号）
- [ ] 12.3 编写删除成员确认对话框
- [ ] 12.4 编写 AddPetDialog（为成员选择宠物类型 + 命名）
- [ ] 12.5 编写家庭管理 widget 测试

### 第十三阶段：Flutter 任务管理页面

- [ ] 13.1 编写 models：Task, TaskCompletion
- [ ] 13.2 编写 TaskService
- [ ] 13.3 编写 TaskProvider
- [ ] 13.4 管理员视角：TaskListScreen（任务列表 + 创建/编辑/删除任务）
- [ ] 13.5 成员视角：MemberTaskScreen（查看任务 + 提交完成）
- [ ] 13.6 管理员审核页面：ReviewScreen（查看待审核列表 → 通过/拒绝 → 自动喂养宠物）
- [ ] 13.7 编写任务相关 widget 测试

### 第十四阶段：Flutter 宠物喂养交互

- [ ] 14.1 编写 FeedPetAnimation（审核通过后宠物的喂养动画反馈）
- [ ] 14.2 编写宠物升级动画（经验值满级 → 升级提示 + 新形态展示）
- [ ] 14.3 编写宠物详情页 PetDetailScreen（查看等级、历史经验、形态展示）

### 第十五阶段：Flutter 个人中心

- [ ] 15.1 编写 ProfileScreen（显示个人信息、昵称、头像）
- [ ] 15.2 编写编辑个人信息页 EditProfileScreen（修改昵称、上传头像）
- [ ] 15.3 编写退出登录功能
- [ ] 15.4 编写个人中心 widget 测试

### 第十六阶段：Flutter 全量测试与收尾

- [ ] 16.1 运行 `flutter analyze`，确保零警告
- [ ] 16.2 运行 `flutter test`，确保所有测试通过
- [ ] 16.3 端到端手动测试：完整流程（注册 → 创建家庭 → 添加成员和宠物 → 创建任务 → 提交 → 审核 → 喂养升级）
- [ ] 16.4 UI 微调与 polish

---

## API 路由总览

```
POST   /api/auth/register          注册（管理员）
POST   /api/auth/login             登录
GET    /api/auth/me                当前用户信息

POST   /api/families               创建家庭组
GET    /api/families/{id}          查看家庭组
POST   /api/families/{id}/members  添加子成员
DELETE /api/families/{id}/members/{mid} 删除成员
GET    /api/families/{id}/members  查看成员列表

POST   /api/pets                   添加宠物
GET    /api/families/{id}/pets     查看家庭宠物

POST   /api/tasks                  创建任务
GET    /api/families/{id}/tasks    查看任务列表
PUT    /api/tasks/{id}             更新任务
DELETE /api/tasks/{id}             删除任务

POST   /api/tasks/{id}/completions 提交任务完成
PUT    /api/completions/{id}/review 审核任务

GET    /api/users/{id}             查看用户
PUT    /api/users/{id}             更新用户信息
```

---

## Flutter 状态管理 & 路由

- **状态管理**: Riverpod（flutter_riverpod + riverpod_annotation）
- **路由**: go_router（支持路由守卫，未登录跳转登录页）
- **网络请求**: Dio（统一拦截器处理 token 注入、错误提示）
- **持久化**: shared_preferences（token、onboarding 标记）
- **图片加载**: cached_network_image

---

## 开发规范

- **TDD**: 每个功能先写测试，再写实现
- **后端阶段完成后运行**: `uv run ruff check . && uv run ruff format . && uv run mypy app/ && uv run pytest`
- **前端阶段完成后运行**: `flutter analyze && flutter test`
- **开发顺序**: 后端（阶段 1-7）→ 前端（阶段 8-16）
- **中文**: 用户面对的字符串使用中文

---

## Agent 并行开发规划

### 依赖分析

```
后端 scaffold (阶段1) ─┬─→ Auth (阶段2) ──┬─→ Family (阶段3) ──┬─→ Pet (阶段4) ──┐
                       │                   │                     │                  ├─→ 集成测试 (阶段7)
                       │                   │                     └─→ Task (阶段5) ──┘
                       │                   └─→ Profile (阶段6) ────────────────────┘
                       │
Flutter scaffold (阶段8) ─┬─→ Auth 页面 (阶段9) ──┬─→ Home (阶段11) ──┬─→ 宠物交互 (阶段14)
                          │                        │                   ├─→ 家庭管理 (阶段12)
                          │                        │                   └─→ 任务管理 (阶段13)
                          │                        └─→ Onboarding (阶段10)
                          └─→ 个人中心 (阶段15) ─────────────────────→ 全量测试 (阶段16)
```

### 并行原则

1. **后端 & 前端完全并行**：`backend/` 和 `app/` 是独立目录，无文件冲突
2. **共享契约**：所有 Agent 参照本 plan.md 中的数据模型和 API 规格作为接口契约
3. **前端用 mock 数据先跑通 UI**：后端 API 未就绪时，前端服务层可返回 mock 数据，后续替换为真实 API 调用
4. **同一目录内串行**：如两个 Agent 都需要修改 `backend/app/models/`，则串行执行

### 任务分配表

| Agent | 阶段 | 任务 | 依赖 | 产出 |
|-------|------|------|------|------|
| **A (后端核心)** | 1 | 项目 scaffold、Docker、DB 配置 | 无 | `backend/` 项目骨架 |
| | 2 | User model + auth API + JWT | A1 | 注册/登录接口 |
| | 3 | Family model + API | A2 | 家庭组 CRUD |
| | 4 | Pet model + 喂养逻辑 | A3 | 宠物系统 |
| | 5 | Task + TaskCompletion + API | A3 | 任务系统 |
| | 6 | 个人资料 API | A2 | 用户信息接口 |
| | 7 | 集成测试 + lint + typecheck | A4+A5+A6 | 全部测试通过 |
| **B (Flutter 基础+认证)** | 8 | Flutter 项目搭建、依赖、目录 | 无 | `app/` 项目骨架 |
| | 9 | 认证页面 + AuthProvider | B8 | 登录/注册页 |
| | 10 | Onboarding 引导页 | B8 | 引导流程 |
| | 15 | 个人中心页面 | B9 | 个人资料页 |
| **C (Flutter 业务页面)** | 11 | Home 主界面 + PetCard | B8+B9 | 主页 + 底部导航 |
| | 12 | 家庭管理页面 | B8+B9 | 成员/宠物管理 |
| | 13 | 任务管理页面 | B8+B9 | 任务 CRUD + 审核 |
| | 14 | 宠物喂养动画 + 升级 | C11 | 喂养交互 |

### 执行顺序

```
Round 0 (串行):     A1 + B8 → 后端 scaffold + Flutter scaffold 并行
Round 1 (串行):     A2 → 后端 Auth
Round 2 (并行):     A3 + B9 → 后端 Family // Flutter Auth 页面
Round 3 (并行):     A4 + B10 → 后端 Pet // Flutter Onboarding
Round 4 (并行):     A5 + C11 → 后端 Task // Flutter Home
Round 5 (并行):     A6 + C12 → 后端 Profile // Flutter 家庭管理
Round 6 (并行):     C13 + B15 → Flutter 任务管理 // Flutter 个人中心
Round 7 (并行):     C14 → Flutter 宠物交互
Round 8 (串行):     A7 + C16 → 后端集成测试 + Flutter 全量测试 + 收尾
```

### Agent 启动指令

每个 Agent 启动时需要被告知：
1. 自己负责的阶段编号
2. 需要等待哪些前置阶段完成
3. 参照 `plan.md` 中的数据模型和 API 规格
4. 完成后运行对应的 lint/test 命令
