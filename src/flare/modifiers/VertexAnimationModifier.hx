package flare.modifiers;

import openfl.Vector;
import flare.core.Mesh3D;
import flare.materials.Material3D;

/**
 * VertexAnimationModifier implements per-vertex keyframe morph animation (vertex cache / blend shapes).
 */
class VertexAnimationModifier extends Modifier {
    public var frames:Vector<Vector<Float>>;
    public var frameSkip:Int = 0;
    public var normals:Bool = false;
    public var morphEnabled:Bool = false;
    public var morphValue:Float = 0;
    public var morphFromFrame:Int = 0;
    public var morphToFrame:Int = 0;

    public function new(framesCount:Int = 0) {
        super();
        this.frames = new Vector<Vector<Float>>();
    }

    public function gotoAndStop(frame:Float):Void {
        morphFromFrame = Math.floor(frame);
        morphToFrame = Math.ceil(frame);
        morphValue = frame - morphFromFrame;
    }

    public function interpolate(from:Int, to:Int, weight:Float):Void {
        morphFromFrame = from;
        morphToFrame = to;
        morphValue = weight;
    }

    override public function clone():Modifier {
        var m = new VertexAnimationModifier();
        m.frameSkip = frameSkip;
        m.normals = normals;
        m.morphEnabled = morphEnabled;
        return m;
    }

    override public function draw(includeChildren:Bool = true, material:Material3D = null):Void {}

    public function toString():String {
        return "[VertexAnimationModifier frames=" + frames.length + "]";
    }
}
