package flare.modifiers;

import openfl.geom.Matrix3D;
import openfl.Vector;
import flare.core.Mesh3D;
import flare.core.Pivot3D;
import flare.core.Surface3D;
import flare.system.Device3D;

/**
 * SurfaceSkinData holds CPU and GPU skeletal vertex buffers for a single surface of a skinned mesh.
 */
class SurfaceSkinData {
    public var surface:Surface3D;
    public var origPositions:Vector<Float>;
    public var origNormals:Vector<Float>;
    public var weights:Vector<Float>;
    public var boneIndices:Vector<Int>;
    public var numVertices:Int = 0;
    public var cachedFrames:Map<Int, Vector<Float>> = new Map<Int, Vector<Float>>();
    public var cachedGpuBuffers:Map<Int, openfl.display3D.VertexBuffer3D> = new Map<Int, openfl.display3D.VertexBuffer3D>();

    public function new(surf:Surface3D) {
        this.surface = surf;
    }
}

/**
 * SkinModifier implements matrix palette skeletal mesh deformation for bone-based character animation.
 * Features pre-baked GPU VertexBuffer cache for ultra-fast multi-instance clone and multi-surface character rendering.
 */
class SkinModifier extends Modifier {
    public var bindTransform:Matrix3D;
    public var bones:Array<Pivot3D>;
    public var invBoneMatrix:Array<Matrix3D>;
    public var boneMatrices:Array<Matrix3D>;
    public var mesh:Mesh3D;
    public var root:Pivot3D;
    public var skinData:Array<Array<Int>>;

    // Legacy single surface properties (backward-compatible)
    public var origPositions:Vector<Float>;
    public var origNormals:Vector<Float>;
    public var weights:Vector<Float>;
    public var boneIndices:Vector<Int>;
    public var numVertices:Int = 0;
    public var totalFrames:Int = 0;
    public var dynamicDeformation:Bool = false;
    public var cachedFrames:Map<Int, Vector<Float>> = new Map<Int, Vector<Float>>();
    public var cachedGpuBuffers:Map<Int, openfl.display3D.VertexBuffer3D> = new Map<Int, openfl.display3D.VertexBuffer3D>();

    // Multi-surface skinning data
    public var surfaceSkins:Array<SurfaceSkinData> = [];

    private var _rawBones:Array<Vector<Float>>;
    private var _tempInvMeshWorld:Matrix3D;

    public function new(mesh:Mesh3D = null) {
        super();
        this.mesh = mesh;
        if (mesh != null) {
            for (s in mesh.surfaces) {
                if (s != null) {
                    s.isSkinned = true;
                    s._dirty = false;
                }
            }
        }
        this.bones = [];
        this.invBoneMatrix = [];
        this.boneMatrices = [];
        this.bindTransform = new Matrix3D();
        this._rawBones = [];
        this._tempInvMeshWorld = new Matrix3D();
        this.surfaceSkins = [];
    }

    public function addBone(pivot:Pivot3D, invMatrix:Matrix3D = null):Int {
        var idx = bones.length;
        bones.push(pivot);

        if (invMatrix != null) {
            invBoneMatrix.push(invMatrix);
        } else {
            var inv = new Matrix3D();
            inv.copyFrom(pivot.world);
            inv.invert();
            invBoneMatrix.push(inv);
        }

        boneMatrices.push(new Matrix3D());
        var raw = new Vector<Float>(16);
        _rawBones.push(raw);
        return idx;
    }

    public function addSurfaceSkin(surf:Surface3D, origPos:Vector<Float>, origNorm:Vector<Float>, w:Vector<Float>, bIdx:Vector<Int>, count:Int):SurfaceSkinData {
        var sData = new SurfaceSkinData(surf);
        sData.origPositions = origPos;
        sData.origNormals = origNorm;
        sData.weights = w;
        sData.boneIndices = bIdx;
        sData.numVertices = count;
        surfaceSkins.push(sData);

        if (surf != null) {
            surf.isSkinned = true;
            surf._dirty = false;
        }

        // Also synchronize primary surface data for legacy properties
        if (surfaceSkins.length == 1) {
            this.origPositions = origPos;
            this.origNormals = origNorm;
            this.weights = w;
            this.boneIndices = bIdx;
            this.numVertices = count;
        }

        return sData;
    }

