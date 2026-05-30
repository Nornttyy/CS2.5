# 项目说明

一个 **2D 非像素风（HD / 矢量 / 平滑插画风）** 游戏，使用 **Godot 4** 开发。
玩法类型尚未确定，先搭建工程与基础规范，确定玩法后再补充。

## 技术栈

- 引擎：Godot 4.x（稳定版）
- 脚本：GDScript（如需高性能模块再考虑 C# / GDExtension）
- 渲染：默认 Forward+（桌面端）；若计划发布到 Web/移动端，改用 Compatibility 渲染后端

## 非像素风的关键设置（重要）

因为是「非像素风」而不是像素风，以下默认值必须区别于像素游戏教程的常见写法：

- **纹理过滤用 Linear（线性），不要用 Nearest。**
  - 项目设置：`rendering/textures/canvas_textures/default_texture_filter = Linear`
  - 导入图片时 Filter 保持开启，避免缩放后出现锯齿/硬边。
- **窗口缩放用 `canvas_items` 模式**，而非 `viewport`：
  - `display/window/stretch/mode = canvas_items`
  - `display/window/stretch/aspect = expand`（或 `keep`，按需）
- **使用高分辨率素材**（PNG/SVG/WebP），允许平滑缩放；UI 优先用矢量或高 DPI 资源。
- 美术资源面向「缩放后依然清晰」设计，不依赖整数像素对齐。

## 工程约定

- 目录结构（建议，按需调整）：
  - `scenes/` 场景（`.tscn`）
  - `scripts/` 脚本（`.gd`，与场景分离便于复用）
  - `assets/` 美术、音频、字体等原始资源
  - `autoload/` 全局单例（Autoload）
  - `addons/` 第三方插件
- 命名：场景/节点用 PascalCase，脚本文件用 snake_case，变量/函数用 snake_case。
- 优先用「组合 + 信号」解耦，避免节点间硬引用满天飞。

## 常用命令

> 安装好 Godot 后，将 `godot` 替换为本机可执行文件路径。

- 命令行打开编辑器：`godot --editor --path .`
- 无头运行（CI/测试）：`godot --headless --path .`
- 导出（需先在编辑器里配置 export preset）：`godot --headless --export-release "<preset>" <output>`

## 给 Claude 的工作提示

- 改动 `.tscn` / `.tres` 等 Godot 资源文件时要谨慎：它们是带 UID 和内部引用的文本格式，手改易损坏，能在编辑器里做的尽量说明步骤而不是直接乱改文件。
- 涉及美术/缩放表现时，始终按「非像素风」处理（线性过滤、平滑缩放），不要套用像素风的 Nearest 设置。
- 玩法尚未确定：涉及核心玩法决策时先和用户确认，不要擅自假定游戏类型。
