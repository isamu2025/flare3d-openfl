package flare.materials.filters;

import flare.core.Texture3D;

/**
 * ReflectionMapFilter mixes a planar or spherical reflection texture into the surface color.
 */
class ReflectionMapFilter extends Filter3D {
    public var texture:Texture3D;
    public var level:Float;
    public var blendMode:String;

    public function new(texture:Texture3D = null, level:Float = 1.0, blendMode:String = null) {
        super("reflectionMap");
        this.texture = texture;
        this.level = level;
        this.blendMode = blendMode;
    }
}
