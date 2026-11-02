# Flare3D for OpenFL

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.md)
[![Haxe](https://img.shields.io/badge/Haxe-4.3+-orange.svg)](https://haxe.org/)
[![OpenFL](https://img.shields.io/badge/OpenFL-9.5+-red.svg)](https://www.openfl.org/)
[![Release](https://img.shields.io/github/v/release/isamu2025/flare3d-openfl)](https://github.com/isamu2025/flare3d-openfl/releases)

[English](#english) | [中文说明](#中文说明)

---

<a name="english"></a>
## English

**Flare3D for OpenFL** is an industrial-grade, open-source port of the classic Flare3D 2.7.1 Stage3D 3D game engine to modern **Haxe 4** and **OpenFL 9.5+**.

Matching the architecture and ecosystem quality of Away3D for OpenFL, this library provides a high-performance 3D scene graph, modular shader pipeline (`Shader3D` / AGAL / FLSL), geometric primitives, spatial collisions, multi-surface skeletal animation deformation, and post-processing effects. Fully compatible with **HTML5 (WebGL)** and native desktop platforms (**Windows / macOS / Linux** via C++ / OpenGL / DirectX).

### Key Features

1. **High-Performance 3D Scene Graph**: Hierarchical `Pivot3D` transformation tree with complete support for translation, rotation, scaling, quaternions, and Euler angles.
2. **Hardware-Accelerated Shader Pipeline**: Built-in `Shader3D` and modular filters (`TextureMapFilter`, `EnvironmentMapFilter`, `LightFilter`, `NormalMapFilter`, `AlphaMaskFilter`, etc.) backed directly by Stage3D `Context3D`.
3. **Multi-Surface Skeletal Animation**: Matrix palette skinning modifier (`SkinModifier`) supporting multi-surface models, keyframe GPU vertex buffer pre-baking, and label-based animation state machines.
4. **Collision & Physics**: Built-in `SphereCollision` ellipsoid sliding physics, `RayCollision`, SAT testing, and broadphase collision detection.
5. **Post-Processing & Custom Shaders**: Runtime FLSL shader parser, Bloom, Depth of Field (DOF), Sepia, Dream, Night Vision, Dynamic Reflections, and Shadow Projectors.
6. **Cross-Platform Targets**:
   - Web: WebGL / WebAssembly (HTML5)
   - Desktop: Windows / macOS / Linux (C++ / Neko)
   - Mobile: Android / iOS ready

### Installation

#### Method 1: Install via Git (Recommended)
```bash
haxelib git flare3d https://github.com/isamu2025/flare3d-openfl.git
```

#### Method 2: Install via Haxelib Center (Once published)
```bash
haxelib install flare3d
```

#### Method 3: Local Development Mode (`haxelib dev`)
If you clone this repository locally to contribute or test:
```bash
# In the cloned flare3d-openfl repository directory:
haxelib dev flare3d .

# Or by specifying your local folder path:
haxelib dev flare3d "/path/to/flare3d-openfl"
```

### Quick Start

Add Flare3D and OpenFL to your project's `project.xml`:

```xml
<haxelib name="openfl" />
<haxelib name="flare3d" />
<window depth-buffer="true" stencil-buffer="true" antialiasing="4" />
```

Create a simple rotating 3D scene in `src/Main.hx`:

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

        // 1. Initialize 3D viewport (orbit controls & resize handling)
        var scene = new Viewer3D(this);
        scene.clearColor.setTo(0.15, 0.15, 0.15);

        // 2. Create 3D material
        var material = new Shader3D("cubeMat", [new ColorFilter(0x3388ff)]);

        // 3. Create 3D box primitive
        var cube = new Box("myCube", 100, 100, 100, 1, material);
        scene.addChild(cube);
    }
}
```

### Package Overview

- `flare.basic`: `Scene3D`, `Viewer3D`
- `flare.core`: `Pivot3D`, `Mesh3D`, `Surface3D`, `Camera3D`, `Light3D`, `Texture3D`, `Label3D`
- `flare.materials`: `Material3D`, `Shader3D`, `filters.*`
- `flare.primitives`: `Box`, `Sphere`, `Plane`, `SkyBox`, `Torus`, `Cone`, `Cylinder`
- `flare.collisions`: `RayCollision`, `SphereCollision`, `MouseCollision`
- `flare.modifiers`: `SkinModifier`, `VertexAnimationModifier`, `MorphModifier`
- `flare.loaders`: `Flare3DLoader`, `ZF3DLoader`, `ColladaLoader`
- `flare.system`: `Device3D`, `Input3D`, `Library3D`

---

<a name="中文说明"></a>
## 中文说明

**Flare3D for OpenFL** 是经典 Stage3D 3D 游戏引擎 Flare3D 在现代 **Haxe 4** 与 **OpenFL 9.5+** 平台上的工业级开源移植实现。

本库对标 [Away3D for OpenFL](https://lib.haxe.org/p/away3d/) 的架构与生态标准，提供高效的 3D 场景图系统、可插拔着色器材质（`Shader3D` / AGAL / FLSL）、几何图元生成、空间物理碰撞、多表面骨骼蒙皮动画支持以及完备的后处理特效管线，全面适配 **HTML5 (WebGL)** 及 **Windows / macOS / Linux** 桌面原生平台 (C++ / OpenGL / DirectX)。

### 特性亮点

1. **高性能 3D 场景图**：基于 `Pivot3D` 层次变换树，全面支持旋转、平移、缩放与四元数/欧拉角定向。
2. **硬件加速着色管线**：内置 `Shader3D` 与模块化滤镜（`TextureMapFilter`, `EnvironmentMapFilter`, `LightFilter`, `NormalMapFilter`, `AlphaMaskFilter` 等），底层直接利用 OpenFL Stage3D `Context3D` 驱动。
3. **多表面骨骼动画与 GPU 预烘焙**：矩阵调色板蒙皮修改器（`SkinModifier`），支持多 Surface 独立 Palette 映射与关键帧 GPU 顶点缓存预烘焙，轻松支持数百实例同屏流畅渲染。
4. **空间碰撞与物理系统**：内置 `SphereCollision` 椭球滑动物理碰撞与重力/摩擦力机制、`RayCollision` 射线检测与 SAT 空间包围盒测试。
5. **后处理特效与动态 Shader**：运行时 FLSL 着色器动态解析、Bloom 泛光、景深（DOF）、老照片（Sepia）、梦境、夜视、动态镜面反射与阴影投射器（ShadowProjector）。
6. **多端原生支持**：
   - 网页端：编译为 WebGL / WebAssembly (HTML5)；
   - 原生桌面：编译为 Windows / macOS / Linux C++ 原生程序；
   - 移动端：适配 Android / iOS。

### 安装方式

#### 方式一：通过 Git 一键安装（推荐）
```bash
haxelib git flare3d https://github.com/isamu2025/flare3d-openfl.git
```

#### 方式二：通过官方 Haxelib 中心安装（发布后）
```bash
haxelib install flare3d
```

#### 方式三：本地源码开发模式 (`haxelib dev`)
若从 GitHub 克隆了本地源码，可将当前目录直接注册为开发包：
```bash
# 在克隆的 flare3d-openfl 根目录下执行：
haxelib dev flare3d .

# 或直接指定您的本地存放目录：
haxelib dev flare3d "/path/to/flare3d-openfl"
```

### 快速上手 (Quick Start)

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
        scene.clearColor.setTo(0.15, 0.15, 0.15);

        // 2. 创建 3D 材质
        var material = new Shader3D("cubeMat", [new ColorFilter(0x3388ff)]);

        // 3. 创建 3D 立方体图元
        var cube = new Box("myCube", 100, 100, 100, 1, material);
        scene.addChild(cube);
    }
}
```

### 模块结构

- `flare.basic`: `Scene3D`, `Viewer3D`
- `flare.core`: `Pivot3D`, `Mesh3D`, `Surface3D`, `Camera3D`, `Light3D`, `Texture3D`, `Label3D`
- `flare.materials`: `Material3D`, `Shader3D`, `filters.*`
- `flare.primitives`: `Box`, `Sphere`, `Plane`, `SkyBox`, `Torus`, `Cone`, `Cylinder`
- `flare.collisions`: `RayCollision`, `SphereCollision`, `MouseCollision`
- `flare.modifiers`: `SkinModifier`, `VertexAnimationModifier`, `MorphModifier`
- `flare.loaders`: `Flare3DLoader`, `ZF3DLoader`, `ColladaLoader`
- `flare.system`: `Device3D`, `Input3D`, `Library3D`

---

## 开源协议 (License)

本项目基于 [MIT License](LICENSE.md) 开源。
