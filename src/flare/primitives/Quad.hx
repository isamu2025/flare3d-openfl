package flare.primitives;

import openfl.geom.Rectangle;
import flare.core.Camera3D;
import flare.core.Mesh3D;
import flare.core.Surface3D;
import flare.materials.Material3D;
import flare.materials.NullMaterial;
import flare.system.Device3D;

/**
 * Quad creates a 2D or screen-aligned rectangular mesh in screen-space NDC coordinates.
 */
class Quad extends Mesh3D {
    public var fullScreenMode:Bool;
    private var _surf:Surface3D;
    private var _x:Float = 0;
    private var _y:Float = 0;
    private var _width:Float = 1;
    private var _height:Float = 1;

    public function new(name:String = "quad", x:Float = 0, y:Float = 0, width:Float = 1, height:Float = 1, fullScreenMode:Bool = false, material:Material3D = null) {
        super(name);
        this.fullScreenMode = fullScreenMode;

        _surf = new Surface3D(name + "_surf");
        _surf.addVertexData(Surface3D.POSITION, 3);
        _surf.addVertexData(Surface3D.UV0, 2);
        _surf.addVertexData(Surface3D.NORMAL, 3);

        var v = _surf.vertexData;
        var i = _surf.indexData;

        // 8 floats per vertex (pos: 3, uv: 2, norm: 3)
        v.push(-1); v.push(1); v.push(0);
        v.push(0); v.push(0);
        v.push(0); v.push(0); v.push(1);

        v.push(1); v.push(1); v.push(0);
        v.push(1); v.push(0);
        v.push(0); v.push(0); v.push(1);

        v.push(-1); v.push(-1); v.push(0);
        v.push(0); v.push(1);
        v.push(0); v.push(0); v.push(1);

        v.push(1); v.push(-1); v.push(0);
        v.push(1); v.push(1);
        v.push(0); v.push(0); v.push(1);

        // Consistent CCW winding for both triangles
        i.push(0); i.push(2); i.push(1);
        i.push(2); i.push(3); i.push(1);

        var mat:Material3D = (material != null) ? material : new NullMaterial();
        addSurface(_surf, mat);

        setTo(x, y, width, height, fullScreenMode);
    }

    public function setTo(x:Float, y:Float, width:Float, height:Float, fullScreenMode:Bool = false):Void {
        this._x = x;
        this._y = y;
        this._width = width;
        this._height = height;
        this.fullScreenMode = fullScreenMode;
    }

    override public function render(camera:Camera3D = null, clearDepth:Bool = false, target:Dynamic = null):Void {
        draw(false, null);
    }

    override public function draw(includeChildren:Bool = true, material:Material3D = null):Void {
        if (!visible) return;

        var ctx = (scene != null && scene.context != null) ? scene.context : Device3D.context;
        if (_surf != null && (_surf.vertexBuffer == null || _surf.indexBuffer == null)) {
            if (ctx != null) {
                _surf.upload(ctx);
            }
        }

        var vp:Rectangle = null;
        if (scene != null && scene.viewPort != null) {
            vp = scene.viewPort;
        } else if (Device3D.scene != null && Device3D.scene.viewPort != null) {
            vp = Device3D.scene.viewPort;
        } else {
            vp = new Rectangle(0, 0, 800, 450);
        }

        var vpW = (vp.width > 0) ? vp.width : 800.0;
        var vpH = (vp.height > 0) ? vp.height : 450.0;

        world.identity();

        if (fullScreenMode || (_width == 0 && _height == 0)) {
            // Full screen NDC: vertices (-1,-1) to (1,1) mapped directly
            world.identity();
        } else {
            var rx = _x / vpW;
            var ry = _y / vpH;
            var rw = _width / vpW;
            var rh = _height / vpH;
            world.appendScale(rw != 0 ? rw : 0.00001, rh != 0 ? rh : 0.00001, 1);
            world.appendTranslation(-1 + rw + rx * 2, 1 - rh - ry * 2, 0);
        }

        var cam:Camera3D = (scene != null) ? scene.camera : Device3D.camera;
        var mat:Material3D = (material != null) ? material : (_surf != null ? _surf.material : null);
        if (mat != null && _surf != null) {
            mat.draw(this, _surf, cam);
        }

        if (includeChildren) {
            for (c in children) {
                c.draw(true, material);
            }
        }
    }
}
