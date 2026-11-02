# Flare3D for OpenFL

**Flare3D for OpenFL** 是经典的 Stage3D 3D 游戏引擎 Flare3D 在现代 Haxe 4 与 OpenFL 9.5+ 平台上的工业级开源移植实现。

本库对标 [Away3D for OpenFL](https://lib.haxe.org/p/away3d/) 的架构与生态标准，提供高效的 3D 场景图系统、可插拔着色器材质（Shader3D / AGAL）、几何图元生成、空间碰撞与骨骼动画支持，全面适配 HTML5 (WebGL) 及 Windows / macOS / Linux 桌面原生平台 (C++ / OpenGL / DirectX)。

---

## 特性亮点

1. **高性能 3D 场景图**：基于 `Pivot3D` 层次变换树，全面支持旋转、平移、缩放与四元数/欧拉角定向。
2. **硬件加速着色管线**：内置 `Shader3D` 与模块化滤镜（`ColorFilter`, `TextureMapFilter`, `LightFilter`, `NormalMapFilter` 等），底层直接利用 OpenFL Stage3D `Context3D` 与 `AGALMiniAssembler` 驱动。
3. **开箱即用 3D 视口**：`Viewer3D` 内置平滑鼠标轨道旋转、平移与滚轮缩放控制，几行代码即可搭建 3D 演示。
4. **标准 HaxeLib 规范**：配置完备的 `haxelib.json` 与 `include.xml`，只需 `<haxelib name="flare3d" />` 即可一键引入。
5. **多端原生支持**：
   - 网页端：编译为 WebGL / WebAssembly (HTML5)；
   - 原生桌面：编译为 Windows / macOS / Linux C++ 原生程序；
   - 移动端：支持 iOS / Android。

---

## 本地安装与开发模式

在本地将当前源码目录注册为 haxelib 开发包：

```powershell
haxelib dev flare3d "d:\ai\my-llm-test\gemini-3.8-flash\flare3d-openfl"
```

---

## 快速上手 (Quick Start)

在 OpenFL 项目的 `project.xml` 中引入：

```xml
<haxelib name="openfl" />
<haxelib name="flare3d" />
<window depth-buffer="true" stencil-buffer="true" antialiasing="4" />
```

在 `src/Main.hx` 中编写标准 Flare3D 代码：

```haxe
package;

import openfl.display.Sprite;
import flare.basic.Viewer3D;
import flare.primitives.Box;
import flare.materials.Shader3D;
import flare.materials.filters.ColorFilter;

class Main extends Sprite {
    public function new() {
        super();
        
        // 1. 初始化 3D 视口 (自动监听窗口缩放与鼠标漫游)
        var scene = new Viewer3D(this);
        scene.clearColor = 0x222222;
        
        // 2. 创建 3D 材质
        var material = new Shader3D("cubeMat", [new ColorFilter(0x3388ff)]);
        
        // 3. 创建 3D 立方体图元
        var cube = new Box("myCube", 100, 100, 100, 1, material);
        scene.addChild(cube);
    }
}
```

---

## 模块组织

- `flare.basic`: `Scene3D`, `Viewer3D`
- `flare.core`: `Pivot3D`, `Mesh3D`, `Surface3D`, `Camera3D`, `Light3D`, `Texture3D`, `Label3D`
- `flare.materials`: `Material3D`, `Shader3D`, `filters.*`
- `flare.primitives`: `Box`, `Sphere`, `Plane`, `SkyBox`
- `flare.collisions`: `RayCollision`, `SphereCollision`, `MouseCollision`
- `flare.loaders`: `Flare3DLoader`, `ZF3DLoader`, `ColladaLoader`
- `flare.system`: `Device3D`, `Input3D`, `Library3D`
