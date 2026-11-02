package flare.physics.colliders;

import flare.core.Pivot3D;

/**
 * BoxCollider represents a 3D rectangular bounding box for collision detection.
 */
class BoxCollider extends Collider {
    public var width:Float;
    public var height:Float;
    public var depth:Float;
    public var halfWidth:Float;
    public var halfHeight:Float;
    public var halfDepth:Float;

    public function new(pivot:Pivot3D = null, width:Float = 10, height:Float = 10, depth:Float = 10) {
        super(pivot);
        this.shape = Collider.SHAPE_BOX;
        this.width = width;
        this.height = height;
        this.depth = depth;
        this.halfWidth = width * 0.5;
        this.halfHeight = height * 0.5;
        this.halfDepth = depth * 0.5;
    }
}
