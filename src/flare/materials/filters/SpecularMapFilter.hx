package flare.materials.filters;

import flare.core.Texture3D;

/**
 * SpecularMapFilter in Flare3D.
 * Modulates specular intensity and color reflection using a specular map texture.
 */
class SpecularMapFilter extends Filter3D {
    public var texture:Texture3D;
    public var power:Float;
    public var level:Float;
    public var channel:Int;
    public var offsetX:Float = 0.0;
    public var offsetY:Float = 0.0;

    // Aliases for compatibility
    public var specularMap(get, set):Texture3D;
    private inline function get_specularMap():Texture3D return texture;
    private inline function set_specularMap(v:Texture3D):Texture3D return texture = v;

    public var glossiness(get, set):Float;
    private inline function get_glossiness():Float return power;
    private inline function set_glossiness(v:Float):Float return power = v;

    public var intensity(get, set):Float;
    private inline function get_intensity():Float return level;
    private inline function set_intensity(v:Float):Float return level = v;

    public function new(texture:Texture3D = null, power:Float = 50.0, level:Float = 1.0, channel:Int = 0) {
        super("specularMap");
        this.texture = texture;
        this.power = power;
        this.level = level;
        this.channel = channel;
        this.repeatX = 1.0;
        this.repeatY = 1.0;
    }
}
