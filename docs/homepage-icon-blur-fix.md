# 首页图标模糊修复方案

## 问题描述

HomePets 首页场景图标（任务贴纸、商店篮子、付费徽章）和任务面板内图标在高 DPI 设备上显示模糊，而家庭相框图标清晰。

## 根因分析

两个独立根因叠加：

### 1. Flame 渲染管线 — Paint 默认 FilterQuality.none

首页场景图标通过 Flame 游戏引擎的 `_SceneSpriteComponent` 渲染。其 `Paint` 对象未设置 `filterQuality`，默认 `FilterQuality.none`（最近邻采样）。

图标在 840×1871 设计画布上定义，手机屏幕（~390 逻辑像素宽）渲染时需缩小约 5.7 倍。最近邻采样直接丢弃像素 → 锯齿/模糊。

家庭相框（1254×1254）不受影响的原因：原生分辨率极高，即使最近邻丢弃像素，剩余信息仍足够保持清晰。

### 2. 任务面板图标分辨率不足

Widget 层任务面板中的 checkbox、星星等图标原生分辨率仅 47~74px，在高 DPI（3x）屏幕上的渲染需求为 120~189 物理像素，素材被强制放大 2.5 倍，超出任何采样算法能补偿的范围。

其他任务弹窗（删除确认、编辑任务、上下文菜单）中的图标同样存在分辨率 < 渲染需求的问题。

## 修复方案

### 第一步：渲染管线修复

**文件：** `app/lib/screens/home/game/home_scene_game.dart`

两处 `Paint` 实例添加 `filterQuality`：

```dart
// _SceneSpriteComponent（行 3973）— 首页场景 UI 图标
final Paint _spritePaint = Paint()
  ..filterQuality = ui.FilterQuality.medium;

// _PetSpriteComponent（行 4202）— 宠物精灵
final Paint _spritePaint = Paint()
  ..filterQuality = ui.FilterQuality.medium;
```

**文件：** `app/lib/screens/home/game/home_scene_game.dart`

Flame 任务面板内 5 处 `SpriteComponent` 添加 `paint.filterQuality`：

- `_TaskPanelOverlay`：面板底板、标题贴纸
- `_TaskPanelActionButton`：「新增任务」按钮贴纸
- `_TaskPanelItem`：行背景、checkbox

```dart
SpriteComponent(
  sprite: checkboxSprite,
  ...
)..paint.filterQuality = ui.FilterQuality.high,
```

**文件：** `app/lib/screens/home/home_scene_flame_view.dart`

Widget 层任务面板 8 处 `Image.asset()` 补 `filterQuality: FilterQuality.high`：

| 行号 | 图标 |
|------|------|
| 1787 | 任务行背景 (rowWarm/Green/Pink/Yellow) |
| 1813 | checkbox 空状态 |
| 1859 | 奖励星星（静态） |
| 1892 | 奖励星星（完成飞行动画） |
| 1979 | 空行背景 |
| 2173 | 任务贴纸便签 |
| 3459 | 上下文菜单底板 |
| 3590 | sprite 背景图 |

### 第二步：任务面板图标 4x 放大

以下 18 个图标使用 LANCZOS 算法放大至 4 倍分辨率。原始文件备份为 `*_original_backup.png`。

**目录：** `app/assets/images/ui/`

| 子目录 | 文件 | 原始分辨率 | 目标分辨率 |
|--------|------|-----------|-----------|
| `task_delete/` | `trash.png` | 116×124 | 464×496 |
| | `note.png` | 104×121 | 416×484 |
| | `cat_head.png` | 123×105 | 492×420 |
| | `cancel_button.png` | 178×82 | 712×328 |
| | `cancel_button_pressed.png` | 178×82 | 712×328 |
| | `delete_button.png` | 178×86 | 712×344 |
| | `delete_button_pressed.png` | 178×86 | 712×344 |
| 根目录 | `task_context_menu_board_compact.png` | 135×169 | 540×676 |
| | `task_context_menu_btn_edit.png` | 120×54 | 480×216 |
| | `task_context_menu_btn_delete.png` | 120×54 | 480×216 |
| | `task_context_menu_btn_cancel.png` | 120×54 | 480×216 |
| | `task_panel_checkbox_checked.png` | 160×164 | 640×656 |
| | `task_panel_checkbox_empty.png` | 134×130 | 536×520 |
| | `task_panel_reward_star.png` | 148×140 | 592×560 |
| | `task_panel_icon_food_bowl.png` | 208×186 | 832×744 |
| | `task_panel_icon_hamster.png` | 216×201 | 864×804 |
| | `task_panel_icon_leaf.png` | 178×210 | 712×840 |
| | `task_panel_icon_rabbit.png` | 208×220 | 832×880 |

## 效果

- `FilterQuality.medium`：mipmap 双线性采样替代最近邻，大幅缩小时不再丢像素
- 4x 素材：高 DPI 屏幕下有足够像素填充渲染区域，不会出现强制放大导致的模糊

## 涉及文件清单

### 代码（3 个文件）

| 文件 | 改动类型 |
|------|---------|
| `app/lib/screens/home/game/home_scene_game.dart` | `_spritePaint` filterQuality + `SpriteComponent` paint filterQuality（7 处） |
| `app/lib/screens/home/home_scene_flame_view.dart` | `Image.asset()` filterQuality（8 处） |
| `app/lib/screens/home/task_panel_sprite_catalog.dart` | 无改动（引用路径保持不变） |

### 素材（18 个文件）

`app/assets/images/ui/task_delete/`（7 个）
`app/assets/images/ui/` 根目录（11 个）

## 回滚方法

1. 代码改动通过 `git diff` / `git checkout` 回滚
2. 素材通过 `*_original_backup.png` 覆盖回原名即可恢复原始分辨率
