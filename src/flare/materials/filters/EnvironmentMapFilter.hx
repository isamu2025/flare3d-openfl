package flare.materials.filters;

import flare.core.Texture3D;

/**
 * EnvironmentMapFilter reflects an environment texture based on vertex or pixel normals.
 */
class EnvironmentMapFilter extends Filter3D {
    public static inline var PER_PIXEL:String = "perPixel";
    public static inline var PER_VERTEX:String = "perVertex";

    public var texture:Texture3D;
    public var scaleX:Float = 1.0;
    public var scaleY:Float = 1.0;
    public var blendMode:String;
    public var techniqueName:String;

    public function new(texture:Texture3D = null, blendMode:String = null, alpha:Float = 1.0, techniqueName:String = "perPixel") {
        super("environmentMap");
        this.texture = texture;
        this.blendMode = blendMode;
        this.alpha = alpha;
        this.techniqueName = techniqueName;
    }
}
