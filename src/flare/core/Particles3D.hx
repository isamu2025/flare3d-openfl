package flare.core;

import openfl.Vector;
import openfl.geom.Vector3D;
import openfl.geom.Point;
import openfl.geom.Matrix3D;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.display.GradientType;
import openfl.display.PNGEncoderOptions;
import openfl.display3D.Context3D;
import openfl.display3D.Program3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.Context3DTriangleFace;
import openfl.display3D.Context3DVertexBufferFormat;
import flare.basic.Scene3D;
import flare.core.Camera3D;
import flare.core.Mesh3D;
import flare.core.Surface3D;
import flare.core.Texture3D;
import flare.core.Pivot3D;
import flare.materials.Material3D;
import flare.system.Device3D;
import openfl.utils.AGALMiniAssembler;

/**
 * Internal single particle state. Pre-allocated in fixed pool for 0 GC performance.
 */
class ParticleInstance {
    public var posX:Float = 0.0;
    public var posY:Float = 0.0;
    public var posZ:Float = 0.0;
    public var velX:Float = 0.0;
    public var velY:Float = 0.0;
    public var velZ:Float = 0.0;
    public var age:Float = 0.0;
    public var maxLife:Float = 1.0;
    public var sizeStartX:Float = 2.8;
    public var sizeStartY:Float = 2.8;
    public var sizeEndX:Float = 0.0;
    public var sizeEndY:Float = 0.0;
    public var angle:Float = 0.0;
    public var spinSpeed:Float = 0.0;
    public var active:Bool = false;

    public function new() {}
}

/**
 * Dedicated high-performance Stage3D particle material.
 * Supports premultiplied alpha AGAL shading, custom blend modes, 
 * depth test without depth write, and camera-space screen billboarding.
 */
class ParticleMaterial3D extends Material3D {
    private var _program:Program3D = null;
    private var _mvp:Matrix3D = new Matrix3D();
    private var _texture:Texture3D = null;

    public var blendMode:String = Particles3D.BLEND_NORMAL;
    public var texture(get, set):Texture3D;

    public function new(name:String = "particle_mat", texture:Texture3D = null) {
        super(name);
        this.texture = texture;
        this.depthWrite = false;
        this.twoSided = true;
        this.transparent = true;
    }

    private function get_texture():Texture3D return _texture;
    private function set_texture(t:Texture3D):Texture3D {
        _texture = t;
        return t;
    }

    private function initProgram(context:Context3D):Void {
        if (_program != null) return;

        // Vertex Shader:
        // va0: Position (World Space)
        // va1: UV (0..1)
        // va3: Color (R, G, B, A)
        // vc0..vc3: MVP matrix (View-Projection matrix if worldPositions=true)
        var vSource = 
            "m44 op, va0, vc0\n" +
            "mov v0, va1\n" +
            "mov v4, va3\n";

        // Fragment Shader:
        // Sample texture -> multiply by vertex color -> premultiply RGB by Alpha -> output
        var fSource = 
            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>\n" +
            "mul ft0, ft0, v4\n" +
            "mul ft0.xyz, ft0.xyz, ft0.www\n" +
            "mov oc, ft0\n";

        try {
            var assembler = new AGALMiniAssembler();
            _program = assembler.assemble2(context, 1, vSource, fSource);
        } catch (e:Dynamic) {
            trace("[ParticleMaterial3D] Failed to compile AGAL shader: " + e);
        }
    }

    override public function draw(mesh:Mesh3D, surface:Surface3D, camera:Camera3D):Void {
        var context = Device3D.context;
        if (context == null || surface == null || camera == null) return;
        if (surface.numTriangles <= 0) return;

        initProgram(context);
        if (_program == null) return;

        surface.upload(context);
        if (surface.vertexBuffer == null || surface.indexBuffer == null) return;

        Device3D.setProgram(_program);

        var p3d:Particles3D = Std.isOfType(mesh, Particles3D) ? cast mesh : null;
        if (p3d != null && p3d.worldPositions) {
            _mvp.copyFrom(camera.viewProjection);
        } else {
            _mvp.copyFrom(mesh.world);
            _mvp.append(camera.viewProjection);
        }
        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _mvp, true);

