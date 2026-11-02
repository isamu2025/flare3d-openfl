package flare.loaders;

import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.ProgressEvent;
import openfl.net.URLRequest;
import flare.system.ILibraryExternalItem;

/**
 * SWFLoader provides asset loading compatibility for legacy SWF containers.
 */
class SWFLoader extends EventDispatcher implements ILibraryExternalItem {
    private var _bytesLoaded:Int = 0;
    private var _bytesTotal:Int = 0;
    private var _loaded:Bool = false;
    private var _request:Dynamic;
    private var _data:Dynamic;

    public var bytesLoaded(get, never):Int;
    public var bytesTotal(get, never):Int;
    public var data(get, never):Dynamic;
    public var loaded(get, never):Bool;
    public var request(get, never):Dynamic;

    public function new(request:Dynamic = null) {
        super();
        this._request = request;
        if (request != null) {
            load();
        }
    }

    public function load():Void {
        _loaded = true;
        dispatchEvent(new Event(Event.COMPLETE));
    }

    public function close():Void {}

    public function dispose():Void {
        close();
        _data = null;
    }

    private function get_bytesLoaded():Int return _bytesLoaded;
    private function get_bytesTotal():Int return _bytesTotal;
    private function get_data():Dynamic return _data;
    private function get_loaded():Bool return _loaded;
    private function get_request():Dynamic return _request;
}
