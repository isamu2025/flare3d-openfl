package flare.materials.filters;

import flare.core.Texture3D;

/**
 * NormalMapFilter applies tangent-space normal mapping to simulate surface depth details.
 */
class NormalMapFilter extends Filter3D {
    public var normalMap:Texture3D;
    public var repeat:Bool = true;
    public var channel:Int = 0;
    public var offsetX:Float = 0.0;
    public var offsetY:Float = 0.0;
    public var normalScale:Float = 1.0;

    public var texture(get, set):Texture3D;
    private inline function get_texture():Texture3D return normalMap;
    private inline function set_texture(v:Texture3D):Texture3D return normalMap = v;

    public function new(normalMap:Texture3D = null, channelOrRepeat:Dynamic = null, techniqueName:String = null) {
        super("normalMap");
        this.normalMap = normalMap;
        if (Std.isOfType(channelOrRepeat, Bool)) {
            this.repeat = cast channelOrRepeat;
        } else if (Std.isOfType(channelOrRepeat, Int)) {
            this.channel = cast channelOrRepeat;
        }
        this.repeatX = 1.0;
        this.repeatY = 1.0;
    }
}
