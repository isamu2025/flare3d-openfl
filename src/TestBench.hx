class TestBench {
    static function main() {
        var vcount = 6600;
        var pos = new openfl.Vector<Float>(vcount * 3);
        var norm = new openfl.Vector<Float>(vcount * 3);
        var weights = new openfl.Vector<Float>(vcount * 2);
        var indices = new openfl.Vector<Int>(vcount * 2);
        var vdata = new openfl.Vector<Float>(vcount * 8);

        for (i in 0...vcount) {
            weights[i*2] = 0.5; weights[i*2+1] = 0.5;
            indices[i*2] = 0; indices[i*2+1] = 1;
        }

        var m0 = new openfl.Vector<Float>(16);
        for (i in 0...16) m0[i] = (i % 5 == 0) ? 1.0 : 0.0;
        var rawBones = [m0, m0];

        var t0 = openfl.Lib.getTimer();
        var iters = 60;
        for (iter in 0...iters) {
            for (i in 0...vcount) {
                var pIdx = i * 3;
                var px = pos[pIdx];
                var py = pos[pIdx + 1];
                var pz = pos[pIdx + 2];

                var nx = norm[pIdx];
                var ny = norm[pIdx + 1];
                var nz = norm[pIdx + 2];

                var wIdx = i * 2;
                var w0 = weights[wIdx];
                var w1 = weights[wIdx + 1];

                var b0 = indices[wIdx];
                var b1 = indices[wIdx + 1];

                var mb0 = rawBones[b0];
                var mb1 = rawBones[b1];

                var sx = (px * mb0[0] + py * mb0[4] + pz * mb0[8] + mb0[12]) * w0 + (px * mb1[0] + py * mb1[4] + pz * mb1[8] + mb1[12]) * w1;
                var sy = (px * mb0[1] + py * mb0[5] + pz * mb0[9] + mb0[13]) * w0 + (px * mb1[1] + py * mb1[5] + pz * mb1[9] + mb1[13]) * w1;
                var sz = (px * mb0[2] + py * mb0[6] + pz * mb0[10] + mb0[14]) * w0 + (px * mb1[2] + py * mb1[6] + pz * mb1[10] + mb1[14]) * w1;

                var snx = (nx * mb0[0] + ny * mb0[4] + nz * mb0[8]) * w0 + (nx * mb1[0] + ny * mb1[4] + nz * mb1[8]) * w1;
                var sny = (nx * mb0[1] + ny * mb0[5] + nz * mb0[9]) * w0 + (nx * mb1[1] + ny * mb1[5] + nz * mb1[9]) * w1;
                var snz = (nx * mb0[2] + ny * mb0[6] + nz * mb0[10]) * w0 + (nx * mb1[2] + ny * mb1[6] + nz * mb1[10]) * w1;

                var dst = i * 8;
                vdata[dst + 0] = sx;
                vdata[dst + 1] = sy;
                vdata[dst + 2] = sz;
                vdata[dst + 5] = snx;
                vdata[dst + 6] = sny;
                vdata[dst + 7] = snz;
            }
        }
        var elapsed = openfl.Lib.getTimer() - t0;
        Sys.println("Elapsed for " + iters + " frames: " + elapsed + " ms (" + (elapsed / iters) + " ms/frame)");
    }
}
