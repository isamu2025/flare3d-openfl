package flare.loaders;

import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.utils.ByteArray;
import flare.core.Pivot3D;
import flare.core.Camera3D;
import flare.core.Light3D;
import flare.core.Mesh3D;
import flare.core.Shape3D;
import flare.materials.Material3D;
import flare.system.ILibraryExternalItem;
import flare.basic.Scene3D;

/**
 * Flare3DLoader1 loads legacy Version 1 Flare3D (.f3d) binary models.
 */
class Flare3DLoader1 extends Pivot3D implements ILibraryExternalItem {
    public static inline var CURR_VERSION:Int = 1;

    public var magic:String = "F3D";
    public var resourcesPath:String = "";
    public var version:Int = 1;

    private var _activeCamera:Camera3D;
    private var _bytesLoaded:Int = 0;
    private var _bytesTotal:Int = 0;
    private var _loaded:Bool = false;
    private var _parent:Pivot3D;
    private var _request:Dynamic;
    private var _sceneContext:Scene3D;

    public var activeCamera(get, set):Camera3D;
    public var bytesLoaded(get, never):Int;
    public var bytesTotal(get, never):Int;
    public var loaded(get, never):Bool;
    public var request(get, never):Dynamic;

    public function new(request:Dynamic = null, parent:Pivot3D = null, sceneContext:Scene3D = null) {
        super("f3d_v1");
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

    public function loadBytes(bytes:ByteArray):Void {
        _loaded = true;
        dispatchEvent(new Event(Event.COMPLETE));
    }

    public function close():Void {}
    public function dispose():Void { close(); }
    public function extract():Void {}
    public function optimizeSurfaces():Void {}
    public function parse():Void {}
    public function playAll():Void {}
    public function setColors():Void {}

    public function createNormals():Void {}
    public function readAnimation():Void {}
    public function readBoundings():Void {}
    public function readCamera():Camera3D return new Camera3D();
    public function readColors():Void {}
    public function readFaces():Void {}
    public function readHeader():Bool return true;
    public function readLabels():Void {}
    public function readLight():Light3D return new Light3D();
    public function readMaps():Void {}
    public function readMaterial():Material3D return null;
    public function readMaterials():Void {}
    public function readMesh():Mesh3D return new Mesh3D();
    public function readModifiers():Void {}
    public function readNodeMaterials():Void {}
    public function readPivots():Void {}
    public function readRender():Void {}
    public function readResources():Void {}
    public function readShape():Shape3D return new Shape3D();
    public function readSkin():Void {}
    public function readSmoothingGroups():Void {}
    public function readUserData():Void {}
    public function readVertex():Void {}
    public function readVertexAnimation():Void {}

    private function completeEvent(e:Event):Void { dispatchEvent(e); }
    private function progressEvent(e:ProgressEvent):Void { dispatchEvent(e); }
    private function resourceCompleteEvent(e:Event):Void {}
    private function resourceProgressEvent(e:ProgressEvent):Void {}

    private function get_activeCamera():Camera3D return _activeCamera;
    private function set_activeCamera(val:Camera3D):Camera3D return _activeCamera = val;
    private function get_bytesLoaded():Int return _bytesLoaded;
    private function get_bytesTotal():Int return _bytesTotal;
    private function get_loaded():Bool return _loaded;
    private function get_request():Dynamic return _request;
}
