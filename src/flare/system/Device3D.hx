package flare.system;

import openfl.display.Stage;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.Context3DTriangleFace;
import flare.core.Camera3D;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;
import openfl.Vector;

/**
 * Device3D manages Stage3D Context3D state, viewports, and render statistics.
 */
class Device3D {
    public static var profile:String = "baseline";
    public static var cameraGlobal:Matrix3D = new Matrix3D();
    public static var viewProj:Matrix3D = new Matrix3D();
    public static var proj:Matrix3D = new Matrix3D();
    public static var view:Matrix3D = new Matrix3D();
    public static var viewPort:Rectangle = null;
    public static var nearFar:Vector<Float> = new Vector<Float>(4, true);
    public static var cam:Vector<Float> = new Vector<Float>(4, true);
    public static var screen:Vector<Float> = new Vector<Float>(4, true);
    public static var mouse:Vector<Float> = new Vector<Float>(4, true);
    public static var random:Vector<Float> = new Vector<Float>(4, true);
    public static var lastMaterial:Dynamic = null;
    public static var program:Dynamic = null;
    public static var depthWrite:Bool = true;
    public static var usedSamples:Int = 8;
    public static var usedBuffers:Int = 8;
    public static var context:Context3D;
    public static var stage:Stage;
    public static var camera:Camera3D;
    public static var defaultCamera:Camera3D;
    public static var scene:flare.basic.Scene3D;
    public static var camX:Float = 0.0;
    public static var camY:Float = 0.0;
    public static var camZ:Float = 0.0;
    
    public static var drawCalls:Int = 0;
    public static var triangles:Int = 0;
    public static var frame:Int = 0;
    
    public static var blendSource:Context3DBlendFactor = Context3DBlendFactor.ONE;
    public static var blendDest:Context3DBlendFactor = Context3DBlendFactor.ZERO;
    public static var depthTest:Bool = true;
    public static var depthCompare:Context3DCompareMode = Context3DCompareMode.LESS_EQUAL;
    public static var cullFace:Context3DTriangleFace = Context3DTriangleFace.BACK;
    public static var invertCullFace(get, set):Bool;
    private static var _invertCullFace:Bool = false;
    private static function get_invertCullFace():Bool {
        return _invertCullFace;
    }
    private static function set_invertCullFace(value:Bool):Bool {
        if (_invertCullFace != value) {
            _invertCullFace = value;
            if (context != null) {
                var targetCull = cullFace;
                if (_invertCullFace) {
                    if (targetCull == Context3DTriangleFace.BACK) targetCull = Context3DTriangleFace.FRONT;
                    else if (targetCull == Context3DTriangleFace.FRONT) targetCull = Context3DTriangleFace.BACK;
                }
                context.setCulling(targetCull);
            }
        }
        return value;
    }
    public static var ignoreStates:Bool = false;
    
    public static var currentProgram:openfl.display3D.Program3D = null;
    public static var currentTexture0:openfl.display3D.textures.TextureBase = null;
    public static var currentVertexBuffer:openfl.display3D.VertexBuffer3D = null;
    public static var currentSurface:flare.core.Surface3D = null;
    public static var currentMaterial:Dynamic = null;
    public static var currentMesh:Dynamic = null;
    
    public static function resetStats():Void {
        drawCalls = 0;
        triangles = 0;
        currentProgram = null;
        currentTexture0 = null;
        currentVertexBuffer = null;
        currentSurface = null;
        currentMaterial = null;
        currentMesh = null;
        if (context != null) {
            context.setDepthTest(depthTest, depthCompare);
            context.setBlendFactors(blendSource, blendDest);
            context.setCulling(cullFace);
        }
    }
    
    public static function setProgram(p:openfl.display3D.Program3D):Void {
        if (context == null || p == null) return;
        if (currentProgram != p) {
            currentProgram = p;
            context.setProgram(p);
        }
    }
    
    public static function setVertexBuffers(vb:openfl.display3D.VertexBuffer3D, surface:flare.core.Surface3D = null):Void {
        if (context == null || vb == null) return;
        if (currentVertexBuffer != vb || currentSurface != surface) {
            currentVertexBuffer = vb;
            currentSurface = surface;
            if (surface != null && surface.hasCustomChannels) {
                for (a in 0...8) context.setVertexBufferAt(a, null);
                for (ch in surface.vertexChannels) {
                    var fmt = ch.size == 1 ? openfl.display3D.Context3DVertexBufferFormat.FLOAT_1 :
                              ch.size == 2 ? openfl.display3D.Context3DVertexBufferFormat.FLOAT_2 :
                              ch.size == 3 ? openfl.display3D.Context3DVertexBufferFormat.FLOAT_3 :
                              openfl.display3D.Context3DVertexBufferFormat.FLOAT_4;
                    if (ch.type == flare.core.Surface3D.POSITION) {
                        context.setVertexBufferAt(0, vb, ch.offset, fmt);
                    } else if (ch.type == flare.core.Surface3D.UV0) {
                        context.setVertexBufferAt(1, vb, ch.offset, fmt);
                    } else if (ch.type == flare.core.Surface3D.NORMAL) {
                        context.setVertexBufferAt(2, vb, ch.offset, fmt);
                    } else if (ch.type == flare.core.Surface3D.COLOR0) {
                        context.setVertexBufferAt(3, vb, ch.offset, fmt);
                    }
                }
            } else {
                context.setVertexBufferAt(0, vb, 0, openfl.display3D.Context3DVertexBufferFormat.FLOAT_3);
                context.setVertexBufferAt(1, vb, 3, openfl.display3D.Context3DVertexBufferFormat.FLOAT_2);
                context.setVertexBufferAt(2, vb, 5, openfl.display3D.Context3DVertexBufferFormat.FLOAT_3);
                if (surface != null && surface.vertexStride >= 10) {
                    context.setVertexBufferAt(3, vb, 8, openfl.display3D.Context3DVertexBufferFormat.FLOAT_2);
                } else {
                    context.setVertexBufferAt(3, null);
                }
            }
        }
    }
    
    public static function setTextureAt(sampler:Int, tex:openfl.display3D.textures.TextureBase):Void {
        if (context == null) return;
        if (sampler == 0) {
            if (currentTexture0 != tex) {
                currentTexture0 = tex;
                context.setTextureAt(0, tex);
            }
        } else {
            context.setTextureAt(sampler, tex);
        }
    }
    
    public static function setBlendFactors(src:Context3DBlendFactor, dest:Context3DBlendFactor):Void {
        if (context == null || ignoreStates) return;
        if (blendSource != src || blendDest != dest) {
            blendSource = src;
            blendDest = dest;
            context.setBlendFactors(src, dest);
        }
    }
    
    public static function setDepthTest(test:Bool, compare:Context3DCompareMode):Void {
        if (context == null || ignoreStates) return;
        if (depthTest != test || depthCompare != compare) {
            depthTest = test;
            depthCompare = compare;
            context.setDepthTest(test, compare);
        }
    }
    
    public static function setCulling(cull:Context3DTriangleFace):Void {
        if (context == null || ignoreStates) return;
        if (cullFace != cull) {
            cullFace = cull;
            var targetCull = cull;
            if (_invertCullFace) {
                if (targetCull == Context3DTriangleFace.BACK) targetCull = Context3DTriangleFace.FRONT;
                else if (targetCull == Context3DTriangleFace.FRONT) targetCull = Context3DTriangleFace.BACK;
            }
            context.setCulling(targetCull);
        }
    }
}
