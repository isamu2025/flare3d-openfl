package flare.materials.filters;

/**
 * SkinTransformFilter transforms vertex positions in the vertex shader using skeletal bone matrix palettes.
 */
class SkinTransformFilter extends Filter3D {
    public var bones:Int;

    public function new(bones:Int = 1) {
        super("skinTransform");
        this.bones = bones;
    }

    public function init():Void {}
    public function process():Void {}
}
