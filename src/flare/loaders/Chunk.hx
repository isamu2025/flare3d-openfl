package flare.loaders;

import openfl.utils.ByteArray;
import openfl.geom.Matrix3D;
import openfl.Vector;
import flare.core.Frame3D;

/**
 * Chunk encapsulates a binary data packet with Tag/Chunk ID and helper read methods for the F3D format.
 */
class Chunk extends ByteArray {
    public static inline var F3D_ANIMATION:Int = 9;
    public static inline var F3D_BONES:Int = 1;
    public static inline var F3D_BOUNDINGS:Int = 8;
    public static inline var F3D_CAMERA:Int = 4;
    public static inline var F3D_CHANNEL:Int = 5;
    public static inline var F3D_COLORS:Int = 9;
    public static inline var F3D_FACES:Int = 2;
    public static inline var F3D_FRAMES:Int = 10;
    public static inline var F3D_HELPER:Int = 3;
    public static inline var F3D_LABELS:Int = 5;
    public static inline var F3D_LIGHT:Int = 5;
    public static inline var F3D_MAPS:Int = 4;
    public static inline var F3D_MATERIALS:Int = 30;
    public static inline var F3D_MATERIAL:Int = 1;
    public static inline var F3D_MATERIAL_ENVIRONMENT:Int = 4;
    public static inline var F3D_MATERIAL_FLATCOLOR:Int = 5;
    public static inline var F3D_MATERIAL_FLATSHADEDCOLOR:Int = 6;
    public static inline var F3D_MATERIAL_FLATTEXTURE:Int = 7;
    public static inline var F3D_MATERIAL_MULTIMATERIAL:Int = 8;
    public static inline var F3D_MATERIAL_PLANAR:Int = 11;
    public static inline var F3D_MATERIAL_SHADEDCOLOR:Int = 9;
    public static inline var F3D_MATERIAL_STANDARD:Int = 3;
    public static inline var F3D_MATERIAL_UNDEFINED:Int = 2;
    public static inline var F3D_MATERIAL_WIREFRAME:Int = 10;
    public static inline var F3D_MESH:Int = 8;
    public static inline var F3D_MODIFIERS:Int = 50;
    public static inline var F3D_MODIFIER:Int = 1;
    public static inline var F3D_PIVOTS:Int = 40;
    public static inline var F3D_PIVOT:Int = 2;
    public static inline var F3D_PROPERTIES:Int = 10;
    public static inline var F3D_RENDER:Int = 3;
    public static inline var F3D_SHAPE:Int = 6;
    public static inline var F3D_SKIN:Int = 2;
    public static inline var F3D_SMOOTH:Int = 3;
    public static inline var F3D_SPLINE:Int = 7;
    public static inline var F3D_TEXTURES:Int = 20;
    public static inline var F3D_TEXTURE:Int = 1;
    public static inline var F3D_TFACE:Int = 7;
    public static inline var F3D_TVERT:Int = 6;
    public static inline var F3D_USERDATA:Int = 4;
    public static inline var F3D_VERTEX:Int = 1;
    public static inline var F3D_VERTEX_ANIMATION:Int = 7;
    public static inline var F3D_WEIGHTS:Int = 2;

    public var id:Int = 0;

    public function new(bytes:ByteArray = null) {
        super();
        if (bytes != null) {
            bytes.readBytes(this, 0, bytes.bytesAvailable);
            position = 0;
        }
    }

    public function readColor():Int {
        var r = readUnsignedByte();
        var g = readUnsignedByte();
        var b = readUnsignedByte();
        var a = (bytesAvailable > 0) ? readUnsignedByte() : 255;
        return (a << 24) | (r << 16) | (g << 8) | b;
    }

    public function readMatrix3D():Frame3D {
        var raw = new Vector<Float>(16);
        // Standard F3D 3x4 affine matrix (12 floats) or 4x4 (16 floats)
        for (i in 0...12) {
            raw[i] = readFloat();
        }
        raw[12] = 0;
        raw[13] = 0;
        raw[14] = 0;
        raw[15] = 1;
        return new Frame3D(raw);
    }

    public function readString():String {
        var len = readUnsignedShort();
        if (len == 0) return "";
        return readUTFBytes(len);
    }
}
