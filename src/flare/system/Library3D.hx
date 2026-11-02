package flare.system;

import flare.core.Texture3D;
import flare.materials.Material3D;
import flare.core.Pivot3D;
import openfl.events.Event;
import openfl.events.ProgressEvent;

/**
 * Library3D caches reusable textures, materials, and 3D assets.
 */
class Library3D extends openfl.events.EventDispatcher {
    private static var _textures:Map<String, Texture3D> = new Map();
    private static var _materials:Map<String, Material3D> = new Map();

    private var _itemsByName:Map<String, Dynamic> = new Map();
    public var items:Array<Dynamic> = [];
    public var scene:Dynamic;
    public var progress:Float = 0;
    public var maxConnections:Int = 10;
    public var autoLoad:Bool = false;

    private var _completedCount:Int = 0;
    private var _totalItemsToLoad:Int = 0;
    private var _completedList:Array<Dynamic> = [];

    public function new(maxConnections:Int = 10, autoLoad:Bool = false) {
        super();
        this.maxConnections = maxConnections;
        this.autoLoad = autoLoad;
    }

    public function push(item:Dynamic):Void {
        if (items.indexOf(item) == -1) {
            items.push(item);
        }
        if (autoLoad) {
            load();
        }
    }

    public function addItem(name:String, item:Dynamic):Void {
        _itemsByName.set(name, item);
        if (Std.isOfType(item, Texture3D)) {
            addTexture(name, cast item);
        } else if (Std.isOfType(item, Material3D)) {
            addMaterial(name, cast item);
        }
        if (items.indexOf(item) == -1) {
            items.push(item);
        }
    }

    public function getItem(name:String):Dynamic {
        if (_itemsByName.exists(name)) {
            return _itemsByName.get(name);
        }
        var t = getTexture(name);
        if (t != null) return t;
        return getMaterial(name);
    }

    public function load():Void {
        var externalItems:Array<ILibraryExternalItem> = [];
        for (it in items) {
            if (Std.isOfType(it, ILibraryExternalItem)) {
                externalItems.push(cast it);
            }
        }

        _totalItemsToLoad = externalItems.length;
        _completedCount = 0;
        _completedList = [];

        if (_totalItemsToLoad == 0) {
            progress = 1.0;
            dispatchEvent(new Event(Event.COMPLETE));
            return;
        }

        for (ext in externalItems) {
            if (ext.loaded) {
                _onItemComplete(ext);
            } else {
                if (Std.isOfType(ext, openfl.events.IEventDispatcher)) {
                    var d:openfl.events.IEventDispatcher = cast ext;
                    d.addEventListener(Event.COMPLETE, function(e:Event) {
                        _onItemComplete(ext);
                    });
                }
                ext.load();
                if (ext.loaded) {
                    _onItemComplete(ext);
                }
            }
        }
    }

    private function _onItemComplete(item:Dynamic):Void {
        if (_completedList.indexOf(item) != -1) return;
        _completedList.push(item);
        _completedCount++;
        if (_totalItemsToLoad > 0) {
            progress = _completedCount / _totalItemsToLoad;
        } else {
            progress = 1.0;
        }
        dispatchEvent(new Event("progress"));

        if (_completedCount >= _totalItemsToLoad) {
            progress = 1.0;
            dispatchEvent(new Event(Event.COMPLETE));
        }
    }

    public static function addTexture(name:String, tex:Texture3D):Void {
        _textures.set(name, tex);
    }

    public static function getTexture(name:String):Texture3D {
        return _textures.get(name);
    }

    public static function addMaterial(name:String, mat:Material3D):Void {
        _materials.set(name, mat);
    }

    public static function getMaterial(name:String):Material3D {
        return _materials.get(name);
    }

    public static function clear():Void {
        for (t in _textures) {
            t.dispose();
        }
        _textures = new Map();

        for (m in _materials) {
            m.dispose();
        }
        _materials = new Map();
    }
}
