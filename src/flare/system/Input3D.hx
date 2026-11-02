package flare.system;

import openfl.display.Stage;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;

/**
 * Input3D provides keyboard and mouse state tracking for 3D interactions.
 * Matches original Flare3D Input3D API.
 */
class Input3D {
    // Key Constants
    public static inline var A:Int = 65;
    public static inline var B:Int = 66;
    public static inline var C:Int = 67;
    public static inline var D:Int = 68;
    public static inline var E:Int = 69;
    public static inline var F:Int = 70;
    public static inline var G:Int = 71;
    public static inline var H:Int = 72;
    public static inline var I:Int = 73;
    public static inline var J:Int = 74;
    public static inline var K:Int = 75;
    public static inline var L:Int = 76;
    public static inline var M:Int = 77;
    public static inline var N:Int = 78;
    public static inline var O:Int = 79;
    public static inline var P:Int = 80;
    public static inline var Q:Int = 81;
    public static inline var R:Int = 82;
    public static inline var S:Int = 83;
    public static inline var T:Int = 84;
    public static inline var U:Int = 85;
    public static inline var V:Int = 86;
    public static inline var W:Int = 87;
    public static inline var X:Int = 88;
    public static inline var Y:Int = 89;
    public static inline var Z:Int = 90;

    public static inline var UP:Int = 38;
    public static inline var DOWN:Int = 40;
    public static inline var LEFT:Int = 37;
    public static inline var RIGHT:Int = 39;

    public static inline var SPACE:Int = 32;
    public static inline var ENTER:Int = 13;
    public static inline var ESCAPE:Int = 27;
    public static inline var TAB:Int = 9;
    public static inline var SHIFT:Int = 16;
    public static inline var CONTROL:Int = 17;
    public static inline var ALTERNATE:Int = 18;
    public static inline var BACKSPACE:Int = 8;
    public static inline var DELETE:Int = 46;
    public static inline var INSERT:Int = 45;
    public static inline var HOME:Int = 36;
    public static inline var END:Int = 35;
    public static inline var PAGE_UP:Int = 33;
    public static inline var PAGE_DOWN:Int = 34;

    public static inline var NUMBER_0:Int = 48;
    public static inline var NUMBER_1:Int = 49;
    public static inline var NUMBER_2:Int = 50;
    public static inline var NUMBER_3:Int = 51;
    public static inline var NUMBER_4:Int = 52;
    public static inline var NUMBER_5:Int = 53;
    public static inline var NUMBER_6:Int = 54;
    public static inline var NUMBER_7:Int = 55;
    public static inline var NUMBER_8:Int = 56;
    public static inline var NUMBER_9:Int = 57;

    public static inline var NUMPAD_0:Int = 96;
    public static inline var NUMPAD_1:Int = 97;
    public static inline var NUMPAD_2:Int = 98;
    public static inline var NUMPAD_3:Int = 99;
    public static inline var NUMPAD_4:Int = 100;
    public static inline var NUMPAD_5:Int = 101;
    public static inline var NUMPAD_6:Int = 102;
    public static inline var NUMPAD_7:Int = 103;
    public static inline var NUMPAD_8:Int = 104;
    public static inline var NUMPAD_9:Int = 105;
    public static inline var NUMPAD_MULTIPLY:Int = 106;
    public static inline var NUMPAD_ADD:Int = 107;
    public static inline var NUMPAD_ENTER:Int = 108;
    public static inline var NUMPAD_SUBTRACT:Int = 109;
    public static inline var NUMPAD_DECIMAL:Int = 110;
    public static inline var NUMPAD_DIVIDE:Int = 111;

    // Mouse and Keyboard State
    public static var stage:Stage;
    public static var mouseX:Float = 0;
    public static var mouseY:Float = 0;
    public static var mouseXSpeed:Float = 0;
    public static var mouseYSpeed:Float = 0;
    public static var mouseDown:Bool = false;
    public static var mouseHit:Bool = false;
    public static var mouseUp:Bool = false;
    public static var mouseMoved(get, never):Bool;
    private static inline function get_mouseMoved():Bool return (mouseXSpeed != 0 || mouseYSpeed != 0);
    public static var delta:Int = 0;
    public static var keyCode:Int = 0;

