# DesktopDestruction

一款 macOS 原生桌面视觉发泄工具。启动后会先截取当前桌面画面，再在全屏透明覆盖层中展示锤子、机枪、电锯、水枪、火焰、炸弹、橡皮擦、火箭和拳头等效果。

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

## 预编译产物

- [Apple Silicon / arm64](artifacts/DesktopDestruction-Apple-Silicon.zip)
- [Intel / x86_64](artifacts/DesktopDestruction-Intel-x86_64.zip)

压缩包内是完整的 `.app`，解压后可直接拖到“应用程序”。如果需要校验文件，可在仓库根目录执行：

```bash
cd artifacts
shasum -a 256 -c SHA256SUMS
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

## 操作

- 左键：使用当前工具
- 右键拖动：打开工具轮盘
- `1` 到 `9`：切换工具
- 滚轮：切换工具
- `R`：恢复桌面
- 连按两次 `ESC`：退出
- 鼠标靠近屏幕顶部：显示工具栏

## 说明

当前实现已经覆盖需求中的核心玩法：一次性截图背景、9 种工具、持久裂纹/弹孔/灼痕/水痕、粒子、屏幕震动、合成音效、右键轮盘、自动隐藏工具栏、设置面板、恢复和退出。ScreenCaptureKit 可作为后续升级点，用于更高的多屏与兼容性适配。
