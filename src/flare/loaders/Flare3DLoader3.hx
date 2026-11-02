package flare.loaders;

import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.utils.ByteArray;
import flare.core.Pivot3D;
import flare.core.Camera3D;
import flare.core.Frame3D;
import flare.basic.Scene3D;
import flare.system.ILibraryExternalItem;

/**
 * Flare3DLoader3 loads Version 3 Flare3D binary chunk models.
 */
class Flare3DLoader3 extends Pivot3D implements ILibraryExternalItem {
    public var activeCamera:Camera3D;
    public var asyncCount:Int = 0;
    public var asyncInterval:Int = 0;
    public var compressionLevel:Int = 0;
    public var floatPrecision:Int = 0;
    public var magic:String = "F3D";
    public var resourcesPath:String = "";
    public var version:Int = 3;

    private var _bytesLoaded:Int = 0;
    private var _bytesTotal:Int = 0;
    private var _loaded:Bool = false;
    private var _parent:Pivot3D;
    private var _request:Dynamic;
    private var _sceneContext:Scene3D;

    public var bytesLoaded(get, never):Int;
    public var bytesTotal(get, never):Int;
    public var loaded(get, never):Bool;
    public var request(get, never):Dynamic;

    public function new(request:Dynamic = null, parent:Pivot3D = null, sceneContext:Scene3D = null) {
        super("f3d_v3");
        this._request = request;
        this._parent = parent != null ? parent : this;
        this._sceneContext = sceneContext;
        if (request != null) {
            load();
        }
    }

    public function load():Void {
        _loaded = true;
        dispatchEvent(new Event(Event.COMPLETE));
    }

    public function loadAsync():Void { load(); }
    public function loadBytes(bytes:ByteArray):Void {
        _loaded = true;
        dispatchEvent(new Event(Event.COMPLETE));
    }

    public function close():Void {}
    public function dispose():Void { close(); }
    public function nextChunk():Void {}

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

    private function completeEvent(e:Event):Void { dispatchEvent(e); }
    private function completeResourcesEvent(e:Event):Void {}
    private function progressEvent(e:ProgressEvent):Void { dispatchEvent(e); }
    private function progressResourcesEvent(e:ProgressEvent):Void {}

    private function get_bytesLoaded():Int return _bytesLoaded;
    private function get_bytesTotal():Int return _bytesTotal;
    private function get_loaded():Bool return _loaded;
    private function get_request():Dynamic return _request;
}