    private static var _downs:Map<Int, Bool> = new Map();
    private static var _hits:Map<Int, Bool> = new Map();
    private static var _ups:Map<Int, Bool> = new Map();
    private static var _initialized:Bool = false;

    public static function initialize(st:Stage):Void {
        init(st);
    }

    public static function init(st:Stage):Void {
        if (_initialized || st == null) return;
        stage = st;
        _initialized = true;

        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
        stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
    }

    private static function onKeyDown(e:KeyboardEvent):Void {
        var code = e.keyCode;
        if (code == 0 && e.charCode > 0) {
            code = e.charCode;
            // Only if keyCode was 0, convert ASCII lowercase 'a'..'z' to uppercase keyCode 'A'..'Z'
            if (code >= 97 && code <= 122) code -= 32;
        }

        keyCode = code;
        if (!_downs.exists(code) || !_downs.get(code)) _hits.set(code, true);
        _downs.set(code, true);

        // Also map standard main-keyboard keys (+/= and -/_) to NUMPAD_ADD and NUMPAD_SUBTRACT
        if (code == 187 || code == 61) {
            if (!_downs.exists(NUMPAD_ADD) || !_downs.get(NUMPAD_ADD)) _hits.set(NUMPAD_ADD, true);
            _downs.set(NUMPAD_ADD, true);
        } else if (code == 189 || code == 173) {
            if (!_downs.exists(NUMPAD_SUBTRACT) || !_downs.get(NUMPAD_SUBTRACT)) _hits.set(NUMPAD_SUBTRACT, true);
            _downs.set(NUMPAD_SUBTRACT, true);
        }
    }

    private static function onKeyUp(e:KeyboardEvent):Void {
        var code = e.keyCode;
        if (code == 0 && e.charCode > 0) {
            code = e.charCode;
            if (code >= 97 && code <= 122) code -= 32;
        }

        _downs.set(code, false);
        _hits.set(code, false);
        _ups.set(code, true);

        if (code == 187 || code == 61) {
            _downs.set(NUMPAD_ADD, false);
            _hits.set(NUMPAD_ADD, false);
            _ups.set(NUMPAD_ADD, true);
        } else if (code == 189 || code == 173) {
            _downs.set(NUMPAD_SUBTRACT, false);
            _hits.set(NUMPAD_SUBTRACT, false);
            _ups.set(NUMPAD_SUBTRACT, true);
        }
    }

    private static function onMouseDown(e:MouseEvent):Void {
        if (!mouseDown) mouseHit = true;
        mouseDown = true;
    }

    private static function onMouseUp(e:MouseEvent):Void {
        mouseDown = false;
        mouseUp = true;
    }

    private static function onMouseMove(e:MouseEvent):Void {
        mouseXSpeed = e.stageX - mouseX;
        mouseYSpeed = e.stageY - mouseY;
        mouseX = e.stageX;
        mouseY = e.stageY;
    }

    private static function onMouseWheel(e:MouseEvent):Void {
        delta = e.delta;
    }

    public static inline function keyDown(key:Int):Bool {
        return _downs.exists(key) && _downs.get(key);
    }

    public static function keyHit(key:Int):Bool {
        if (_hits.exists(key) && _hits.get(key)) {
            _hits.set(key, false); // Consumed hit
            return true;
        }
        return false;
    }

    public static inline function keyUp(key:Int):Bool {
        return _ups.exists(key) && _ups.get(key);
    }

    public static inline function isKeyDown(key:Int):Bool {
        return keyDown(key);
    }

    public static inline function isMouseDown():Bool {
        return mouseDown;
    }

    public static function update():Void {
        mouseHit = false;
        mouseUp = false;
        delta = 0;
        mouseXSpeed = 0;
        mouseYSpeed = 0;
        for (k in _ups.keys()) _ups.remove(k);
    }

    public static function reset():Void {
        _downs = new Map();
        _hits = new Map();
        _ups = new Map();
        mouseDown = false;
        mouseHit = false;
        mouseUp = false;
        delta = 0;
    }
}
