package flare.physics;

import openfl.geom.Vector3D;

/**
 * Interface for geometric shapes used in collision detection and support-mapping.
 */
interface IShape {
    public function getSupportPoints(dir:Vector3D, out:Vector3D):Void;
    public function project(axis:Vector3D, out:Vector3D):Void;
}
