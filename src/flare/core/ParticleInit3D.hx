package flare.core;

import openfl.geom.Vector3D;

/**
 * ParticleInit3D defines initial properties for emitted particles.
 */
class ParticleInit3D {
    public var position:Vector3D;
    public var velocity:Vector3D;
    public var color:Vector3D;
    public var scale:Float = 1;
    public var spin:Float = 0;
    public var energy:Float = 100;
    public var size:Float = 1;

    public function new() {
        position = new Vector3D();
        velocity = new Vector3D();
        color = new Vector3D(1, 1, 1, 1);
    }
}
