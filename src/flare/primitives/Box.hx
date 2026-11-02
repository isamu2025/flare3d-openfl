package flare.primitives;

import flare.materials.Material3D;

/**
 * Box is an alias/subclass of Cube for compatibility.
 */
class Box extends Cube {
    public function new(name:String = "box", width:Float = 100, height:Float = 100, depth:Float = 100, segments:Int = 1, material:Material3D = null) {
        super(name, width, height, depth, segments, material);
    }
}