        // Bind Texture
        var activeTex = _texture;
        if (activeTex == null && p3d != null) {
            activeTex = p3d.getFallbackTexture();
        }
        if (activeTex != null) {
            activeTex.upload(context);
            if (activeTex.texture != null) {
                Device3D.setTextureAt(0, activeTex.texture);
            }
        }

        // Set Blend mode (Premultiplied source with respective destinations)
        switch (blendMode) {
            case Particles3D.BLEND_SCREEN:
                Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR);
            case Particles3D.BLEND_ADD, Particles3D.BLEND_ADDITIVE:
                Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
            case Particles3D.BLEND_MULTIPLY:
                Device3D.setBlendFactors(Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ZERO);
            case Particles3D.BLEND_NONE:
                Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
            default: // BLEND_NORMAL, BLEND_ALPHA, BLEND_ALPHA_BLENDED, etc.
                Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
        }

        Device3D.setDepthTest(false, Context3DCompareMode.LESS_EQUAL);
        Device3D.setCulling(Context3DTriangleFace.NONE);

        // Bind vertex channels: va0=pos, va1=uv, va2=dummy normal, va3=color
        Device3D.setVertexBuffers(surface.vertexBuffer, surface);

        context.drawTriangles(surface.indexBuffer, surface.firstIndex, surface.numTriangles);

        Device3D.drawCalls++;
        Device3D.triangles += surface.numTriangles;
    }

    override public function clone():Material3D {
        var m = new ParticleMaterial3D(name + "_clone", _texture);
        m.blendMode = this.blendMode;
        return m;
    }
}

/**
 * Particles3D in Flare3D.
 * Hardware-accelerated GPU billboard particle system supporting velocity, gravity,
 * lifecycles, color gradients, billboarding, screen/additive blending, and burst controls.
 */
class Particles3D extends Mesh3D {
    public static inline var BLEND_NORMAL:String = "normal";
    public static inline var BLEND_ADD:String = "add";
    public static inline var BLEND_ADDITIVE:String = "additive";
    public static inline var BLEND_SCREEN:String = "screen";
    public static inline var BLEND_MULTIPLY:String = "multiply";
    public static inline var BLEND_ALPHA:String = "alpha";
    public static inline var BLEND_ALPHA_BLENDED:String = "alphaBlended";
    public static inline var BLEND_ALPHA_BLENDED2:String = "alphaBlended2";
    public static inline var BLEND_NONE:String = "none";

    public var worldPositions:Bool = true;
    public var worldVelocities:Bool = true;
    public var randomSpin:Float = 0.0;
    public var duration:Float = 0.0; // 0 = continuous
    public var delay:Float = 0.0;
    public var life:Float = 2.5; // lifespan in seconds
    public var emissionRate:Float = 160.0; // particles per second
    public var maxParticles:Int = 2000;

    public var lifeTime(get, set):Float;
    private inline function get_lifeTime():Float return life;
    private inline function set_lifeTime(v:Float):Float return life = v;

    public var loops(default, set):Int = 0; // 0 = infinite loops
    private function set_loops(val:Int):Int {
        loops = val;
        if (val > 0) {
            _emitting = false;
        }
        return val;
    }

    public var velocity:Vector3D;
    public var gravity:Vector3D;
    public var randomVelocity:Dynamic = 0.0;

    private var _startSize:Point = new Point(2.8, 2.8);
    private var _endSize:Point = new Point(0, 0);

