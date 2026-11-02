package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.Lib.getTimer;
import flare.basic.*;
import flare.core.*;
import flare.materials.*;
import flare.materials.filters.*;
import flare.primitives.*;
import flare.flsl.*;
import flare.utils.Vector3DUtils;

/**
 * @author Ariel Nehmad
 */
class Test61_LightScattering extends Sprite
{
	private var scene:Scene3D;
	private var sphere:Sphere;
	private var radialBlur:FLSLMaterial;
	private var blur:FLSLMaterial;
	private var texture:Texture3D;
	private var target:Texture3D;
	private var _renderFrames:Int = 0;
	
	public function new() 
	{
		super();
		scene = new Viewer3D( this, null, 0.2 );
		scene.backgroundColor = 0x000000;
		scene.autoResize = true;
		
		texture = new Texture3D( new Point( 512, 512 ) );
		texture.upload( scene );
		
		target = new Texture3D( new Point( 512, 512 ) );
		target.upload( scene );
		
		blur = new FLSLMaterial( "blurAndBlend", "blurAndBlend.flsl.compiled" );
		radialBlur = new FLSLMaterial( "radialBlur", "radialBlur.flsl.compiled" );
		
		sphere = new Sphere( "light", 30, 24, new Shader3D( "", [new ColorFilter(0xffc0a0)], false ) );
		sphere.scene = scene;
		
		scene.addChildFromFile( "geoSphere.zf3d" );
		scene.addEventListener( Scene3D.RENDER_EVENT, renderEvent );
	}
	
	private function renderEvent(e:Event):Void 
	{
		scene.camera.rotateY( 0.2, false, Vector3DUtils.ZERO );
		
		// cancel the default render.
		e.preventDefault();

		if (texture.texture == null) texture.upload(scene);
		if (target.texture == null) target.upload(scene);
		
		// renders the lights mask into the texture.
		scene.context.setRenderToTexture( texture.texture, true );
		scene.context.clear(0, 0, 0, 1);
		// we draw into the texture without any color, just to store depth buffer values.
		scene.context.setColorMask( false, false, false, false );
		scene.render();
		// then we render the colored spheres which will be the light sources.
		scene.context.setColorMask( true, true, true, true );
		drawSpheres();
		
		// apply the radial blur on the resulted texture.
		radialBlur.params.inputTexture.value = texture;
		radialBlur.params.outputTexture.value = target;
		scene.drawQuadTexture( null, 0, 0, stage.stageWidth, stage.stageHeight, radialBlur );
		
		blur.params.inputTexture.value = target;
		blur.params.outputTexture.value = texture;
		scene.drawQuadTexture( null, 0, 0, stage.stageWidth, stage.stageHeight, blur );
		
		// renders the scene normally.
		scene.context.setRenderToBackBuffer();
		scene.render();
		drawSpheres();
		
		scene.drawQuadTexture( texture, 0, 0, stage.stageWidth, stage.stageHeight, null, "one", "one" );

		#if sys
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| (Sys.args().indexOf("auto") != -1)
			|| sys.FileSystem.exists("auto_exit.flag");
		if (isAuto) {
			_renderFrames++;
			if (_renderFrames >= 15) {
				saveScreenshot("test61.png");
				Sys.exit(0);
			}
		}
		#end
	}
	
	private function drawSpheres():Void
	{
		var timer:Float = getTimer();
		
		sphere.x = Math.sin( timer / 800 ) * 40;
		sphere.y = Math.cos( timer / 450 ) * 40;
		sphere.draw();
		
		sphere.x = -Math.cos( timer / 400 ) * 40;
		sphere.y = -Math.sin( timer / 760 ) * 40;
		sphere.draw();
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
