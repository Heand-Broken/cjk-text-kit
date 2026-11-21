# itch.io 上架操作手册 — CJK Text Kit

本目录里的文件已备齐，只剩账号侧的操作需要在浏览器与命令行完成。

| 文件 | 用途 |
|---|---|
| `itch-page.md` | 页面标题、短描述、完整描述正文（直接复制粘贴） |
| `cover.png` | 封面图，630 × 250 |
| `demo.gif` | 动态演示，760 × 475，约 13 秒循环 |
| `demo.png` | 静态对照图，1280 × 800 |
| `feature-ruby.png` | 注音对照，单张最有说服力的图 |
| `feature-spacing.png` | 中西文间距示例 |
| `feature-squeeze.png` | 标点挤压示例 |
| `publish.ps1` / `publish.bat` | Windows 上一键上传（推荐） |
| `publish.sh` | Git Bash / macOS / Linux 上传 |

---

## 0. 前置条件（一次性，可能要等）

1. **itch.io 账号**：到 <https://itch.io/register> 注册并验证邮箱。
2. **税务问卷**：itch.io 首次收款前必须完成，通常 **2–7 个工作日**出结果。
   入口在 *Account Settings → Payments → Tax info*。**先做这一步**，否则
   后面收不到钱。
3. **收款方式**：问卷通过后绑定 PayPal 或 Stripe Connect。在
   *Account Settings → Payments* 设置。
4. **安装 butler**（itch.io 官方上传工具）：
   ```powershell
   winget install itchio.butler
   ```
   或从 <https://itch.io/docs/butler/> 下载 `butler.exe` 放进 PATH。
5. **生成 API key**：*Account Settings → User → API keys* → New API Key。

## 1. 打包

在项目根目录执行：

```powershell
python tools/package_release.py
```

产出：

```
dist/cjk-text-kit-v1.0.0.zip        插件本体
dist/cjk-text-kit-demo-v1.0.0.zip   可直接运行的 demo 工程
```

两个包都上传。**demo 包是转化利器**：买家可以在买之前先跑一遍。

## 2. 上传文件

```powershell
.\itch\publish.ps1 -Project 你的用户名/cjk-text-kit
```

或者双击 `itch\publish.bat` 后按提示输入 `用户名/cjk-text-kit`。
Git Bash / macOS / Linux 用 `./itch/publish.sh 用户名/cjk-text-kit`。

API key 读取顺序：环境变量 `ITCH_API_KEY` → `itch/api_key.txt`。
建议把 key 写进 `itch/api_key.txt`（该文件不要提交到版本库）。

> 如果 `butler` 报 "project not found"，先在网站上建一个空项目，
> 名字填 `cjk-text-kit`，可见性设为 **Draft**，保存后再跑上传。

## 3. 填写页面

打开 `https://itch.io/你的用户名/cjk-text-kit`：

| 位置 | 填什么 |
|---|---|
| **Title** | `CJK Text Kit for Godot 4 — Furigana, Kinsoku & CJK Typography` |
| **Short description** | `The CJK typography layer Godot never shipped.` |
| **Description** | `itch-page.md` 里 "Description" 代码块内的全部内容 |
| **Cover image** | `cover.png` |
| **Embedded file** | `demo.gif` |
| **Screenshots** | `feature-ruby.png`、`feature-spacing.png`、`feature-squeeze.png`、`demo.png` |
| **Classification** | Kind: *Assets* → Type: *Tools*；Platforms 勾 Windows / macOS / Linux / Web |
| **Tags** | `godot` `godot4` `visual-novel` `typography` `japanese` |
| **Status** | *Released* |
| **Price** | 首发 **$9.99**，稳定后改成 **$19.99** |
| **Visibility** | 全部填完、素材上传完再改 **Public** |

### 关于图片

`itch-page.md` 里的图片用的是相对路径（`feature-ruby.png`）。在 itch 的
描述编辑器里**直接拖拽上传**对应图片，编辑器会自动替换成正确 URL；或者
把相对路径换成你自己的 CDN 地址。

### 关于抽成

*Account Settings → Payments* 里可以把 itch.io 平台抽成设为 **0%**。
建议首发期间设为 0% 换取更好的价格竞争力，稳定后再调整。

## 4. 发布后推广

itch 的流量主要来自站内搜索和帖子，外部流量要自己引。按优先级：

1. **BOOTH（pixiv）** — 日文圈的主要市场，比 itch 更精准。做一份日文版
   页面与日文 demo 视频。
2. **X / Twitter** — 日中独立开发者的聚集地。发布那段 30 秒对照视频：
   同一段文本，左边是正确注音，右边是 `[ruby=...]` 字面文本。这一帧
   自己就说明了一切。
3. **itch.io devlog / 帖子** — 站内流量，配合折扣。
4. **Baidu / Bilibili / 小红书** — 中文独立开发者与视觉小说圈。
5. **Godot Asset Store** — 免费上架做长期引流位。付费功能官方还没开放，
   但页面是永久的。

**交叉导流**：在 FaceDeck 页面加一句"另见 CJK Text Kit"，反过来也一样。
两者面向同一批买家（日 / 中视觉小说独立开发者），一个管立绘，一个管文本。
这是目前最直接的转化路径。

## 5. 关于收益预期（别自我安慰）

- 成熟工具在 itch.io 的真实量级：全年 **567 份 / $4,869**（Pixel Composer
  的公开年报）。
- 同样品类的 Godot 插件价格带在 **$5–$35**。
- 一个没有评价、没有视频、没有历史的新工具，初期通常是**每月十几份**。

所以 $19.99 的插件，第一年 **60–200 份、约 $900–$3,000** 是合理预期。
这不是一个能替代工资的生意，是一个可以复利的第一块砖。真正的收入来自
产品线叠加 + itch 之外的渠道。

## 6. 常见问题

**上传后下载链接失效？**
`butler push` 不会自动改版本号或改已有文件。需要更新时重新 push 即可，
但要在 *Settings → Version* 里手动改版本号和 changelog。

**打包时 `.uid` 文件要不要保留？**
保留。Godot 4.4+ 用它存脚本的稳定资源 ID，官方插件也都带着。当前打包
脚本已经默认保留 `.uid`、排除 `.import`。

**Linux/macOS 买家怎么装？**
插件是纯 GDScript，跨平台。字体请用 `CJKFonts.create_system_font()`
解析系统字体，或使用自己有权分发的字体文件。

**买家在 Godot 4.4 上能用吗？**
插件只用 4.0 起就存在的 API，4.4 预计可用，但**未经验证**（下载受网络
限制无法实测）。如果买家反馈问题，在 README 的 Compatibility 一节补上
实测结论。