    public var startSize(get, set):Dynamic;
    private function get_startSize():Dynamic return _startSize;
    private function set_startSize(val:Dynamic):Dynamic {
        if (Std.isOfType(val, Float) || Std.isOfType(val, Int)) {
            var f:Float = cast val;
            _startSize.setTo(f, f);
        } else if (val != null) {
            var px:Float = Reflect.hasField(val, "x") ? Reflect.field(val, "x") : 2.8;
            var py:Float = Reflect.hasField(val, "y") ? Reflect.field(val, "y") : px;
            _startSize.setTo(px, py);
        }
        return val;
    }

    public var endSize(get, set):Dynamic;
    private function get_endSize():Dynamic return _endSize;
    private function set_endSize(val:Dynamic):Dynamic {
        if (Std.isOfType(val, Float) || Std.isOfType(val, Int)) {
            var f:Float = cast val;
            _endSize.setTo(f, f);
        } else if (val != null) {
            var px:Float = Reflect.hasField(val, "x") ? Reflect.field(val, "x") : 0.0;
            var py:Float = Reflect.hasField(val, "y") ? Reflect.field(val, "y") : px;
            _endSize.setTo(px, py);
        }
        return val;
    }

    public var blendMode(get, set):String;
    private inline function get_blendMode():String return _particleMat.blendMode;
    private function set_blendMode(val:String):String {
        _particleMat.blendMode = val;
        return val;
    }

    private var _texture:Texture3D = null;
    public var texture(get, set):Texture3D;
    private inline function get_texture():Texture3D return _texture;
    private function set_texture(val:Dynamic):Texture3D {
        if (Std.isOfType(val, String)) {
            _texture = new Texture3D(cast val);
        } else {
            _texture = cast val;
        }
        _particleMat.texture = _texture;
        return _texture;
    }

    // Color gradient
    public var colors:Array<Dynamic> = [0xffffff];
    public var colorRatios:Array<Dynamic> = [0];
    private var _parsedColors:Array<{r:Float, g:Float, b:Float, a:Float}> = [{r: 1.0, g: 1.0, b: 1.0, a: 1.0}];
    private var _normalizedRatios:Array<Float> = [0.0];

    public var alphas:Array<Dynamic> = [1.0];
    public var alphaRatios:Array<Dynamic> = [0.0];
    private var _normalizedAlphaRatios:Array<Float> = [0.0];

    // Runtime state
    private var _paused:Bool = false;
    public var paused(get, never):Bool;
    private inline function get_paused():Bool return _paused;

    public var emitting(get, set):Bool;
    private inline function get_emitting():Bool return _emitting;
    private inline function set_emitting(v:Bool):Bool return _emitting = v;
    private var _emitting:Bool = true;

    private var _emissionTimer:Float = 0.0;
    private var _delayTimer:Float = 0.0;
    private var _currentLoop:Int = 0;
    private var _spawnAccumulator:Float = 0.0;
    private var _nextSpawnIndex:Int = 0;
    private var _lastTime:Int = 0;

    // Particle pool
    private var _particles:Array<ParticleInstance>;

    // Stage3D rendering objects
    private var _surface:Surface3D;
    private var _particleMat:ParticleMaterial3D;
    private static var _defaultFallbackTexture:Texture3D = null;

