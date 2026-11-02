package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.utils.ByteArray;
import flare.basic.*;
import flare.core.*;
import flare.flsl.*;
import flare.loaders.*;
import flare.materials.*;
import flare.materials.filters.*;
import flare.system.*;

/**
 * @author Ariel Nehmad.
 */
class Test44_EdgeFilter extends Sprite 
{
	private static var edgeFilterData:ByteArray;
	
	private var scene:Scene3D;
	private var customShader:Shader3D;
	private var _renderFrames:Int = 0;
	private var _isLoaded:Bool = false;
	
	public function new() 
	{
		super();
		#if sys
		try {
			var bytes = sys.io.File.getBytes("assets/edgeFilter.flsl.compiled");
			edgeFilterData = ByteArray.fromBytes(bytes);
		} catch (e:Dynamic) {
			try {
				var bytes = sys.io.File.getBytes("edgeFilter.flsl.compiled");
				edgeFilterData = ByteArray.fromBytes(bytes);
			} catch (e:Dynamic) {}
		}
		#end

		scene = new Viewer3D(this, null, 0.25, 1 );
		scene.autoResize = true;
		scene.antialias = 2;
		
		scene.lights.techniqueName = LightFilter.LINEAR;
		scene.lights.maxDirectionalLights = 1;
		scene.lights.maxPointLights = 1;
		scene.lights.defaultLight.color.setTo( 0.4, 0.3, 0.2 );
		
		scene.registerClass( ZF3DLoader );
		scene.addChildFromFile( "vaca.zf3d" );
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
		
		var l:Light3D = new Light3D();
		l.setPosition( -100, 100, 0 );
		l.setParams( 0x3060ff, 200, 1, 1, true );
		l.parent = scene;
	}
	
	private function completeEvent(e:Event):Void 
	{
		_isLoaded = true;
		trace("[Test44] camera name=" + scene.camera.name + " pos=" + scene.camera.getPosition() + " dir=" + scene.camera.getDir());
		customShader = cast(scene.getMaterialByName( "Material #360" ), Shader3D);
		if (customShader != null) {
			customShader.filters.push( new FLSLFilter( edgeFilterData, openfl.display.BlendMode.NORMAL ) );
			customShader.filters.push( new NormalMapFilter( new Texture3D( "1895-normal.jpg" ) ) );
			customShader.filters.push( new SpecularFilter( 50, 0.2 ) );
			customShader.build();
			scene.setMaterial( customShader );
		}
		
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
	}
	
	private function updateEvent(e:Event):Void 
	{
		if ( Input3D.keyHit( Input3D.NUMBER_1 ) ) scene.lights.techniqueName = LightFilter.NO_LIGHTS;
		if ( Input3D.keyHit( Input3D.NUMBER_2 ) ) scene.lights.techniqueName = LightFilter.PER_VERTEX;
		if ( Input3D.keyHit( Input3D.NUMBER_3 ) ) scene.lights.techniqueName = LightFilter.LINEAR;
		if ( Input3D.keyHit( Input3D.NUMBER_4 ) ) scene.lights.techniqueName = LightFilter.SAMPLED;
	}

	private function postRenderEvent(e:Event):Void 
	{
		#if sys
		var hasFlag = false;
		try {
			if (sys.FileSystem.exists("auto_exit.flag")) {
				hasFlag = true;
				sys.FileSystem.deleteFile("auto_exit.flag");
			} else if (sys.FileSystem.exists("../../auto_exit.flag")) {
				hasFlag = true;
				sys.FileSystem.deleteFile("../../auto_exit.flag");
			} else if (sys.FileSystem.exists("../../../auto_exit.flag")) {
				hasFlag = true;
				sys.FileSystem.deleteFile("../../../auto_exit.flag");
			}
		} catch (e:Dynamic) {}
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| hasFlag;
		if (isAuto && _isLoaded) {
			_renderFrames++;
			if (_renderFrames == 1) {
				saveScreenshot("test44_frame0.png");
			}
			if (_renderFrames >= 25) {
				saveScreenshot("test44.png");
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
			var b = new openfl.display.BitmapData(w, h, false, 0x404040);
			if (scene != null && scene.context != null) {
				scene.context.drawToBitmapData(b);
			}
			var pngBytes = b.encode(b.rect, new openfl.display.PNGEncoderOptions());
			if (pngBytes != null) {
				#if sys
				sys.io.File.saveBytes(filename, pngBytes);
				try { sys.io.File.saveBytes("../../" + filename, pngBytes); } catch (e:Dynamic) {}
				try { sys.io.File.saveBytes("../../../" + filename, pngBytes); } catch (e:Dynamic) {}
				#end
			}
		} catch (e:Dynamic) {
			trace("Failed to save screenshot: " + e);
		}
	}
}