    override public function update():Void {
        if (mesh == null) return;

        var animPivot:Pivot3D = (root != null) ? root : ((mesh.parent != null) ? mesh.parent : mesh);
        var total = this.totalFrames > 0 ? this.totalFrames : (animPivot.totalFrames > 0 ? animPivot.totalFrames : 26);
        var curFrame = (mesh.labels != null && mesh.labels.length > 0) ? mesh.currentFrame : animPivot.currentFrame;
        var fKey = Std.int(Math.floor(curFrame)) % total;
        if (fKey < 0) fKey += total;

        var topRoot:Pivot3D = (root != null) ? root : ((mesh.parent != null) ? mesh.parent : mesh);
        if (topRoot != null) {
            topRoot.currentFrame = curFrame;
            for (b in bones) {
                b.currentFrame = curFrame;
            }
            topRoot.updateTransforms(true);
        }

        if (dynamicDeformation) {
            if (bones.length == 0) return;
            computeDeformation(fKey);
            return;
        }

        if (surfaceSkins.length > 0) {
            var needCompute = false;
            for (sData in surfaceSkins) {
                if (!sData.cachedGpuBuffers.exists(fKey) && !sData.cachedFrames.exists(fKey)) {
                    needCompute = true;
                    break;
                }
            }
            if (needCompute) {
                computeDeformation(fKey);
            }

            if (Device3D.context != null) {
                for (sData in surfaceSkins) {
                    var gpuBuf = sData.cachedGpuBuffers.get(fKey);
                    if (gpuBuf == null && sData.cachedFrames.exists(fKey)) {
                        var fVec = sData.cachedFrames.get(fKey);
                        gpuBuf = Device3D.context.createVertexBuffer(sData.numVertices, 8);
                        gpuBuf.uploadFromVector(fVec, 0, sData.numVertices);
                        sData.cachedGpuBuffers.set(fKey, gpuBuf);
                    }
                    if (gpuBuf != null && sData.surface != null) {
                        sData.surface.vertexBuffer = gpuBuf;
                        sData.surface.isSkinned = true;
                        sData.surface._dirty = false;
                    }
                }
            }
            return;
        }

        // Single surface backward compatibility
        if (Device3D.context != null && !cachedGpuBuffers.keys().hasNext() && cachedFrames.keys().hasNext()) {
            for (k in cachedFrames.keys()) {
                var fVec = cachedFrames.get(k);
                var buf = Device3D.context.createVertexBuffer(numVertices, 8);
                buf.uploadFromVector(fVec, 0, numVertices);
                cachedGpuBuffers.set(k, buf);
            }
        }
        var gpuBuf = cachedGpuBuffers.get(fKey);
        if (gpuBuf == null && Device3D.context != null && cachedFrames.exists(fKey)) {
            var fVec = cachedFrames.get(fKey);
            gpuBuf = Device3D.context.createVertexBuffer(numVertices, 8);
            gpuBuf.uploadFromVector(fVec, 0, numVertices);
            cachedGpuBuffers.set(fKey, gpuBuf);
        }

        if (gpuBuf != null && mesh.surfaces.length > 0) {
            mesh.surfaces[0].vertexBuffer = gpuBuf;
            mesh.surfaces[0].isSkinned = true;
            mesh.surfaces[0]._dirty = false;
            for (i in 1...mesh.surfaces.length) {
                if (mesh.surfaces[i].vertexData == mesh.surfaces[0].vertexData) {
                    mesh.surfaces[i].vertexBuffer = gpuBuf;
                    mesh.surfaces[i].isSkinned = true;
                    mesh.surfaces[i]._dirty = false;
                }
            }
            return;
        }

        // Fallback to real-time computation if not pre-baked
        if (bones.length == 0) return;
        computeDeformation(fKey);
    }

