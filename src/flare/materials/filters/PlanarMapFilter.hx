package flare.materials.filters;

import flare.core.Texture3D;

/**
 * PlanarMapFilter generates planar mirror reflections for water and polished marble surfaces.
 */
class PlanarMapFilter extends Filter3D {
    public var reflectionTexture:Texture3D;
    public var reflectivity:Float = 0.5;

    public function new(reflectionTexture:Texture3D = null, reflectivity:Float = 0.5) {
        super("planarMap");
        this.reflectionTexture = reflectionTexture;
        this.reflectivity = reflectivity;
    }
}
