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
	 * Working with materials.
	 * 
	 * @author Ariel Nehmad
	 */
	class Test26_Materiasl2 extends Sprite 
	{
		private var scene:Scene3D;
		private var model:Pivot3D;
		
		private var diffuse:Texture3D;
		private var normal:Texture3D;
		private var environment:Texture3D;
		private var specular:Texture3D;
	
		public function new() 
		{
			super();
			scene = new Viewer3D( this );
			scene.lights.ambientColor.setTo( 0.2, 0.2, 0.2 );
			if (Std.isOfType(scene, Viewer3D)) {
				var viewer:Viewer3D = cast scene;
				viewer.setTarget( 0, 70, 0 );
			}
			
			scene.camera = new Camera3D();
			scene.camera.setPosition( 250, 70, 0 );
			scene.camera.lookAt( 0, 70, 0 );
			if (Std.isOfType(scene, Viewer3D)) {
				var viewer:Viewer3D = cast scene;
				viewer.syncOrbitFromCamera();
			}
			
			model = scene.addChildFromFile( "vaca.zf3d" );
			diffuse = scene.addTextureFromFile( "metal.jpg" );
			specular = scene.addTextureFromFile( "terrain.png" );
			normal = scene.addTextureFromFile( "images.jpg" );
			environment = scene.addTextureFromFile( "rusty.png" );
			
			scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
			scene.pause();
		}
		
		private function completeEvent(e:Event):Void 
		{
			var tFilter:TextureMapFilter = new TextureMapFilter( diffuse );
			
			var sFilter:SpecularMapFilter = new SpecularMapFilter( specular, 50, 1 );
			sFilter.repeatX = 2;
			sFilter.repeatY = 2;
			
			var nFilter:NormalMapFilter = new NormalMapFilter( normal );
			nFilter.repeatX = 5;
			nFilter.repeatY = 5;
			
			var eFilter:EnvironmentMapFilter = new EnvironmentMapFilter( environment, BlendMode.MULTIPLY, 1, EnvironmentMapFilter.PER_PIXEL );
			
			// creates a new material for a skinned mesh.
			var material:Shader3D = new Shader3D( "test", null, true, Shader3D.VERTEX_SKIN );
			material.filters.push( tFilter );
			material.filters.push( nFilter );
			material.filters.push( sFilter );
			material.filters.push( eFilter );
			material.build();
			
			var line01 = model.getChildByName( "Line01" );
			if (line01 != null) {
				line01.setMaterial( material );
			} else {
				model.setMaterial( material );
			}

			if (Std.isOfType(scene, Viewer3D)) {
				var viewer:Viewer3D = cast scene;
				viewer.setTarget( 0, 70, 0 );
				viewer.camera.setPosition( 250, 70, 0 );
				viewer.camera.lookAt( 0, 70, 0 );
				viewer.syncOrbitFromCamera();
			}
			
			scene.resume();
		}
	}