    public function new(name:String = "Particles3D", maxParticles:Int = 2000, texture:Dynamic = null) {
        super(name);
        this.maxParticles = maxParticles;
        this.velocity = new Vector3D(0, 0, 0);
        this.gravity = new Vector3D(0, 0, 0);

        // Pre-allocate particle pool
        _particles = [];
        for (i in 0...this.maxParticles) {
            _particles.push(new ParticleInstance());
        }

        // Configure Surface3D layout:
        // Position: 3 floats (offset 0)
        // UV0: 2 floats (offset 3)
        // Normal: 3 floats (offset 5, dummy)
        // Color0: 4 floats (offset 8)
        // Stride: 12 floats per vertex
        _surface = new Surface3D(name + "_surf");
        _surface.addVertexData(Surface3D.POSITION, 3);
        _surface.addVertexData(Surface3D.UV0, 2);
        _surface.addVertexData(Surface3D.NORMAL, 3);
        _surface.addVertexData(Surface3D.COLOR0, 4);

        _surface.vertexData = new Vector<Float>(this.maxParticles * 4 * 12);
        _surface.indexData = new Vector<UInt>(this.maxParticles * 6);
        _surface.numTriangles = 0;

        // Build static index buffer for all quads
        var iData = _surface.indexData;
        for (i in 0...this.maxParticles) {
            var baseIdx:UInt = i * 4;
            var iIdx = i * 6;
            iData[iIdx + 0] = baseIdx + 0;
            iData[iIdx + 1] = baseIdx + 1;
            iData[iIdx + 2] = baseIdx + 2;
            iData[iIdx + 3] = baseIdx + 0;
            iData[iIdx + 4] = baseIdx + 2;
            iData[iIdx + 5] = baseIdx + 3;
        }

        _particleMat = new ParticleMaterial3D(name + "_mat");
        addSurface(_surface, _particleMat);

        if (texture != null) {
            this.texture = texture;
        }

        setColors([0xffffff], [0]);
    }

    public function getFallbackTexture():Texture3D {
        if (_defaultFallbackTexture == null) {
            var bmd = new BitmapData(64, 64, true, 0x00000000);
            var shape = new Shape();
            var g = shape.graphics;
            var m = new openfl.geom.Matrix();
            m.createGradientBox(64, 64, 0, 0, 0);
            g.beginGradientFill(GradientType.RADIAL, [0xffffff, 0xffffff, 0xffffff], [1.0, 0.6, 0.0], [0, 80, 255], m);
            g.drawRect(0, 0, 64, 64);
            g.endFill();
            bmd.draw(shape);
            _defaultFallbackTexture = new Texture3D(bmd);
        }
        return _defaultFallbackTexture;
    }

    public function setColors(colors:Array<Dynamic>, ratios:Array<Dynamic> = null):Void {
        this.colors = colors != null ? colors.copy() : [0xffffff];
        if (ratios != null) {
            this.colorRatios = ratios.copy();
        } else {
            this.colorRatios = [];
            for (i in 0...this.colors.length) {
                this.colorRatios.push(this.colors.length > 1 ? (i / (this.colors.length - 1)) * 255.0 : 0.0);
            }
        }

        _parsedColors = [];
        for (hexVal in this.colors) {
            var hex:Int = Std.isOfType(hexVal, Int) ? cast hexVal : Std.parseInt(Std.string(hexVal));
            var a:Float = 1.0;
            var r:Float = 0.0;
            var g:Float = 0.0;
            var b:Float = 0.0;
            if (hex > 0xffffff) {
                a = ((hex >> 24) & 0xff) / 255.0;
                r = ((hex >> 16) & 0xff) / 255.0;
                g = ((hex >> 8) & 0xff) / 255.0;
                b = (hex & 0xff) / 255.0;
            } else {
                r = ((hex >> 16) & 0xff) / 255.0;
                g = ((hex >> 8) & 0xff) / 255.0;
                b = (hex & 0xff) / 255.0;
            }
            _parsedColors.push({r: r, g: g, b: b, a: a});
        }

        var maxR:Float = 1.0;
        for (r in this.colorRatios) {
            var rf:Float = cast r;
            if (rf > maxR) maxR = rf;
        }
        var scale:Float = (maxR > 1.0) ? (1.0 / 255.0) : 1.0;
        _normalizedRatios = [];
        for (r in this.colorRatios) {
            var rf:Float = cast r;
            _normalizedRatios.push(rf * scale);
        }
    }

