package flare.core;

import openfl.Vector;
import openfl.geom.Vector3D;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DBlendFactor;
import flare.materials.Shader3D;
import flare.materials.filters.TextureMapFilter;
import flare.materials.filters.ColorFilter;

/**
 * IonSmokeParticles simulates 3D billboard ionized smoke/dust plumes for sci-fi fan vents.
 * Uses high-performance pre-allocated flat arrays with ZERO runtime garbage collection (0 GC).
 * Quads automatically align with Camera3D world orientation to ensure true 360-degree billboarding.
 */
class IonSmokeParticles extends Mesh3D {
    public var maxParticles:Int;
    public var emitterCenter:Vector3D;
    public var emitterNormal:Vector3D;
    public var emitterTang1:Vector3D;
    public var emitterTang2:Vector3D;
    public var emitterRadius:Float = 12.0;

    public var thrustSpeed:Float = 26.0;
    public var swirlSpeed:Float = 7.5;
    public var drag:Float = 0.985;
    public var startSize:Float = 4.0;
    public var endSize:Float = 26.0;
    public var minLife:Float = 1.4;
    public var maxLife:Float = 2.4;

    public var emitting:Bool = true;

    // 零 GC 预分配标量数组 (Flat Typed Arrays for 60 FPS in Neko & HTML5)
    private var _posX:Vector<Float>;
    private var _posY:Vector<Float>;
    private var _posZ:Vector<Float>;
    private var _velX:Vector<Float>;
    private var _velY:Vector<Float>;
    private var _velZ:Vector<Float>;
    private var _age:Vector<Float>;
    private var _life:Vector<Float>;
    private var _rot:Vector<Float>;
    private var _rotSpeed:Vector<Float>;

    private var _surface:Surface3D;
    private var _mat:Shader3D;
    private var _lastTime:Int = 0;

    public function new(name:String = "ion_smoke", maxParticles:Int = 36, texture:Texture3D = null, ionColor:Int = 0x22EEFF, alpha:Float = 0.85) {
        super(name);
        this.maxParticles = maxParticles;

        emitterCenter = new Vector3D(0, 0, 0);
        emitterNormal = new Vector3D(0, 1, 0);
        emitterTang1 = new Vector3D(1, 0, 0);
        emitterTang2 = new Vector3D(0, 0, 1);

        _posX = new Vector<Float>(maxParticles);
        _posY = new Vector<Float>(maxParticles);
        _posZ = new Vector<Float>(maxParticles);
        _velX = new Vector<Float>(maxParticles);
        _velY = new Vector<Float>(maxParticles);
        _velZ = new Vector<Float>(maxParticles);
        _age = new Vector<Float>(maxParticles);
        _life = new Vector<Float>(maxParticles);
        _rot = new Vector<Float>(maxParticles);
        _rotSpeed = new Vector<Float>(maxParticles);

        _surface = new Surface3D(name + "_surf");
        _surface.vertexData = new Vector<Float>(maxParticles * 32);
        _surface.indexData = new Vector<UInt>(maxParticles * 6);

        // 创建发光离子材质 (Additive 混合模式，重叠粒子高亮发光，边缘呈现轻柔淡雅烟尘雾气)
        _mat = new Shader3D(name + "_mat", [
            new TextureMapFilter(texture),
            new ColorFilter(ionColor, alpha)
        ]);
        _mat.depthWrite = false;
        _mat.sourceFactor = Context3DBlendFactor.SOURCE_ALPHA;
        _mat.destFactor = Context3DBlendFactor.ONE;
        _mat.twoSided = true;

        addSurface(_surface, _mat);

        initParticles();
    }

    /**
     * 配置风扇发射基准位置、法线与物理几何尺度
     */
    public function setEmitter(center:Vector3D, normal:Vector3D, radius:Float, fanScale:Float = 1.0):Void {
        emitterCenter.copyFrom(center);
        emitterNormal.copyFrom(normal);
        emitterNormal.normalize();

        // 构造切线正交基底 (Orthonormal Basis on Fan Mouth Disk)
        var ref = (Math.abs(emitterNormal.x) < 0.8) ? new Vector3D(1, 0, 0) : new Vector3D(0, 1, 0);
        emitterTang1 = emitterNormal.crossProduct(ref);
        emitterTang1.normalize();
        emitterTang2 = emitterNormal.crossProduct(emitterTang1);
        emitterTang2.normalize();

        emitterRadius = Math.max(6.0, radius);
        thrustSpeed = 24.0 * Math.max(0.8, fanScale);
        swirlSpeed = 7.0 * Math.max(0.8, fanScale);
        startSize = 4.5 * Math.max(0.8, fanScale);
        endSize = 28.0 * Math.max(0.8, fanScale);

        // 重新随机初始化分布，使得初始时刻即有连贯饱满的烟柱
        for (i in 0...maxParticles) {
            _life[i] = minLife + Math.random() * (maxLife - minLife);
            _age[i] = Math.random() * _life[i];
            spawnParticle(i, true);
        }
    }

