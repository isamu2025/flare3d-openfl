package flare.core;

/**
 * Easing3D provides standard animation easing functions.
 */
class Easing3D {
    public static function easeNone(t:Float, d:Float):Float {
        return t / d;
    }

    public static function easeInQuad(t:Float, d:Float):Float {
        t /= d;
        return t * t;
    }

    public static function easeOutQuad(t:Float, d:Float):Float {
        t /= d;
        return -t * (t - 2);
    }

    public static function easeInOutQuad(t:Float, d:Float):Float {
        t /= d / 2;
        if (t < 1) return 0.5 * t * t;
        t--;
        return -0.5 * (t * (t - 2) - 1);
    }

    public static function easeInCubic(t:Float, d:Float):Float {
        t /= d;
        return t * t * t;
    }

    public static function easeOutCubic(t:Float, d:Float):Float {
        t = t / d - 1;
        return t * t * t + 1;
    }

    public static function easeInOutCubic(t:Float, d:Float):Float {
        t /= d / 2;
        if (t < 1) return 0.5 * t * t * t;
        t -= 2;
        return 0.5 * (t * t * t + 2);
    }

    public static function easeInQuart(t:Float, d:Float):Float {
        t /= d;
        return t * t * t * t;
    }

    public static function easeOutQuart(t:Float, d:Float):Float {
        t = t / d - 1;
        return -(t * t * t * t - 1);
    }

    public static function easeInOutQuart(t:Float, d:Float):Float {
        t /= d / 2;
        if (t < 1) return 0.5 * t * t * t * t;
        t -= 2;
        return -0.5 * (t * t * t * t - 2);
    }

    public static function easeInQuint(t:Float, d:Float):Float {
        t /= d;
        return t * t * t * t * t;
    }

    public static function easeOutQuint(t:Float, d:Float):Float {
        t = t / d - 1;
        return t * t * t * t * t + 1;
    }

    public static function easeInOutQuint(t:Float, d:Float):Float {
        t /= d / 2;
        if (t < 1) return 0.5 * t * t * t * t * t;
        t -= 2;
        return 0.5 * (t * t * t * t * t + 2);
    }

    public static function easeInSine(t:Float, d:Float):Float {
        return -Math.cos(t / d * (Math.PI / 2)) + 1;
    }

    public static function easeOutSine(t:Float, d:Float):Float {
        return Math.sin(t / d * (Math.PI / 2));
    }

    public static function easeInOutSine(t:Float, d:Float):Float {
        return -0.5 * (Math.cos(Math.PI * t / d) - 1);
    }

    public static function easeInExpo(t:Float, d:Float):Float {
        return (t == 0) ? 0 : Math.pow(2, 10 * (t / d - 1));
    }

    public static function easeOutExpo(t:Float, d:Float):Float {
        return (t == d) ? 1 : (-Math.pow(2, -10 * t / d) + 1);
    }

    public static function easeInOutExpo(t:Float, d:Float):Float {
        if (t == 0) return 0;
        if (t == d) return 1;
        t /= d / 2;
        if (t < 1) return 0.5 * Math.pow(2, 10 * (t - 1));
        return 0.5 * (-Math.pow(2, -10 * --t) + 2);
    }

    public static function easeInCirc(t:Float, d:Float):Float {
        t /= d;
        return -(Math.sqrt(1 - t * t) - 1);
    }

    public static function easeOutCirc(t:Float, d:Float):Float {
        t = t / d - 1;
        return Math.sqrt(1 - t * t);
    }

    public static function easeInOutCirc(t:Float, d:Float):Float {
        t /= d / 2;
        if (t < 1) return -0.5 * (Math.sqrt(1 - t * t) - 1);
        t -= 2;
        return 0.5 * (Math.sqrt(1 - t * t) + 1);
    }

    public static function easeInElastic(t:Float, d:Float):Float {
        if (t == 0) return 0;
        t /= d;
        if (t == 1) return 1;
        var p = d * 0.3;
        var s = p / 4;
        t -= 1;
        return -(Math.pow(2, 10 * t) * Math.sin((t * d - s) * (2 * Math.PI) / p));
    }

    public static function easeOutElastic(t:Float, d:Float):Float {
        if (t == 0) return 0;
        t /= d;
        if (t == 1) return 1;
        var p = d * 0.3;
        var s = p / 4;
        return Math.pow(2, -10 * t) * Math.sin((t * d - s) * (2 * Math.PI) / p) + 1;
    }

    public static function easeInOutElastic(t:Float, d:Float):Float {
        if (t == 0) return 0;
        t /= d / 2;
        if (t == 2) return 1;
        var p = d * (0.3 * 1.5);
        var s = p / 4;
        if (t < 1) {
            t -= 1;
            return -0.5 * (Math.pow(2, 10 * t) * Math.sin((t * d - s) * (2 * Math.PI) / p));
        }
        t -= 1;
        return Math.pow(2, -10 * t) * Math.sin((t * d - s) * (2 * Math.PI) / p) * 0.5 + 1;
    }

    public static function easeOutBounce(t:Float, d:Float):Float {
        t /= d;
        if (t < (1 / 2.75)) {
            return 7.5625 * t * t;
        } else if (t < (2 / 2.75)) {
            t -= (1.5 / 2.75);
            return 7.5625 * t * t + 0.75;
        } else if (t < (2.5 / 2.75)) {
            t -= (2.25 / 2.75);
            return 7.5625 * t * t + 0.9375;
        } else {
            t -= (2.625 / 2.75);
            return 7.5625 * t * t + 0.984375;
        }
    }

    public static function easeInBounce(t:Float, d:Float):Float {
        return 1.0 - easeOutBounce(d - t, d);
    }

    public static function easeInOutBounce(t:Float, d:Float):Float {
        if (t < d * 0.5) return easeInBounce(t * 2, d) * 0.5;
        return easeOutBounce(t * 2 - d, d) * 0.5 + 0.5;
    }
}
