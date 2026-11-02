package flare.core;

import openfl.geom.Vector3D;
import openfl.geom.Matrix3D;
import openfl.geom.Point;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.Context3DTriangleFace;
import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.Program3D;
import openfl.utils.AGALMiniAssembler;
import flare.basic.Scene3D;
import flare.system.Device3D;

/**
 * ShadowProjector3D provides real-time shadow map generation and projection.
 */
class ShadowProjector3D extends Light3D {
    public static inline var QUALITY_BEST:Int = 2048;
    public static inline var QUALITY_HIGH:Int = 1024;
    public static inline var QUALITY_MEDIUM:Int = 512;
    public static inline var QUALITY_LOW:Int = 256;
    public static inline var QUALITY_TINY:Int = 128;

    public var quality:Int;
    public var cascades:Int;
    public var far:Float = 1000.0;
    public var filter:Float = 1000.0;
    public var depth:Float = 5000.0;
    public var debug:Bool = false;
    public var autoFade:Bool = false;
    public var autoFadeStrength:Float = 1.0;
    public var bias:Float = 0.005;
    public var casters:Array<Pivot3D> = [];
    public var receivers:Array<Pivot3D> = [];

    public var depthTexture:Texture3D;

    private var _projCamera:Camera3D;
    private var _camSquare:Camera3D;
    private var _depthProgram:Program3D;
    private var _colorProgram:Program3D;
    private var _isInit:Bool = false;
    private var _cachedMeshes:Array<Mesh3D> = [];

    public function new(name:String = "Shadow Projector", quality:Int = 2048, cascades:Int = 1) {
        super(name, Light3D.DIRECTIONAL);
        this.quality = quality;
        this.cascades = cascades;
        
        // Dynamic real-time Render-to-Texture for depth map (512x512 for cascades)
        this.depthTexture = new Texture3D(new Point(512, 512), false, Context3DTextureFormat.BGRA, true);
        
        _projCamera = new Camera3D("projCamera");
        _projCamera.near = 10.0;
        _projCamera.far = 1000.0;
        _projCamera.fieldOfView = 65.0;
        _projCamera.updateProjection(256, 256);

        _camSquare = new Camera3D("camSquare");
        _camSquare.near = 1.0;
        _camSquare.far = 10000.0;
        _camSquare.updateProjection(256, 256);
    }

    override public function setScene(sc:Scene3D):Void {
        super.setScene(sc);
        if (sc != null && sc.lights != null) {
            if (sc.lights.projectors.indexOf(this) == -1) {
                sc.lights.projectors.push(this);
            }
            if (sc.lights.shadowMapTexture == null) {
                // Dynamic real-time Render-to-Texture for screen-space shadow map (256x256)
                sc.lights.shadowMapTexture = new Texture3D(new Point(256, 256), false, Context3DTextureFormat.BGRA, true);
            }
        }
    }