    public function computeDeformation(fKey:Int):Void {
        mesh.updateWorldMatrix();
        _tempInvMeshWorld.copyFrom(mesh.world);
        _tempInvMeshWorld.invert();
        if (Math.isNaN(_tempInvMeshWorld.rawData[0])) {
            _tempInvMeshWorld.identity();
        }

        for (i in 0...bones.length) {
            var bone = bones[i];
            bone.updateWorldMatrix();
            var m = boneMatrices[i];
            m.identity();
            if (i < invBoneMatrix.length && invBoneMatrix[i] != null) {
                m.append(invBoneMatrix[i]);
            }
            m.append(bone.world);
            m.append(_tempInvMeshWorld);

            if (Math.isNaN(m.rawData[0])) {
                m.identity();
            }

            m.copyRawDataTo(_rawBones[i]);
        }

        // Deform multi-surface skins
        if (surfaceSkins.length > 0) {
            for (sData in surfaceSkins) {
                deformSurfaceSkin(sData, fKey);
            }
            return;
        }

        // Deform single surface (legacy)
        if (numVertices > 0 && origPositions != null && weights != null && boneIndices != null && mesh.surfaces.length > 0) {
            var primarySurf = mesh.surfaces[0];
            var vData = primarySurf.vertexData;
            if (vData == null) return;

            var bpv:Int = (numVertices > 0 && weights != null) ? Std.int(Math.max(1, Math.round(weights.length / numVertices))) : 1;
            var fVec = vData.copy();
            var rawBones = _rawBones;
            var hasNormals = (origNormals != null && origNormals.length >= numVertices * 3);

            for (i in 0...numVertices) {
                var pIdx = i * 3;
                var px = origPositions[pIdx];
                var py = origPositions[pIdx + 1];
                var pz = origPositions[pIdx + 2];

                var nx:Float = hasNormals ? origNormals[pIdx] : 0.0;
                var ny:Float = hasNormals ? origNormals[pIdx + 1] : 0.0;
                var nz:Float = hasNormals ? origNormals[pIdx + 2] : 0.0;

                var wIdx = i * bpv;
                var dst = i * 8;

                var rx:Float = 0;
                var ry:Float = 0;
                var rz:Float = 0;
                var rnx:Float = 0;
                var rny:Float = 0;
                var rnz:Float = 0;
                var totalW:Float = 0;

                for (k in 0...bpv) {
                    var wk = weights[wIdx + k];
                    if (wk > 0.0001) {
                        var bk = boneIndices[wIdx + k];
                        if (bk >= 0 && bk < rawBones.length) {
                            var mk = rawBones[bk];
                            if (mk != null) {
                                rx += (px * mk[0] + py * mk[4] + pz * mk[8] + mk[12]) * wk;
                                ry += (px * mk[1] + py * mk[5] + pz * mk[9] + mk[13]) * wk;
                                rz += (px * mk[2] + py * mk[6] + pz * mk[10] + mk[14]) * wk;

                                if (hasNormals) {
                                    rnx += (nx * mk[0] + ny * mk[4] + nz * mk[8]) * wk;
                                    rny += (nx * mk[1] + ny * mk[5] + nz * mk[9]) * wk;
                                    rnz += (nx * mk[2] + ny * mk[6] + nz * mk[10]) * wk;
                                }
                                totalW += wk;
                            }
                        }
                    }
                }

                if (totalW > 0.0001) {
                    fVec[dst + 0] = rx / totalW;
                    fVec[dst + 1] = ry / totalW;
                    fVec[dst + 2] = rz / totalW;
                    if (hasNormals) {
                        var len = Math.sqrt(rnx * rnx + rny * rny + rnz * rnz);
                        if (len > 0.0001) {
                            fVec[dst + 5] = rnx / len;
                            fVec[dst + 6] = rny / len;
                            fVec[dst + 7] = rnz / len;
                        }
                    }
                } else {
                    fVec[dst + 0] = px;
                    fVec[dst + 1] = py;
                    fVec[dst + 2] = pz;
                }
            }

            cachedFrames.set(fKey, fVec);

            if (Device3D.context != null) {
                var gpuBuf:openfl.display3D.VertexBuffer3D = null;
                if (dynamicDeformation) {
                    gpuBuf = primarySurf.vertexBuffer;
                    if (gpuBuf == null) {
                        gpuBuf = Device3D.context.createVertexBuffer(numVertices, 8);
                    }
                } else {
                    gpuBuf = Device3D.context.createVertexBuffer(numVertices, 8);
                    cachedGpuBuffers.set(fKey, gpuBuf);
                }
                gpuBuf.uploadFromVector(fVec, 0, numVertices);
                primarySurf.vertexBuffer = gpuBuf;
                primarySurf.isSkinned = true;
                primarySurf._dirty = false;
                for (i in 1...mesh.surfaces.length) {
                    if (mesh.surfaces[i].vertexData == primarySurf.vertexData) {
                        mesh.surfaces[i].vertexBuffer = gpuBuf;
                        mesh.surfaces[i].isSkinned = true;
                        mesh.surfaces[i]._dirty = false;
                    }
                }
            }
        }
    }

