package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import openfl.geom.Vector3D;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;
import openfl.Lib;
import openfl.Lib.getTimer;
import openfl.net.URLRequest;
import flare.basic.*;
import flare.core.*;
import flare.materials.*;
import flare.materials.filters.*;
import flare.primitives.*;
import flare.collisions.*;
import flare.loaders.*;
import flare.system.*;
import flare.events.*;
import flare.physics.*;
import flare.physics.colliders.*;
import flare.modifiers.*;
import flare.flsl.*;

import flare.basic.*;
	import flare.core.*;
	import flare.materials.*;
	import flare.materials.filters.*;
	import flare.system.*;
	import flare.utils.*;
	import openfl.display.*;
	import openfl.events.*;
	import openfl.utils.*;
	
	// [SWF metadata]
	
	/**
	 * NormalMap test. Drag to rotate the camera
	 * 
	 * @author Ariel Nehmad
	 */
	class Test29_NormalMap extends Sprite 
	{
		private var scene:Scene3D;
		private var material:Shader3D;
		private var model:Pivot3D;
		
		private var diffuse:Texture3D;
		private var normal:Texture3D;
		private var environment:Texture3D;
		
		private var light0:Light3D;
		private var light1:Light3D;
		private var light2:Light3D;
		
		public function new() 
		{
			super();
			scene = new Viewer3D( this );
			scene.lights.maxPointLights = 3;
			scene.lights.maxDirectionalLights = 0;
			scene.lights.ambientColor.setTo( 0.2, 0.2, 0.2 );
			scene.lights.techniqueName = LightFilter.SAMPLED;
			scene.clearColor.setTo( 80 / 255.0, 80 / 255.0, 80 / 255.0 );
			
			light0 = new Light3D();
			light0.setParams( 0xffffff, 500, 1, 1, false );
			light0.setPosition( 100, 0, -100 );
			light0.parent = scene;
			
			light1 = new Light3D();
			light1.setParams( 0xff0000, 500, 1, 1, false );
			light1.setPosition( -100, 100, -100 );
			light1.parent = scene;
			
			light2 = new Light3D();
			light2.setParams( 0x0000ff, 500, 1, 1, false );
			light2.setPosition( 0, 200, 200 );
			light2.parent = scene;
			
			model = scene.addChildFromFile( "elsa.zf3d" );
			diffuse = scene.addTextureFromFile( "gorda.png" );
			normal = scene.addTextureFromFile( "images.jpg" );
			environment = scene.addTextureFromFile( "cell01mod.png" );
			
			scene.pause();
			scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		}
		
		private function completeEvent(e:Event):Void 
		{
			if (Std.isOfType(scene, Viewer3D)) {
				var viewer:Viewer3D = cast scene;
				viewer.setTarget( 0, 0, 0 );
				scene.camera.setPosition( 0, 50, -200 );
				scene.camera.lookAt( 0, 0, 0 );
				viewer.syncOrbitFromCamera();
			} else if (scene.camera != null) {
				scene.camera.setPosition( 0, 50, -200 );
				scene.camera.lookAt( 0, 0, 0 );
			}

			material = new Shader3D( "test" );
			material.filters.push( new TextureMapFilter( diffuse ) );
			material.filters.push( new NormalMapFilter( normal ) );
			material.filters.push( new SpecularFilter( 50, 0.3 ) );
			material.build();
			
			cast(material.filters[1], NormalMapFilter).repeatX = 10;
			cast(material.filters[1], NormalMapFilter).repeatY = 10;
			
			model.setMaterial( material );
			
			scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
			scene.resume();
		}
		
		private function updateEvent(e:Event):Void 
		{
			light0.x = Math.cos( getTimer() / 1300 ) * 300;
			
			if ( Input3D.keyHit( Input3D.NUMBER_1 ) ) scene.lights.techniqueName = LightFilter.NO_LIGHTS;
			if ( Input3D.keyHit( Input3D.NUMBER_2 ) ) scene.lights.techniqueName = LightFilter.PER_VERTEX;
			if ( Input3D.keyHit( Input3D.NUMBER_3 ) ) scene.lights.techniqueName = LightFilter.LINEAR;
			if ( Input3D.keyHit( Input3D.NUMBER_4 ) ) scene.lights.techniqueName = LightFilter.SAMPLED;
			
		}
	}
