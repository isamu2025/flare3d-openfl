package deng.fzip;

import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.ProgressEvent;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;

/**
 * FZip loads, parses, and extracts files from ZIP archives (used internally by Flare3D ZF3D files).
 */
class FZip extends EventDispatcher {
    private var _files:Array<FZipFile>;
    private var _urlLoader:URLLoader;

    public function new(filenameEncoding:String = "utf-8") {
        super();
        _files = [];
    }

    public function load(request:URLRequest):Void {
        _urlLoader = new URLLoader();
        _urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
        _urlLoader.addEventListener(Event.COMPLETE, onComplete);
        _urlLoader.load(request);
    }

    private function onComplete(e:Event):Void {
        var b:ByteArray = cast _urlLoader.data;
        if (b != null) loadBytes(b);
    }

    public function loadBytes(bytes:ByteArray):Void {
        _files = [];
        try {
            var input = new haxe.io.BytesInput(bytes);
            var entries = haxe.zip.Reader.readZip(input);
            for (entry in entries) {
                var f = new FZipFile();
                f.filename = entry.fileName;
                var uncompressedBytes = haxe.zip.Reader.unzip(entry);
                f.content = ByteArray.fromBytes(uncompressedBytes);
                f.sizeUncompressed = uncompressedBytes.length;
                _files.push(f);
                dispatchEvent(new FZipEvent(FZipEvent.FILE_LOADED, f));
            }
        } catch (e:Dynamic) {}

        dispatchEvent(new Event(Event.COMPLETE));
    }

    public function getFileAt(index:Int):FZipFile {
        return (index >= 0 && index < _files.length) ? _files[index] : null;
    }

    public function getFileByName(name:String):FZipFile {
        for (f in _files) {
            if (f.filename == name) return f;
        }
        return null;
    }

    public function getFileCount():Int {
        return _files.length;
    }

    public function close():Void {
        if (_urlLoader != null) {
            try { _urlLoader.close(); } catch (e:Dynamic) {}
        }
    }
}
