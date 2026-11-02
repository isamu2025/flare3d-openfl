package flare.loaders;

import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;
import openfl.utils.Endian;
import openfl.geom.Matrix3D;
import openfl.Vector;
import openfl.display.BitmapData;
import flare.core.Pivot3D;
import flare.core.Mesh3D;
import flare.core.Camera3D;
import flare.core.Light3D;
import flare.core.Surface3D;
import flare.core.Texture3D;
import flare.core.Frame3D;
import flare.materials.Shader3D;
import flare.materials.filters.ColorFilter;
import flare.materials.filters.TextureMapFilter;
import flare.system.ILibraryExternalItem;
import flare.system.Library3D;
import flare.basic.Scene3D;

/**
 * Flare3DLoader2 loads and parses Flare3D Version 2 (C3D / F3D v2) binary chunk models.
 */
class Flare3DLoader2 extends Pivot3D implements ILibraryExternalItem {
    public var activeCamera:Camera3D;
    public var asyncCount:Int = 0;
    public var asyncInterval:Int = 0;
    public var compressionLevel:Int = 0;
    public var floatPrecision:Int = 0;
    public var magic:String = "C3D";
    public var resourcesPath:String = "";
    public var version:Int = 2;

    public var bytesLoaded:Float = 0;
    public var bytesTotal:Float = 0;
    public var loaded:Bool = false;
    public var request:URLRequest;

    private var _bytes:ByteArray;
    private var _header:Bool = false;
    private var _ids:Array<Dynamic>;
    private var _library:Library3D;
    private var _nullMaterial:Shader3D;
    private var _parent:Pivot3D;
    private var _resourcesTotal:Int = 0;
    private var _sceneContext:Scene3D;
    private var _urlLoader:URLLoader;

    public function new(request:Dynamic = null, parent:Pivot3D = null, sceneContext:Scene3D = null) {
        super("f3d_v2");
        if (Std.isOfType(request, URLRequest)) {
            this.request = cast request;
        } else if (Std.isOfType(request, String)) {
            this.request = new URLRequest(cast request);
        }
        this._parent = parent != null ? parent : this;
        this._sceneContext = sceneContext;
        this._library = new Library3D();
        this._ids = [];

        if (request != null) {
            load();
        }
    }

    public function load():Void {
        if (request == null || request.url == null) return;
        var urlStr:String = request.url;

        #if sys
        var resolved = flare.system.AssetResolver.resolve(urlStr);
        if (sys.FileSystem.exists(resolved)) {
            try {
                var bytes = ByteArray.fromBytes(sys.io.File.getBytes(resolved));
                loadBytes(bytes);
                return;
            } catch (e:Dynamic) {}
        }
        #end

        _urlLoader = new URLLoader();
        _urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
        _urlLoader.addEventListener(Event.COMPLETE, completeEvent);
        _urlLoader.load(request);
    }

    public function loadAsync():Void {
        load();
    }

    public function loadBytes(bytes:ByteArray):Void {
        if (bytes == null || bytes.length < 4) return;
        _bytes = bytes;
        bytesLoaded = bytes.length;
        bytesTotal = bytes.length;
        parse();
    }

    private function completeEvent(e:Event):Void {
        var bytes:ByteArray = cast _urlLoader.data;
        if (bytes != null) loadBytes(bytes);
    }

