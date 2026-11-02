package flare.materials.filters;

import flare.core.Texture3D;

/**
 * LightMapFilter blends pre-baked static lighting textures onto surfaces.
 */
class LightMapFilter extends Filter3D {
    public var texture:Texture3D;
    public var channel:Int = 2;
    public var blendMode:String = "multiply";
    public var level:Float = 1.0;

    public function new(texture:Texture3D = null, channel:Int = 2, blendMode:String = "multiply") {
        super("lightMap");
        this.texture = texture;
        this.channel = channel;
        this.blendMode = blendMode;
        if (texture != null) {
            texture.wrapMode = Texture3D.WRAP_CLAMP;
            texture.mipMode = Texture3D.MIP_NONE;
        }
    }
}
