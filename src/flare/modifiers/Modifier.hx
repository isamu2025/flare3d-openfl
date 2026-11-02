package flare.modifiers;

import flare.core.Mesh3D;
import flare.materials.Material3D;

/**
 * Modifier is the base class for geometry deformation and vertex modifiers.
 */
class Modifier {
    public function new() {}

    public function clone():Modifier {
        return new Modifier();
    }

    public function update():Void {}

    public function draw(mesh:Mesh3D, material:Material3D = null):Void {}
}
