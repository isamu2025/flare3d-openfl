package flare.core;

import openfl.Vector;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import flare.system.Device3D;

/**
 * Surface3D holds geometry vertex arrays and GPU buffers (VertexBuffer3D & IndexBuffer3D).
 */
class Surface3D {
    public static inline var POSITION:Int = 0;
    public static inline var NORMAL:Int = 1;
    public static inline var UV0:Int = 2;
    public static inline var COLOR0:Int = 3;
    public static inline var TANGENT:Int = 4;
    public static inline var BITANGENT:Int = 5;
    public static inline var SKIN_WEIGHTS:Int = 6;
    public static inline var SKIN_INDICES:Int = 7;
    public static inline var UV1:Int = 2;
    public static inline var UV2:Int = 14;

    public var name:String;
    public var vertexData:Vector<Float>;
    public var indexData:Vector<UInt>;
    public var vertexStride:Int = 8; // default: pos(3) + uv(2) + normal(3)
    public var sizePerVertex(get, set):Int;
    private inline function get_sizePerVertex():Int return vertexStride;
    private inline function set_sizePerVertex(v:Int):Int return vertexStride = v;
    public var material:flare.materials.Material3D;
    
    public var vertexVector(get, set):Vector<Float>;
    private inline function get_vertexVector():Vector<Float> return vertexData;
    private inline function set_vertexVector(v:Vector<Float>):Vector<Float> return vertexData = v;

    public var indexVector(get, set):Vector<UInt>;
    private inline function get_indexVector():Vector<UInt> return indexData;
    private inline function set_indexVector(v:Vector<UInt>):Vector<UInt> return indexData = v;

    public var vertexBuffer:VertexBuffer3D;
    public var indexBuffer:IndexBuffer3D;
    public var userData:Dynamic;

    public var _dirty:Bool = true;
    public var _allocatedVertices:Int = 0;
    public var _allocatedIndices:Int = 0;

    public var centerX:Float = 0.0;
    public var centerY:Float = 0.0;
    public var centerZ:Float = 0.0;
    public var hasCenter:Bool = false;

    public function computeCenter():Void {
        if (vertexData == null || vertexData.length < 3) return;
        var minX = 1e9, maxX = -1e9;
        var minY = 1e9, maxY = -1e9;
        var minZ = 1e9, maxZ = -1e9;
        var stride = vertexStride > 0 ? vertexStride : 8;
        var len = vertexData.length;
        var i = 0;
        while (i < len) {
            var vx = vertexData[i];
            var vy = vertexData[i + 1];
            var vz = vertexData[i + 2];
            if (vx < minX) minX = vx;
            if (vx > maxX) maxX = vx;
            if (vy < minY) minY = vy;
            if (vy > maxY) maxY = vy;
            if (vz < minZ) minZ = vz;
            if (vz > maxZ) maxZ = vz;
            i += stride;
        }
        centerX = (minX + maxX) * 0.5;
        centerY = (minY + maxY) * 0.5;
        centerZ = (minZ + maxZ) * 0.5;
        hasCenter = true;
    }

    public inline function invalidate():Void {
        _dirty = true;
    }

    public function new(name:String = "surface") {
        this.name = name;
        this.vertexData = new Vector<Float>();
        this.indexData = new Vector<UInt>();
    }

    public var vertexChannels:Array<{type:Int, size:Int, offset:Int}> = [];
    public var hasCustomChannels:Bool = false;

