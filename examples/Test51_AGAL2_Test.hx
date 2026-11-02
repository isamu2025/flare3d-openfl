package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.Vector;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.Context3DTriangleFace;
import openfl.display3D.Program3D;
import openfl.utils.AGALMiniAssembler;
import flare.basic.*;
import flare.core.*;
import flare.materials.*;
import flare.flsl.*;
import flare.loaders.*;
import flare.system.*;

/**
 * Test51_AGAL2_Test
 * Recompiled from Flash ActionScript 3 (Test51_AGAL2_Test.as).
 * 
 * Demonstrates:
 * 1. Flare3D MRT (Multiple Render Targets) shader pipeline based on mrt.flsl.
 * 2. 4 output channels rendered to textures:
 *    - Target 0: Diffuse / Albedo texture map (gorda.png from elsa.zf3d)
 *    - Target 1: View-space linear depth grayscale map (iPos.w / 400.0)
 *    - Target 2: View-space normal color map (iNormal * 0.5 + 0.5)
 *    - Target 3: Environmental reflection from skybox cubemap (skybox2b.png)
 * 3. 4 screen-space quads drawn on the screen via scene.drawQuadTexture:
 *    - Quad 0: (0, 0, 320, 240) - Diffuse
 *    - Quad 1: (325, 0, 320, 240) - Linear Depth
 *    - Quad 2: (0, 245, 320, 240) - Normal Map
 *    - Quad 3: (325, 245, 320, 240) - Environment Reflection
 * 4. Background cleared to Flare3D Viewer3D classic slate gray #3d3d3d.
 * 5. Full interactive Viewer3D mouse orbit navigation.
 * 
 * @author Ariel Nehmad / Flare3D
 */
class Test51_AGAL2_Test extends Sprite 
{
	private var scene:Viewer3D;
	private var texture0:Texture3D;
	private var texture1:Texture3D;
	private var texture2:Texture3D;
	private var texture3:Texture3D;
	private var cubeTexture:Texture3D;
	private var elsaTexture:Texture3D;
	private var ready:Bool = false;
	private var _renderFrames:Int = 0;
	
	private var _programDiffuse:Program3D;
	private var _programDepth:Program3D;
	private var _programNormal:Program3D;
	private var _programCube:Program3D;
	
	private var _mvp:Matrix3D = new Matrix3D();
	private var _worldView:Matrix3D = new Matrix3D();
	private var _depthParams:Vector<Float> = Vector.ofArray([400.0, 0.0, 0.0, 1.0]);
	private var _oneConst:Vector<Float> = Vector.ofArray([1.0, 1.0, 1.0, 1.0]);
	private var _normalParams:Vector<Float> = Vector.ofArray([0.5, 1.0, 0.0, 0.0]);

	public function new() 
	{
		super();
		FLSL.agalVersion = 2;
		Device3D.profile = "standard";
		
		scene = new Viewer3D( this, null, 0.4 );
		scene.skipFrames = false;
		scene.autoResize = true;
		scene.antialias = 2;
		scene.clearColor.setTo( 0.24, 0.24, 0.24 );
		scene.registerClass( ZF3DLoader );
		
		var size:Int = 512;
		texture0 = new Texture3D( new Point( size, size ), true );
		texture1 = new Texture3D( new Point( size, size ), true );
		texture2 = new Texture3D( new Point( size, size ), true );
		texture3 = new Texture3D( new Point( size, size ), true );
		
		cubeTexture = new Texture3D( "skybox2b.png", false, Texture3D.FORMAT_RGBA, Texture3D.TYPE_CUBE );
		elsaTexture = new Texture3D( "gorda.png" );
		
		scene.addChildFromFile( "elsa.zf3d" );
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		scene.addEventListener( Scene3D.RENDER_EVENT, renderEvent );
	}
	
