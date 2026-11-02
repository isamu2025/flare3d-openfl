package flare.flsl;

import flare.core.Surface3D;

/**
 * FLSLSurface binds geometry vertex buffer references during rendering.
 */
class FLSLSurface extends FLSL {
    public var value:Surface3D;

    public function new(value:Surface3D = null) {
        super();
        this.value = value;
    }
}
