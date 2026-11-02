package examples.physics;

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
	import flare.physics.colliders.*;
	import flare.physics.*;
	import flare.primitives.*;
	import openfl.display.*;
	import openfl.events.*;
	
	/**
	 * A bit of strees test :)
	 * Make sure to compile it in "Release" mode!.
	 * @author Ariel Nehmad
	 */
	class Test04_BruteForce extends Sprite 
	{
		private var scene:Scene3D;
		private var spheresBatch:MeshBatch3D;
		private var cubesBatch:MeshBatch3D;
		
		public function new() 
		{
			super();
			scene = new Viewer3D( this, null, 0.2 );
			scene.autoResize = true;
			scene.clearColor.setTo( 0.2, 0.3, 0.4 );
			scene.camera.setPosition( 250, 500, -700 );
			scene.camera.lookAt( 0, 0, 0 );
			scene.lights.setFogProperties( true, 0, 1600, 0.1, 0.2, 0.3 );
			scene.lights.setGamma();
			
			// create the floor.
			var floorMaterial:Shader3D = new Shader3D( "fm", [new NullFilter(0xffffff, 20)] );
			var floor:Cube = new Cube( "", 2000, 30, 2000, 1, floorMaterial );
			floor.collider = new BoxCollider( floor.width, floor.height, floor.depth );
			floor.collider.isStatic = true;
			floor.y = -0;
			floor.parent = scene;
			
			// create spheres and cubes.
			var cubesMaterial:Shader3D = new Shader3D( "cm", [new NullFilter( 0x405060, 5 )] );
			var sphereMaterial:Shader3D = new Shader3D( "sm", [new NullFilter( 0x604050, 5 )] );
			var sphere:Sphere = new Sphere( "s", 15, 24, sphereMaterial );
			var cube:Cube = new Cube( "c", 50, 25, 25, 1, cubesMaterial );
			
			// we use a batch for each one to speed up the rendering part and focus on the physics performance.
			spheresBatch = new MeshBatch3D( sphere );
			cubesBatch = new MeshBatch3D( cube );
			
			var collider:Collider;
			
			// brute force 500 spheres + 500 cubes, all set to neverSleep.
			// to try with sleeping mode, uncomment the folowing line (see docs).
			//Physics.sleepingOverlap = 0.5;
			
			for (i in 0...500) {
				
				// spheres.
				collider = new SphereCollider( sphere.radius );
				collider.isRigidBody = true;
				collider.neverSleep = true;
				collider.friction = 1;
				collider.restitution = 0.3;
				collider.position.x = Math.random() * 500 - 250;
				collider.position.y = Math.random() * 900 + 100;
				collider.position.z = Math.random() * 500 - 250;
				spheresBatch.addInstance( collider.position, collider.orientation );
				// we add the collider manually because we're using a batch instead of a regular Pivot3D.
				scene.physics.addCollider( collider );
				
				// cubes.
				collider = new BoxCollider( cube.width, cube.height, cube.depth );
				collider.isRigidBody = true;
				collider.neverSleep = true;
				collider.friction = 1;
				collider.restitution = 0.3;
				collider.position.x = Math.random() * 500 - 250;
				collider.position.y = Math.random() * 900 + 100;
				collider.position.z = Math.random() * 500 - 250;
				cubesBatch.addInstance( collider.position, collider.orientation );
				// we add the collider manually because we're using a batch instead of a regular Pivot3D.
				scene.physics.addCollider( collider );
			}
			
			scene.addChild( spheresBatch );
			scene.addChild( cubesBatch );
			scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
		}
		
		private function updateEvent(e:Event):Void 
		{
			scene.physics.step( 3, 1 / 30 );
		}
	}
