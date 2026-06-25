# 拾星小宠七天试用期与强制 Paywall 方案说明

文档状态：方案设计，不改代码。  
汇总人：@TechLead  
日期：2026-05-16

## 1. 结论

推荐方案：

```text
后端权威 7 天免费体验 + RevenueCat/商店订阅校验 + 前端统一访问拦截 + 到期强制 Paywall
```

也就是：

- 新用户注册并创建家庭后，自动获得 7 天免费体验。
- 7 天内正常使用拾星小宠核心功能。
- 到期后如果没有有效订阅，进入强制 Paywall。
- 未订阅时不能使用核心功能，但必须保留合规和账号相关入口。
- 订阅状态以后端 entitlement 为准，不能只靠前端本地时间或本地缓存。
- RevenueCat 用于购买、恢复购买、订阅真实性验证和 webhook 同步。

关键提醒：

- 不要做“用户没有同意订阅，7 天后自动扣费”。如果要自动续费免费试用，必须走 App Store / Google Play 的订阅试用购买流程，并在购买页明确展示试用时长、试用结束后的价格和周期。
- 本文推荐第一版采用“先免费体验 7 天，第 8 天再引导订阅”的模式，不把商店侧 free trial 作为唯一试用机制。
- 如果后续决定使用商店官方 7 天 free trial，就不要再叠加拾星小宠自定义 7 天体验，避免“双重试用”和审核/用户理解混乱。

## 2. 当前项目基础

项目中已经有部分订阅能力：

- Flutter 端已有 `RevenueCatService`、`RevenueCatNotifier`、`PaywallScreen`。
- 路由已有 `/paywall`，当前会重定向到 `/home?panel=paywall`。
- `docs/revenuecat-configuration.md` 已说明 RevenueCat public SDK key、secret key、webhook auth 等配置。
- 当前 `RevenueCatService.initialize()` 还没有绑定稳定 app user id，默认匿名用户会让后端 webhook 难以映射到拾星小宠用户/家庭。
- 当前 Paywall 视觉资产里有较多烘焙文字/价格，不适合正式订阅页，需要改成 Flutter 动态文本。

本文只说明目标方案，不要求现阶段修改代码。

## 3. 产品规则

### 3.1 试用主体

推荐：按家庭 owner / 管理员账号生效。

规则：

- 管理员注册成功并创建家庭后，家庭获得 7 天免费体验。
- 家庭内成员共享 owner 的试用/订阅状态。
- 孩子/成员档案不独立购买、不独立订阅。
- 如果用户还没创建家庭，可以临时按个人账号记录试用状态；一旦创建家庭，迁移到家庭级 entitlement。

原因：

- 拾星小宠是家庭任务和宠物成长产品，付费决策人是家长。
- 家庭只订阅一次更符合使用场景。
- 不按设备或本地安装时间计时，避免卸载重装、换设备、改本地时间绕过。

### 3.2 试用开始时间

推荐：

```text
管理员注册成功并自动创建家庭时开始试用
```

后端记录：

```text
trial_started_at = server_now_utc
trial_ends_at = server_now_utc + 7 days
```

老用户迁移建议：

- 如果功能上线前已有用户，建议从上线当天补发 7 天试用。
- 不建议按历史注册时间直接判过期，否则大量老用户上线后立刻被 Paywall 锁住，体验很硬。

### 3.3 锁定范围

试用过期且未订阅时锁定核心功能：

- 首页主场景互动。
- 添加/编辑/删除家庭成员。
- 选择/编辑宠物。
- 创建、编辑、删除、完成任务。
- 宠物成长、积分、任务记录等核心数据写入。
- 家庭管理相关能力。

可以保留只读概览入口，但第一版建议简单：核心界面统一进入强制 Paywall，避免状态复杂。

### 3.4 必须保留入口

即使试用过期且未订阅，也不能把用户锁死。必须可访问：

- 登录 / 退出登录。
- 恢复购买。
- 订阅管理 / 取消订阅说明。
- 隐私政策。
- 用户协议。
- 账号删除 / 数据删除。
- 客服 / 反馈。
- App 版本信息。
- 订阅状态刷新 / 重试。

这些入口既是用户信任问题，也是 Apple / Google 审核风险点。

