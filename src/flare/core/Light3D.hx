package flare.core;

import openfl.display.BitmapData;
import openfl.geom.Vector3D;

/**
 * Light3D represents directional and point lights with color, attenuation, and radius.
 */
class Light3D extends Pivot3D {
    public static inline var DIRECTIONAL:Int = 0;
    public static inline var POINT:Int = 1;

    public var type:Int;
    public var color:Vector3D;
    public var multiplier:Float = 1.0;
    public var radius:Float = 0.0;
    public var attenuation:Float = 100.0;
    public var infinite:Bool = true;
    public var sample:BitmapData;

    public var inView(get, never):Bool;

    public function new(name:String = "light", type:Int = DIRECTIONAL, c:Dynamic = null, mult:Float = 1.0) {
        super(name);
        this.type = type;
        this.multiplier = mult;
        this.color = new Vector3D(1.0, 1.0, 1.0, 1.0);
        if (c != null) {
            setColor(c);
        }
        if (type == POINT) {
            infinite = false;
            radius = 2000.0;
        }
    }

    public function setParams(c:Int = 0xffffff, radius:Float = 0, attenuation:Float = 1, multiplier:Float = 1, infinite:Bool = false):Void {
        setColor(c);
        this.radius = radius;
        this.attenuation = attenuation;
        this.multiplier = multiplier;
        this.infinite = infinite;
        if (radius > 0) {
            this.type = POINT;
        }
    }

    public function setColor(c:Int):Void {
        color.x = ((c >> 16) & 0xff) / 255.0;
        color.y = ((c >> 8) & 0xff) / 255.0;
        color.z = (c & 0xff) / 255.0;
        color.w = 1.0;
    }

    override public function setScene(sc:flare.basic.Scene3D):Void {
        if (this.scene != null && this.scene.lights != null) {
            this.scene.lights.list.remove(this);
        }
        super.setScene(sc);
        if (sc != null && sc.lights != null) {
            if (sc.lights.list.indexOf(this) == -1) {
                sc.lights.list.push(this);
            }
        }
    }

    override public function clone():Pivot3D {
        var l = new Light3D(name, type);
        l.color = color.clone();
        l.multiplier = multiplier;
        l.radius = radius;
        l.attenuation = attenuation;
        l.infinite = infinite;
        return l;
    }

    override public function dispose():Void {
        super.dispose();
        sample = null;
    }

    private function get_inView():Bool return true;
}