    public function setAlphas(alphas:Array<Dynamic>, ratios:Array<Dynamic> = null):Void {
        this.alphas = alphas != null ? alphas.copy() : [1.0];
        if (ratios != null) {
            this.alphaRatios = ratios.copy();
        } else {
            this.alphaRatios = [];
            for (i in 0...this.alphas.length) {
                this.alphaRatios.push(this.alphas.length > 1 ? (i / (this.alphas.length - 1)) * 255.0 : 0.0);
            }
        }

        var maxR:Float = 1.0;
        for (r in this.alphaRatios) {
            var rf:Float = cast r;
            if (rf > maxR) maxR = rf;
        }
        var scale:Float = (maxR > 1.0) ? (1.0 / 255.0) : 1.0;
        _normalizedAlphaRatios = [];
        for (r in this.alphaRatios) {
            var rf:Float = cast r;
            _normalizedAlphaRatios.push(rf * scale);
        }
    }

    public function getAlphaAt(t:Float):Float {
        if (alphas.length == 0) return 1.0;
        if (alphas.length == 1 || t <= _normalizedAlphaRatios[0]) return cast alphas[0];
        var lastIdx = alphas.length - 1;
        if (t >= _normalizedAlphaRatios[lastIdx]) return cast alphas[lastIdx];

        for (i in 0...lastIdx) {
            var r0 = _normalizedAlphaRatios[i];
            var r1 = _normalizedAlphaRatios[i + 1];
            if (t >= r0 && t <= r1) {
                var frac = (r1 > r0) ? ((t - r0) / (r1 - r0)) : 0.0;
                var a0:Float = cast alphas[i];
                var a1:Float = cast alphas[i + 1];
                return a0 + (a1 - a0) * frac;
            }
        }
        return cast alphas[lastIdx];
    }

    public function getColorAt(t:Float):{r:Float, g:Float, b:Float, a:Float} {
        var alphaMod = getAlphaAt(t);
        if (_parsedColors.length == 0) {
            return {r: 1.0, g: 1.0, b: 1.0, a: alphaMod};
        }
        if (_parsedColors.length == 1 || t <= _normalizedRatios[0]) {
            var c = _parsedColors[0];
            return {r: c.r, g: c.g, b: c.b, a: c.a * alphaMod};
        }
        var lastIdx = _parsedColors.length - 1;
        if (t >= _normalizedRatios[lastIdx]) {
            var c = _parsedColors[lastIdx];
            return {r: c.r, g: c.g, b: c.b, a: c.a * alphaMod};
        }

        for (i in 0...lastIdx) {
            var r0 = _normalizedRatios[i];
            var r1 = _normalizedRatios[i + 1];
            if (t >= r0 && t <= r1) {
                var frac = (r1 > r0) ? ((t - r0) / (r1 - r0)) : 0.0;
                var c0 = _parsedColors[i];
                var c1 = _parsedColors[i + 1];
                return {
                    r: c0.r + (c1.r - c0.r) * frac,
                    g: c0.g + (c1.g - c0.g) * frac,
                    b: c0.b + (c1.b - c0.b) * frac,
                    a: (c0.a + (c1.a - c0.a) * frac) * alphaMod
                };
            }
        }
        var c = _parsedColors[lastIdx];
        return {r: c.r, g: c.g, b: c.b, a: c.a * alphaMod};
    }