## 4. 状态机

建议后端和前端统一使用以下状态：

| 状态 | 含义 | 是否允许核心功能 | 前端表现 |
| --- | --- | --- | --- |
| `loading` | 正在拉取状态 | 否 | 启动加载或骨架屏，不直接放行 |
| `trial_active` | 试用中，剩余 3 天以上 | 是 | 首页轻量显示剩余天数 |
| `trial_expiring` | 试用剩 2 天或 1 天 | 是 | 温和提醒，可关闭 |
| `trial_expired_unsubscribed` | 试用结束且无订阅 | 否 | 强制 Paywall |
| `subscribed_active` | 订阅有效 | 是 | 正常使用，设置页显示会员状态 |
| `subscription_grace_period` | 商店宽限期 / 账单重试期 | 是或受限，由后端决定 | 提醒用户更新付款方式 |
| `subscription_expired` | 订阅已过期且无宽限 | 否 | 强制 Paywall |
| `offline_cached_active` | 最近一次后端确认有效，短暂离线 | 可短时只读或有限放行 | 显示离线提示 |
| `offline_unverified_or_expired` | 无法确认且本地状态已过期/未知 | 否 | 要求联网确认 |
| `blocked` | 后端明确禁止访问 | 否 | 显示原因和支持入口 |

核心原则：

- 试用和订阅判断以后端 UTC 时间为准。
- Flutter 只展示后端返回的剩余天数和状态。
- 本地缓存只能优化体验，不能作为永久授权。

## 5. 后端设计

### 5.1 数据模型

推荐长期方案：新增 `subscriptions` 表，而不是把所有字段塞进 `users`。

建议字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | int | 主键 |
| `user_id` | int nullable | 用户级订阅时使用 |
| `family_id` | int nullable | 家庭级订阅时使用，推荐主路径 |
| `trial_started_at` | datetime | 试用开始时间 |
| `trial_ends_at` | datetime | 试用结束时间 |
| `status` | str/enum | `trial_active` / `trial_expired_unsubscribed` / `subscribed_active` / `subscription_grace_period` / `subscription_expired` / `blocked` |
| `provider` | str | `revenuecat` |
| `entitlement_id` | str | 例如 `premium` |
| `revenuecat_app_user_id` | str | RevenueCat app user id |
| `original_app_user_id` | str nullable | RevenueCat 原始用户 id |
| `product_id` | str nullable | 当前订阅商品 id |
| `expires_at` | datetime nullable | 订阅到期时间 |
| `will_renew` | bool | 是否自动续订 |
| `last_verified_at` | datetime nullable | 最近一次服务端校验时间 |
| `last_event_id` | str nullable | 最近处理的 RevenueCat webhook event id，用于幂等 |
| `created_at` | datetime | 创建时间 |
| `updated_at` | datetime | 更新时间 |

第一版如果为了快速实现，也可以先在 `users` 或 `families` 上加字段；但如果已经确定家庭共享订阅，建议直接使用独立 `subscriptions` 表关联 `family_id`。

### 5.2 状态查询接口

建议接口：

```http
GET /api/subscription/status
```

或命名为：

```http
GET /api/me/entitlement
```

推荐响应：

```json
{
  "status": "trial_active",
  "access_allowed": true,
  "paywall_required": false,
  "reason": null,
  "scope": "family",
  "family_id": 12,
  "trial_started_at": "2026-05-16T00:00:00Z",
  "trial_ends_at": "2026-05-23T00:00:00Z",
  "trial_days_remaining": 7,
  "is_premium_active": false,
  "entitlement_id": "premium",
  "product_id": null,
  "subscription_expires_at": null,
  "will_renew": false,
  "last_verified_at": "2026-05-16T00:00:00Z"
}
```

试用过期响应：

```json
{
  "status": "trial_expired_unsubscribed",
  "access_allowed": false,
  "paywall_required": true,
  "reason": "trial_expired",
  "trial_days_remaining": 0,
  "entitlement_id": "premium"
}
```

订阅有效响应：

```json
{
  "status": "subscribed_active",
  "access_allowed": true,
  "paywall_required": false,
  "reason": null,
  "is_premium_active": true,
  "subscription_expires_at": "2026-06-16T00:00:00Z",
  "will_renew": true,
  "entitlement_id": "premium"
}
```

