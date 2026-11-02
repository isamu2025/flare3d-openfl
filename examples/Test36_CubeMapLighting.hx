package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import flare.basic.*;
import flare.core.*;
import flare.loaders.*;
import flare.system.*;

/**
 * Flare3D Example 36: CubeMap Lighting
 * Matches original ActionScript 3 Test36_CubeMapLighting
 */
class Test36_CubeMapLighting extends Sprite 
{
	private var scene:Scene3D;
	private var _renderFrames:Int = 0;
	
	public function new() 
	{
		super();
		scene = new Viewer3D(this, null, 0.2 );
		scene.registerClass( ZF3DLoader );
		scene.autoResize = true;
		scene.antialias = 2;
		
		scene.camera = new Camera3D();
		scene.camera.setPosition( -80, 80, 80 );
		scene.camera.lookAt( 0, 0, 0 );
		if (Std.isOfType(scene, Viewer3D)) {
			cast(scene, Viewer3D).syncOrbitFromCamera();
		}
		
		scene.clearColor.setTo( 0.25, 0.25, 0.25 );
		
		scene.lights.defaultLight = null;
		scene.lights.maxDirectionalLights = 0;
		scene.lights.maxPointLights = 0;
		scene.lights.ambientColor.setTo( 0, 0, 0 );
		
		// cubemap lighting works even in NO_LIGHTS mode and provides a super fast
		// approach for static lighting, specially for mobile devices.
		// cubeMap can be used with normal maps and could be used to emulate
		// indirect global skybox lighting.
		scene.lights.cubeMap = new Texture3D( "cubemap18.png", false, Texture3D.FORMAT_RGBA, Texture3D.TYPE_CUBE );
		
		scene.addChildFromFile( "teapot2.zf3d" );
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );

		scene.addEventListener( Scene3D.POSTRENDER_EVENT, onPostRender );
	}
	
	private function updateEvent(e:Event):Void 
	{
		scene.context.enableErrorChecking = true;
		if ( Input3D.keyHit( Input3D.NUMBER_1 ) ) {
			scene.lights.maxDirectionalLights = 0;
			scene.lights.maxPointLights = 0;
		}
		if ( Input3D.keyHit( Input3D.NUMBER_2 ) ) {
			scene.lights.maxDirectionalLights = 0;
			scene.lights.maxPointLights = 1;
		}
		if ( Input3D.keyHit( Input3D.NUMBER_3 ) ) {
			scene.lights.maxDirectionalLights = 1;
			scene.lights.maxPointLights = 1;
		}
	}

	private function onPostRender(e:Event):Void 
	{
		#if sys
		if (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1") {
			_renderFrames++;
			if (_renderFrames == 20) {
			saveScreenshot("test36_mode1.png");
			} else if (_renderFrames == 30) {
				scene.lights.maxDirectionalLights = 0;
				scene.lights.maxPointLights = 1;
			} else if (_renderFrames == 45) {
				saveScreenshot("test36_mode2.png");
			} else if (_renderFrames == 55) {
				scene.lights.maxDirectionalLights = 1;
				scene.lights.maxPointLights = 1;
			} else if (_renderFrames == 70) {
				saveScreenshot("test36_mode3.png");
				Sys.exit(0);
			}
		}
		#end
	}

	private function saveScreenshot(filename:String):Void 
	{
		try {
			var w = stage != null ? stage.stageWidth : 800;
			var h = stage != null ? stage.stageHeight : 450;
			if (w <= 0) w = 800;
			if (h <= 0) h = 450;
			var bmp = new openfl.display.BitmapData(w, h, false, 0x404040);
			if (scene != null && scene.context != null) {
				scene.context.drawToBitmapData(bmp);
			}
			var pngBytes = bmp.encode(bmp.rect, new openfl.display.PNGEncoderOptions());
			if (pngBytes != null) {
				#if sys
				sys.io.File.saveBytes(filename, pngBytes);
				try { sys.io.File.saveBytes("../../" + filename, pngBytes); } catch (e:Dynamic) {}
				try { sys.io.File.saveBytes("../../../" + filename, pngBytes); } catch (e:Dynamic) {}
				#end
			}
		} catch (e:Dynamic) {
			trace("Error saving screenshot: " + e);
		}
	}
}