    private function spawnParticle():Void {
        var p:ParticleInstance = null;
        for (i in 0...maxParticles) {
            var idx = (_nextSpawnIndex + i) % maxParticles;
            if (!_particles[idx].active) {
                p = _particles[idx];
                _nextSpawnIndex = (idx + 1) % maxParticles;
                break;
            }
        }

        // Recycle oldest particle if all active
        if (p == null) {
            p = _particles[_nextSpawnIndex];
            _nextSpawnIndex = (_nextSpawnIndex + 1) % maxParticles;
        }

        // Emitter spawn position
        if (worldPositions) {
            var wp = this.getPosition(false);
            p.posX = wp.x + (Math.random() - 0.5) * 1.5;
            p.posY = wp.y + (Math.random() - 0.5) * 1.5;
            p.posZ = wp.z + (Math.random() - 0.5) * 1.5;
        } else {
            p.posX = (Math.random() - 0.5) * 1.5;
            p.posY = (Math.random() - 0.5) * 1.5;
            p.posZ = (Math.random() - 0.5) * 1.5;
        }

        var baseVel = (velocity != null) ? velocity : new Vector3D(0, 0, 0);
        var rvX:Float = 0.0;
        var rvY:Float = 0.0;
        var rvZ:Float = 0.0;

        var hasBaseVel = (baseVel.x != 0.0 || baseVel.y != 0.0 || baseVel.z != 0.0);
        var hasRandomVel = false;
        var rvNum:Float = 0.0;
        if (Std.isOfType(randomVelocity, Float) || Std.isOfType(randomVelocity, Int)) {
            rvNum = cast randomVelocity;
            hasRandomVel = (rvNum > 0.0);
        } else if (randomVelocity != null) {
            hasRandomVel = true;
        }

        if (hasRandomVel) {
            if (rvNum > 0.0) {
                if (baseVel.y > 20.0) {
                    // Ballistic fountain burst: radial spread in XZ, upward jitter in Y
                    var spreadAngle = Math.random() * Math.PI * 2.0;
                    var spreadRad = Math.random() * (rvNum * 0.42);
                    rvX = Math.cos(spreadAngle) * spreadRad;
                    rvZ = Math.sin(spreadAngle) * spreadRad;
                    rvY = (Math.random() - 0.4) * (rvNum * 0.35);
                } else {
                    rvX = (Math.random() - 0.5) * rvNum;
                    rvY = (Math.random() - 0.5) * rvNum;
                    rvZ = (Math.random() - 0.5) * rvNum;
                }
            } else if (Std.isOfType(randomVelocity, Vector3D)) {
                var rvV:Vector3D = cast randomVelocity;
                rvX = (Math.random() - 0.5) * 2.0 * rvV.x;
                rvY = (Math.random() - 0.5) * 2.0 * rvV.y;
                rvZ = (Math.random() - 0.5) * 2.0 * rvV.z;
            }
        } else if (!hasBaseVel) {
            // Natural isotropic diffusion around the central emitter (soft billowy smoke)
            var theta = Math.random() * Math.PI * 2.0;
            var phi = Math.acos(2.0 * Math.random() - 1.0);
            var speed = 6.0 + Math.random() * 8.0; // 6 ~ 14 speed
            rvX = speed * Math.sin(phi) * Math.cos(theta);
            rvY = speed * Math.sin(phi) * Math.sin(theta);
            rvZ = speed * Math.cos(phi);
        }

        p.velX = baseVel.x + rvX;
        p.velY = baseVel.y + rvY;
        p.velZ = baseVel.z + rvZ;

        p.age = 0.0;
        var baseLife = this.life;
        // For ballistic fountain trajectories with downward gravity, ensure life covers the full parabolic arc
        if (gravity != null && gravity.y < -5.0 && baseVel.y > 20.0) {
            var flightTime = (2.0 * baseVel.y) / Math.abs(gravity.y);
            if (flightTime * 1.05 > baseLife) {
                baseLife = flightTime * 1.05;
            }
        }
        p.maxLife = baseLife * (0.85 + Math.random() * 0.3);

        p.sizeStartX = _startSize.x;
        p.sizeStartY = _startSize.y;
        p.sizeEndX = _endSize.x;
        p.sizeEndY = _endSize.y;

        p.angle = Math.random() * Math.PI * 2.0;
        p.spinSpeed = (Math.random() - 0.5) * 2.0 * (randomSpin * (Math.PI / 180.0) * 5.0);

        p.active = true;
    }

