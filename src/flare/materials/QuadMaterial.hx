package flare.materials;

import flare.core.Texture3D;
import flare.materials.filters.TextureMapFilter;

/**
 * QuadMaterial represents a specialized material for 2D/screen-space Quads.
 */
class QuadMaterial extends Shader3D {
    public var texture(get, set):Texture3D;
    private var _texFilter:TextureMapFilter;

    public function new(texture:Texture3D = null) {
        super("quadMaterial");
        if (texture != null) {
            _texFilter = new TextureMapFilter(texture);
            filters.push(_texFilter);
        }
    }

    private inline function get_texture():Texture3D {
        return _texFilter != null ? _texFilter.texture : null;
    }

    private inline function set_texture(t:Texture3D):Texture3D {
        if (_texFilter == null) {
            _texFilter = new TextureMapFilter(t);
            filters.push(_texFilter);
        } else {
            _texFilter.texture = t;
        }
        return t;
    }
}
