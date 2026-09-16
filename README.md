# DesktopDestruction

一款 macOS 原生桌面视觉发泄工具。启动后会先截取当前桌面画面，再在全屏透明覆盖层中展示锤子、机枪、电锯、水枪、火焰、炸弹、橡皮擦、核弹、拳头以及虫子、小人、车辆、动物、任意 emoji 和围墙等 15 种工具效果。

## 安全边界

- 所有破坏都只发生在内存截图和覆盖层上。
- 不读取、移动、重命名或删除真实文件。
- 按 `R` 可立即恢复完整截图背景。

## 构建与运行

```bash
cd DesktopDestruction
swift build
./scripts/build_app.sh native
```

也可以分别构建 Apple Silicon 或 Intel 包：

```bash
./scripts/build_app.sh arm64
./scripts/build_app.sh x86_64
```

脚本会优先使用钥匙串里的 Apple Development 证书签名。这样每次重新编译后，macOS 的屏幕录制授权仍指向同一个稳定签名主体，而不是 ad-hoc 签名的单个 `cdhash`。没有证书时才退回 ad-hoc 签名。

安装到固定路径（推荐，避免 TCC 权限随路径漂移）：

```bash
./scripts/install_app.sh build/DesktopDestruction-Apple-Silicon.app /Applications/DesktopDestruction-Apple-Silicon.app
```

安装脚本的目标必须是完整的 `.app` 路径。它会先把新包复制到同目录的临时位置，签名校验通过后才替换旧包。

首次运行需要授予屏幕录制权限。开发时也可以使用合成背景跳过权限：

```bash
DD_FAKE_BACKGROUND=1 ./build/DesktopDestruction.app/Contents/MacOS/DesktopDestruction
```

## 美术资源

内置的漫画风工具图标和特效贴图位于 `Sources/DesktopDestruction/Resources/Art`。如需调整配色或造型，可以修改 `scripts/generate_art.py` 后重新生成：

```bash
python3 scripts/generate_art.py Sources/DesktopDestruction/Resources/Art
```

生成脚本依赖 Python 3 和 Pillow。

## 操作

- 左键：使用当前工具
- 右键拖动：打开工具轮盘
- `1` 到 `9`、`0`：切换工具或放虫子
- `P`：放小人
- `A`：放动物
- `V`：放车
- `E`：放任意 emoji
- `W`：放围墙
- 滚轮：切换工具
- `R`：恢复桌面
- 连按两次 `ESC`：退出
- 鼠标靠近屏幕顶部：显示工具栏

## 说明

当前实现已经覆盖需求中的核心玩法：一次性截图背景、15 种工具、永久血迹、持久裂纹/弹孔/灼痕/水痕、漫画风粒子与特效、屏幕震动、合成音效、右键轮盘、自动隐藏工具栏、设置面板、恢复和退出。

## 生物与核爆

- 僵尸会追咬普通人和动物，被咬者会变成僵尸；僵尸移速更慢、会聚群，每 6 个同阶僵尸融合成更高阶巨型僵尸，血量和破坏力递增。
- 动物会咬人和其他动物，进食后逐渐变大、变快、咬合范围变大。
- 小人包含更多女性和深肤色角色，并保留跑步、跳舞、太空漫步、英雄冲刺等差异化移动。
- 大型僵尸可以撞毁围墙、引爆车辆并碾压虫子、植物和其他非僵尸 actor。
- 围墙会阻挡普通生物移动，但会被炸弹、核弹和大型僵尸破坏。
- 炸弹和核弹点击时只放置/发射，伤害在爆炸和余波阶段结算。
- 核弹带有蘑菇云、多段冲击波、余波、大范围火场和强烈屏幕震动。