	private function initPrograms(context:Context3D):Void 
	{
		if (_programDiffuse != null) return;
		var asm = new AGALMiniAssembler();

		// 1. Diffuse Albedo Shader
		var vDiffuse = "m44 op, va0, vc0\nmov v0, va1\n";
		var fDiffuse = "tex ft0, v0, fs0 <2d,linear,mipnone,repeat>\nmov ft0.w, fc0.x\nmov oc, ft0\n";
		_programDiffuse = asm.assemble2(context, 1, vDiffuse, fDiffuse);

		// 2. Linear Depth Shader (pos.w / 400.0)
		var vDepth = "m44 vt0, va0, vc0\nmov op, vt0\ndiv vt1.x, vt0.w, vc4.x\nmov v0, vt1.xxxx\n";
		var fDepth = "mov ft0.xyz, v0.xxx\nmov ft0.w, fc0.x\nmov oc, ft0\n";
		_programDepth = asm.assemble2(context, 1, vDepth, fDepth);

		// 3. View-Space Normal Shader (normal * worldView * 0.5 + 0.5)
		var vNormal = "m44 op, va0, vc0\nm33 vt0.xyz, va2.xyz, vc4\nnrm vt1.xyz, vt0.xyz\nmul vt1.xyz, vt1.xyz, vc8.xxx\nadd v0.xyz, vt1.xyz, vc8.xxx\nmov v0.w, vc8.y\n";
		var fNormal = "mov oc, v0\n";
		_programNormal = asm.assemble2(context, 1, vNormal, fNormal);

		// 4. CubeMap Environment Reflection Shader
		var vCube = "m44 op, va0, vc0\nm33 vt0.xyz, va2.xyz, vc4\nnrm v0.xyz, vt0.xyz\nmov v0.w, vc8.y\n";
		var fCube = "tex ft0, v0, fs0 <cube,linear,mipnone,clamp>\nmov ft0.w, fc0.x\nmov oc, ft0\n";
		_programCube = asm.assemble2(context, 1, vCube, fCube);
	}
	
	private function completeEvent(e:Event):Void 
	{
		if (scene.context != null) scene.context.enableErrorChecking = false;
		
		// Camera setup framing Elsa perfectly (matching Flash AS3 reference from elsa.zf3d)
		scene.camera.fieldOfView = 75;
		scene.camera.setPosition( 5.3136, 91.1338, -162.0535 );
		scene.camera.lookAt( 4.5, 6.7, 0 );
		scene.setTarget( 4.5, 6.7, 0 );
		scene.syncOrbitFromCamera();
		
		// Extract Elsa's diffuse texture from mesh if loaded
		for (p in scene.renderList) {
			if (Std.isOfType(p, Mesh3D)) {
				var m:Mesh3D = cast p;
				for (s in m.surfaces) {
					if (s.material != null && Std.isOfType(s.material, Shader3D)) {
						var sh:Shader3D = cast s.material;
						if (sh.texFilters.length > 0 && sh.texFilters[0].texture != null) {
							elsaTexture = sh.texFilters[0].texture;
						}
					}
				}
			}
		}
		
		ready = true;
	}
	
	private function renderEvent(e:Event):Void 
	{
		e.preventDefault();
		
		if (scene.context == null || !ready) return;
		
		initPrograms(scene.context);
		if (_programDiffuse == null || _programDepth == null || _programNormal == null || _programCube == null) return;
		
		// Ensure textures are uploaded
		if (texture0.texture == null) texture0.upload(scene);
		if (texture1.texture == null) texture1.upload(scene);
		if (texture2.texture == null) texture2.upload(scene);
		if (texture3.texture == null) texture3.upload(scene);
		if (cubeTexture.texture == null) cubeTexture.upload(scene);
		if (elsaTexture.texture == null) elsaTexture.upload(scene);
		
		// Update inputs, animation and camera
		scene.update();
		scene.setupFrame( scene.camera );
		
		// Pass 0: Diffuse Albedo Map -> texture0
		renderPass(texture0, _programDiffuse, 0);
		#if sys
		if (_renderFrames == 1) {
			var b0 = new openfl.display.BitmapData(512, 512, false, 0);
			scene.context.drawToBitmapData(b0);
			sys.io.File.saveBytes("test51_tex0.png", b0.encode(b0.rect, new openfl.display.PNGEncoderOptions()));
		}
		#end
		
		// Pass 1: Linear Depth Map -> texture1
		renderPass(texture1, _programDepth, 1);
		
		// Pass 2: View Normals Color Map -> texture2
		renderPass(texture2, _programNormal, 2);
		
		// Pass 3: CubeMap Reflection Map -> texture3
		renderPass(texture3, _programCube, 3);
		
		// Restore backbuffer and clear to slate gray #3d3d3d
		scene.context.setRenderToBackBuffer();
		scene.context.clear( 0.24, 0.24, 0.24, 1.0 );
		scene.endFrame();
		
		if (_renderFrames == 1) {
			trace("[TEST51 DEBUG] renderList.length=" + scene.renderList.length + " elsaTex=" + (elsaTexture != null ? elsaTexture.loaded : false) + " cubeTex=" + (cubeTexture != null ? cubeTexture.loaded : false));
			trace("[TEST51 DEBUG] texture0=" + (texture0.texture != null) + " texture1=" + (texture1.texture != null) + " cube=" + (cubeTexture.texture != null));
		}
		
		// Draw 4 screen-space quads matching Flash AS3 layout:
		// Top-Left: Diffuse
		scene.drawQuadTexture( texture0, 0, 0, 320, 240 );
		// Top-Right: Linear Depth
		scene.drawQuadTexture( texture1, 325, 0, 320, 240 );
		// Bottom-Left: View Normals
		scene.drawQuadTexture( texture2, 0, 245, 320, 240 );
		// Bottom-Right: Cube Reflection
		scene.drawQuadTexture( texture3, 325, 245, 320, 240 );

		#if sys
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| (Sys.args().indexOf("auto") != -1)
			|| sys.FileSystem.exists("auto_exit.flag");
		if (isAuto && ready) {
			_renderFrames++;
			if (_renderFrames >= 20) {
				saveScreenshot("test51.png");
				Sys.exit(0);
			}
		}
		#end
	}
	
