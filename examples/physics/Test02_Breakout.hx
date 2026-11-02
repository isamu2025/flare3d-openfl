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
	import flare.loaders.*;
	import flare.physics.*;
	import flare.system.*;
	import flare.utils.*;
	import openfl.display.*;
	import openfl.events.*;
	import openfl.geom.*;
	
	/**
	 * Minimalistic breakout game.
	 * @author Ariel Nehmad
	 */
	class Test02_Breakout extends Sprite 
	{
		// [Embed metadata]
		private var Model:Class<Dynamic>;
		
		private var scene:Scene3D;
		private var model:Flare3DLoader;
		private var ball:Pivot3D;
		private var pad:Pivot3D;
		
		private var speed:Float = 10;
		private var dir:Vector3D = new Vector3D();
		private var normal:Vector3D = new Vector3D();
		
		public function new() 
		{
			super();
			scene = new Scene3D( this );
			scene.autoResize = true;
			scene.allowImportSettings = true;
			scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
			
			reset();
		}
		
		private function reset():Void
		{
			scene.pause();
			
			if (model != null) 
				model.dispose();
			
			model = new Flare3DLoader( Type.createInstance(Model, []));
			model.addEventListener( Event.COMPLETE, completeEvent );
			model.load();
			model.parent = scene;
			
			dir.x = Math.random() * 2 - 1;
			dir.y = 0;
			dir.z = -1;
			dir.normalize();
		}
		
		private function completeEvent(e:Event):Void 
		{
			model.removeEventListener( Event.COMPLETE, completeEvent );
			
			// colliders are already set in the IDE, so we just get their references.
			// it is worth to mention that the ball is set to collect contacts, otherwise it wont.
			ball = scene.getChildByName( "ball" );
			pad = scene.getChildByName( "pad" );
			
			scene.resume();
		}
		
		private function updateEvent(e:Event):Void 
		{
			// the pad is a kinematic object, so we get collisions with the walls for free.
			if ( Input3D.keyDown( Input3D.LEFT ) ) pad.x -= 10;
			if ( Input3D.keyDown( Input3D.RIGHT ) ) pad.x += 10;
			
			dir.normalize();
			dir.scaleBy( speed );
			ball.x += dir.x;
			ball.z += dir.z;
			
			// update collisions.
			scene.physics.step();
			
			if (ball.collider.numContacts > 0) {
				// we just get the first contact info.
				var data:ContactData = ball.collider.contactData[0];
				
				if ( data.collider.pivot.name == "pad" ) {
					// adjust the normal depending on the ball to pad distance.
					normal.x = (ball.x - pad.x);
					normal.y = 0;
					normal.z = 200;
				} else {
					normal.x = data.info.normalX;
					normal.y = data.info.normalY;
					normal.z = data.info.normalZ;
				}
				
				// remove blocks.
				if ( data.collider.pivot.name == "block" )
					scene.removeChild( data.collider.pivot );
					
				// and mirror the ball direction.
				Vector3DUtils.mirror( dir, normal, dir );
			}
			
			pad.z = -400;
			
			if ( Input3D.keyHit( Input3D.R ) )
				reset();
		}
	}
