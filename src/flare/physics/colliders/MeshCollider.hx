package flare.physics.colliders;

import flare.core.Mesh3D;
import flare.core.Pivot3D;

/**
 * MeshCollider represents an arbitrary polygonal triangle mesh for static or dynamic collision.
 */
class MeshCollider extends Collider {
    public var mesh:Mesh3D;

    public function new(pivot:Pivot3D = null, mesh:Mesh3D = null) {
        super(pivot);
        this.shape = Collider.SHAPE_MESH;
        this.mesh = mesh;
        this.isStatic = true; // Mesh colliders default to static terrain/obstacles
        this.invMass = 0;
    }
}
