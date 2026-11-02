package flare.materials.filters;

import flare.core.Texture3D;

/**
 * TextureMapFilter maps a 2D Texture3D onto the mesh surface using UV coordinates.
 */
class TextureMapFilter extends Filter3D {
    public var texture:Texture3D;
    public var repeat:Bool;
    public var offsetX:Float = 0.0;
    public var offsetY:Float = 0.0;

    public function new(texture:Texture3D = null, repeat:Bool = true) {
        super("textureMap");
        this.texture = texture != null ? texture : Texture3D.defaultTexture;
        this.repeat = repeat;
    }
}
