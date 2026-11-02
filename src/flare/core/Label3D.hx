package flare.core;

/**
 * Label3D marks named keyframe ranges within an animation timeline.
 */
class Label3D {
    public var name:String;
    public var from:Float;
    public var to:Float;

    public function new(name:String, from:Float, to:Float) {
        this.name = name;
        this.from = from;
        this.to = to;
    }

    public function toString():String {
        return '[Label3D name: "$name", from: $from, to: $to]';
    }
}

/**
 * Labels abstract wrapper that supports both array index and string key access.
 * Allows `pivot.labels["anim1"]` and `pivot.labels[0]`.
 */
@:forward(length, push, iterator, indexOf, remove, copy)
abstract Labels(Array<Label3D>) from Array<Label3D> to Array<Label3D> {
    public inline function new(a:Array<Label3D> = null) {
        this = a != null ? a : [];
    }

    @:arrayAccess
    public function getByString(name:String):Label3D {
        if (this == null) return null;
        for (l in this) {
            if (l != null && l.name == name) return l;
        }
        return null;
    }

    @:arrayAccess
    public inline function getByIndex(index:Int):Label3D {
        if (this == null) return null;
        return this[index];
    }

    @:arrayAccess
    public inline function setByIndex(index:Int, value:Label3D):Label3D {
        if (this != null) this[index] = value;
        return value;
    }

    public inline function get(name:String):Label3D {
        return getByString(name);
    }
}
