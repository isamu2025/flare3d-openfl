package flare.materials.filters;

import flare.core.Texture3D;

/**
 * TextureMaskFilter masks fragments using an arbitrary texture and color channel.
 */
class TextureMaskFilter extends Filter3D {
    public static inline var ALPHA:Int = 0;
    public static inline var RED:Int = 1;
    public static inline var GREEN:Int = 2;
    public static inline var BLUE:Int = 3;

    public var texture:Texture3D;
    public var channel:Int;
    public var threshold:Float;
    public var technique:String;

    public function new(texture:Texture3D = null, channel:Int = 0, threshold:Float = 0.5, technique:String = null) {
        super("textureMask");
        this.texture = texture;
        this.channel = channel;
        this.threshold = threshold;
        this.technique = technique;
    }
}
