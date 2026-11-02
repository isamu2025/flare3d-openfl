package flare.flsl;

import openfl.geom.Matrix3D;

/**
 * FLSLMatrix binds a 4x4 matrix constant (MVP, World, View) into shader constant registers.
 */
class FLSLMatrix extends FLSL {
    public var value:Matrix3D;

    public function new(value:Matrix3D = null) {
        super();
        this.value = value != null ? value : new Matrix3D();
    }

    public function clone():FLSLMatrix {
        return new FLSLMatrix(value.clone());
    }
}