    public function update(delta:Float, camera:Camera3D = null):Void {
        if (_paused) return;

        var dt = Math.min(Math.max(delta, 0.001), 0.1);

        // Spawning logic
        if (_emitting) {
            if (_delayTimer > 0.0) {
                _delayTimer -= dt;
            } else {
                _emissionTimer += dt;
                var effectiveRate = this.emissionRate;
                if (duration > 0.0 && duration <= 1.0 && effectiveRate <= 200.0) {
                    effectiveRate = 500.0;
                }

                _spawnAccumulator += effectiveRate * dt;
                while (_spawnAccumulator >= 1.0) {
                    spawnParticle();
                    _spawnAccumulator -= 1.0;
                }

                if (duration > 0.0 && _emissionTimer >= duration) {
                    _currentLoop++;
                    if (loops > 0 && _currentLoop >= loops) {
                        _emitting = false;
                    } else {
                        _emissionTimer = 0.0;
                        _delayTimer = delay;
                    }
                }
            }
        }

        // Camera billboard orientation vectors
        var rx:Float = 1.0, ry:Float = 0.0, rz:Float = 0.0;
        var ux:Float = 0.0, uy:Float = 1.0, uz:Float = 0.0;
        if (camera != null) {
            var raw = camera.world.rawData;
            rx = raw[0]; ry = raw[1]; rz = raw[2];
            ux = raw[4]; uy = raw[5]; uz = raw[6];
        }

        var gx = (gravity != null) ? gravity.x : 0.0;
        var gy = (gravity != null) ? gravity.y : 0.0;
        var gz = (gravity != null) ? gravity.z : 0.0;

        var vData = _surface.vertexData;
        var activeCount = 0;

        for (i in 0...maxParticles) {
            var p = _particles[i];
            if (!p.active) continue;

            p.age += dt;
            if (p.age >= p.maxLife) {
                p.active = false;
                continue;
            }

            // Physics integration
            p.velX += gx * dt;
            p.velY += gy * dt;
            p.velZ += gz * dt;

            p.posX += p.velX * dt;
            p.posY += p.velY * dt;
            p.posZ += p.velZ * dt;

            p.angle += p.spinSpeed * dt;

            var t = p.age / p.maxLife;
            var hx = (p.sizeStartX * (1.0 - t) + p.sizeEndX * t) * 0.5;
            var hy = (p.sizeStartY * (1.0 - t) + p.sizeEndY * t) * 0.5;

            var col = getColorAt(t);

            var cosA = Math.cos(p.angle);
            var sinA = Math.sin(p.angle);

            var rotRx = rx * cosA - ux * sinA;
            var rotRy = ry * cosA - uy * sinA;
            var rotRz = rz * cosA - uz * sinA;

            var rotUx = rx * sinA + ux * cosA;
            var rotUy = ry * sinA + uy * cosA;
            var rotUz = rz * sinA + uz * cosA;

            var dxr = rotRx * hx; var dyr = rotRy * hx; var dzr = rotRz * hx;
            var dxu = rotUx * hy; var dyu = rotUy * hy; var dzu = rotUz * hy;

            var px = p.posX; var py = p.posY; var pz = p.posZ;
            var r = col.r; var g = col.g; var b = col.b; var a = col.a;

            var base = activeCount * 48; // 4 vertices * 12 floats

            // V0 (Bottom-Left): UV (0, 1)
            vData[base + 0] = px - dxr - dxu;
            vData[base + 1] = py - dyr - dyu;
            vData[base + 2] = pz - dzr - dzu;
            vData[base + 3] = 0.0; vData[base + 4] = 1.0;
            vData[base + 5] = 0.0; vData[base + 6] = 0.0; vData[base + 7] = 1.0; // dummy normal
            vData[base + 8] = r; vData[base + 9] = g; vData[base + 10] = b; vData[base + 11] = a;

            // V1 (Bottom-Right): UV (1, 1)
            vData[base + 12] = px + dxr - dxu;
            vData[base + 13] = py + dyr - dyu;
            vData[base + 14] = pz + dzr - dzu;
            vData[base + 15] = 1.0; vData[base + 16] = 1.0;
            vData[base + 17] = 0.0; vData[base + 18] = 0.0; vData[base + 19] = 1.0;
            vData[base + 20] = r; vData[base + 21] = g; vData[base + 22] = b; vData[base + 23] = a;

            // V2 (Top-Right): UV (1, 0)
            vData[base + 24] = px + dxr + dxu;
            vData[base + 25] = py + dyr + dyu;
            vData[base + 26] = pz + dzr + dzu;
            vData[base + 27] = 1.0; vData[base + 28] = 0.0;
            vData[base + 29] = 0.0; vData[base + 30] = 0.0; vData[base + 31] = 1.0;
            vData[base + 32] = r; vData[base + 33] = g; vData[base + 34] = b; vData[base + 35] = a;

            // V3 (Top-Left): UV (0, 0)
            vData[base + 36] = px - dxr + dxu;
            vData[base + 37] = py - dyr + dyu;
            vData[base + 38] = pz - dzr + dzu;
            vData[base + 39] = 0.0; vData[base + 40] = 0.0;
            vData[base + 41] = 0.0; vData[base + 42] = 0.0; vData[base + 43] = 1.0;
            vData[base + 44] = r; vData[base + 45] = g; vData[base + 46] = b; vData[base + 47] = a;

            activeCount++;
        }

        _surface.numTriangles = activeCount * 2;
        if (activeCount > 0 && _surface.vertexBuffer != null) {
            _surface.vertexBuffer.uploadFromVector(vData, 0, activeCount * 4);
        }
    }

