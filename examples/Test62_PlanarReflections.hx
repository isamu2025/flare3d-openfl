package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Point;
import flare.basic.*;
import flare.core.*;
import flare.flsl.*;
import flare.materials.*;
import flare.primitives.*;
import flare.system.*;
import flare.utils.PlanarReflection;

/**
 * @author Jason Huang
 */
class Test62_PlanarReflections extends Sprite
{
	private var scene:Scene3D;
	private var model:Pivot3D;
	
	private var reflection:PlanarReflection;
	private var texture:Texture3D;
	private var material:Shader3D;
	private var filter:FLSLFilter;
	private var plane:Plane;
	private var _renderFrames:Int = 0;
	
	public function new() 
	{
		super();
		scene = new Viewer3D( this, null, 0.2 );
		scene.autoResize = true;
		scene.camera = new Camera3D();
		scene.camera.setPosition( 0, 100, -200 );
		scene.camera.lookAt( 0, 0, 0 );
		
		reflection = new PlanarReflection();
		
		texture = new Texture3D( new Point( 512, 512 ) );
		texture.wrapMode = Texture3D.WRAP_CLAMP;
		texture.upload( scene );
		
		filter = new FLSLFilter( "screenProj.flsl.compiled" );
		filter.params.texture.value = texture;
		
		material = new Shader3D( "Mirror Material", [ filter ] );
		material.twoSided = true;
		
		plane = new Plane( "Mirror", 500, 500, 1, material, "+xz" );
		plane.scene = scene;
		
		model = scene.addChildFromFile( "elsa.zf3d" );
		model.y = 30;
		scene.camera.setPosition( 0, 100, -200 );
		scene.camera.lookAt( 0, 0, 0 );
		if (Std.isOfType(scene, Viewer3D)) {
			cast(scene, Viewer3D).syncOrbitFromCamera();
		}
		
		scene.addEventListener( Scene3D.RENDER_EVENT, renderEvent );
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
	}
	
	private function renderEvent(e:Event):Void 
	{
		if (model != null) {
			model.rotateX( 1 );
			model.rotateZ( 0.7 );
		}
		
		drawMirror();
	}

	private function postRenderEvent(e:Event):Void 
	{
		#if sys
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| (Sys.args().indexOf("auto") != -1)
			|| sys.FileSystem.exists("auto_exit.flag");
		if (isAuto) {
			_renderFrames++;
			if (_renderFrames >= 15) {
				saveScreenshot("test62.png");
				Sys.exit(0);
			}
		}
		#end
	}
	
	private function drawMirror():Void
	{
		if (texture.texture == null) texture.upload(scene);

		// try to get a small value, the large value would kill the far plane.
		reflection.accuracy = 1 / scene.camera.far; 
		reflection.update( plane.world );
		
		if ( reflection.isBehind( scene.camera ) )
			return;
		
		reflection.setupCamera( scene.camera );
		
		scene.context.setRenderToTexture( texture.texture, true );
		scene.context.clear( 62 / 255.0, 62 / 255.0, 62 / 255.0, 1.0 );
		
		Device3D.invertCullFace = true;
		for (p in scene.renderList )
			if ( Std.isOfType(p, Mesh3D) )
				p.draw( false );
		Device3D.invertCullFace = false;
		
		scene.context.setRenderToBackBuffer();
		scene.setupFrame( scene.camera );
		
		plane.draw();
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
				#end
			}
		} catch (e:Dynamic) {
			trace("Error saving screenshot: " + e);
		}
	}
}
