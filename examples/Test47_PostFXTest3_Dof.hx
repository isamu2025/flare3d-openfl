package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.utils.ByteArray;
import flare.basic.*;
import flare.core.*;
import flare.loaders.*;
import flare.materials.*;
import flare.materials.filters.*;
import flare.flsl.*;
import flare.primitives.*;
import flare.system.*;

/**
 * @author Ariel Nehmad
 */
class Test47_PostFXTest3_Dof extends Sprite 
{
	private static var fovData:ByteArray;
	
	private var scene:Viewer3D;
	private var quad:Quad;
	
	private var sceneTexture:Texture3D;
	private var depthTexture:Texture3D;
	
	private var depthMaterial:FLSLMaterial;
	private var dofMaterial:FLSLMaterial;
	private var _renderFrames:Int = 0;
	private var _isLoaded:Bool = false;
	
	public function new() 
	{
		super();
		#if sys
		try {
			var bytes = sys.io.File.getBytes("assets/dof.flsl.compiled");
			fovData = ByteArray.fromBytes(bytes);
		} catch (e:Dynamic) {
			try {
				var bytes = sys.io.File.getBytes("dof.flsl.compiled");
				fovData = ByteArray.fromBytes(bytes);
			} catch (e:Dynamic) {}
		}
		#end

		scene = new Viewer3D( this, null, 0.1 );
		scene.registerClass( ZF3DLoader );
		scene.autoResize = true;
		scene.skipFrames = false;			
		scene.antialias = 2;
		
		depthTexture = new Texture3D( new Point( 512, 256 ), true );
		sceneTexture = new Texture3D( new Point( 512, 256 ), true );
		
		depthMaterial = new FLSLMaterial( "dof", fovData, "depth" );
		depthMaterial.params.nearFar.value[0] = 100;
		depthMaterial.params.nearFar.value[1] = 500;
		
		dofMaterial = new FLSLMaterial( "dof", fovData, "dof" );
		dofMaterial.params.sceneTexture.value = sceneTexture;
		dofMaterial.params.depthTexture.value = depthTexture;
		
		quad = new Quad( "depth", 0, 0, 0, 0, true, dofMaterial );
		
		scene.addChildFromFile( "chess2.zf3d" );
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		scene.addChild( new SkyBox( "skybox2b.png", SkyBox.HORIZONTAL_CROSS, scene ) );
	}
	
	private function completeEvent(e:Event):Void 
	{
		_isLoaded = true;
																																																				if (scene != null && scene.camera != null) {
			scene.camera.setPosition(-183.79, 79.39, 301.19);
			scene.camera.lookAt(-19.95, 23.45, 0.00);
			scene.camera.fieldOfView = 96.84;
			scene.camera.near = 10;
			scene.camera.far = 4000;
			scene.setTarget(-19.95, 23.45, 0.00);
			var sw:Float = (stage != null && stage.stageWidth > 0) ? stage.stageWidth : 800;
			var sh:Float = (stage != null && stage.stageHeight > 0) ? stage.stageHeight : 450;
			scene.camera.updateProjection(sw, sw > 0 ? sh : 450);
			scene.syncOrbitFromCamera();
		}
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
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
		// make sure the texture is ready to use.
		if (depthTexture.scene == null || depthTexture.texture == null) depthTexture.upload( scene );
		if (sceneTexture.scene == null || sceneTexture.texture == null) sceneTexture.upload( scene );
		
		if (scene.context != null && depthTexture.texture != null) {
			// this time, we'll render our custom depth pass.
			scene.context.setRenderToTexture( depthTexture.texture, true );
			scene.context.clear( 1.0, 1.0, 1.0, 1.0 );
			
			// draws everything on the render list.
			var len:Int = scene.renderList.length;
			for (i in 0...len) scene.renderList[i].draw( false, depthMaterial );
			
			scene.context.setRenderToBackBuffer();
		}
		
		// render the scene to a texture to mix with the depth texture.
		scene.render( scene.camera, false, sceneTexture );
		
		quad.draw();

		#if sys
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| (Sys.args().indexOf("auto") != -1)
			|| sys.FileSystem.exists("auto_exit.flag");
		if (isAuto && _isLoaded) {
			_renderFrames++;
			if (_renderFrames >= 20) {
				saveScreenshot("test47.png");
				saveTextureScreenshot(depthTexture, "depth.png");
				saveTextureScreenshot(sceneTexture, "scene_tex.png");
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
		} catch (e:Dynamic) {
			trace("Failed to save screenshot: " + e);
		}
	}

	private function saveTextureScreenshot(tex:Texture3D, filename:String):Void 
	{
		try {
			if (scene == null || scene.context == null || tex == null || tex.texture == null) return;
			var w = tex.width > 0 ? Std.int(tex.width) : 512;
			var h = tex.height > 0 ? Std.int(tex.height) : 256;
			var b = new openfl.display.BitmapData(w, h, true, 0x0);
			scene.context.setRenderToTexture(tex.texture, false);
			scene.context.drawToBitmapData(b);
			scene.context.setRenderToBackBuffer();
			var pngBytes = b.encode(b.rect, new openfl.display.PNGEncoderOptions());
			if (pngBytes != null) {
				#if sys
				sys.io.File.saveBytes(filename, pngBytes);
				try { sys.io.File.saveBytes("../../" + filename, pngBytes); } catch (e:Dynamic) {}
				#end
			}
		} catch (e:Dynamic) {
			trace("Failed to save texture screenshot: " + e);
		}
	}
}
