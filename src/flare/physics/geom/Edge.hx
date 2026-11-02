package flare.physics.geom;

import openfl.geom.Vector3D;

/**
 * Edge represents a directed segment between two vertices in a collision mesh.
 */
class Edge extends Vector3D {
    public var v0:Vertex;
    public var v1:Vertex;
    public var tri:Triangle;
    public var valid:Bool = true;

    public function new(v0:Vertex = null, v1:Vertex = null) {
        super();
        this.v0 = v0;
        this.v1 = v1;
        if (v0 != null && v1 != null) {
            x = v1.x - v0.x;
            y = v1.y - v0.y;
            z = v1.z - v0.z;
        }
    }
}