### 5.3 后端访问控制

不能只在 Flutter 弹 Paywall。所有核心 API 都必须加后端 guard。

建议新增依赖：

```python
def require_active_access(current_user: User = Depends(get_current_user)) -> User:
    # 1. 查询用户/家庭 entitlement
    # 2. 订阅有效 -> allow
    # 3. 试用未过期 -> allow
    # 4. 宽限期 -> 按策略 allow 或有限 allow
    # 5. 否则 raise 402
    return current_user
```

试用过期返回：

```http
HTTP/1.1 402 Payment Required
```

```json
{
  "detail": {
    "code": "ENTITLEMENT_REQUIRED",
    "message": "试用期已结束，请订阅后继续使用。",
    "reason": "trial_expired",
    "trial_ends_at": "2026-05-08T00:00:00Z"
  }
}
```

需要保护：

- 宠物、任务、家庭成员、积分、成长记录等核心 API。
- 后续如恢复商店功能，也必须保护积分消费、道具购买等接口。

白名单：

- 登录 / 注册。
- 订阅状态查询。
- 购买同步。
- RevenueCat webhook。
- 恢复购买所需接口。
- 账号删除 / 数据删除。
- 隐私政策 / 用户协议 / 客服信息。
- 健康检查。

### 5.4 RevenueCat 同步

建议接口：

```http
POST /api/revenuecat/webhook
POST /api/subscription/sync
```

Webhook 要求：

- 使用 `REVENUECAT_WEBHOOK_AUTH` 校验 `Authorization` header。
- 快速返回，复杂处理可异步化。
- 处理重复事件：用 RevenueCat event id 幂等。
- 不只看事件类型，要基于 entitlement、expiration、product id、app user id 更新最终状态。

需要处理的事件：

- `INITIAL_PURCHASE`
- `RENEWAL`
- `UNCANCELLATION`
- `CANCELLATION`
- `EXPIRATION`
- `BILLING_ISSUE`
- `PRODUCT_CHANGE`
- `TRANSFER`

购买成功后的即时同步：

1. Flutter 完成 RevenueCat purchase / restore。
2. Flutter 调用后端 `/api/subscription/sync`。
3. 后端用 RevenueCat secret/API 查询当前 app user id 的 entitlement。
4. 后端更新本地 subscription 状态。
5. Flutter 重新请求 `/api/subscription/status`。
6. `access_allowed = true` 后关闭 Paywall。

这样可以避免 webhook 延迟导致用户已付费但仍被挡在 Paywall。

### 5.5 RevenueCat App User ID

必须使用稳定 app user id，不建议匿名用户。

推荐：

```text
user_{user_id}
```

如果采用家庭级订阅，也可以：

```text
family_{family_id}
```

注意：

- 如果用 `family_{family_id}`，必须在家庭创建后再绑定或调用 `Purchases.logIn()`。
- 如果先匿名初始化 RevenueCat，再登录，需要调用 `logIn(stableAppUserId)` 做身份切换。
- 后端 webhook 必须能从 RevenueCat app user id 映射回拾星小宠用户/家庭。

## 6. Flutter 端设计

### 6.1 统一 Entitlement Gate

建议在 `authProvider` 之后新增：

```text
subscriptionProvider / entitlementProvider
```

职责：

- 登录后拉取 `/api/subscription/status`。
- 保存状态、剩余天数、到期时间、paywall reason。
- 购买/恢复购买后刷新状态。
- 监听 API 402 并触发 Paywall。

路由层建议：

- 使用 `GoRouter.redirect` 或顶层 `EntitlementGate` 做统一拦截。
- 不要在各页面散落 `showDialog(paywall)`，否则容易重复弹窗、返回栈混乱、绕过部分入口。
- 到期后进入稳定的 `/paywall?reason=trial_expired&return=/home` 或全屏锁定壳。

### 6.2 路由放行与锁定

放行：

- `/login`
- `/register`
- `/paywall`
- `/profile/legal/privacy`
- `/profile/legal/terms`
- `/support`
- `/account/delete`
- 退出登录
- 恢复购买 / 订阅管理说明

