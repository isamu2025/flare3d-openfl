package flare.flsl;

import openfl.display3D.Program3D;
import openfl.utils.ByteArray;
import openfl.Vector;

/**
 * FLSLProgram stores the compiled GPU shaders and rasterizer/blend state configuration.
 */
class FLSLProgram {
    public var colorMask:Int = 15;
    public var cullFace:String = "back";
    public var debug:Bool = false;
    public var depthCompare:String = "lessEqual";
    public var depthWrite:Bool = true;
    public var destFactor:String = "zero";
    public var srcFactor:String = "one";
    public var fragmentBytes:ByteArray;
    public var fragmentConstants:Vector<Float>;
    public var vertexBytes:ByteArray;
    public var vertexConstants:Vector<Float>;
    public var program:Program3D;

    public function new() {
        fragmentConstants = new Vector<Float>();
        vertexConstants = new Vector<Float>();
    }
}