    public function addVertexData(type:Int, size:Int = -1, data:Vector<Float> = null):Void {
        if (size <= 0) {
            if (type == UV0 || type == UV1 || type == UV2 || type == 8) size = 2;
            else if (type == COLOR0) size = 4;
            else size = 3;
        }
        if (!hasCustomChannels) {
            vertexChannels = [];
            vertexStride = 0;
            hasCustomChannels = true;
        }
        var offset = vertexStride;
        vertexChannels.push({type: type, size: size, offset: offset});

        if (data != null) {
            var oldStride = vertexStride;
            var newStride = oldStride + size;
            var numVerts = oldStride > 0 ? Std.int(vertexData.length / oldStride) : Std.int(data.length / size);

            if (oldStride == 0 || vertexData.length == 0) {
                vertexData = new Vector<Float>(data.length);
                for (i in 0...data.length) {
                    vertexData[i] = data[i];
                }
            } else {
                var newVector = new Vector<Float>(numVerts * newStride);
                var dIdx = 0;
                for (i in 0...numVerts) {
                    var srcBase = i * oldStride;
                    var dstBase = i * newStride;
                    for (j in 0...oldStride) {
                        newVector[dstBase + j] = vertexData[srcBase + j];
                    }
                    for (j in 0...size) {
                        newVector[dstBase + oldStride + j] = (dIdx < data.length) ? data[dIdx++] : 0.0;
                    }
                }
                vertexData = newVector;
            }
            vertexStride = newStride;
        } else {
            vertexStride += size;
        }
        _dirty = true;
    }

    public var numVertices(get, never):Int;
    private inline function get_numVertices():Int {
        return vertexStride > 0 ? Std.int(vertexData.length / vertexStride) : 0;
    }

    public var firstIndex:Int = 0;
    public var isSkinned:Bool = false;
    public var numTriangles(get, set):Int;
    private var _numTriangles:Int = 0;
    private inline function get_numTriangles():Int {
        return _numTriangles > 0 ? _numTriangles : (indexData != null ? Std.int(indexData.length / 3) : 0);
    }
    private inline function set_numTriangles(v:Int):Int {
        return _numTriangles = v;
    }

    public function upload(context:Context3D = null):Void {
        if (context == null) context = Device3D.context;
        if (context == null || vertexData.length == 0 || indexData.length == 0) return;
        if (!_dirty && vertexBuffer != null && indexBuffer != null) return;

        var vCount = numVertices;
        var iCount = indexData.length;
        if (vCount == 0 || iCount == 0) return;

        if (isSkinned) {
            // Skinned surface vertex buffers are managed and uploaded dynamically by SkinModifier.
            // Under no circumstances should the static undeformed bind-pose vertexData be uploaded here,
            // otherwise it will corrupt frame 0 or cause A-pose flickering during animation playback.
            if (indexBuffer == null || _allocatedIndices < iCount) {
                if (indexBuffer != null) indexBuffer.dispose();
                indexBuffer = context.createIndexBuffer(iCount);
                _allocatedIndices = iCount;
                indexBuffer.uploadFromVector(indexData, 0, iCount);
            }
            _dirty = false;
            return;
        }

        if (vertexBuffer == null || (_allocatedVertices > 0 && _allocatedVertices < vCount)) {
            if (vertexBuffer != null && _allocatedVertices > 0) vertexBuffer.dispose();
            vertexBuffer = context.createVertexBuffer(vCount, vertexStride);
            _allocatedVertices = vCount;
            vertexBuffer.uploadFromVector(vertexData, 0, vCount);
        } else if (_dirty) {
            vertexBuffer.uploadFromVector(vertexData, 0, vCount);
        }

        if (indexBuffer == null || _allocatedIndices < iCount) {
            if (indexBuffer != null) indexBuffer.dispose();
            indexBuffer = context.createIndexBuffer(iCount);
            _allocatedIndices = iCount;
        }
        indexBuffer.uploadFromVector(indexData, 0, iCount);

        _dirty = false;
    }

    public function dispose():Void {
        if (!isSkinned && vertexBuffer != null) {
            vertexBuffer.dispose();
            vertexBuffer = null;
        } else {
            vertexBuffer = null;
        }
        if (indexBuffer != null) {
            indexBuffer.dispose();
            indexBuffer = null;
        }
        _allocatedVertices = 0;
        _allocatedIndices = 0;
        _dirty = true;
    }
}
