package flare.core;

import openfl.geom.Vector3D;
import openfl.Vector;
import flare.materials.Material3D;

/**
 * MeshBatch3D renders thousands of identical mesh instances using GPU batching or instanced buffers.
 */
class MeshBatch3D extends Pivot3D {
    public var mesh:Mesh3D;
    public var maxInstances:Int;
    public var enableCameraCulling:Bool = true;
    public var positions:Vector<Float>;
    public var orientations:Vector<Float>;
    public var surfaces:Array<Surface3D>;
    public var material:Material3D;

    private var _instanceCount:Int = 0;

    public function new(mesh:Mesh3D, maxInstances:Int = 1000) {
        super("meshBatch_" + (mesh != null ? mesh.name : ""));
        this.mesh = mesh;
        this.maxInstances = maxInstances;
        this.positions = new Vector<Float>();
        this.orientations = new Vector<Float>();
        this.surfaces = mesh != null ? mesh.surfaces : [];
    }

    public function addInstance(position:Vector3D, orientation:Vector3D = null):Int {
        positions.push(position.x);
        positions.push(position.y);
        positions.push(position.z);

        if (orientation != null) {
            orientations.push(orientation.x);
            orientations.push(orientation.y);
            orientations.push(orientation.z);
            orientations.push(orientation.w);
        } else {
            orientations.push(0);
            orientations.push(0);
            orientations.push(0);
            orientations.push(1);
        }

        return _instanceCount++;
    }

    override public function draw(includeChildren:Bool = true, material:Material3D = null):Void {
        if (mesh == null || _instanceCount == 0) return;
        super.draw(includeChildren, material);
    }
}