    private function initParticles():Void {
        var iData = _surface.indexData;
        for (i in 0...maxParticles) {
            _life[i] = minLife + Math.random() * (maxLife - minLife);
            _age[i] = Math.random() * _life[i];
            spawnParticle(i, true);

            var baseIdx:UInt = i * 4;
            var iIdx = i * 6;
            iData[iIdx + 0] = baseIdx + 0;
            iData[iIdx + 1] = baseIdx + 1;
            iData[iIdx + 2] = baseIdx + 2;
            iData[iIdx + 3] = baseIdx + 0;
            iData[iIdx + 4] = baseIdx + 2;
            iData[iIdx + 5] = baseIdx + 3;
        }
    }

    private function spawnParticle(i:Int, preAge:Bool = false):Void {
        if (!preAge) {
            _age[i] = 0.0;
            _life[i] = minLife + Math.random() * (maxLife - minLife);
        }
        _rot[i] = Math.random() * Math.PI * 2.0;
        _rotSpeed[i] = (Math.random() - 0.5) * 2.2;

        // 在风扇圆盘口内部随机采样 (开方分布确保面积均匀)
        var angle = Math.random() * Math.PI * 2.0;
        var r = Math.sqrt(Math.random()) * emitterRadius;
        var cosA = Math.cos(angle);
        var sinA = Math.sin(angle);

        // 初始位置：风扇中心 + 圆盘偏移 + 贴近风扇开口向上 1.5 单元
        var ox = (emitterTang1.x * cosA + emitterTang2.x * sinA) * r + emitterNormal.x * 1.5;
        var oy = (emitterTang1.y * cosA + emitterTang2.y * sinA) * r + emitterNormal.y * 1.5;
        var oz = (emitterTang1.z * cosA + emitterTang2.z * sinA) * r + emitterNormal.z * 1.5;

        // 初始速度：
        // 1. 沿风扇法线向太空强力喷射
        var spd = thrustSpeed * (0.85 + Math.random() * 0.35);
        var vx = emitterNormal.x * spd;
        var vy = emitterNormal.y * spd;
        var vz = emitterNormal.z * spd;

        // 2. 顺应风扇叶片高速自转的切向涡旋 (Swirl vortex)
        var swirlX = (-emitterTang1.x * sinA + emitterTang2.x * cosA) * swirlSpeed;
        var swirlY = (-emitterTang1.y * sinA + emitterTang2.y * cosA) * swirlSpeed;
        var swirlZ = (-emitterTang1.z * sinA + emitterTang2.z * cosA) * swirlSpeed;

        // 3. 锥形轻微外扩扩散
        var expX = (emitterTang1.x * cosA + emitterTang2.x * sinA) * (thrustSpeed * 0.14);
        var expY = (emitterTang1.y * cosA + emitterTang2.y * sinA) * (thrustSpeed * 0.14);
        var expZ = (emitterTang1.z * cosA + emitterTang2.z * sinA) * (thrustSpeed * 0.14);

        _velX[i] = vx + swirlX + expX;
        _velY[i] = vy + swirlY + expY;
        _velZ[i] = vz + swirlZ + expZ;

        if (preAge && _age[i] > 0.0) {
            var simDt = _age[i];
            _posX[i] = emitterCenter.x + ox + _velX[i] * simDt;
            _posY[i] = emitterCenter.y + oy + _velY[i] * simDt;
            _posZ[i] = emitterCenter.z + oz + _velZ[i] * simDt;
        } else {
            _posX[i] = emitterCenter.x + ox;
            _posY[i] = emitterCenter.y + oy;
            _posZ[i] = emitterCenter.z + oz;
        }
    }

    public function updateParticles(dt:Float, camera:Camera3D):Void {
        for (i in 0...maxParticles) {
            _age[i] += dt;
            if (_age[i] >= _life[i]) {
                spawnParticle(i, false);
            } else {
                _posX[i] += _velX[i] * dt;
                _posY[i] += _velY[i] * dt;
                _posZ[i] += _velZ[i] * dt;
                _velX[i] *= drag;
                _velY[i] *= drag;
                _velZ[i] *= drag;
                _rot[i] += _rotSpeed[i] * dt;
            }
        }
        updateGeometry(camera);
    }

