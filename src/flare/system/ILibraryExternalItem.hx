package flare.system;

import openfl.net.URLRequest;

/**
 * Interface for external assets loaded through Library3D.
 */
interface ILibraryExternalItem extends ILibraryItem {
    var bytesLoaded:Float;
    var bytesTotal:Float;
    var loaded:Bool;
    var request:URLRequest;

    function load():Void;
    function close():Void;
}
