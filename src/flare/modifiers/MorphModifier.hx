package flare.modifiers;

import flare.core.Mesh3D;
import flare.core.Surface3D;

/**
 * MorphModifier blends multiple geometric morph targets via weighted blend shapes.
 */
class MorphModifier extends Modifier {
    public var mesh:Mesh3D;
    public var targets:Array<Surface3D>;
    public var weights:Array<Float>;

    public function new(mesh:Mesh3D = null) {
        super();
        this.mesh = mesh;
        this.targets = [];
        this.weights = [];
    }

    public function addTarget(surface:Surface3D, initialWeight:Float = 0):Int {
        var idx = targets.length;
        targets.push(surface);
        weights.push(initialWeight);
        return idx;
    }

    public function setWeight(index:Int, weight:Float):Void {
        if (index >= 0 && index < weights.length) {
            weights[index] = weight;
        }
    }

    public function getWeight(index:Int):Float {
        return (index >= 0 && index < weights.length) ? weights[index] : 0.0;
    }
}