    public function start(delay:Float = 0.0):Void {
        _currentLoop = 0;
        _delayTimer = delay;
        _emissionTimer = 0.0;
        _emitting = true;
        _paused = false;
        visible = true;
    }

    public function pause():Void {
        _paused = true;
    }

    public function resume():Void {
        _paused = false;
    }

    override public function stop(includeChildren:Bool = true):Void {
        _emitting = false;
        super.stop(includeChildren);
    }

    public function reset():Void {
        for (p in _particles) {
            p.active = false;
        }
        _spawnAccumulator = 0.0;
        _surface.numTriangles = 0;
    }

    override public function render(camera:Camera3D = null, clearDepth:Bool = false, target:Dynamic = null):Void {
        if (!_paused) {
            var now = openfl.Lib.getTimer();
            var dt:Float = (_lastTime > 0) ? (now - _lastTime) / 1000.0 : 0.016666;
            _lastTime = now;
            var activeCam = (camera != null) ? camera : (Device3D.scene != null ? Device3D.scene.camera : null);
            update(dt, activeCam);
        }
        super.render(camera, clearDepth, target);
    }

    override public function cloneBasic():Pivot3D {
        var p = new Particles3D(name + "_clone", maxParticles, _texture);
        copyTo(p);
        return p;
    }

    override public function copyTo(target:Pivot3D):Void {
        super.copyTo(target);
        if (Std.isOfType(target, Particles3D)) {
            var p:Particles3D = cast target;
            // CRITICAL: Ensure cloned particle system renders its own surface and material!
            p.surfaces = [p._surface];
            p.materials = [p._particleMat];
            p.worldPositions = this.worldPositions;
            p.worldVelocities = this.worldVelocities;
            p.randomSpin = this.randomSpin;
            p.duration = this.duration;
            p.loops = this.loops;
            p.delay = this.delay;
            p.life = this.life;
            p.emissionRate = this.emissionRate;
            p.startSize = this.startSize;
            p.endSize = this.endSize;
            if (this.velocity != null) p.velocity = this.velocity.clone();
            if (this.gravity != null) p.gravity = this.gravity.clone();
            p.randomVelocity = this.randomVelocity;
            p.blendMode = this.blendMode;
            p.setColors(this.colors, this.colorRatios);
            p.setAlphas(this.alphas, this.alphaRatios);
            p.texture = this.texture;
        }
    }

    override public function clone():Pivot3D {
        var p = cloneBasic();
        for (c in children) {
            p.addChild(c.clone());
        }
        return p;
    }
}