锁定：

- `/home`
- `/tasks`
- `/family`
- 宠物详情
- 任务完成/编辑/创建
- 成员创建/编辑/删除
- 所有核心写操作入口

### 6.3 Paywall 模式

Paywall 需要区分两种模式：

| 模式 | 场景 | 是否允许关闭 |
| --- | --- | --- |
| `optional` | 用户主动查看会员页 | 可以 |
| `blocking` | 试用到期且无订阅 | 不可关闭进入核心功能 |

`blocking` 模式要求：

- 不展示关闭按钮，或关闭时只提示“试用期已结束，请订阅后继续使用”。
- Android 返回键不能绕过。
- iOS 手势返回不能绕过。
- 点击背景不能关闭。
- 购买成功 / 恢复购买成功后自动返回原目标页面。
- 购买取消 / 失败后留在 Paywall，但合规入口仍可点击。

### 6.4 API 402 拦截

`ApiClient` 增加统一处理：

- 收到 `402` 且 code 为 `ENTITLEMENT_REQUIRED`。
- 不清登录 token。
- 更新 entitlement 状态。
- 跳转或打开强制 Paywall。

建议通过 `SubscriptionAccessBus` 之类的事件总线通知 UI，不让 API 层直接持有 `BuildContext`。

### 6.5 本地缓存与离线

本地可缓存：

- `last_entitlement_status`
- `trial_ends_at`
- `subscription_expires_at`
- `last_verified_at`
- `paywall_return_route`

使用原则：

- 缓存只用于启动速度和短时间离线提示。
- 不能用缓存长期放行。
- 第一次登录或状态未知时必须联网确认。
- 已过期或无法确认时，不允许进入核心功能。

## 7. Paywall 信息架构与文案

### 7.1 试用期内

首页轻量提示：

```text
7 天免费体验已开启，还剩 6 天
```

设置/会员入口：

```text
试用期内可完整体验家庭任务、宠物成长和任务记录。试用结束后需要订阅继续使用。
```

剩 2 天 / 1 天：

```text
试用期即将结束。订阅后可继续管理家庭任务和宠物成长。
```

不要在试用期内每天强弹 Paywall。首日应该优先让用户完成“添加孩子 -> 选择宠物 -> 创建任务 -> 确认完成一次”的核心闭环。

### 7.2 试用结束

标题：

```text
试用期已结束
```

说明：

```text
订阅拾星小宠后，可以继续使用家庭任务、宠物成长和成长记录功能。
```

主按钮：

```text
继续使用拾星小宠
```

副入口：

```text
恢复购买
管理订阅
联系客服
隐私政策
用户协议
删除账号/数据
```

### 7.3 订阅购买信息

必须动态展示：

- 套餐名。
- 订阅周期。
- 真实价格和本地货币。
- 订阅权益。
- 是否自动续订。
- 如果使用商店侧 free trial，明确写清试用时长、试用结束后的价格/周期、取消方式。

不允许：

- 把价格、周期、试用说明烘进图片。
- 显示与 App Store / Google Play 返回价格不一致的金额。
- 使用“永久免费”之类会误导用户的文案。

### 7.4 必备状态

Paywall 至少覆盖：

- 加载套餐。
- 无可用套餐。
- 购买中。
- 购买成功但后端同步中。
- 购买失败。
- 用户取消购买。
- 恢复购买中。
- 恢复成功。
- 恢复失败。
- 已订阅但状态刷新失败。
- 离线无法确认。
- 订阅过期。
- 账单宽限期 / 重试期。

## 8. 视觉与素材方案

推荐视觉方向：

- 沿用拾星小宠温馨纸张/房间风格。
- 不做冷冰冰的商业锁屏。
- 语气是“继续守护家庭任务和宠物成长”，不是“禁止使用”。

素材原则：

- 背景底板、插图、按钮底图、权益 icon 可以是图片。
- 价格、周期、套餐名、试用说明、条款、恢复购买、错误提示必须由 Flutter 动态文本渲染。
- 不要继续使用烘字大图作为最终 Paywall。

建议素材包：

