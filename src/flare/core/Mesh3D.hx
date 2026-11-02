package flare.core;

import flare.materials.Material3D;

/**
 * Mesh3D represents a 3D polygonal model comprised of Surfaces and Materials.
 */
class Mesh3D extends Pivot3D {
    public var surfaces:Array<Surface3D>;
    public var materials:Array<Material3D>;
    public var modifier:flare.modifiers.Modifier;
    public var isExemptFromCulling:Bool = false;
    public static var enablePlanetCulling:Bool = false;
    public var bounds:Boundings3D;

    public function new(name:String = "mesh") {
        super(name);
        this.surfaces = [];
        this.materials = [];
        updateCullingExemption();
    }

    override public function onNameChanged():Void {
        updateCullingExemption();
    }

    public function updateCullingExemption():Void {
        var n = (name != null) ? name : "";
        if (n == "floor" || n == "sky" || n == "astronaut" || n == "shadow" || n == "energy" || n == "player_container") {
            isExemptFromCulling = true;
        } else if (StringTools.startsWith(n, "ion_smoke") || StringTools.startsWith(n, "Sphere00") || StringTools.startsWith(n, "EnergyBoost")) {
            isExemptFromCulling = true;
        } else {
            var nLower = n.toLowerCase();
            if (StringTools.startsWith(nLower, "energy")) {
                isExemptFromCulling = true;
            } else {
                isExemptFromCulling = false;
            }
        }
    }

    public var material(get, set):Material3D;
    private inline function get_material():Material3D {
        if (materials.length > 0 && materials[0] != null) return materials[0];
        if (surfaces.length > 0 && surfaces[0] != null && surfaces[0].material != null) return surfaces[0].material;
        return null;
    }
    private inline function set_material(value:Material3D):Material3D {
        setMaterial(value);
        return value;
    }

    override public function setMaterial(mat:flare.materials.Material3D, includeChildren:Bool = true):Void {
        for (i in 0...surfaces.length) {
            materials[i] = mat;
            if (surfaces[i] != null) surfaces[i].material = mat;
        }
        if (includeChildren) {
            for (c in children) {
                c.setMaterial(mat, true);
            }
        }
    }

    public function addSurface(surface:Surface3D, mat:Material3D = null):Surface3D {
        surfaces.push(surface);
        if (mat == null && surface != null && surface.material != null) {
            mat = surface.material;
        }
        materials.push(mat);
        if (surface != null && mat != null) {
            surface.material = mat;
        }
        return surface;
    }

    private static var _defaultMat:Material3D;
    public static function getDefaultMaterial():Material3D {
        if (_defaultMat == null) {
            _defaultMat = new flare.materials.Shader3D("defaultMeshMat", [
                new flare.materials.filters.ColorFilter(0x888888),
                new flare.materials.filters.LightFilter(),
                new flare.materials.filters.SpecularFilter(30, 0.8)
            ]);
            _defaultMat.twoSided = true;
        }
        return _defaultMat;
    }

    override public function render(camera:Camera3D = null, clearDepth:Bool = false, target:Dynamic = null):Void {
        if (!visible) return;
        var cam = (camera != null) ? camera : flare.system.Device3D.camera;
        if (cam == null) return;

        // 零分配球体地平线背面精准剔除 (仅在特定星球场景开启)
        if (enablePlanetCulling && !isExemptFromCulling) {
            var raw = world.rawData;
            var ox = raw[12], oy = raw[13], oz = raw[14];
            var camX = flare.system.Device3D.camX;
            var camY = flare.system.Device3D.camY;
            var camZ = flare.system.Device3D.camZ;

            // 1. 点积检测：背面半球物体必定被巨大球体遮挡 (dot < 3000.0 安全视界余量留足78度)
            var dot = ox * camX + oy * camY + oz * camZ;
            if (dot < 3000.0) {
                return;
            }

            // 2. 切线视距检测：切线距离112 + 16安全余量 = 128
            var dx = ox - camX;
            var dy = oy - camY;
            var dz = oz - camZ;
            var distSq = dx * dx + dy * dy + dz * dz;
            if (distSq > 16384.0) { // 128 * 128
                return;
            }
        }

        if (modifier != null) {
            modifier.update();
        }

        if (hasDrawListeners && hasEventListener(Pivot3D.ENTER_DRAW_EVENT)) {
            dispatchEvent(new openfl.events.Event(Pivot3D.ENTER_DRAW_EVENT));
        }

        for (i in 0...surfaces.length) {
            var surf = surfaces[i];
            var mat = (i < materials.length) ? materials[i] : null;
            if (mat == null && surf != null) mat = surf.material;
            if (mat == null) mat = material;
            if (mat == null) mat = getDefaultMaterial();

            if (mat != null && surf != null) {
                mat.draw(this, surf, cam);
            }
        }

        if (hasDrawListeners && hasEventListener(Pivot3D.EXIT_DRAW_EVENT)) {
            dispatchEvent(new openfl.events.Event(Pivot3D.EXIT_DRAW_EVENT));
        }
    }