    private function deformSurfaceSkin(sData:SurfaceSkinData, fKey:Int):Void {
        var nVerts = sData.numVertices;
        if (nVerts <= 0 || sData.origPositions == null || sData.weights == null || sData.boneIndices == null || sData.surface == null) return;
        var vData = sData.surface.vertexData;
        if (vData == null) return;

        var origPos = sData.origPositions;
        var weights = sData.weights;
        var boneIndices = sData.boneIndices;
        var rawBones = _rawBones;

        var bpv:Int = (nVerts > 0 && weights != null) ? Std.int(Math.max(1, Math.round(weights.length / nVerts))) : 1;
        var hasNormals = (sData.origNormals != null && sData.origNormals.length >= nVerts * 3);
        var origNorm = sData.origNormals;
        var fVec = vData.copy();
        for (i in 0...nVerts) {
            var pIdx = i * 3;
            var px = origPos[pIdx];
            var py = origPos[pIdx + 1];
            var pz = origPos[pIdx + 2];

            var nx:Float = hasNormals ? origNorm[pIdx] : 0.0;
            var ny:Float = hasNormals ? origNorm[pIdx + 1] : 0.0;
            var nz:Float = hasNormals ? origNorm[pIdx + 2] : 0.0;

            var wIdx = i * bpv;
            var dst = i * 8;

            var rx:Float = 0;
            var ry:Float = 0;
            var rz:Float = 0;
            var rnx:Float = 0;
            var rny:Float = 0;
            var rnz:Float = 0;
            var totalW:Float = 0;

            for (k in 0...bpv) {
                var wk = weights[wIdx + k];
                if (wk > 0.0001) {
                    var bk = boneIndices[wIdx + k];
                    if (bk >= 0 && bk < rawBones.length) {
                        var mk = rawBones[bk];
                        if (mk != null) {
                            rx += (px * mk[0] + py * mk[4] + pz * mk[8] + mk[12]) * wk;
                            ry += (px * mk[1] + py * mk[5] + pz * mk[9] + mk[13]) * wk;
                            rz += (px * mk[2] + py * mk[6] + pz * mk[10] + mk[14]) * wk;

                            if (hasNormals) {
                                rnx += (nx * mk[0] + ny * mk[4] + nz * mk[8]) * wk;
                                rny += (nx * mk[1] + ny * mk[5] + nz * mk[9]) * wk;
                                rnz += (nx * mk[2] + ny * mk[6] + nz * mk[10]) * wk;
                            }
                            totalW += wk;
                        }
                    }
                }
            }

            if (totalW > 0.0001) {
                fVec[dst + 0] = rx / totalW;
                fVec[dst + 1] = ry / totalW;
                fVec[dst + 2] = rz / totalW;
                if (hasNormals) {
                    var len = Math.sqrt(rnx * rnx + rny * rny + rnz * rnz);
                    if (len > 0.0001) {
                        fVec[dst + 5] = rnx / len;
                        fVec[dst + 6] = rny / len;
                        fVec[dst + 7] = rnz / len;
                    }
                }
            } else {
                fVec[dst + 0] = px;
                fVec[dst + 1] = py;
                fVec[dst + 2] = pz;
            }
        }

        sData.cachedFrames.set(fKey, fVec);

        if (Device3D.context != null) {
            var gpuBuf = Device3D.context.createVertexBuffer(nVerts, 8);
            gpuBuf.uploadFromVector(fVec, 0, nVerts);
            sData.cachedGpuBuffers.set(fKey, gpuBuf);
            sData.surface.vertexBuffer = gpuBuf;
            sData.surface.isSkinned = true;
            sData.surface._dirty = false;
        }
    }

    public function prebakeAnimation(numFrames:Int = 0):Void {
        var hasData = (surfaceSkins.length > 0) || (numVertices > 0);
        if (mesh == null || bones.length == 0 || !hasData) return;
        var t0 = openfl.Lib.getTimer();

        if (numFrames <= 0) {
            numFrames = (bones.length > 0 && bones[0].frames != null) ? bones[0].frames.length : 0;
            if (numFrames <= 0 && mesh.totalFrames > 0) numFrames = mesh.totalFrames;
            if (numFrames <= 0) numFrames = 26;
        }
        this.totalFrames = numFrames;

        var topRoot:Pivot3D = (root != null) ? root : ((mesh.parent != null) ? mesh.parent : mesh);

        // Pre-compute deformation for all keyframes
        for (f in 0...numFrames) {
            topRoot.currentFrame = f;
            for (b in bones) {
                b.currentFrame = f;
            }
            topRoot.updateTransforms(true);
            computeDeformation(f);
        }

        topRoot.currentFrame = 0;
        for (b in bones) {
            b.currentFrame = 0;
        }
        topRoot.updateTransforms(true);

        var totalVerts = 0;
        if (surfaceSkins.length > 0) {
            for (s in surfaceSkins) totalVerts += s.numVertices;
        } else {
            totalVerts = numVertices;
        }

        var dt = openfl.Lib.getTimer() - t0;
        flare.system.DebugLog.log("[SkinModifier] Prebaked " + numFrames + " frames in " + dt + " ms (surfs=" + surfaceSkins.length + ", totalVerts=" + totalVerts + ").");
    }
}
