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
	import flare.events.*;
	import flare.loaders.*;
	import flare.system.*;
	import openfl.display.*;
	import openfl.events.*;
	import openfl.geom.*;
	
	/**
	 * Tiny AngrySphere style game.
	 * @author Ariel Nehmad
	 */
	class Test03_AngrySphere extends Sprite 
	{
		// [Embed metadata]
		private var Model:Class<Dynamic>;
		
		private var scene:Scene3D;
		private var model:Flare3DLoader;
		private var ball:Pivot3D;
		private var center:Pivot3D;
		
		public function new() 
		{
			super();
			scene = new Scene3D( this );
			scene.autoResize = true;
			scene.allowImportSettings = true;
			scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
			scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
			
			reset();
		}
		
		private function postRenderEvent(e:Event):Void 
		{
			scene.physics.debug();
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
		}
		
		private function completeEvent(e:Event):Void 
		{
			model.removeEventListener( Event.COMPLETE, completeEvent );
			
			center = scene.getChildByName( "center" );
			
			ball = model.getChildByName( "ball" );
			ball.addEventListener( MouseEvent3D.MOUSE_DOWN, mouseDownEvent );
			ball.addEventListener( Pivot3D.EXIT_DRAG_EVENT, exitDragEvent );
			
			scene.resume();
		}
		
		private function updateEvent(e:Event):Void 
		{
			scene.physics.step( 3, 1 / 12 );
			
			if ( Input3D.keyHit( Input3D.R ) )
				reset();
		}
		
		private function exitDragEvent(e:Event):Void 
		{
			// constrain the ball to the center.
			ball.setPosition( center.x, center.y, center.z, 0.7 );
			
			// if we reach the macimum distance when draging, set the ball at its maximum distance.
			var d:Vector3D = new Vector3D();
			d.x = ball.x - center.x;
			d.y = ball.y - center.y;
			d.z = ball.z - center.z;
			if ( d.length > 100 ) {
				d.normalize();
				d.scaleBy( 100 );
				ball.setPosition( center.x + d.x, center.y + d.y, center.z + d.z );
			}
		}
		
		private function mouseDownEvent(e:MouseEvent3D):Void 
		{
			// drag the ball along a plane pointing forward..
			ball.startDrag( true, new Vector3D( 0, 0, 1 ) );
			
			stage.addEventListener( MouseEvent.MOUSE_UP, mouseUpEvent );
		}
		
		private function mouseUpEvent(e:MouseEvent):Void 
		{
			ball.stopDrag();
			
			// calculate the impulse direction, multiplied by some random factor.
			var factor:Float = 3;
			var dx:Float = (center.x - ball.x) * factor;
			var dy:Float = (center.y - ball.y) * factor;
			var dz:Float = (center.z - ball.z) * factor;
			ball.collider.applyImpulse( dx, dy, dz );
			
			stage.removeEventListener( MouseEvent.MOUSE_UP, mouseUpEvent );
		}
	}