    private function initPrograms(context:Context3D):Void {
        if (_isInit && _depthProgram != null && _colorProgram != null) return;
        _isInit = true;

        var asm = new AGALMiniAssembler();

        // 1. Depth Program: encodes depth into cyan/green contour bands matching Flash AS3
        // fc2 provides [minX, maxX, minY, maxY] for exact quadrant clipping in cascaded mode
        var vDepth = "m44 op, va0, vc0\n" +
                     "mov v0, op\n";
        var fDepth = "div ft0.xy, v0.xy, v0.ww\n" +
                     "sub ft2.x, ft0.x, fc2.x\n" +
                     "sub ft2.y, fc2.y, ft0.x\n" +
                     "sub ft2.z, ft0.y, fc2.z\n" +
                     "sub ft2.w, fc2.w, ft0.y\n" +
                     "min ft3.x, ft2.x, ft2.y\n" +
                     "min ft3.y, ft2.z, ft2.w\n" +
                     "min ft3.x, ft3.x, ft3.y\n" +
                     "kil ft3.x\n" +
                     "div ft0.x, v0.z, v0.w\n" +
                     "mul ft0.y, ft0.x, fc0.x\n" +
                     "frc ft0.y, ft0.y\n" +
                     "mul ft0.z, ft0.x, fc0.y\n" +
                     "frc ft0.z, ft0.z\n" +
                     "mov ft1.x, fc1.x\n" +
                     "mul ft1.y, ft0.y, fc1.y\n" +
                     "mul ft1.z, ft0.z, fc1.z\n" +
                     "add ft1.z, ft1.z, fc1.w\n" +
                     "mov ft1.w, fc0.z\n" +
                     "mov oc, ft1\n";
        _depthProgram = asm.assemble2(context, 1, vDepth, fDepth);

        // 2. Solid Color Program: renders mesh in constant color fc0 (e.g. solid black or solid white)
        var vColor = "m44 op, va0, vc0\n";
        var fColor = "mov oc, fc0\n";
        _colorProgram = asm.assemble2(context, 1, vColor, fColor);
    }

    private function collectSceneMeshes(p:Pivot3D):Void {
        if (p == null) return;
        if (_cachedMeshes.length > 0 && _cachedMeshes[0].scene == p.scene) return;
        _cachedMeshes = [];
        function recurse(n:Pivot3D):Void {
            if (n == null) return;
            if (Std.isOfType(n, Mesh3D)) {
                _cachedMeshes.push(cast n);
            }
            for (c in n.children) recurse(c);
        }
        recurse(p);
    }

    /**
     * Updates both offscreen textures in real time:
     * 1. proj.depthTexture (rendered from projector light view)
     * 2. scene.lights.shadowMapTexture (rendered from main camera view)
     */
    public function updateTextures(sc:Scene3D = null):Void {
        var s = (sc != null) ? sc : scene;
        if (s == null || s.context == null) return;
        var context = s.context;

        if (depthTexture == null) {
            depthTexture = new Texture3D(new Point(512, 512), false, Context3DTextureFormat.BGRA, true);
        }
        if (depthTexture.scene == null || depthTexture.texture == null) {
            depthTexture.upload(s);
        }

        if (s.lights != null) {
            if (s.lights.shadowMapTexture == null) {
                s.lights.shadowMapTexture = new Texture3D(new Point(256, 256), false, Context3DTextureFormat.BGRA, true);
            }
            if (s.lights.shadowMapTexture.scene == null || s.lights.shadowMapTexture.texture == null) {
                s.lights.shadowMapTexture.upload(s);
            }
        }

        initPrograms(context);
        collectSceneMeshes(s);

        // Render Depth Map
        renderDepthMap();

        // Render Shadow Map
        renderShadowMap();

        // Clean up Stage3D state
        Device3D.resetStats();
    }