```text
paywall_panel_bg_9slice
paywall_hero_family_pet
trial_badge_7_days
benefit_family
benefit_tasks
benefit_growth
plan_card_selected
plan_card_unselected
primary_cta_normal
primary_cta_pressed
primary_cta_loading
primary_cta_disabled
trial_countdown_chip
expired_lock_soft
offline_verify_hint
```

上架截图建议：

- 可规划一张“7 天试用 / 订阅权益”截图。
- 文案必须明确“7 天试用，之后需订阅继续使用”。
- 不展示“永久免费”或模糊付费条件的说法。

## 9. 合规要求

必须补齐：

- 隐私政策 URL。
- 用户协议 URL。
- 账号删除 / 数据删除路径。
- 支持邮箱或客服入口。
- App Store / Google Play 元数据中明确说明订阅和 IAP。

Paywall 必须保留：

- 恢复购买。
- 订阅管理 / 取消说明。
- 隐私政策。
- 用户协议。
- 客服。
- 账号删除 / 数据删除。

儿童/家庭场景口径：

- 产品面向家长。
- 孩子是家长创建和管理的成员档案。
- 不面向儿童独立注册。
- 不让孩子成员触发支付。
- 不做广告追踪。

如果使用商店官方 free trial：

- 必须按商店规则配置。
- 用户必须明确同意订阅。
- 购买页必须明确试用时长、试用结束后的价格和周期、可取消方式。

## 10. 官方依据

- Apple 自动续订订阅要求：订阅页需要包含订阅名称/时长/服务内容、完整续订价格、恢复购买入口；如果有免费试用，购买流程中必须清楚说明免费试用持续多久以及试用结束后的价格。<https://developer.apple.com/app-store/subscriptions/>
- Apple introductory offers：App Store Connect 支持为自动续订订阅配置 free trial / pay up front / pay as you go；eligible 用户可看到 introductory offer。<https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions/>
- Apple 账号删除要求：支持账号创建的 App 需要提供账号删除能力。<https://developer.apple.com/support/offering-account-deletion-in-your-app>
- Google Play 订阅：订阅通过 base plan / offer 提供 entitlement；免费试用可以作为 offer 配置，试用结束后转入 base plan。<https://support.google.com/googleplay/android-developer/answer/12154973>
- Google Play 账号删除和数据删除要求：<https://support.google.com/googleplay/android-developer/answer/13327111>
- RevenueCat Entitlements：使用 entitlement 判断用户是否有访问权限。<https://www.revenuecat.com/docs/customers/customer-info>
- RevenueCat Webhooks：Webhook 应校验 Authorization，处理延迟和重复事件，并保持幂等。<https://www.revenuecat.com/docs/integrations/webhooks>

## 11. 不建议做法

- 不建议用纯 `SharedPreferences` 或本地安装时间判断 7 天。
- 不建议用手机本地时间判断试用是否过期。
- 不建议只在前端拦截，不在后端核心 API 做 entitlement guard。
- 不建议用户没明确订阅就自动收费。
- 不建议 App 内 7 天体验和商店 7 天免费试用同时叠加。
- 不建议把 Paywall 做成完全无出口的死锁页面。
- 不建议让孩子成员看到购买按钮。
- 不建议把价格、套餐名、条款、恢复购买烘进 PNG。
- 不建议试用期内每天强弹商业化页面。
- 不建议购买成功后只相信客户端回调，必须刷新后端状态。

## 12. 实施阶段建议

### 阶段 1：产品和合规定稿

1. 确认订阅按家庭共享。
2. 确认老用户补发 7 天试用。
3. 确认第一版使用拾星小宠自定义免费体验，不使用商店侧 free trial。
4. 补隐私政策、用户协议、账号/数据删除入口。
5. 定稿 Paywall 文案和套餐描述。

### 阶段 2：后端 entitlement

1. 新增 `subscriptions` 表或等价字段。
2. 注册/创建家庭时初始化试用。
3. 新增 `/api/subscription/status`。
4. 新增核心 API `require_active_access`。
5. 新增 RevenueCat webhook。
6. 新增 `/api/subscription/sync`。
7. 写试用、过期、订阅、webhook、幂等测试。

### 阶段 3：Flutter 访问门禁

