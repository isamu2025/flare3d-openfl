package flare.loaders;

import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.ProgressEvent;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;
import flare.system.ILibraryExternalItem;

/**
 * ByteArrayLoader loads raw binary assets from network or local storage.
 */
class ByteArrayLoader extends EventDispatcher implements ILibraryExternalItem {
    private var _bytesLoaded:Int = 0;
    private var _bytesTotal:Int = 0;
    private var _loaded:Bool = false;
    private var _loader:URLLoader;
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
        if (_request == null) return;
        var urlStr:String = Std.isOfType(_request, URLRequest) ? cast(_request, URLRequest).url : Std.string(_request);

        #if sys
        var resolved = flare.system.AssetResolver.resolve(urlStr);
        if (sys.FileSystem.exists(resolved)) {
            var b = ByteArray.fromBytes(sys.io.File.getBytes(resolved));
            _data = b;
            _bytesLoaded = b.length;
            _bytesTotal = b.length;
            _loaded = true;
            dispatchEvent(new Event(Event.COMPLETE));
            return;
        }
        #end

        _loader = new URLLoader();
        _loader.dataFormat = URLLoaderDataFormat.BINARY;
        _loader.addEventListener(Event.COMPLETE, completeEvent);
        _loader.addEventListener(ProgressEvent.PROGRESS, progressEvent);
        _loader.load(Std.isOfType(_request, URLRequest) ? cast(_request, URLRequest) : new URLRequest(urlStr));
    }

    private function completeEvent(e:Event):Void {
        _data = _loader.data;
        _loaded = true;
        dispatchEvent(new Event(Event.COMPLETE));
    }

    private function progressEvent(e:ProgressEvent):Void {
        _bytesLoaded = Math.round(e.bytesLoaded);
        _bytesTotal = Math.round(e.bytesTotal);
        dispatchEvent(e);
    }

    public function close():Void {
        if (_loader != null) {
            try { _loader.close(); } catch (e:Dynamic) {}
        }
    }

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
