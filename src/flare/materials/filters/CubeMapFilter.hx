package flare.materials.filters;

import flare.core.Texture3D;

/**
 * CubeMapFilter maps 6-sided cubic environmental reflection onto meshes.
 */
class CubeMapFilter extends Filter3D {
    public var texture(get, set):Texture3D;
    public var cubeMap:Texture3D;
    public var level:Float = 1.0;
    public var blendMode:String;

    private inline function get_texture():Texture3D return cubeMap;
    private inline function set_texture(v:Texture3D):Texture3D return cubeMap = v;

    public function new(texture:Texture3D = null, level:Float = 1.0, blendMode:String = "multiply") {
        super("cubeMap");
        this.cubeMap = texture;
        this.level = level;
        this.blendMode = blendMode;
    }
}