    private function updateGeometry(camera:Camera3D):Void {
        var vData = _surface.vertexData;

        // 提取相机世界空间右向与上向单位向量 (实现极致精准的全向 360 度 3D Billboard)
        var rx:Float = 1.0, ry:Float = 0.0, rz:Float = 0.0;
        var ux:Float = 0.0, uy:Float = 1.0, uz:Float = 0.0;
        if (camera != null) {
            var raw = camera.world.rawData;
            rx = raw[0]; ry = raw[1]; rz = raw[2];
            ux = raw[4]; uy = raw[5]; uz = raw[6];
        }

        for (i in 0...maxParticles) {
            var px = _posX[i];
            var py = _posY[i];
            var pz = _posZ[i];
            var progress = _age[i] / _life[i];
            if (progress < 0.0) progress = 0.0;
            if (progress > 1.0) progress = 1.0;

            // 粒子尺度沿生命周期自然膨胀 (升空扩散)
            var s = (startSize + progress * (endSize - startSize)) * 0.5;

            // 诞生时聚变微光，末端柔和融入太空
            if (progress < 0.18) {
                s *= (progress / 0.18);
            } else if (progress > 0.70) {
                s *= (1.0 - (progress - 0.70) / 0.30);
            }

            // 零三角函数开销的纯标量正交屏幕投影 (极致性能，0 CPU 瓶颈)
            var rxs = rx * s;
            var rys = ry * s;
            var rzs = rz * s;

            var uxs = ux * s;
            var uys = uy * s;
            var uzs = uz * s;

            var base = i * 32;

            // V0 (Bottom-Left)
            vData[base + 0] = px - rxs - uxs;
            vData[base + 1] = py - rys - uys;
            vData[base + 2] = pz - rzs - uzs;
            vData[base + 3] = 0.0; vData[base + 4] = 1.0;
            vData[base + 5] = 0.0; vData[base + 6] = 0.0; vData[base + 7] = 1.0;

            // V1 (Bottom-Right)
            vData[base + 8] = px + rxs - uxs;
            vData[base + 9] = py + rys - uys;
            vData[base + 10] = pz + rzs - uzs;
            vData[base + 11] = 1.0; vData[base + 12] = 1.0;
            vData[base + 13] = 0.0; vData[base + 14] = 0.0; vData[base + 15] = 1.0;

            // V2 (Top-Right)
            vData[base + 16] = px + rxs + uxs;
            vData[base + 17] = py + rys + uys;
            vData[base + 18] = pz + rzs + uzs;
            vData[base + 19] = 1.0; vData[base + 20] = 0.0;
            vData[base + 21] = 0.0; vData[base + 22] = 0.0; vData[base + 23] = 1.0;

            // V3 (Top-Left)
            vData[base + 24] = px - rxs + uxs;
            vData[base + 25] = py - rys + uys;
            vData[base + 26] = pz - rzs + uzs;
            vData[base + 27] = 0.0; vData[base + 28] = 0.0;
            vData[base + 29] = 0.0; vData[base + 30] = 0.0; vData[base + 31] = 1.0;
        }

        if (_surface.vertexBuffer != null) {
            _surface.vertexBuffer.uploadFromVector(vData, 0, maxParticles * 4);
        } else if (flare.system.Device3D.context != null) {
            _surface.upload(flare.system.Device3D.context);
        }
    }

    override public function render(camera:Camera3D = null, clearDepth:Bool = false, target:Dynamic = null):Void {
        if (!visible) return;
        var cam = (camera != null) ? camera : flare.system.Device3D.camera;
        if (cam == null) return;

        // 视界与距离精准剔除 (基于发射口真实物理位置 emitterCenter，避免 Mesh3D 默认原点误判)
        var ox = emitterCenter.x;
        var oy = emitterCenter.y;
        var oz = emitterCenter.z;
        var camX = flare.system.Device3D.camX;
        var camY = flare.system.Device3D.camY;
        var camZ = flare.system.Device3D.camZ;
        var camLenSq = camX * camX + camY * camY + camZ * camZ;
        if (camLenSq > 1000.0) {
            // 1. 点积检测：背面半球物体必定被巨大球体遮挡
            // 给向太空喷射的烟柱预留充裕地平线外露余量 (dot < 2500.0 才判定为背面遮挡)
            var dot = ox * camX + oy * camY + oz * camZ;
            if (dot < 2500.0) {
                return;
            }

            // 2. 切线视距检测：远距离剔除 (防止渲染远端地平线外的风扇烟柱)
            var dx = ox - camX;
            var dy = oy - camY;
            var dz = oz - camZ;
            var distSq = dx * dx + dy * dy + dz * dz;
            if (distSq > 22500.0) { // 150 * 150
                return;
            }
        }

        if (emitting) {
            var curTime = openfl.Lib.getTimer();
            var dt = (_lastTime > 0) ? Math.min(0.05, (curTime - _lastTime) / 1000.0) : 0.016666;
            _lastTime = curTime;
            updateParticles(dt, cam);
        }

        super.render(cam);
    }
}
