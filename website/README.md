# 拾星小宠官网

官方域名：https://pickstarpet.kkqin.com

静态站点，无需构建。将本目录部署到 Web 服务器根路径即可。

## 页面

| 路径 | 文件 | 说明 |
|------|------|------|
| `/` | `index.html` | 首页（品牌 + 转化） |
| `/privacy.html` | `privacy.html` | 隐私政策 |
| `/terms.html` | `terms.html` | 用户协议 |
| `/support.html` | `support.html` | 帮助 / FAQ / 删号 |

## 设计语言

- 奶油底色 + 薄荷绿主 CTA（与 App / 小红书物料一致）
- 真实 App 图标 `assets/app-icon.png`
- 产品插画：`login-bg.png`、`hero-home.png`、宠物与任务素材
- 响应式：桌面双栏 Hero，平板/手机自动堆叠

## 本地预览

```bash
cd website
python -m http.server 5173
```

打开 http://localhost:5173

## 部署

生产域名 `https://pickstarpet.kkqin.com` 由后端容器同时提供 API 与官网静态页：

- 后端启动时会查找 monorepo 的 `website/`（Docker 镜像内为 `/app/website`）
- 对外路径：`/privacy.html`、`/terms.html`、`/support.html`、`/`、`/styles.css`、`/assets/*`
- 构建镜像（在仓库根目录）：

```bash
./backend/build-docker.sh
# 或
docker build -f backend/Dockerfile -t pickstarpet:latest .
```

本地仅预览静态页时：

1. `cd website && python -m http.server 5173`
2. 确认 `assets/`、`styles.css` 可访问
3. App Store 正式链接就绪后，替换首页 / 支持页下载 URL
4. 如需 ICP 备案，在页脚 `site-footer__bottom` 追加