    private function parse():Void {
        _bytes.endian = Endian.LITTLE_ENDIAN;
        _bytes.position = 0;
        var header = _bytes.readUTFBytes(3);
        var data:ByteArray = _bytes;

        if (header == "C3D") {
            _bytes.position = 13;
            var compressed = new ByteArray();
            _bytes.readBytes(compressed, 0, _bytes.length - 13);
            compressed.uncompress();
            data = compressed;
        } else if (header == "F3D") {
            data = new ByteArray();
            _bytes.position = 13;
            _bytes.readBytes(data, 0, _bytes.length - 13);
        }

        data.endian = Endian.LITTLE_ENDIAN;
        data.position = 0;

        var buffers:Map<Int, Vector<Float>> = new Map();
        var indicesMap:Map<Int, Vector<UInt>> = new Map();
        var texturesMap:Map<Int, Texture3D> = new Map();
        var defaultMat = new Shader3D("f3d_mat", [new ColorFilter(0x888888)]);

        var tagCount = 0;
        while (data.bytesAvailable > 4 && tagCount < 5000) {
            tagCount++;
            var tagLen = data.readUnsignedByte();
            if (tagLen == 0 || tagLen > data.bytesAvailable) break;

            var tagName = data.readUTFBytes(tagLen);
            var chunkSize = data.readUnsignedInt();
            if (chunkSize > data.bytesAvailable) break;

            var chunkEnd = data.position + chunkSize;

            switch (tagName) {
                case "buffer":
                    var bufId = data.readUnsignedShort();
                    var count = data.readUnsignedInt();
                    var floats = new Vector<Float>(count);
                    for (i in 0...count) {
                        floats[i] = data.readFloat();
                    }
                    buffers.set(bufId, floats);

                case "idx":
                    var idxId = data.readUnsignedShort();
                    var count = data.readUnsignedInt();
                    var idxs = new Vector<UInt>(count);
                    for (i in 0...count) {
                        idxs[i] = data.readUnsignedShort();
                    }
                    indicesMap.set(idxId, idxs);

                case "tex":
                    var texId = data.readUnsignedShort();
                    var imgBytes = new ByteArray();
                    var imgLen = chunkSize - 2;
                    if (imgLen > 0) {
                        data.readBytes(imgBytes, 0, imgLen);
                        try {
                            #if (sys && lime)
                            var limeImg = lime.graphics.Image.fromBytes(imgBytes);
                            if (limeImg != null) {
                                var bmp = BitmapData.fromImage(limeImg);
                                var tex = new Texture3D(bmp);
                                texturesMap.set(texId, tex);
                            }
                            #end
                        } catch (e:Dynamic) {}
                    }

                case "obj":
                    var objNameLen = data.readUnsignedByte();
                    var objName = data.readUTFBytes(objNameLen);
                    var objType = data.readUnsignedByte();

                    var rawMat = new Vector<Float>(16);
                    for (i in 0...12) {
                        rawMat[i] = data.readFloat();
                    }
                    rawMat[12] = 0; rawMat[13] = 0; rawMat[14] = 0; rawMat[15] = 1;

                    var mesh = new Mesh3D(objName);
                    mesh.setTransform(new Matrix3D(rawMat));

                    while (data.position < chunkEnd) {
                        if (data.bytesAvailable < 1) break;
                        var subTagLen = data.readUnsignedByte();
                        if (subTagLen == 0 || subTagLen > data.bytesAvailable) break;
                        var subTagName = data.readUTFBytes(subTagLen);
                        var subChunkSize = data.readUnsignedInt();
                        var subEnd = data.position + subChunkSize;

                        if (subTagName == "surf") {
                            var surfBufId = data.readUnsignedShort();
                            var surfIdxId = data.readUnsignedShort();
                            var surfMatId = (data.position < subEnd) ? data.readUnsignedShort() : 0;

                            var buf = buffers.get(surfBufId);
                            var idxs = indicesMap.get(surfIdxId);

                            if (buf != null && idxs != null) {
                                var surf = new Surface3D("surf_" + objName);
                                surf.vertexVector = buf;
                                surf.indexVector = idxs;

                                var mat = defaultMat;
                                if (texturesMap.exists(surfMatId)) {
                                    mat = new Shader3D("mat_" + objName, [new TextureMapFilter(texturesMap.get(surfMatId))]);
                                }
                                surf.material = mat;
                                mesh.addSurface(surf);
                            }
                        }
                        data.position = subEnd;
                    }
                    _parent.addChild(mesh);

                case "camera":
                    var cam = new Camera3D("f3d_camera");
                    activeCamera = cam;
                    _parent.addChild(cam);

                default:
                    // skip unknown
            }
            data.position = chunkEnd;
        }

        loaded = true;
        dispatchEvent(new Event(Event.COMPLETE));
    }

    public function close():Void {
        if (_urlLoader != null) {
            try { _urlLoader.close(); } catch (e:Dynamic) {}
        }
    }

    override public function dispose():Void {
        close();
        _bytes = null;
    }

    public function nextChunk():Void {}
    public function progressEvent(e:ProgressEvent):Void { dispatchEvent(e); }
    public function progressResourcesEvent(e:ProgressEvent):Void {}
    public function completeResourcesEvent(e:Event):Void {}

    public function readAnimation():Void {}
    public function readBounds():Void {}
    public function readBuffer():Void {}
    public function readCamera():Void {}
    public function readData():Void {}
    public function readFLSLByteCode():Void {}
    public function readFilter():Void {}
    public function readFrames():Void {}
    public function readHeader():Void {}
    public function readIndices():Void {}
    public function readLight():Void {}
    public function readMatrix3D():Frame3D return new Frame3D();
    public function readObject():Pivot3D return new Pivot3D();
    public function readShader():Void {}
    public function readSkin():Void {}
    public function readSurface():Void {}
    public function readTexture():Void {}
}