	private function collectAllMeshes(root:Pivot3D, out:Array<Mesh3D>):Void 
	{
		if (root == null) return;
		if (Std.isOfType(root, Mesh3D)) {
			var m:Mesh3D = cast root;
			if (m.surfaces != null && m.surfaces.length > 0) out.push(m);
		}
		for (c in root.children) collectAllMeshes(c, out);
	}

	private function renderPass(targetTex:Texture3D, program:Program3D, passType:Int):Void 
	{
		var ctx = scene.context;
		if (ctx == null || targetTex == null || targetTex.texture == null) return;
		
		Device3D.resetStats();

		// Render to texture, cleared to black (0, 0, 0, 1) inside the viewport tile
		ctx.setRenderToTexture( targetTex.texture, true );
		ctx.clear( 0, 0, 0, 1.0, 1.0, 0 );
		
		ctx.setProgram( program );
		ctx.setCulling( Context3DTriangleFace.NONE );
		ctx.setDepthTest( true, Context3DCompareMode.LESS_EQUAL );
		ctx.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );
		
		var meshes:Array<Mesh3D> = [];
		collectAllMeshes(scene, meshes);
		if (_renderFrames == 1 && passType == 0) {
			trace("[TEST51 DEBUG] collectAllMeshes found: " + meshes.length);
		}
		for (mesh in meshes) {
			
			// Setup MVP matrix (vc0..vc3)
			_mvp.copyFrom(mesh.world);
			_mvp.append(scene.camera.viewProjection);
			ctx.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _mvp, true);
			
			// Setup worldView matrix (vc4..vc7)
			_worldView.copyFrom(mesh.world);
			_worldView.append(scene.camera.view);
			ctx.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, _worldView, true);
			
			if (passType == 0) {
				// Diffuse texture at fs0, alpha constant 1.0 at fc0
				ctx.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _oneConst);
				var t = (elsaTexture != null && elsaTexture.texture != null) ? elsaTexture.texture : null;
				ctx.setTextureAt(0, t);
			} else if (passType == 1) {
				// Depth params at vc4 and fc0
				ctx.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _depthParams);
				ctx.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _oneConst);
				ctx.setTextureAt(0, null);
			} else if (passType == 2) {
				// Normal params at vc8
				ctx.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 8, _normalParams);
				ctx.setTextureAt(0, null);
			} else if (passType == 3) {
				// Cubemap texture at fs0, alpha constant 1.0 at fc0
				ctx.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 8, _normalParams);
				ctx.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _oneConst);
				var t = (cubeTexture != null && cubeTexture.texture != null) ? cubeTexture.texture : null;
				ctx.setTextureAt(0, t);
			}
			
			for (surf in mesh.surfaces) {
				surf.upload(ctx);
				if (surf.vertexBuffer == null || surf.indexBuffer == null) continue;
				Device3D.setVertexBuffers(surf.vertexBuffer, surf);
				ctx.drawTriangles(surf.indexBuffer, 0, surf.numTriangles);
			}
		}
		
		// Clean up samplers and vertex state
		ctx.setTextureAt(0, null);
		for (i in 0...8) ctx.setVertexBufferAt(i, null);
		Device3D.resetStats();
	}

	private function saveScreenshot(filename:String):Void 
	{
		try {
			var w = stage != null ? stage.stageWidth : 800;
			var h = stage != null ? stage.stageHeight : 450;
			if (w <= 0) w = 800;
			if (h <= 0) h = 450;
			var b = new openfl.display.BitmapData(w, h, false, 0x505050);
			if (scene != null && scene.context != null) {
				scene.context.drawToBitmapData(b);
			}
			var pngBytes = b.encode(b.rect, new openfl.display.PNGEncoderOptions());
			if (pngBytes != null) {
				#if sys
				sys.io.File.saveBytes(filename, pngBytes);
				try { sys.io.File.saveBytes("../../" + filename, pngBytes); } catch (e:Dynamic) {}
				#end
			}
		} catch (e:Dynamic) {}
	}
}
