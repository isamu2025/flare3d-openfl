package flare.physics.colliders;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import flare.core.Pivot3D;

/**
 * Collider is the foundational physical body in Flare3D's physics engine.
 * It combines spatial collision volume geometry and rigid body dynamics.
 */
class Collider {
    public static inline var SHAPE_NULL:Int = 0;
    public static inline var SHAPE_BOX:Int = 1;
    public static inline var SHAPE_SPHERE:Int = 2;
    public static inline var SHAPE_MESH:Int = 3;
    public static inline var SHAPE_RAY:Int = 4;

    public var shape:Int = SHAPE_NULL;
    public var pivot:Pivot3D;
    public var position:Vector3D;
    public var linearVelocity:Vector3D;
    public var angularVelocity:Vector3D;
    public var gravity:Vector3D;

    public var mass:Float = 1.0;
    public var invMass:Float = 1.0;
    public var restitution:Float = 0.3;
    public var friction:Float = 0.5;

    public var isStatic:Bool = false;
    public var isRigidBody:Bool = true;
    public var isTrigger:Bool = false;
    public var enabled:Bool = true;
    public var sleeping:Bool = false;

    public function new(pivot:Pivot3D = null) {
        this.pivot = pivot;
        this.position = new Vector3D();
        this.linearVelocity = new Vector3D();
        this.angularVelocity = new Vector3D();
        this.gravity = null;

        if (pivot != null) {
            syncFromPivot();
        }
    }

    public function syncFromPivot():Void {
        if (pivot != null) {
            position.setTo(pivot.x, pivot.y, pivot.z);
        }
    }

    public function syncToPivot():Void {
        if (pivot != null) {
            pivot.setPosition(position.x, position.y, position.z);
        }
    }

    public function setMass(newMass:Float):Void {
        this.mass = newMass;
        if (newMass <= 0 || isStatic) {
            this.invMass = 0;
            this.isStatic = true;
        } else {
            this.invMass = 1.0 / newMass;
            this.isStatic = false;
        }
    }

    public function applyImpulse(ix:Float, iy:Float, iz:Float, atPos:Vector3D = null):Void {
        if (isStatic) return;
        linearVelocity.x += ix * invMass;
        linearVelocity.y += iy * invMass;
        linearVelocity.z += iz * invMass;
        sleeping = false;
    }

    public function applyTorque(tx:Float, ty:Float, tz:Float):Void {
        if (isStatic) return;
        angularVelocity.x += tx;
        angularVelocity.y += ty;
        angularVelocity.z += tz;
        sleeping = false;
    }

    public function resetVelocities():Void {
        linearVelocity.setTo(0, 0, 0);
        angularVelocity.setTo(0, 0, 0);
    }

    public function update(timeStep:Float):Void {
        if (isStatic || !enabled || sleeping) return;

        // Linear movement integration
        position.x += linearVelocity.x * timeStep;
        position.y += linearVelocity.y * timeStep;
        position.z += linearVelocity.z * timeStep;

        if (pivot != null) {
            syncToPivot();
            if (angularVelocity.lengthSquared > 0.0001) {
                pivot.rotateX(angularVelocity.x * timeStep * 180 / Math.PI);
                pivot.rotateY(angularVelocity.y * timeStep * 180 / Math.PI);
                pivot.rotateZ(angularVelocity.z * timeStep * 180 / Math.PI);
            }
        }
    }
}