    override public function draw(includeChildren:Bool = true, material:Material3D = null):Void {
        if (_dirty || parent == null) updateTransforms(true);
        if (visible) {
            var cam = flare.system.Device3D.camera;
            if (cam != null) {
                if (modifier != null) {
                    modifier.update();
                }

                if (hasDrawListeners && hasEventListener(Pivot3D.ENTER_DRAW_EVENT)) {
                    dispatchEvent(new openfl.events.Event(Pivot3D.ENTER_DRAW_EVENT));
                }

                for (i in 0...surfaces.length) {
                    var surf = surfaces[i];
                    var mat = material;
                    if (mat == null && i < materials.length) mat = materials[i];
                    if (mat == null && surf != null) mat = surf.material;
                    if (mat == null) mat = this.material;
                    if (mat == null) mat = getDefaultMaterial();

                    if (mat != null && surf != null) {
                        mat.draw(this, surf, cam);
                    }
                }

                if (hasDrawListeners && hasEventListener(Pivot3D.EXIT_DRAW_EVENT)) {
                    dispatchEvent(new openfl.events.Event(Pivot3D.EXIT_DRAW_EVENT));
                }
            }
        }
        if (includeChildren) {
            for (c in children) {
                c.draw(includeChildren, material);
            }
        }
    }

    override public function cloneBasic():Pivot3D {
        var m = new Mesh3D(name);
        copyTo(m);
        return m;
    }

    override public function copyTo(target:Pivot3D):Void {
        super.copyTo(target);
        if (Std.isOfType(target, Mesh3D)) {
            var m:Mesh3D = cast target;
            m.surfaces = this.surfaces.copy();
            m.materials = this.materials.copy();
            m.isExemptFromCulling = this.isExemptFromCulling;
            m.modifier = this.modifier;
            if (this.bounds != null) {
                m.bounds = this.bounds.clone();
            }
        }
    }

    public function getBounds():Boundings3D {
        if (bounds != null) return bounds;
        if (surfaces == null || surfaces.length == 0) return null;

        var minX = 1e9, maxX = -1e9;
        var minY = 1e9, maxY = -1e9;
        var minZ = 1e9, maxZ = -1e9;
        var foundVertices = false;

        for (surf in surfaces) {
            if (surf != null && surf.vertexData != null && surf.vertexData.length >= 3) {
                var stride = surf.vertexStride > 0 ? surf.vertexStride : 8;
                var len = surf.vertexData.length;
                var i = 0;
                while (i < len) {
                    var vx = surf.vertexData[i];
                    var vy = surf.vertexData[i + 1];
                    var vz = surf.vertexData[i + 2];
                    if (vx < minX) minX = vx;
                    if (vx > maxX) maxX = vx;
                    if (vy < minY) minY = vy;
                    if (vy > maxY) maxY = vy;
                    if (vz < minZ) minZ = vz;
                    if (vz > maxZ) maxZ = vz;
                    i += stride;
                }
                foundVertices = true;
            }
        }

        if (foundVertices) {
            bounds = new Boundings3D();
            bounds.update(minX, minY, minZ, maxX, maxY, maxZ);
            return bounds;
        }
        return null;
    }

    override public function getScreenRect(out:openfl.geom.Rectangle = null, camera:Camera3D = null, viewPort:openfl.geom.Rectangle = null):Bool {
        if (bounds == null) {
            getBounds();
        }
        if (bounds == null) return false;

        if (out == null) out = new openfl.geom.Rectangle();

        var cam = (camera != null) ? camera : ((scene != null) ? scene.camera : flare.system.Device3D.camera);
        if (cam == null) return false;

        var vp = (viewPort != null) ? viewPort : ((cam.viewPort != null) ? cam.viewPort : ((scene != null) ? scene.viewPort : new openfl.geom.Rectangle(0, 0, 800, 450)));
        if (vp == null) return false;

        if (_dirty || parent == null) updateTransforms(true);

        var m = new openfl.geom.Matrix3D();
        m.copyFrom(world);
        m.append(cam.viewProjection);

        var raw = m.rawData;
        var bMin = bounds.min;
        var bMax = bounds.max;

        var inFront:Bool = false;

        var p0_w:Float = bMin.x * raw[3] + bMin.y * raw[7] + bMin.z * raw[11] + raw[15];
        var p0_x:Float = (bMin.x * raw[0] + bMin.y * raw[4] + bMin.z * raw[8] + raw[12]) / p0_w;
        var p0_y:Float = (bMin.x * raw[1] + bMin.y * raw[5] + bMin.z * raw[9] + raw[13]) / p0_w;

        if (p0_w > 0) inFront = true;

        out.setTo(p0_x, p0_y, p0_x, p0_y);

        for (i in 1...8) {
            var cx = ((i & 1) != 0) ? bMax.x : bMin.x;
            var cy = ((i & 2) != 0) ? bMax.y : bMin.y;
            var cz = ((i & 4) != 0) ? bMax.z : bMin.z;

            var pw = cx * raw[3] + cy * raw[7] + cz * raw[11] + raw[15];
            var px = (cx * raw[0] + cy * raw[4] + cz * raw[8] + raw[12]) / pw;
            var py = (cx * raw[1] + cy * raw[5] + cz * raw[9] + raw[13]) / pw;

            if (pw > 0) inFront = true;

            if (px < out.x) out.x = px;
            if (py > out.y) out.y = py;
            if (px > out.width) out.width = px;
            if (py < out.height) out.height = py;
        }

        if (!inFront) return false;

        out.y = -out.y;
        out.width = out.width - out.x;
        out.height = -out.height - out.y;

        var halfW:Float = vp.width * 0.5;
        var halfH:Float = vp.height * 0.5;

        out.x = out.x * halfW + halfW + vp.x;
        out.y = out.y * halfH + halfH + vp.y;
        out.width = out.width * halfW;
        out.height = out.height * halfH;

        if (out.x < 0) {
            out.width += out.x;
            out.x = 0;
        }
        if (out.y < 0) {
            out.height += out.y;
            out.y = 0;
        }
        if (out.right > vp.width) {
            out.right = vp.width;
        }
        if (out.bottom > vp.height) {
            out.bottom = vp.height;
        }

        return true;
    }
}
