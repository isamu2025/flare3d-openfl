package deng.fzip;

import openfl.events.ErrorEvent;
import openfl.events.Event;

/**
 * Event dispatched when zip archive decoding encounters corrupted data or CRC mismatches.
 */
class FZipErrorEvent extends ErrorEvent {
    public static inline var PARSE_ERROR:String = "parseError";

    public function new(type:String, text:String = "", id:Int = 0, bubbles:Bool = false, cancelable:Bool = false) {
        super(type, bubbles, cancelable, text, id);
    }

    override public function clone():Event {
        return new FZipErrorEvent(type, text, id, bubbles, cancelable);
    }
}
