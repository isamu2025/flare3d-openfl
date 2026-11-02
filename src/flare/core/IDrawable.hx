package flare.core;

import flare.materials.Material3D;

/**
 * Interface implemented by 3D objects that can be drawn into the scene.
 */
interface IDrawable {
    public var inView(get, never):Bool;
    public function draw(includeChildren:Bool = true, material:Material3D = null):Void;
}
