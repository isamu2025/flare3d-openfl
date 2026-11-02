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
	class Test25_Materiasl1 extends Sprite 
	{
		private var scene:Scene3D;
		private var model:Pivot3D;
		private var normal:Texture3D;
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
			scene.camera.setPosition( 200, 70, 0 );
			scene.camera.lookAt( 0, 70, 0 );
			if (Std.isOfType(scene, Viewer3D)) {
				var viewer:Viewer3D = cast scene;
				viewer.syncOrbitFromCamera();
			}
			
			model = scene.addChildFromFile( "vaca.zf3d" );
			specular = scene.addTextureFromFile( "terrain.png" );
			normal = scene.addTextureFromFile( "images.jpg" );
			
			scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
			scene.pause();
		}
		
		private function completeEvent(e:Event):Void 
		{
			var sFilter:SpecularMapFilter = new SpecularMapFilter( specular, 50, 1 );
			sFilter.repeatX = 2;
			sFilter.repeatY = 2;
			
			var nFilter:NormalMapFilter = new NormalMapFilter( normal );
			nFilter.repeatX = 5;
			nFilter.repeatY = 5;
			
			// gets the original material and adds new filters to it.
			var material:Shader3D = cast(model.getMaterialByName( "Material #360" ), Shader3D);
			if (material == null) {
				material = cast(model.getMaterialByName( "Material_Cow" ), Shader3D);
			}
			if (material == null) {
				var allMats = model.getMaterials();
				for (m in allMats) {
					if (m != null && (m.name == "Material #360" || m.name.indexOf("360") != -1)) {
						material = cast m;
						break;
					}
				}
				if (material == null && allMats.length > 0) {
					material = cast allMats[0];
				}
			}
			if (material != null) {
				material.filters.push( nFilter );
				material.filters.push( sFilter );
				material.build();
			}

			if (Std.isOfType(scene, Viewer3D)) {
				var viewer:Viewer3D = cast scene;
				viewer.setTarget( 0, 70, 0 );
				viewer.camera.setPosition( 200, 70, 0 );
				viewer.camera.lookAt( 0, 70, 0 );
				viewer.syncOrbitFromCamera();
			}
			
			scene.resume();
		}
	}
