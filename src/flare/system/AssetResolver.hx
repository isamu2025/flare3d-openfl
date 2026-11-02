package flare.system;

class AssetResolver {
    public static function resolve(url:String):String {
        if (url == null || url == "") return url;
        #if sys
        if (sys.FileSystem.exists(url)) return url;

        try {
            var roots:Array<String> = [];
            var cwd = Sys.getCwd();
            if (cwd != null && cwd != "") roots.push(cwd);
            
            var progPath = Sys.programPath();
            if (progPath != null && progPath != "") {
                var progDir = haxe.io.Path.directory(progPath);
                if (progDir != null && progDir != "" && roots.indexOf(progDir) == -1) {
                    roots.push(progDir);
                }
            }

            for (startDir in roots) {
                var dir = startDir;
                for (i in 0...7) {
                    var candidate = haxe.io.Path.join([dir, "assets", url]);
                    if (sys.FileSystem.exists(candidate)) {
                        DebugLog.log("[AssetResolver] Found candidate: " + candidate);
                        return candidate;
                    }
                    var candidateDirect = haxe.io.Path.join([dir, url]);
                    if (sys.FileSystem.exists(candidateDirect)) {
                        DebugLog.log("[AssetResolver] Found candidateDirect: " + candidateDirect);
                        return candidateDirect;
                    }
                    var candidateBin = haxe.io.Path.join([dir, "..", "assets", url]);
                    if (sys.FileSystem.exists(candidateBin)) {
                        DebugLog.log("[AssetResolver] Found candidateBin: " + candidateBin);
                        return candidateBin;
                    }
                    var parent = haxe.io.Path.directory(dir);
                    if (parent == "" || parent == null || parent == dir) break;
                    dir = parent;
                }
            }
            DebugLog.log("[AssetResolver] Not found, fallback to url: " + url);
        } catch (e:Dynamic) {
            DebugLog.log("[AssetResolver] Exception: " + e);
        }
        #end
        return url;
    }
}