1. 新增 `SubscriptionStatus` model。
2. 新增 `SubscriptionService`。
3. 新增 `subscriptionProvider`。
4. 登录后拉取后端状态。
5. GoRouter 或 `EntitlementGate` 统一拦截。
6. Dio 402 统一触发 Paywall。
7. Paywall 增加 `blocking` 模式。

### 阶段 4：RevenueCat 生产接入

1. 使用稳定 app user id 初始化或登录 RevenueCat。
2. 配置 iOS / Android production public SDK key。
3. 配置 entitlement id。
4. 配置 webhook authorization。
5. 使用 RevenueCat Test Store / sandbox 验证购买、恢复、过期、退款。

### 阶段 5：设计与素材

1. 拆分 Paywall 素材，移除烘字价格和条款。
2. 补试用倒计时 chip、到期页、离线提示、购买失败状态。
3. 做 Android / iOS 真机截图验收。
4. 准备上架截图，明确付费条件。

## 13. 测试用例

### 后端

- 注册新用户后试用开始时间为服务端 UTC 当前时间。
- 新用户 `trial_ends_at = trial_started_at + 7 days`。
- 试用期内调用核心 API 成功。
- 试用过期且无订阅调用核心 API 返回 402。
- 订阅有效时即使试用过期也允许访问。
- 家庭成员共享 owner 订阅。
- 孩子成员不能发起购买。
- webhook 鉴权失败返回 401。
- webhook 重复事件不会重复处理。
- 购买、续订、取消、过期、退款、账单失败状态更新正确。
- `/api/subscription/sync` 可立即修复 webhook 延迟。

### Flutter

- 登录后 `trial_active` 不弹强制 Paywall。
- 试用期显示剩余天数。
- 剩 2/1 天显示温和提醒。
- `trial_expired_unsubscribed` 自动进入 blocking Paywall。
- blocking Paywall 无法用关闭按钮、返回键、手势、空白点击绕过。
- 购买成功后刷新后端状态并自动回到原页面。
- 恢复购买成功后自动解锁。
- 购买取消/失败时仍停留 Paywall，合规入口可点击。
- API 402 触发 Paywall。
- 离线但缓存有效时按策略提示。
- 离线且状态未知/已过期时要求联网确认。

### 审核与合规

- Paywall 显示真实价格、周期、权益、恢复购买、隐私政策和用户协议。
- App Store / Google Play 元数据说明订阅/IAP。
- 账号删除入口在 Paywall 锁定状态下仍可访问。
- 孩子成员不会看到购买按钮。
- 上架截图没有误导“永久免费”。

## 14. 验收标准

1. 新用户注册/创建家庭后 7 天内可正常使用核心功能。
2. 第 8 天打开 App 自动进入强制 Paywall。
3. 未订阅时无法进入首页、任务、家庭、宠物等核心功能。
4. 未订阅时直接调用核心 API 返回 402。
5. 订阅成功后立即解除限制。
6. 恢复购买成功后立即解除限制。
7. 订阅过期、退款或失效后重新进入限制状态。
8. Paywall 保留恢复购买、订阅管理、隐私政策、用户协议、账号/数据删除、客服入口。
9. RevenueCat production key、entitlement id、webhook auth 都通过环境变量配置。
10. App Store / Google Play 审核所需隐私、订阅、账号删除说明齐全。

## 15. 仍需产品确认

推荐默认值如下：

| 决策点 | 推荐 |
| --- | --- |
| 订阅范围 | 家庭 owner 订阅，家庭共享 |
| 试用开始 | 管理员注册并创建家庭时 |
| 老用户迁移 | 上线当天补发 7 天试用 |
| 商店侧 free trial | 第一版不使用，避免双重试用 |
| 到期后是否允许只读 | 第一版不进入核心界面，只保留合规入口 |
| 孩子成员是否看到购买按钮 | 不显示，只提示请家长订阅 |
| Paywall 是否可关闭 | optional 模式可关闭；blocking 模式不能关闭进入核心功能 |

## 16. 一句话原则

**前端负责清晰展示和统一拦截，后端负责最终访问控制，RevenueCat 负责订阅真实性，试用期由后端 UTC 时间统一计算，合规入口永远不能被 Paywall 挡住。**
