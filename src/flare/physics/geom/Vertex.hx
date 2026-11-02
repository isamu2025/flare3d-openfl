package flare.physics.geom;

import openfl.geom.Vector3D;

/**
 * Vertex represents a 3D vertex position for collision geometry meshes.
 */
class Vertex extends Vector3D {
    public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 0) {
        super(x, y, z, w);
    }
}
