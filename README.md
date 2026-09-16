# DesktopDestruction

一款 macOS 原生桌面视觉发泄工具。默认启动一块不透明全屏漫画画板，直接展示锤子、机枪、电锯、水枪、火焰、炸弹、橡皮擦、核弹、拳头以及虫子、小人、车辆、动物、任意 emoji 和围墙等 15 种工具效果。持久破坏会累积绘制到分块位图画布中，不会因为弹孔和血迹越来越多而不断增加图层。

## 渲染架构

持久破坏使用 512pt 分块位图画板：弹孔、裂纹、灼痕、血迹和水痕直接画进对应 tile 的 `CGContext`，同一轮 runloop 内只把被修改的 tile 生成新的 `CGImage` 并提交给固定数量的 `CALayer`。因此破坏数量增长不会带来等量的蒙版图层，橡皮擦也只扫描被触碰区域附近的 tile 记录。

## 安全边界

- 所有破坏都只发生在程序生成的画板和内存位图中。
- 不读取、移动、重命名或删除真实文件。
- 按 `R` 可立即清空所有持久破坏并恢复干净画板。

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


安装到固定路径（推荐，避免 TCC 权限随路径漂移）：

```bash
./scripts/install_app.sh build/DesktopDestruction-Apple-Silicon.app /Applications/DesktopDestruction-Apple-Silicon.app
```

安装脚本的目标必须是完整的 `.app` 路径。它会先把新包复制到同目录的临时位置，签名校验通过后才替换旧包。

默认画板模式不需要屏幕录制权限，也不会出现权限检测界面。如需临时玩“真实桌面截图”模式，可以显式开启：

```bash
DD_CAPTURE_DESKTOP=1 ./build/DesktopDestruction.app/Contents/MacOS/DesktopDestruction
```

这个可选模式才需要屏幕录制权限；如果截图失败，会自动退回漫画画板。

## 美术资源

固定小人、常见动物和僵尸优先使用 Kenney 的 CC0 漫画贴图；Kenney 没覆盖的固定动物会回退到内置 OpenMoji，仍缺失时才使用系统 emoji。任意 emoji 模式优先使用内置 OpenMoji。火焰、烟、火花、枪口光、碎屑和爆炸来自 Kenney Particle Pack 与 OpenGameArt 的 CC0 素材。顶部工具栏、轮盘和鼠标指针使用系统 emoji；蘑菇云、裂纹和血迹仍使用项目内的漫画风定制绘制。

外部素材来源与授权见 `THIRD_PARTY_LICENSES.md`。可用以下命令重新拉取：

```bash
python3 scripts/fetch_external_art.py
```

脚本会安装 OpenMoji、Kenney CC0 粒子与角色贴图，以及 OpenGameArt 的 CC0 爆炸贴图。

内置的漫画风特效贴图位于 `Sources/DesktopDestruction/Resources/Art`；外部资源同名贴图由 `fetch_external_art.py` 管理。如需调整其余定制贴图，可以修改 `scripts/generate_art.py` 后重新生成：

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

当前实现已经覆盖需求中的核心玩法：不透明漫画画板、15 种工具、永久血迹、持久裂纹/弹孔/灼痕/水痕、漫画风粒子与特效、屏幕震动、合成音效、右键轮盘、自动隐藏工具栏、设置面板、恢复和退出。

## 生物与核爆

- 生物现在有独立动作系统：待机呼吸、走路、跑步、僵尸潜行、跳舞、太空漫步、跳扑、冲撞、振翅、蛇行、游动、惊逃、燃烧挣扎、撕咬前扑、受击后仰和车辆悬挂起伏，都会随移动状态实时切换。
- 僵尸会追咬普通人和动物，被咬者会变成僵尸；僵尸移速更慢、会聚群，每 2 个同阶僵尸融合成更高阶巨型僵尸，体型、血量和破坏力持续递增，且没有阶数上限。
- 动物会咬人和其他动物，进食后逐渐变大、变快、咬合范围变大。
- 小人包含更多女性和深肤色角色，并保留跑步、跳舞、太空漫步、英雄冲刺等差异化移动。
- 大型僵尸可以撞毁围墙、引爆车辆并碾压虫子、植物和其他非僵尸 actor。
- 围墙会阻挡普通生物移动，但会被炸弹、核弹和大型僵尸破坏。
- 炸弹和核弹点击时只放置/发射，伤害在爆炸和余波阶段结算。
- 核弹带有蘑菇云、多段冲击波、余波、大范围火场和强烈屏幕震动。
