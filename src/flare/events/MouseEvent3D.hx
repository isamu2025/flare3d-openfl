package flare.events;

import openfl.events.Event;
import flare.collisions.CollisionInfo;

/**
 * MouseEvent3D represents 3D mouse interaction events dispatched on Pivot3D objects.
 */
class MouseEvent3D extends Event {
    public static inline var CLICK:String = "click";
    public static inline var MOUSE_DOWN:String = "mouseDown";
    public static inline var MOUSE_MOVE:String = "mouseMove";
    public static inline var MOUSE_OUT:String = "mouseOut";
    public static inline var MOUSE_OVER:String = "mouseOver";
    public static inline var MOUSE_UP:String = "mouseUp";
    public static inline var MOUSE_WHEEL:String = "mouseWheel";

    public var info:CollisionInfo;

    public function new(type:String, info:CollisionInfo = null, bubbles:Bool = false, cancelable:Bool = false) {
        super(type, bubbles, cancelable);
        this.info = info;
    }

    override public function clone():Event {
        return new MouseEvent3D(type, info, bubbles, cancelable);
    }
}
