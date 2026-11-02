package flare.materials;

import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.Context3DTriangleFace;
import flare.core.Camera3D;
import flare.core.Mesh3D;
import flare.core.Surface3D;

/**
 * Material3D is the base class for all Flare3D materials.
 */
class Material3D {
    public var name:String;
    public var sourceFactor:Context3DBlendFactor = Context3DBlendFactor.ONE;
    public var destFactor:Context3DBlendFactor = Context3DBlendFactor.ZERO;
    public var depthWrite:Bool = true;
    public var depthCompare:Context3DCompareMode = Context3DCompareMode.LESS_EQUAL;
    public var twoSided:Bool = false;
    public var cullFace:Context3DTriangleFace = Context3DTriangleFace.BACK;

    public var transparent(get, set):Bool;
    private var _transparent:Bool = false;

    private function get_transparent():Bool {
        return _transparent;
    }

    private function set_transparent(value:Bool):Bool {
        _transparent = value;
        if (value) {
            sourceFactor = Context3DBlendFactor.SOURCE_ALPHA;
            destFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
        } else {
            sourceFactor = Context3DBlendFactor.ONE;
            destFactor = Context3DBlendFactor.ZERO;
        }
        return value;
    }

    public function new(name:String = "material") {
        this.name = name;
    }

    public function clone():Material3D {
        var m = new Material3D(name);
        m.sourceFactor = sourceFactor;
        m.destFactor = destFactor;
        m.depthWrite = depthWrite;
        m.depthCompare = depthCompare;
        m.twoSided = twoSided;
        m.cullFace = cullFace;
        m.transparent = transparent;
        return m;
    }

    public function draw(mesh:Mesh3D, surface:Surface3D, camera:Camera3D):Void {
        // Base implementation overridden by Shader3D
    }

    public function download():Void {
    }

    public function dispose():Void {
    }
}
