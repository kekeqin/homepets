# RevenueCat 配置说明

HomePets 的 Flutter 端使用 RevenueCat public SDK key 初始化购买 SDK。后端只在需要校验订阅状态、处理 webhook 或调用 RevenueCat REST API 时使用服务端 secret key。

## Flutter 开发/测试配置

当前开发和测试构建默认使用 RevenueCat Test Store public SDK key：

```text
test_NFtgmTDZrduESWajnYMSIvXsQeR
```

正常本地开发可以直接运行：

```bash
flutter run
```

如果需要显式指定使用 Test Store：

```bash
flutter run --dart-define=REVENUECAT_USE_TEST_STORE=true
```

`REVENUECAT_IOS_API_KEY` 或 `REVENUECAT_ANDROID_API_KEY` 如果被传成空字符串，代码会在非 release 构建中回退到 Test Store key，避免 paywall 显示“请通过 --dart-define 配置 RevenueCat public SDK key”。

注意：`--dart-define` 是编译期配置。修改 key 后需要完整停止 app 并重新 `flutter run`，hot reload 不会重新注入编译期环境变量。

## Flutter 生产配置

release 构建不会默认使用 Test Store key。上线包必须传 RevenueCat 后台对应平台的 public SDK key：

```bash
flutter build ipa --dart-define=REVENUECAT_IOS_API_KEY=你的_ios_public_key
flutter build appbundle --dart-define=REVENUECAT_ANDROID_API_KEY=你的_android_public_key
```

如果 entitlement id 不是默认的 `premium`，构建时同时传入：

```bash
--dart-define=REVENUECAT_ENTITLEMENT_ID=你的_entitlement_id
```

## 后端配置

后端不要使用 Flutter 的 public SDK key。只有需要服务端验证订阅、同步会员状态、处理退款/过期事件或调用 RevenueCat REST API 时，才需要在 `backend/.env` 中配置：

```env
REVENUECAT_SECRET_API_KEY=
REVENUECAT_PROJECT_ID=
REVENUECAT_WEBHOOK_AUTH=
REVENUECAT_ENTITLEMENT_ID=premium
```

说明：

- `REVENUECAT_SECRET_API_KEY`：RevenueCat 服务端 secret key，通常以 `sk_` 开头，只能放后端。
- `REVENUECAT_PROJECT_ID`：调用 RevenueCat REST API v2 时使用。
- `REVENUECAT_WEBHOOK_AUTH`：RevenueCat webhook 的 Authorization header 校验值，建议使用长随机字符串。
- `REVENUECAT_ENTITLEMENT_ID`：与 RevenueCat Dashboard 中的 entitlement 保持一致，当前默认 `premium`。

## 最佳实践

- Flutter 端只放 public SDK key。public SDK key 可以随 app 分发，但只能用于 SDK 初始化。
- secret key 只放后端 `.env` 或部署平台密钥管理中，不要写入 Flutter、前端资源或 git。
- Test Store key 只用于开发/测试。生产 iOS/Android 包使用各自平台的 RevenueCat public SDK key。
- 推荐 CI/CD 或 IDE run configuration 通过 `--dart-define` 注入生产 key，不要把正式 key 写死在业务代码里。
- 如果后端需要稳定识别订阅用户，前端应使用后端用户 ID 或家庭 owner ID 作为 RevenueCat app user id，避免长期依赖匿名用户 ID。

## 常见问题

### Paywall 提示缺少 public SDK key

确认当前运行的是重新编译后的 app：

```bash
flutter clean
flutter pub get
flutter run
```

如果是 release 包，确认构建命令传入了对应平台 key。

### 本地想强制不用 Test Store

可以显式关闭测试 key 回退：

```bash
flutter run --dart-define=REVENUECAT_USE_TEST_STORE=false
```

这时必须同时传入当前平台 public SDK key，否则 paywall 会显示缺 key。

### 后端是否需要 public SDK key

不需要。public SDK key 属于 Flutter SDK 初始化配置；后端如需接入 RevenueCat，只使用 secret key、project id 和 webhook authorization。

## 官方参考

- RevenueCat SDK 配置：https://www.revenuecat.com/docs/getting-started/configuring-sdk
- RevenueCat API key 类型：https://www.revenuecat.com/docs/projects/authentication
- RevenueCat Test Store：https://www.revenuecat.com/docs/test-and-launch/sandbox/test-store
