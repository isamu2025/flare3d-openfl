package examples;



import openfl.display.Sprite;

import openfl.events.Event;

import openfl.geom.Point;

import openfl.Lib;

import openfl.Lib.getTimer;

import flare.basic.*;

import flare.core.*;

import flare.loaders.*;

import flare.materials.*;

import flare.materials.filters.*;

import flare.primitives.*;

import flare.utils.*;



/**

 * @author Ariel Nehmad

 */

class Test49_DynamicReflection extends Sprite 

{

	private var scene:Scene3D;

	private var teapot:Pivot3D;

	private var chess:Pivot3D;

	

	private var projTexture:Texture3D;

	private var projCamera:Camera3D;

	

	private var envCamera:Camera3D;

	private var envTexture:Texture3D;

	private var envSphere:Pivot3D;

	private var envShader:Shader3D;

	

	private var reflectiveMaterial:Shader3D;

	private var _renderFrames:Int = 0;

	private var _isLoaded:Bool = false;

	

	public function new() 

	{

		super();

		scene = new Viewer3D( this, null, 0.3 );

		scene.skipFrames = false;

		scene.antialias = 2;

		scene.autoResize = true;

		scene.registerClass( ZF3DLoader );

		scene.addEventListener( Scene3D.PROGRESS_EVENT, progressEvent );

		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );

		scene.addChild( new SkyBox( "skybox2b.png", SkyBox.HORIZONTAL_CROSS, scene ) );

		

		chess = scene.addChildFromFile( "chess2.zf3d" );

		teapot = scene.addChildFromFile( "teapot2.zf3d" );
		

		

		projTexture = new Texture3D( new Point( 512, 512 ), true );

		envTexture = new Texture3D( new Point( 512, 512 ), true );

	}

	

	private function progressEvent(e:Event):Void 

	{

	}

	

	private function completeEvent(e:Event):Void 

	{

		trace( "complete" );

		if (_isLoaded) return;
        trace('[SCENE CHILDREN DUMP]');
        function dump(p:Pivot3D, indent:String) {
            trace(indent + p.name + ' pos=' + p.getPosition(false) + ' mesh=' + (Std.isOfType(p, Mesh3D) ? 'yes' : 'no'));
            for (ch in p.children) dump(ch, indent + '  ');
        }
        for (ch in scene.children) dump(ch, '');


		_isLoaded = true;

		

		var textureMap:TextureMapFilter = new TextureMapFilter( projTexture );

		textureMap.repeatX = -2;

		textureMap.repeatY = 1;

		

		envShader = new Shader3D( "envMaterial", [textureMap], false );

		envSphere = new Sphere( "sphere", 128, 24, envShader );

		

		projCamera = new Camera3D( "projCamera", 135 );

		// projCamera.viewPort removed

		projCamera.aspectRatio = 1.0;

		projCamera.updateProjection( 512, 512 );

		projCamera.parent = envSphere;

		

		envCamera = new Camera3D( "envCamera", 30 );

		// envCamera.viewPort removed

		envCamera.aspectRatio = 1.0;

		envCamera.updateProjection( 512, 512 );

		envCamera.z = -0.5 / envCamera.zoom * 256;

		envCamera.parent = envSphere;

		

		reflectiveMaterial = new Shader3D( "reflection", [new EnvironmentMapFilter( envTexture )] );

		

		teapot.setMaterial( reflectiveMaterial );

		if (Std.isOfType(scene, Viewer3D)) {
			var viewer:Viewer3D = cast scene;
			viewer.setTarget(-10, 45, 0);
			scene.camera.fieldOfView = 58;
			scene.camera.near = 10;
			scene.camera.far = 4000;
			scene.camera.setPosition(-430, 180, -250);
			scene.camera.lookAt(-10, 45, 0);
			viewer.syncOrbitFromCamera();
		}
		
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );

	}

	

	private function postRenderEvent(e:Event):Void 

	{

		if (projTexture.scene == null || projTexture.texture == null) projTexture.upload(scene);

		if (envTexture.scene == null || envTexture.texture == null) envTexture.upload(scene);



		teapot.rotateY( -0.5 );

		teapot.x = Math.cos( getTimer() / 2000 ) * 100;

		teapot.z = Math.cos( getTimer() / 1850 ) * 100;

		teapot.y = 100;
        teapot.updateTransforms(true);
        if (_renderFrames < 3) {
            trace('[TEAPOT DEBUG] teapot.world=' + teapot.world.rawData);
            var child = teapot.getChildByName('Teapot001');
            if (child != null) trace('[TEAPOT DEBUG] Teapot001.world=' + child.world.rawData);
        }

		

		envSphere.setPosition( teapot.x, teapot.y, teapot.z );

		Pivot3DUtils.lookAtWithReference( envSphere, 0, 0, 0, scene.camera, scene.camera.getUp(false) );
		envSphere.updateTransforms( true );

		

		teapot.visible = false;

		scene.render( projCamera, false, projTexture );

		teapot.visible = true;

		

		if (scene.context != null && envTexture.texture != null) {

			scene.context.setRenderToTexture( envTexture.texture, true );

			scene.context.setScissorRectangle( null );

			scene.context.clear( 0, 0, 0, 1.0, 1.0, 0 );

			scene.setupFrame( envCamera );

			envSphere.draw( true );

			scene.context.setRenderToBackBuffer();

			scene.context.setScissorRectangle( null );

			if (scene.camera != null) {

				scene.setupFrame( scene.camera );

			}

		}



		#if sys

		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")

			|| (Sys.args().indexOf("--auto-exit") != -1)

			|| (Sys.args().indexOf("auto") != -1)

			|| sys.FileSystem.exists("auto_exit.flag");

		if (isAuto && _isLoaded) {

			_renderFrames++;

			if (_renderFrames >= 20) {

				saveScreenshot("test49.png");
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


	}
