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
	import flare.primitives.*;
	import openfl.display.*;
	import openfl.events.*;
	
	// [SWF metadata]
	
	/**
	 * How to build a new planet.
	 * @author Ariel Nehmad.
	 */
	class Test21_Planet extends Sprite 
	{
		private var scene:Scene3D;
		private var planet:Shader3D;
		private var atmosphere:Shader3D;
		private var sph1:Sphere;
		private var sph2:Sphere;
		
		public function new() 
		{
			super();
			scene = new Viewer3D(this);
			scene.clearColor.setTo( 0, 0, 0 );
			scene.camera.setPosition( 0, 0, -150 );
			scene.camera.lookAt( 0, 0, 0 );
			if (Std.isOfType(scene, Viewer3D)) {
				cast(scene, Viewer3D).syncOrbitFromCamera();
			}
			scene.lights.ambientColor.setTo( 0, 0, 0 );
			scene.lights.maxPointLights = 1;
			scene.lights.defaultLight = null;
			
			var light:Light3D = new Light3D();
			light.multiplier = 1.8;
			light.setPosition( -1000, 1000, -1000 );
			
			var texture1:Texture3D = scene.addTextureFromFile( "tex6.jpg" );
			var texture2:Texture3D = scene.addTextureFromFile( "material16.png" );
			
			planet = new Shader3D( "planetMaterial" );
			planet.filters.push( new TextureMapFilter( texture1 ) );
			planet.build();
			
			atmosphere = new Shader3D( "atmosphereMaterial", null, true );
			atmosphere.filters.push( new EnvironmentMapFilter( texture2, BlendMode.NORMAL, 2 /* saturate a bit the texture. */ ) );
			atmosphere.sourceFactor = "one"; // additive blend mode one & one.;
			atmosphere.destFactor = "one";
			atmosphere.build();
			
			sph1 = new Sphere( "planet", 50, 32, planet );
			sph2 = new Sphere( "atmosphere", 51, 32, atmosphere );
			sph2.layer = 2; // force to render after the other objects.;
			
			scene.addChild( sph1 );
			scene.addChild( sph2 );
			scene.addChild( light );
			
			scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
		}
		
		private function updateEvent(e:Event):Void 
		{
			sph1.rotateY(0.2);
			sph1.rotateX(0.1);
		}
		
	}
