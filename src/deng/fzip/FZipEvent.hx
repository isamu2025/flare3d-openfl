package deng.fzip;

import openfl.events.Event;

/**
 * Event dispatched by FZip during decompression and entry extraction.
 */
class FZipEvent extends Event {
    public static inline var FILE_LOADED:String = "fileLoaded";

    public var file:FZipFile;

    public function new(type:String, file:FZipFile = null, bubbles:Bool = false, cancelable:Bool = false) {
        super(type, bubbles, cancelable);
        this.file = file;
    }

    override public function clone():Event {
        return new FZipEvent(type, file, bubbles, cancelable);
    }
}