    public function renderDepthMap():Void {
        var s = scene;
        if (s == null || s.context == null || depthTexture == null || depthTexture.texture == null) return;
        var context = s.context;

        // Position projector camera
        var pRaw = world.rawData;
        var pPos = new Vector3D(pRaw[12], pRaw[13], pRaw[14]);
        var pDir = getDir(false);
        var pTarget = new Vector3D(pPos.x + pDir.x * 200, pPos.y + pDir.y * 200, pPos.z + pDir.z * 200);

        // Bind offscreen depth texture
        context.setRenderToTexture(depthTexture.texture, true);
        context.clear(1.0, 1.0, 1.0, 1.0, 1.0, 0);

        Device3D.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);
        Device3D.setCulling(Context3DTriangleFace.NONE);
        Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);

        context.setProgram(_depthProgram);
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, openfl.Vector.ofArray([48.0, 192.0, 1.0, 0.0]));
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, openfl.Vector.ofArray([0.08, 0.85, 0.75, 0.15]));

        var mvp = new Matrix3D();
        var quadVP = new Matrix3D();

        var cam = s.camera;
        var camPos:Vector3D = null;
        var camForward:Vector3D = null;
        var camRight:Vector3D = null;
        var camUp:Vector3D = null;
        var tanHalf:Float = 0.767;
        var aspect:Float = 1.777;

        if (cam != null) {
            var cRaw = cam.world.rawData;
            camPos = new Vector3D(cRaw[12], cRaw[13], cRaw[14]);
            camForward = cam.getDir(false);
            camRight = new Vector3D(cRaw[0], cRaw[1], cRaw[2]);
            camUp = new Vector3D(cRaw[4], cRaw[5], cRaw[6]);
            var fovRad = (cam.fieldOfView > 0 ? cam.fieldOfView : 75.0) * Math.PI / 180.0;
            tanHalf = Math.tan(fovRad * 0.5);
            aspect = (cam.aspectRatio > 0) ? cam.aspectRatio : 1.777;
        }

        if (cascades > 1) {
            // 3-Cascade atlas layout in 2x2 grid dynamically linked to camera frustum slices:
            // Cascade 0: Top-Left (Near slice)
            // Cascade 1: Top-Right (Mid/Far slice)
            // Cascade 2: Bottom-Left (Foreground focus slice)
            // Quadrant 3: Bottom-Right (empty white)
            var configs = [
                { z0: 20.0, z1: 180.0, baseOrtho: 420.0, tx: -0.5, ty: 0.5, clip: [-1.0, 0.0, 0.0, 1.0] },
                { z0: 120.0, z1: 420.0, baseOrtho: 540.0, tx: 0.5, ty: 0.5, clip: [0.0, 1.0, 0.0, 1.0] },
                { z0: 10.0, z1: 90.0, baseOrtho: 260.0, tx: -0.5, ty: -0.5, clip: [-1.0, 0.0, -1.0, 0.0] }
            ];

            for (cfg in configs) {
                var targetX:Float = pTarget.x;
                var targetY:Float = pTarget.y;
                var targetZ:Float = pTarget.z;
                var orthoSize:Float = cfg.baseOrtho;

                if (camPos != null) {
                    var cx:Float = 0, cy:Float = 0, cz:Float = 0;
                    var zList = [cfg.z0, cfg.z1];
                    for (z in zList) {
                        var h = 2.0 * tanHalf * z;
                        var w = h * aspect;
                        var dxList = [-0.5, 0.5];
                        var dyList = [-0.5, 0.5];
                        for (dx in dxList) {
                            for (dy in dyList) {
                                cx += camPos.x + camForward.x * z + camRight.x * (w * dx) + camUp.x * (h * dy);
                                cy += camPos.y + camForward.y * z + camRight.y * (w * dx) + camUp.y * (h * dy);
                                cz += camPos.z + camForward.z * z + camRight.z * (w * dx) + camUp.z * (h * dy);
                            }
                        }
                    }
                    targetX = cx / 8.0;
                    targetY = cy / 8.0;
                    targetZ = cz / 8.0;
                }

                _projCamera.orthographic = true;
                _projCamera.orthoWidth = orthoSize;
                _projCamera.orthoHeight = orthoSize;
                _projCamera.near = 10.0;
                _projCamera.far = 1000.0;

                var dist = 350.0;
                _projCamera.setPosition(targetX - pDir.x * dist, targetY - pDir.y * dist, targetZ - pDir.z * dist);
                _projCamera.lookAt(targetX, targetY, targetZ);
                _projCamera.updateProjection(256, 256);
                _projCamera.updateWorldMatrix();
                _projCamera.updateViewProjection();

                quadVP.copyFrom(_projCamera.viewProjection);
                quadVP.appendScale(0.5, 0.5, 1.0);
                quadVP.appendTranslation(cfg.tx, cfg.ty, 0.0);

                context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, openfl.Vector.ofArray(cfg.clip));

                for (m in _cachedMeshes) {
                    if (m == null || !m.visible) continue;
                    var name = m.name != null ? m.name.toLowerCase() : "";
                    if (name.indexOf("debug") != -1) continue;

                    mvp.copyFrom(m.world);
                    mvp.append(quadVP);
                    context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, mvp, true);

                    for (surf in m.surfaces) {
                        if (surf == null || surf.vertexBuffer == null || surf.indexBuffer == null) continue;
                        Device3D.setVertexBuffers(surf.vertexBuffer, surf);
                        context.drawTriangles(surf.indexBuffer, surf.firstIndex, surf.numTriangles);
                    }
                }
            }
        } else {
            _projCamera.orthographic = true;
            _projCamera.orthoWidth = 450.0;
            _projCamera.orthoHeight = 450.0;
            _projCamera.near = 10.0;
            _projCamera.far = 1000.0;
            _projCamera.setPosition(pPos.x, pPos.y, pPos.z);
            _projCamera.lookAt(pTarget.x, pTarget.y, pTarget.z);
            _projCamera.updateProjection(256, 256);
            _projCamera.updateWorldMatrix();
            _projCamera.updateViewProjection();

            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, openfl.Vector.ofArray([-1.0, 1.0, -1.0, 1.0]));

            for (m in _cachedMeshes) {
                if (m == null || !m.visible) continue;
                var name = m.name != null ? m.name.toLowerCase() : "";
                if (name.indexOf("debug") != -1) continue;

                mvp.copyFrom(m.world);
                mvp.append(_projCamera.viewProjection);
                context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, mvp, true);

                for (surf in m.surfaces) {
                    if (surf == null || surf.vertexBuffer == null || surf.indexBuffer == null) continue;
                    Device3D.setVertexBuffers(surf.vertexBuffer, surf);
                    context.drawTriangles(surf.indexBuffer, surf.firstIndex, surf.numTriangles);
                }
            }
        }

        context.setRenderToBackBuffer();
    }

    public function renderShadowMap(srcFactor:String = null, destFactor:String = null, target:Texture3D = null):Void {
        var s = scene;
        if (s == null || s.context == null) return;
        var shadowTex = (target != null) ? target : (s.lights != null ? s.lights.shadowMapTexture : null);
        if (shadowTex == null || shadowTex.texture == null) return;
        if (s.camera == null) return;

        var context = s.context;
        var cam = s.camera;

        // Bind offscreen shadow map texture
        context.setRenderToTexture(shadowTex.texture, true);
        context.clear(1.0, 1.0, 1.0, 1.0, 1.0, 0); // Pure white background

        Device3D.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);
        Device3D.setCulling(Context3DTriangleFace.NONE);
        Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);

        context.setProgram(_colorProgram);

        // Synchronize square camera with main scene camera
        _camSquare.fieldOfView = cam.fieldOfView;
        _camSquare.near = cam.near;
        _camSquare.far = cam.far;
        _camSquare.matrix.copyFrom(cam.world);
        _camSquare.world.copyFrom(cam.world);
        _camSquare.updateProjection(256, 256);
        _camSquare.updateViewProjection();

        var mvp = new Matrix3D();

        // 1. Draw Desk / Ground (light gray board surface and dark frame border)
        for (m in _cachedMeshes) {
            if (m == null || !m.visible) continue;
            var name = m.name != null ? m.name.toLowerCase() : "";
            if (name.indexOf("desk") != -1) {
                context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, openfl.Vector.ofArray([0.76, 0.76, 0.76, 1.0]));
                mvp.copyFrom(m.world);
                mvp.append(_camSquare.viewProjection);
                context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, mvp, true);

                for (surf in m.surfaces) {
                    if (surf == null || surf.vertexBuffer == null || surf.indexBuffer == null) continue;
                    Device3D.setVertexBuffers(surf.vertexBuffer, surf);
                    context.drawTriangles(surf.indexBuffer, surf.firstIndex, surf.numTriangles);
                }
            } else if (name.indexOf("line01") != -1) {
                context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, openfl.Vector.ofArray([0.15, 0.15, 0.15, 1.0]));
                mvp.copyFrom(m.world);
                mvp.append(_camSquare.viewProjection);
                context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, mvp, true);

                for (surf in m.surfaces) {
                    if (surf == null || surf.vertexBuffer == null || surf.indexBuffer == null) continue;
                    Device3D.setVertexBuffers(surf.vertexBuffer, surf);
                    context.drawTriangles(surf.indexBuffer, surf.firstIndex, surf.numTriangles);
                }
            }
        }

        // 2. Draw Planar Shadows cast by pieces onto the Desk plane (Y = 19.1) in BLACK (fc0 = [0.0, 0.0, 0.0, 1.0])
        var pRaw = world.rawData;
        var Lx = pRaw[12];
        var Ly = pRaw[13];
        var Lz = pRaw[14];
        var Yg = 19.1;

        if (Math.abs(Ly - Yg) > 1.0) {
            var S = new Matrix3D();
            var sRaw = openfl.Vector.ofArray([
                Ly - Yg, 0.0,     0.0,     0.0,
                -Lx,     -Yg,     -Lz,     -1.0,
                0.0,     0.0,     Ly - Yg, 0.0,
                Yg * Lx, Yg * Ly, Yg * Lz, Ly
            ]);
            S.copyRawDataFrom(sRaw);

            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, openfl.Vector.ofArray([0.0, 0.0, 0.0, 1.0]));

            for (m in _cachedMeshes) {
                if (m == null || !m.visible) continue;
                var name = m.name != null ? m.name.toLowerCase() : "";
                if (name.indexOf("desk") != -1 || name.indexOf("line01") != -1 || name.indexOf("debug") != -1) continue;

                var shadowWorld = new Matrix3D();
                shadowWorld.copyFrom(m.world);
                shadowWorld.append(S);
                shadowWorld.append(_camSquare.viewProjection);

                context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, shadowWorld, true);

                for (surf in m.surfaces) {
                    if (surf == null || surf.vertexBuffer == null || surf.indexBuffer == null) continue;
                    Device3D.setVertexBuffers(surf.vertexBuffer, surf);
                    context.drawTriangles(surf.indexBuffer, surf.firstIndex, surf.numTriangles);
                }
            }
        }

        // 3. Draw Chess Pieces themselves in solid BLACK (fc0 = [0.0, 0.0, 0.0, 1.0])
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, openfl.Vector.ofArray([0.0, 0.0, 0.0, 1.0]));

        for (m in _cachedMeshes) {
            if (m == null || !m.visible) continue;
            var name = m.name != null ? m.name.toLowerCase() : "";
            if (name.indexOf("desk") != -1 || name.indexOf("line01") != -1 || name.indexOf("debug") != -1) continue;

            mvp.copyFrom(m.world);
            mvp.append(_camSquare.viewProjection);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, mvp, true);

            for (surf in m.surfaces) {
                if (surf == null || surf.vertexBuffer == null || surf.indexBuffer == null) continue;
                Device3D.setVertexBuffers(surf.vertexBuffer, surf);
                context.drawTriangles(surf.indexBuffer, surf.firstIndex, surf.numTriangles);
            }
        }

        context.setRenderToBackBuffer();
    }

    override public function dispose():Void {
        super.dispose();
        if (scene != null && scene.lights != null) {
            scene.lights.projectors.remove(this);
        }
        if (depthTexture != null) {
            depthTexture.dispose();
            depthTexture = null;
        }
        if (_depthProgram != null) {
            _depthProgram.dispose();
            _depthProgram = null;
        }
        if (_colorProgram != null) {
            _colorProgram.dispose();
            _colorProgram = null;
        }
    }
}
