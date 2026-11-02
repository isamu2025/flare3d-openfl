package deng.fzip;

import openfl.utils.ByteArray;

/**
 * FZipFile represents an uncompressed or compressed file entry within a ZIP archive.
 */
class FZipFile {
    public var filename:String;
    public var content:ByteArray;
    public var sizeUncompressed:Int = 0;
    public var sizeCompressed:Int = 0;
    public var versionNumber:Int = 20;

    public function new(encoding:String = "utf-8") {
        content = new ByteArray();
    }

    public function getContentAsString(recompress:Bool = true, encoding:String = "utf-8"):String {
        if (content == null) return "";
        content.position = 0;
        return content.readUTFBytes(content.length);
    }
}
