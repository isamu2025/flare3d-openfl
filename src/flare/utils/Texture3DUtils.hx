package flare.utils;

import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;

/**
 * Utility functions for Texture3D (CubeMap extraction, NormalMap conversion).
 */
class Texture3DUtils {
    public static function extractCubeMap(bitmapData:BitmapData):Array<BitmapData> {
        var faces = new Array<BitmapData>();
        if (bitmapData == null) return faces;

        // Standard 4:3 horizontal cross cubemap extraction matching Flare3D AS3:
        // Size of each cubic tile
        var faceW = Std.int(bitmapData.width / 4);
        var faceH = Std.int(bitmapData.height / 3);
        var size = faceW < faceH ? faceW : faceH;

        // 6 faces corresponding to Stage3D / Flare3D sides:
        // Side 0: +X (Right)  -> col 2, row 1
        // Side 1: -X (Left)   -> col 0, row 1
        // Side 2: +Y (Top)    -> col 1, row 0
        // Side 3: -Y (Bottom) -> col 1, row 2
        // Side 4: +Z (Front)  -> col 1, row 1
        // Side 5: -Z (Back)   -> col 3, row 1
        var faceCoords = [
            { col: 2, row: 1 },
            { col: 0, row: 1 },
            { col: 1, row: 0 },
            { col: 1, row: 2 },
            { col: 1, row: 1 },
            { col: 3, row: 1 }
        ];

        for (i in 0...6) {
            var faceBmp = new BitmapData(size, size, bitmapData.transparent, 0);
            var col = faceCoords[i].col;
            var row = faceCoords[i].row;
            faceBmp.copyPixels(bitmapData, new Rectangle(col * size, row * size, size, size), new Point(0, 0));
            faces.push(faceBmp);
        }
        return faces;
    }

    public static function toNormalMap(bitmapData:BitmapData, x:Float = 1.0, y:Float = 1.0):BitmapData {
        if (bitmapData == null) return null;
        var w = bitmapData.width;
        var h = bitmapData.height;
        var normBmp = new BitmapData(w, h, false, 0);

        for (py in 0...h) {
            for (px in 0...w) {
                var pL = (bitmapData.getPixel(px > 0 ? px - 1 : 0, py) & 0xff) / 255.0;
                var pR = (bitmapData.getPixel(px < w - 1 ? px + 1 : w - 1, py) & 0xff) / 255.0;
                var pT = (bitmapData.getPixel(px, py > 0 ? py - 1 : 0) & 0xff) / 255.0;
                var pB = (bitmapData.getPixel(px, py < h - 1 ? py + 1 : h - 1) & 0xff) / 255.0;

                var dx = (pL - pR) * x;
                var dy = (pT - pB) * y;
                var dz = 1.0;

                var len = Math.sqrt(dx * dx + dy * dy + dz * dz);
                dx /= len; dy /= len; dz /= len;

                var r = Math.round((dx * 0.5 + 0.5) * 255);
                var g = Math.round((dy * 0.5 + 0.5) * 255);
                var b = Math.round((dz * 0.5 + 0.5) * 255);

                normBmp.setPixel(px, py, (r << 16) | (g << 8) | b);
            }
        }
        return normBmp;
    }
}
