package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import flare.basic.Scene3D;
import flare.basic.Viewer3D;
import flare.core.Camera3D;
import flare.core.Light3D;
import flare.core.Pivot3D;
import flare.core.Mesh3D;
import flare.core.Texture3D;
import flare.core.ShadowProjector3D;
import flare.materials.Shader3D;
import flare.materials.filters.LightMapFilter;
import flare.primitives.DebugLight;
import flare.system.Input3D;

/**
 * @author Ariel Nehmad
 */
class Test60_ShadowProjector extends Sprite 
{
	private var scene:Scene3D;
	private var proj:ShadowProjector3D;
	private var camera:Camera3D;
	private var _renderFrames:Int = 0;
	private var _isLoaded:Bool = false;
	
	public function new() 
	{
		super();
		scene = new Viewer3D( this, null, 0.25 );
		scene.autoResize = true;
		scene.addChildFromFile( "chess2_noLightmaps.zf3d" );
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
	}
	
	private function completeEvent(e:Event):Void 
	{
		_isLoaded = true;
		
		// remove original lights.
		var lights = scene.getChildrenByClass( Light3D );
		for (l in lights)
			l.parent = null;
		
		proj = new ShadowProjector3D( "proj 1", ShadowProjector3D.QUALITY_BEST, 3 );
		proj.setPosition( -100, 200, 200 );
		proj.lookAt( 0, 0, 0 );
		proj.far = 1000;
		proj.filter = 1000; 
		proj.setParams( 0xffaa40, 0, 1, 1.5 );
		proj.parent = scene;
		proj.debug = false;
		proj.addChild( new DebugLight( proj ) );
		
		// disable the default light, we want to use the projector instead.
		scene.lights.defaultLight = null;
		scene.lights.ambientColor.setTo( 0.1, 0.2, 0.4 );

		// Camera matching Flash AS3 original active camera in chess2_noLightmaps.zf3d
		if (scene.camera != null) {
			scene.camera.fovMode = Camera3D.FOV_VERTICAL;
			scene.camera.fieldOfView = 75.0;
			scene.camera.near = 1.0;
			scene.camera.far = 100000.0;
			scene.camera.setPosition( 204.198, 153.197, -240.937 );
			scene.camera.lookAt( 0, 0, 0 );
			if (Std.isOfType(scene, Viewer3D)) {
				cast(scene, Viewer3D).setTarget( 0, 0, 0 );
				cast(scene, Viewer3D).syncOrbitFromCamera();
			}
		}

		// Apply soft contact shadow lightmap to Desk surface
		var desk:Mesh3D = cast scene.getChildByName("Desk");
		if (desk != null) {
			var lmTex = new Texture3D("Desk_lightmap.jpg");
			for (m in desk.materials) {
				if (Std.isOfType(m, Shader3D)) {
					var s:Shader3D = cast m;
					s.addFilter(new LightMapFilter(lmTex, 2));
				}
			}
		}
		
		// just debug to see the textures on screen.
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
	}
	
	private function postRenderEvent(e:Event):Void 
	{
		// align the projector with the camera.
		if ( Input3D.keyDown( Input3D.Q ) ) {
			proj.world = scene.camera.world;
			proj.translateZ( 50 );
		}
		
		if (proj != null)
			proj.updateTextures(scene);

		if (proj != null && proj.depthTexture != null)
			scene.drawQuadTexture( proj.depthTexture, 0, 0, 150, 150 );
		if (scene.lights != null && scene.lights.shadowMapTexture != null)
			scene.drawQuadTexture( scene.lights.shadowMapTexture, 0, 150, 150, 150 );

		#if sys
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| (Sys.args().indexOf("auto") != -1)
			|| sys.FileSystem.exists("auto_exit.flag");
		if (isAuto && _isLoaded) {
			_renderFrames++;
			if (_renderFrames >= 15) {
				saveScreenshot("test60.png");
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
				#end
			}
		} catch (e:Dynamic) {
			trace("Error saving screenshot: " + e);
		}
	}
}
